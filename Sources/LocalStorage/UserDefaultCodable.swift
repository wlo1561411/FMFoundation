import Foundation

@propertyWrapper
public struct UserDefaultCodable<T: Codable> {
    private let key: String
    private let defaultValue: T
    private let userDefaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        wrappedValue: T,
        _ suffixKey: String,
        structName: String = #function,
        userDefaults: UserDefaults = .standard,
        decoder: JSONDecoder = .init(),
        encoder: JSONEncoder = .init()
    ) {
        self.key = [structName, suffixKey].joined(separator: "_")
        self.defaultValue = wrappedValue
        self.userDefaults = userDefaults
        self.decoder = decoder
        self.encoder = encoder
    }

    public var wrappedValue: T {
        get {
            guard let data = userDefaults.data(forKey: key)
            else {
                return defaultValue
            }

            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                print(error.localizedDescription)
                return defaultValue
            }
        }
        set {
            let mirror = Mirror(reflecting: newValue)
            if mirror.displayStyle == .optional, mirror.children.isEmpty {
                userDefaults.removeObject(forKey: key)
            } else {
                do {
                    let encoded = try encoder.encode(newValue)
                    userDefaults.set(encoded, forKey: key)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}
