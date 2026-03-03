import Foundation

/// 調整請求參數的抽象化協議。
public protocol APIParameterAdapter {
    /// 組建新的參數。
    /// - Parameter parameter: 現有的參數。
    /// - Returns: 新的參數。
    func adapted(_ parameter: APIParameterConvertible) throws -> APIParameterConvertible
}

/// API 請求參數的抽象介面。
public protocol APIParameterConvertible: Sendable {
    /// 請求參數字典。
    /// - Important: *Keys* 必須為字串且可序列化。
    /// - Note: 僅回傳可安全跨執行緒傳遞的值。
    var dictionary: [String: Sendable] { get }
}

/// 字典型態的參數實作。
extension [String: Sendable]: APIParameterConvertible {
    /// 回傳字典本身作為請求參數。
    public var dictionary: [String: Sendable] {
        self
    }
}
