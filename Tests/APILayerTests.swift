import Foundation
import Testing

@testable import FMFoundation

/// 用於測試中偵測主佇列執行的 key。
private let mainQueueKey = DispatchSpecificKey<Bool>()

/// Stub 回應型別。
enum StubResponseType: String {
    /// 回傳 HTTPURLResponse。
    case http
    /// 回傳非 HTTP 回應。
    case nonHTTP
    /// 直接回傳錯誤。
    case error
}

/// 測試用的 URLProtocol，用於攔截網路請求。
/// - Important: 僅能搭配 `URLSessionConfiguration.ephemeral` 使用。
final class StubURLProtocol: URLProtocol {
    /// 用於在 request 上存放回應資料的 key。
    fileprivate static let responseDataKey = "StubURLProtocol.responseData"
    /// 用於在 request 上存放狀態碼的 key。
    fileprivate static let statusCodeKey = "StubURLProtocol.statusCode"
    /// 用於在 request 上存放回應型別的 key。
    fileprivate static let responseTypeKey = "StubURLProtocol.responseType"

    /// 判斷是否能處理此 request。
    /// - Parameter request: 要評估的 request。
    /// - Returns: 固定回傳 `true` 以攔截所有請求。
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    /// 回傳 request 的標準版本。
    /// - Parameter request: 原始 request。
    /// - Returns: 不修改的 request。
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// 開始載入 request 並回傳 stubbed response。
    override func startLoading() {
        let responseTypeRaw = URLProtocol.property(
            forKey: Self.responseTypeKey,
            in: request
        ) as? String
        let responseType = StubResponseType(rawValue: responseTypeRaw ?? "") ?? .http

        switch responseType {
        case .error:
            client?.urlProtocol(self, didFailWithError: TestError.sample)

        case .nonHTTP:
            let response = URLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data())
            client?.urlProtocolDidFinishLoading(self)

        case .http:
            let responseData = URLProtocol.property(
                forKey: Self.responseDataKey,
                in: request
            ) as? Data ?? Data()
            let statusCode = URLProtocol.property(
                forKey: Self.statusCodeKey,
                in: request
            ) as? Int ?? 200
            let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: responseData)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    /// 停止載入 request。
    override func stopLoading() { }
}

/// 記錄決策是否在主佇列執行。
actor DecisionThreadRecorder {
    /// 儲存主佇列旗標。
    private var isMainQueue: Bool?

    /// 更新主佇列旗標。
    /// - Parameter value: 呼叫端是否在主佇列。
    func setIsMainQueue(_ value: Bool) {
        isMainQueue = value
    }

    /// 取得主佇列旗標。
    /// - Returns: 最近一次記錄的值（若有）。
    func getIsMainQueue() -> Bool? {
        isMainQueue
    }
}

/// 記錄重送次數。
actor RestartRecorder {
    /// 重送次數。
    private var count = 0

    /// 累加並回傳重送次數。
    func increment() -> Int {
        count += 1
        return count
    }

    /// 取得重送次數。
    func getCount() -> Int {
        count
    }
}

/// 測試用決策：記錄執行佇列並繼續決策鏈。
struct DecisionThreadCheck: APIDecision {
    /// 用於捕捉主佇列狀態的 recorder。
    let recorder: DecisionThreadRecorder

    /// 固定套用此決策。
    func shouldApply(request _: some APIRequest, data _: Data, response _: HTTPURLResponse) -> Bool {
        true
    }

    /// 記錄佇列狀態並完成請求。
    /// - Returns: 回傳 `.done` 的型別化回應。
    func apply<Request: APIRequest>(
        request _: Request,
        data _: Data,
        response _: HTTPURLResponse
    ) async -> APIDecisionAction<Request> {
        let isMainQueue = DispatchQueue.getSpecific(key: mainQueueKey) == true
        await recorder.setIsMainQueue(isMainQueue)
        let responseValue = ThreadCheckRequest.Response(message: "ok")
        #expect(responseValue is Request.Response, "Response does not match expected model")
        return .done(responseValue as! Request.Response)
    }
}

/// 用於驗證決策執行上下文的最小請求。
struct ThreadCheckRequest: APIRequest {
    /// 測試用的回應模型。
    struct Response: Codable {
        /// 佔位用欄位，滿足解碼需求。
        let message: String
    }

    /// 請求的 Base URL。
    let baseURL: URL? = URL(string: "https://example.com")
    /// 請求路徑。
    let path = "/thread-check"
    /// HTTP 方法。
    let method: APIHttpMethod = .GET
    /// 請求參數。
    var parameters: APIParameterConvertible = [:]
    /// Content type。
    let contentType: APIContentType = .json
    /// 額外標頭。
    let extraHeader: [String: String] = [:]
    /// 請求逾時。
    let timeout: TimeInterval = 30
    /// 該請求使用的決策。
    let decisions: [APIDecision]
    /// 注入 stub 回應資訊的 adapter。
    let stubAdapter: APIRequestAdapter

    /// 該請求使用的 adapter。
    var adapters: [APIRequestAdapter] {
        [
            stubAdapter,
        ]
    }
}

/// 將 stub 回應資料寫入 URLRequest 的 adapter。
private struct StubResponseAdapter: APIRequestAdapter {
    /// Stub 回應資料。
    let responseData: Data
    /// Stub 狀態碼。
    let statusCode: Int
    /// Stub 回應型別。
    let responseType: StubResponseType

    /// 建立 stub adapter。
    /// - Parameters:
    ///   - responseData: Stub 回應資料。
    ///   - statusCode: Stub 狀態碼。
    ///   - responseType: 回應型別。
    init(
        responseData: Data,
        statusCode: Int,
        responseType: StubResponseType = .http
    ) {
        self.responseData = responseData
        self.statusCode = statusCode
        self.responseType = responseType
    }

    /// 將 stub 資訊附加到 request，供 `StubURLProtocol` 讀取。
    /// - Parameter request: 原始 request。
    /// - Returns: 含 stub 資訊的 request。
    func adapted(_ request: URLRequest) throws -> URLRequest {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return request
        }
        URLProtocol.setProperty(
            responseData,
            forKey: StubURLProtocol.responseDataKey,
            in: mutableRequest
        )
        URLProtocol.setProperty(
            statusCode,
            forKey: StubURLProtocol.statusCodeKey,
            in: mutableRequest
        )
        URLProtocol.setProperty(
            responseType.rawValue,
            forKey: StubURLProtocol.responseTypeKey,
            in: mutableRequest
        )
        return mutableRequest as URLRequest
    }
}

/// 測試用決策：固定回傳 error。
struct ErrorDecision: APIDecision {
    /// 固定套用此決策。
    func shouldApply(request _: some APIRequest, data _: Data, response _: HTTPURLResponse) -> Bool {
        true
    }

    /// 回傳 `.error`。
    func apply<Request: APIRequest>(
        request _: Request,
        data _: Data,
        response _: HTTPURLResponse
    ) async -> APIDecisionAction<Request> {
        .error(TestError.sample)
    }
}

/// 測試用決策：固定回傳 `.done`。
struct DoneDecision: APIDecision {
    /// 要回傳的訊息。
    let message: String

    /// 固定套用此決策。
    func shouldApply(request _: some APIRequest, data _: Data, response _: HTTPURLResponse) -> Bool {
        true
    }

    /// 回傳 `.done`。
    func apply<Request: APIRequest>(
        request _: Request,
        data _: Data,
        response _: HTTPURLResponse
    ) async -> APIDecisionAction<Request> {
        let responseValue = ThreadCheckRequest.Response(message: message)
        return .done(responseValue as! Request.Response)
    }
}

/// 測試用決策：回傳 `.continue` 並帶入新資料。
struct ContinueDecision: APIDecision {
    /// 要注入的回應訊息。
    let message: String

    /// 固定套用此決策。
    func shouldApply(request _: some APIRequest, data _: Data, response _: HTTPURLResponse) -> Bool {
        true
    }

    /// 回傳 `.continue`。
    func apply<Request: APIRequest>(
        request _: Request,
        data _: Data,
        response: HTTPURLResponse
    ) async -> APIDecisionAction<Request> {
        let payload = try! JSONEncoder().encode(ThreadCheckRequest.Response(message: message))
        let httpResponse = HTTPURLResponse(
            url: response.url ?? URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return .continue(payload, httpResponse)
    }
}

/// 測試用決策：回傳 `.restart` 並帶入新決策。
struct RestartDecision: APIDecision {
    /// 重送記錄器。
    let recorder: RestartRecorder
    /// 重送後回傳的訊息。
    let message: String

    /// 固定套用此決策。
    func shouldApply(request _: some APIRequest, data _: Data, response _: HTTPURLResponse) -> Bool {
        true
    }

    /// 回傳 `.restart`。
    func apply<Request: APIRequest>(
        request _: Request,
        data _: Data,
        response _: HTTPURLResponse
    ) async -> APIDecisionAction<Request> {
        let count = await recorder.increment()
        if count == 1 {
            return .restart([DoneDecision(message: message)])
        }
        let responseValue = ThreadCheckRequest.Response(message: "unexpected")
        return .done(responseValue as! Request.Response)
    }
}

/// 測試用錯誤。
enum TestError: Error, Equatable {
    /// 範例錯誤。
    case sample
}

@Suite
struct APILayerTests {
    /// 驗證在 MainActor 上呼叫 send 時，決策仍不在主佇列執行。
    @Test("Decision runs off main when send is called on MainActor")
    @MainActor
    func decisionRunsOffMainFromMainActor() async throws {
        DispatchQueue.main.setSpecific(key: mainQueueKey, value: true)

        let recorder = DecisionThreadRecorder()
        let decision = DecisionThreadCheck(recorder: recorder)
        let responseData = Data()
        let stubAdapter = StubResponseAdapter(responseData: responseData, statusCode: 200)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]

        let session = URLSession(configuration: config)
        let client = APIClient(session: session)
        let request = ThreadCheckRequest(
            decisions: [decision],
            stubAdapter: stubAdapter
        )

        _ = try await request.send(client: client)

        let isMainQueue = await recorder.getIsMainQueue()
        #expect(isMainQueue == false)
    }

    /// 驗證非 HTTP 回應會拋出 `.invalidHTTPResponse`。
    @Test("Non-HTTP response should throw invalidHTTPResponse")
    func nonHTTPResponseThrowsInvalidHTTPResponse() async {
        let stubAdapter = StubResponseAdapter(
            responseData: Data(),
            statusCode: 200,
            responseType: .nonHTTP
        )

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]

        let session = URLSession(configuration: config)
        let client = APIClient(session: session)
        let request = ThreadCheckRequest(
            decisions: [DoneDecision(message: "ok")],
            stubAdapter: stubAdapter
        )

        do {
            _ = try await request.send(client: client)
            #expect(Bool(false), "Expected invalidHTTPResponse")
        } catch {
            if case .invalidHTTPResponse = error {
                // do nothing
            } else {
                #expect(Bool(false), "Unexpected error type: \(error)")
            }
        }
    }

    /// 驗證 session 錯誤會被包成 `.unknown`。
    @Test("Session error should wrap to unknown")
    func sessionErrorWrapsToUnknown() async {
        let stubAdapter = StubResponseAdapter(
            responseData: Data(),
            statusCode: 200,
            responseType: .error
        )

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]

        let session = URLSession(configuration: config)
        let client = APIClient(session: session)
        let request = ThreadCheckRequest(
            decisions: [DoneDecision(message: "ok")],
            stubAdapter: stubAdapter
        )

        do {
            _ = try await request.send(client: client)
            #expect(Bool(false), "Expected unknown error")
        } catch {
            if case .unknown(let underlyingError) = error {
                let nsError = underlyingError as NSError
                #expect(nsError.domain.isEmpty == false)
            } else {
                #expect(Bool(false), "Expected unknown error, got \(error)")
            }
        }
    }

    /// 驗證空決策會拋出 `.emptyDecisions`。
    @Test("Empty decisions should throw emptyDecisions")
    func emptyDecisionsThrowsEmptyDecisions() async {
        let stubAdapter = StubResponseAdapter(responseData: Data(), statusCode: 200)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]

        let session = URLSession(configuration: config)
        let client = APIClient(session: session)
        let request = ThreadCheckRequest(
            decisions: [],
            stubAdapter: stubAdapter
        )

        do {
            _ = try await request.send(client: client)
            #expect(Bool(false), "Expected emptyDecisions")
        } catch {
            if case .emptyDecisions = error {
                // do nothing
            } else {
                #expect(Bool(false), "Expected api error, got \(error)")
            }
        }
    }

    /// 驗證 `.error` 會轉為 `.api`，且帶入 status code。
    @Test("Decision error should map to api error with status code")
    func decisionErrorMapsToAPIError() async {
        let stubAdapter = StubResponseAdapter(responseData: Data(), statusCode: 404)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]

        let session = URLSession(configuration: config)
        let client = APIClient(session: session)
        let request = ThreadCheckRequest(
            decisions: [ErrorDecision()],
            stubAdapter: stubAdapter
        )

        do {
            _ = try await request.send(client: client)
            #expect(Bool(false), "Expected api error")
        } catch {
            if case .api(let underlyingError, let statusCode) = error {
                #expect((underlyingError as? TestError) == .sample)
                #expect(statusCode == 404)
            } else {
                #expect(Bool(false), "Expected api error, got \(error)")
            }
        }
    }

    /// 驗證傳入 decisions 會覆寫 request.decisions。
    @Test("Decisions parameter should override request decisions")
    func decisionsOverrideRequestDecisions() async throws {
        let stubAdapter = StubResponseAdapter(responseData: Data(), statusCode: 200)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]

        let session = URLSession(configuration: config)
        let client = APIClient(session: session)
        let request = ThreadCheckRequest(
            decisions: [DoneDecision(message: "request")],
            stubAdapter: stubAdapter
        )

        let response = try await request.send(
            client: client,
            decisions: [DoneDecision(message: "override")]
        )

        #expect(response.message == "override")
    }

    /// 驗證 `.continue` 會傳遞新資料並交由下一個決策處理。
    @Test("Continue should pass new data to next decision")
    func continuePassesDataToNextDecision() async throws {
        let stubAdapter = StubResponseAdapter(responseData: Data(), statusCode: 200)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]

        let session = URLSession(configuration: config)
        let client = APIClient(session: session)
        let request = ThreadCheckRequest(
            decisions: [
                ContinueDecision(message: "next"),
                ParseResultDecision()
            ],
            stubAdapter: stubAdapter
        )

        let response = try await request.send(client: client)
        #expect(response.message == "next")
    }

    /// 驗證 `.restart` 會重新送出請求並套用新決策。
    @Test("Restart should resend with new decisions")
    func restartResendsWithNewDecisions() async throws {
        let recorder = RestartRecorder()
        let stubAdapter = StubResponseAdapter(responseData: Data(), statusCode: 200)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]

        let session = URLSession(configuration: config)
        let client = APIClient(session: session)
        let request = ThreadCheckRequest(
            decisions: [RestartDecision(recorder: recorder, message: "restart")],
            stubAdapter: stubAdapter
        )

        let response = try await request.send(client: client)
        #expect(response.message == "restart")

        let count = await recorder.getCount()
        #expect(count == 1)
    }

    /// 驗證 RetryDecision 的 shouldApply 條件。
    @Test("RetryDecision shouldApply respects status code and left count")
    func retryDecisionShouldApply() {
        let request = ThreadCheckRequest(
            decisions: [],
            stubAdapter: StubResponseAdapter(responseData: Data(), statusCode: 200)
        )
        let decision = RetryDecision(leftCount: 1)
        let okResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let errorResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!

        #expect(decision.shouldApply(request: request, data: Data(), response: okResponse) == false)
        #expect(decision.shouldApply(request: request, data: Data(), response: errorResponse) == true)

        let noRetryDecision = RetryDecision(leftCount: 0)
        #expect(noRetryDecision.shouldApply(request: request, data: Data(), response: errorResponse) == false)
    }

    /// 驗證 RetryDecision 會回傳 restart 並遞減次數。
    @Test("RetryDecision apply returns restart with decremented count")
    func retryDecisionApplyReturnsRestart() async {
        let decision = RetryDecision(leftCount: 2)
        let request = ThreadCheckRequest(
            decisions: [decision],
            stubAdapter: StubResponseAdapter(responseData: Data(), statusCode: 500)
        )
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!

        let action = await decision.apply(request: request, data: Data(), response: response)

        if case .restart(let decisions) = action {
            let retryDecision = decisions.first { $0 is RetryDecision } as? RetryDecision
            #expect(retryDecision?.leftCount == 1)
        } else {
            #expect(Bool(false), "Expected restart action")
        }
    }
}
