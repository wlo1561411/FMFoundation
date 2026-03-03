import Foundation

@propertyWrapper
public struct UserDefault<T> {
    private let key: String
    private let defaultValue: T
    private let userDefaults: UserDefaults

    public init(wrappedValue: T, _ suffixKey: String, userDefaults: UserDefaults = .standard, structName: String = #function) {
        self.key = [structName, suffixKey].joined(separator: "_")
        self.defaultValue = wrappedValue
        self.userDefaults = userDefaults
    }

    public var wrappedValue: T {
        get {
            userDefaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            let mirror = Mirror(reflecting: newValue)
            if mirror.displayStyle == .optional, mirror.children.isEmpty {
                userDefaults.removeObject(forKey: key)
            } else {
                userDefaults.set(newValue, forKey: key)
            }
        }
    }
}
