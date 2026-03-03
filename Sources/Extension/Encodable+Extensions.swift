import Foundation

extension Encodable {
    public func dictionary(options: JSONSerialization.ReadingOptions = [.allowFragments]) throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data, options: options) as? [String: Any] ?? [:]
    }
}
