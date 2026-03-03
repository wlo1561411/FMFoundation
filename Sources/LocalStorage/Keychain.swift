import Combine
import Foundation
import Security

/// 封裝的 Keychain 存取工具。
///
///     - 自動快取記憶體中的值以避免重複存取 Keychain
///     - 寫入時自動觸發 Publisher 以供 UI 或邏輯綁定
///     - 初始值會從 Keychain 中讀取, 若無則使用提供的預設值
@propertyWrapper
final class Keychain<T: Codable> {
    private let account: String
    private let service: KeychainStorage.Service
    private let defaultValue: T

    /// 緩存一份，降低 Keychain 存取次數
    private let subject: CurrentValueSubject<T, Never>

    init(wrappedValue: T, account: String, service: KeychainStorage.Service) {
        self.account = account
        self.service = service
        self.defaultValue = wrappedValue

        let initial: T
        do {
            initial = try KeychainStorage.read(account: account, service: service) ?? wrappedValue
        } catch {
            print("Keychain \(service.rawValue) \(account) init error: \(error)")
            initial = wrappedValue
        }

        self.subject = CurrentValueSubject(initial)
    }

    var wrappedValue: T {
        get {
            subject.value
        }
        set {
            do {
                try KeychainStorage.save(newValue, account: account, service: service)
                subject.send(newValue)
            } catch {
                print("Keychain \(service.rawValue) \(account) save error: \(error)")
            }
        }
    }

    var projectedValue: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }

    func delete() {
        subject.send(defaultValue)

        do {
            try KeychainStorage.delete(account: account, service: service)
        } catch {
            print("Keychain \(service.rawValue) \(account) delete error: \(error)")
        }
    }
}

struct KeychainStorage {
    struct Service: RawRepresentable {
        let rawValue: String

        fileprivate var name: String {
            var name: [String] = []
            if let bundleId = Bundle.main.bundleIdentifier {
                name.append(bundleId)
            }
            if rawValue.isEmpty == false {
                name.append(rawValue)
            }
            return name.joined(separator: ".")
        }
    }

    enum OperateError: Error {
        case unknown
        case fail(String)

        init(_ prefix: String, status: OSStatus) {
            if let message = SecCopyErrorMessageString(status, nil) as? String {
                self = .fail(prefix + message)
            } else {
                self = .unknown
            }
        }
    }

    static func save(_ object: some Codable, account: String, service: Service) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try save(data, account: account, service: service)
    }

    static func read<T: Codable>(account: String, service: Service) throws -> T? {
        guard let data = try read(account: account, service: service) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    static func save(_ data: Data, account: String, service: Service) throws {
        let query = [
            kSecAttrAccount: account,
            kSecAttrService: service.name,
            kSecClass: kSecClassGenericPassword,
            kSecValueData: data
        ] as CFDictionary

        let status: OSStatus
        switch SecItemCopyMatching(query, nil) {
        case errSecItemNotFound:
            status = SecItemAdd(query, nil)
        case errSecSuccess:
            status = SecItemUpdate(query, [kSecValueData: data] as CFDictionary)
        default:
            throw OperateError.unknown
        }
        guard status == noErr else {
            throw OperateError("save failed, ", status: status)
        }
    }

    static func read(account: String, service: Service) throws -> Data? {
        let query = [
            kSecAttrAccount: account,
            kSecAttrService: service.name,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        switch status {
        case errSecItemNotFound:
            return nil
        case errSecSuccess:
            guard let data = result as? Data else {
                throw OperateError("read failed, ", status: status)
            }
            return data
        default:
            throw OperateError.unknown
        }
    }

    static func update(account: String, newAccount: String, service: Service) throws {
        let query = [
            kSecAttrAccount: account,
            kSecAttrService: service.name,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary

        let update = [
            kSecAttrAccount: newAccount
        ] as CFDictionary

        let status = SecItemUpdate(query, update)
        guard status == noErr
        else {
            throw OperateError("update failed, ", status: status)
        }
    }

    static func delete(account: String, service: Service) throws {
        let query = [
            kSecAttrAccount: account,
            kSecAttrService: service.name,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary

        let status = SecItemDelete(query)
        guard status == noErr
        else {
            throw OperateError("delete failed, ", status: status)
        }
    }
}
