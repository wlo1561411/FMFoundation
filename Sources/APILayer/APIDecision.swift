import Foundation

/// 建構收到回應後執行決策的抽象化協議。
public protocol APIDecision: Sendable {
    /// 判別是否執行此決策。
    /// - Parameters:
    ///   - request: 發出的請求。
    ///   - data: 收到的回應內容。
    ///   - response: 收到的回應。
    /// - Returns: `true` 則執行此決策；反之則判斷下一個決策。
    func shouldApply<Request: APIRequest>(
        request: Request,
        data: Data,
        response: HTTPURLResponse
    ) -> Bool

    /// 執行決策。
    /// - Parameters:
    ///   - request: 發出的請求。
    ///   - data: 收到的回應內容。
    ///   - response: 收到的回應。
    /// - Returns: 決策後的動作。
    func apply<Request: APIRequest>(
        request: Request,
        data: Data,
        response: HTTPURLResponse
    ) async -> APIDecisionAction<Request>
}

// MARK: - Extension

extension [APIDecision] {
    /// 移除指定型別的決策。
    /// - Parameter item: 要移除的決策。
    /// - Returns: 移除後的新陣列。
    public func removing(_ item: APIDecision) -> Array {
        replacing(item, with: nil)
    }

    /// 以新決策取代既有決策。
    /// - Parameters:
    ///   - item: 要被取代的決策。
    ///   - newItem: 新決策，為 `nil` 時代表移除。
    /// - Returns: 替換後的新陣列。
    public func replacing(_ item: APIDecision, with newItem: APIDecision?) -> Array {
        var decisions = self

        guard
            let index = decisions.firstIndex(where: { type(of: $0) == type(of: item) })
        else {
            return self
        }

        _ = decisions.remove(at: index)

        if let newItem {
            decisions.insert(newItem, at: index)
        }

        return decisions
    }
}

/// 執行決策後的動作。
public enum APIDecisionAction<Request: APIRequest> {
    /// 繼續下一個決策。
    case `continue`(Data, HTTPURLResponse)
    /// 帶入新的決策，重新進行請求。
    case restart([APIDecision])
    /// 拋出錯誤。
    case error(Error)
    /// 正常完成請求，後續的決策全數不執行。
    case done(Request.Response)
}

/// 依照 HTTP 狀態碼與剩餘次數進行重試的決策。
public struct RetryDecision: APIDecision {
    /// 剩餘重試次數。
    public let leftCount: Int

    /// 建立重試決策。
    /// - Parameter leftCount: 可重試的剩餘次數。
    public init(leftCount: Int) {
        self.leftCount = leftCount
    }

    /// 判斷是否需要重試。
    /// - Parameters:
    ///   - request: 原始請求。
    ///   - data: 回應資料。
    ///   - response: HTTP 回應。
    /// - Returns: 狀態碼非 2xx 且剩餘次數大於 0 時回傳 `true`。
    public func shouldApply(request _: some APIRequest, data _: Data, response: HTTPURLResponse) -> Bool {
        let isStatusCodeValid = (200..<300).contains(response.statusCode)
        return isStatusCodeValid == false && leftCount > 0
    }

    /// 建立新的重試決策並要求重送。
    /// - Parameters:
    ///   - request: 原始請求。
    ///   - data: 回應資料。
    ///   - response: HTTP 回應。
    /// - Returns: 帶著新的決策清單重新送出。
    public func apply<Request: APIRequest>(
        request: Request,
        data _: Data,
        response _: HTTPURLResponse
    ) async -> APIDecisionAction<Request> {
        let retryDecision = RetryDecision(leftCount: leftCount - 1)
        let newDecisions = request.decisions.replacing(self, with: retryDecision)
        return .restart(newDecisions)
    }
}

/// 用於解析回應資料的 JSONDecoder。
private let decoder = JSONDecoder()

/// 將回應資料解析為 `Request.Response` 的決策。
public struct ParseResultDecision: APIDecision {
    /// 解析回應前的判斷，預設總是套用。
    /// - Parameters:
    ///   - request: 原始請求。
    ///   - data: 回應資料。
    ///   - response: HTTP 回應。
    /// - Returns: 總是回傳 `true`。
    public func shouldApply(request _: some APIRequest, data _: Data, response _: HTTPURLResponse) -> Bool {
        true
    }

    /// 執行 JSON 解析並完成請求。
    /// - Parameters:
    ///   - request: 原始請求。
    ///   - data: 回應資料。
    ///   - response: HTTP 回應。
    /// - Returns: 解析成功則完成，失敗則回傳錯誤。
    public func apply<Request: APIRequest>(
        request: Request,
        data: Data,
        response _: HTTPURLResponse
    ) async -> APIDecisionAction<Request> {
        do {
            let value = try decoder.decode(Request.Response.self, from: data)
            return .done(value)
        } catch {
            return .error(error)
        }
    }
}
