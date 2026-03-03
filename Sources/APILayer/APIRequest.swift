import Foundation

/// 描述 API 請求的抽象協議。
public protocol APIRequest: Sendable {
    /// 收到正常回應的格式。
    associatedtype Response: Codable

    /// API Server 路徑。
    var baseURL: URL? { get }
    /// API 路徑。
    var path: String { get }
    /// API HTTP 方法。
    var method: APIHttpMethod { get }
    /// 請求參數。
    var parameters: APIParameterConvertible { get set }
    /// 參數格式。
    var contentType: APIContentType { get }
    /// 額外的標頭。
    /// - Note: 預設為空
    var extraHeader: [String: String] { get }
    /// 請求超時設定。
    /// - Note: 預設為 30 秒
    var timeout: TimeInterval { get }
    /// 重新請求次數。
    /// - Note: 預設為 0
    var retryCount: Int { get }
    /// 「調整」請求參數的組合器。
    /// - Note: 預設為空
    var parameterAdapters: [APIParameterAdapter] { get }
    /// 「建構」請求的組合器。
    /// - Note: 預設為依序包含方法、標頭、內容與逾時設定。
    var adapters: [APIRequestAdapter] { get }
    /// 收到回應後，「依序」要執行的決策。
    /// - Note: 預設依序包含重試與解析結果。
    var decisions: [APIDecision] { get }
}

// MARK: - Default Implement

extension APIRequest {
    /// 由 `baseURL` 與 `path` 組成的完整 URL。
    /// - Note: 若組合失敗會回傳 `nil`。
    public var url: URL? {
        URL(string: path, relativeTo: baseURL)
    }

    /// 預設沒有額外標頭。
    public var extraHeader: [String: String] {
        [:]
    }

    /// 預設請求逾時 30 秒。
    public var timeout: TimeInterval {
        30
    }

    /// 預設不重試。
    public var retryCount: Int {
        0
    }

    /// 預設不調整參數。
    public var parameterAdapters: [APIParameterAdapter] {
        []
    }

    /// 預設的請求組合器。
    public var adapters: [APIRequestAdapter] {
        [
            method.adapter,
            RequestExtraHeaderAdapter(header: extraHeader),
            RequestContentAdapter(method: method, contentType: contentType, content: parameters),
            RequestTimeoutAdapter(timeout: timeout),
        ]
    }

    /// 預設的決策鏈。
    public var decisions: [APIDecision] {
        [
            RetryDecision(leftCount: retryCount),
            ParseResultDecision()
        ]
    }

    /// 套用參數調整器並更新 `parameters`。
    /// - Throws: 參數調整失敗時拋出錯誤。
    mutating func attachMoreParameter() throws {
        parameters = try parameterAdapters
            .reduce(parameters) {
                try $1.adapted($0).dictionary
            }
    }

    /// 建構 `URLRequest`。
    /// - Returns: 已套用 adapters 的 `URLRequest`。
    /// - Throws: URL 無效或組建過程失敗時拋出錯誤。
    func buildRequest() throws -> URLRequest {
        guard let url else {
            throw URLError(.badURL)
        }
        let request = URLRequest(url: url)
        return try adapters
            .reduce(request) {
                try $1.adapted($0)
            }
    }

    /// 發送請求並回傳解析後的回應。
    /// - Parameters:
    ///   - client: 用於發送請求的 APIClient。
    ///   - decisions: 可覆寫預設決策的決策鏈。
    /// - Returns: 解析後的回應模型。
    public func send(
        client: APIClient = .init(session: .shared),
        decisions: [APIDecision]? = nil
    ) async throws (APIClient.ResponseError) -> Response {
        try await client.send(self, decisions: decisions)
    }
}

/// 支援的 HTTP 方法。
public enum APIHttpMethod: String, Sendable {
    /// HTTP GET。
    case GET
    /// HTTP POST。
    case POST
    #warning("等待實作")
    //    case PUT
    //    case PATCH
    //    case DELETE
    //    case HEAD

    /// 轉為可套用在 `URLRequest` 的 adapter。
    public var adapter: APIRequestAnyAdapter {
        .init { request in
            var request = request
            request.httpMethod = rawValue
            return request
        }
    }
}

/// 請求內容類型。
public enum APIContentType: String, Sendable {
    /// JSON。
    case json = "application/json"
    /// x-www-form-urlencoded。
    case urlForm = "application/x-www-form-urlencoded"

    /// 產生 `Content-Type` 標頭的 adapter。
    public var headerAdapter: APIRequestAnyAdapter {
        .init { req in
            var req = req
            req.setValue(rawValue, forHTTPHeaderField: "Content-Type")
            return req
        }
    }
}
