import Foundation

public protocol AutoCodable: Codable {
    init()
}

extension AutoCodable {
    public init(from decoder: Decoder) throws {
        self.init()
        for (path, decodable) in decodablePaths {
            try decodable.decodeWrappedValue(
                at: path,
                from: decoder,
                target: String(describing: type(of: self))
            )
        }
    }

    private var decodablePaths: [(AutoDecodePath, WrappedDecodable)] {
        var allProperties: [(String, Any)] = []

        var currentMirror: Mirror? = Mirror(reflecting: self)

        while let mirror = currentMirror {
            let properties = mirror
                .children
                .compactMap { child -> (String, Any)? in
                    guard let key = child.label
                    else {
                        return nil
                    }
                    return (key, child.value)
                }

            allProperties.append(contentsOf: properties)

            currentMirror = mirror.superclassMirror
        }

        return allProperties.compactMap { key, value in
            var key = key

            guard key.isEmpty == false
            else {
                return nil
            }

            guard let decodable = value as? WrappedDecodable
            else {
                #if DEBUG
                    print("⚠️ \(key) 不是 DefaultCodable, 不進行 decode")
                #endif
                return nil
            }

            if key.hasPrefix("_") {
                key.remove(at: key.startIndex)
            }

            return (AutoDecodePath(type: .key(key)), decodable)
        }
    }
}
