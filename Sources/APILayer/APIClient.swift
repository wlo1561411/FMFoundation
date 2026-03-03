import Foundation

/// API 請求執行器，負責發送請求並串接決策流程。
public struct APIClient: Sendable {
    public enum ResponseError: Error {
        /// 執行決策為空
        case emptyDecisions
        /// 請求參數錯誤
        case parameter(error: Error)
        /// 伺服器有回應，但不是標準 HTTP 協議的定義
        case invalidHTTPResponse
        /// response 格式錯誤
        case api(error: Error, statusCode: Int)
        /// 未歸類錯誤
        case unknown(error: Error)
    }

    /// 使用的 `URLSession`。
    /// - Important: 請確保是可重用且符合需求的 session（例如可注入測試用配置）。
    public let session: URLSession

    /// 建立 APIClient。
    /// - Parameter session: 用於發送請求的 `URLSession`。
    public init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Private

    /// 發送請求並依序套用決策。
    /// - Parameters:
    ///   - request: 具體的 API 請求。
    ///   - decisions: 可覆寫預設決策的決策鏈。
    /// - Returns: 解析後的回應。
    func send<Request: APIRequest>(
        _ request: Request,
        decisions: [APIDecision]?
    ) async throws (ResponseError)
        -> Request.Response {
        let urlRequest = try makeRequest(request)

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ResponseError.invalidHTTPResponse
            }

            return try await handleDecision(
                request,
                data: data,
                response: httpResponse,
                decisions: decisions ?? request.decisions
            )
        } catch {
            if let responseError = error as? ResponseError {
                throw responseError
            }
            throw .unknown(error: error)
        }
    }

    /// 建立 URLRequest。
    /// - Parameters:
    ///   - request: 具體的 API 請求。
    /// - Returns: 配置後的 URLRequest。
    private func makeRequest(_ request: some APIRequest) throws (ResponseError) -> URLRequest {
        do {
            var request = request
            try request.attachMoreParameter()
            return try request.buildRequest()
        } catch {
            throw .parameter(error: error)
        }
    }

    @concurrent
    /// 依序執行決策直到完成、重試或失敗。
    /// - Parameters:
    ///   - request: 原始請求。
    ///   - data: 回應資料。
    ///   - response: HTTP 回應。
    ///   - decisions: 尚未執行的決策列表。
    /// - Returns: 決策完成後的結果。
    /// - Note: 若沒有任何可用決策，會觸發 `fatalError`。
    private func handleDecision<Request: APIRequest>(
        _ request: Request,
        data: Data,
        response: HTTPURLResponse,
        decisions: [APIDecision]
    ) async throws (ResponseError)
        -> Request.Response {
        guard decisions.isEmpty == false
        else {
            throw .emptyDecisions
        }

        var decisions = decisions
        let current = decisions.removeFirst()

        guard current.shouldApply(request: request, data: data, response: response)
        else {
            return try await handleDecision(
                request,
                data: data,
                response: response,
                decisions: decisions
            )
        }

        switch await current.apply(request: request, data: data, response: response) {
        case .continue(let data, let httpResponse):
            return try await handleDecision(
                request,
                data: data,
                response: httpResponse,
                decisions: decisions
            )
        case .restart(let decisions):
            return try await send(request, decisions: decisions)
        case .error(let error):
            throw .api(error: error, statusCode: response.statusCode)
        case .done(let response):
            return response
        }
    }
}
