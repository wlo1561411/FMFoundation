import Foundation

/// 構建請求結構的抽象化協議。
public protocol APIRequestAdapter: Sendable {
    /// 組件新的請求。
    /// - Parameter request: 現有的請求結構。
    /// - Returns: 新的請求結構。
    func adapted(_ request: URLRequest) throws -> URLRequest
}

/// 自定義構建請求內容的通用 adapter。
public struct APIRequestAnyAdapter: APIRequestAdapter {
    /// 自定請求結構的閉包。
    let closure: @Sendable (URLRequest) throws -> URLRequest

    /// 建立自定義 adapter。
    /// - Parameter closure: 用於轉換 `URLRequest` 的閉包。
    public init(closure: @escaping @Sendable (URLRequest) throws -> URLRequest) {
        self.closure = closure
    }

    /// 套用自定義閉包並回傳新的請求。
    /// - Parameter request: 原始請求。
    /// - Returns: 轉換後的請求。
    public func adapted(_ request: URLRequest) throws -> URLRequest {
        try closure(request)
    }
}

/// 依照 HTTP 方法與 Content-Type 建構請求內容的 adapter。
public struct RequestContentAdapter: APIRequestAdapter {
    /// HTTP 方法。
    public let method: APIHttpMethod
    /// 請求內容類型。
    public let contentType: APIContentType
    /// 請求參數內容。
    public let content: APIParameterConvertible

    /// 依照方法與內容類型組建請求。
    /// - Parameter request: 原始請求。
    /// - Returns: 組建後的請求。
    public func adapted(_ request: URLRequest) throws -> URLRequest {
        switch method {
        case .GET:
            return try URLQueryDataAdapter(data: content).adapted(request)

        case .POST:
            let headerAdapter = contentType.headerAdapter
            let dataAdapter: APIRequestAdapter = switch contentType {
            case .json:
                JSONRequestDataAdapter(data: content)
            case .urlForm:
                URLFormRequestDataAdapter(data: content)
            }

            let request = try headerAdapter.adapted(request)
            return try dataAdapter.adapted(request)
        }
    }
}

/// 將參數轉為 JSON body 的 adapter。
struct JSONRequestDataAdapter: APIRequestAdapter {
    /// 請求參數內容。
    let data: APIParameterConvertible

    /// 轉換為 JSON body。
    /// - Parameter request: 原始請求。
    /// - Returns: 含 JSON body 的請求。
    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request

        request.httpBody = try JSONSerialization.data(
            withJSONObject: data.dictionary,
            options: []
        )

        return request
    }
}

/// 將參數轉為 x-www-form-urlencoded body 的 adapter。
struct URLFormRequestDataAdapter: APIRequestAdapter {
    /// 請求參數內容。
    let data: APIParameterConvertible

    /// 轉換為 form body。
    /// - Parameter request: 原始請求。
    /// - Returns: 含 form body 的請求。
    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        var urlComponents = URLComponents()

        urlComponents.queryItems = data
            .dictionary
            .map {
                .init(name: $0.key, value: "\($0.value)")
            }

        request.httpBody = urlComponents.query?.data(using: .utf8)

        return request
    }
}

/// 將參數以 query string 方式附加到 URL 的 adapter。
struct URLQueryDataAdapter: APIRequestAdapter {
    /// 請求參數內容。
    let data: APIParameterConvertible

    /// 轉換為 query string。
    /// - Parameter request: 原始請求。
    /// - Returns: 含 query string 的請求。
    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request

        guard
            let url = request.url,
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else {
            throw URLError(.badURL)
        }

        var queryItems = urlComponents.queryItems ?? []

        queryItems += data
            .dictionary
            .map {
                .init(name: $0.key, value: "\($0.value)")
            }

        urlComponents.queryItems = queryItems

        request.url = urlComponents.url
        return request
    }
}

/// 追加額外標頭的 adapter。
public struct RequestExtraHeaderAdapter: APIRequestAdapter {
    /// 額外標頭字典。
    public let header: [String: String]

    /// 追加標頭到請求。
    /// - Parameter request: 原始請求。
    /// - Returns: 追加標頭後的請求。
    public func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request

        for item in header {
            request.setValue(item.value, forHTTPHeaderField: item.key)
        }

        return request
    }
}

/// 設定請求逾時時間的 adapter。
public struct RequestTimeoutAdapter: APIRequestAdapter {
    /// 逾時秒數。
    public let timeout: TimeInterval

    /// 套用逾時設定。
    /// - Parameter request: 原始請求。
    /// - Returns: 設定逾時後的請求。
    public func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        request.timeoutInterval = timeout
        return request
    }
}
