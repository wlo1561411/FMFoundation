import Foundation

typealias AutoDecodeInput = (decoder: Decoder, context: AutoDecoderContext, target: String)

struct AutoDecoder<Value> {
    let configuration: (AutoDecodeInput) throws -> Value

    init(configuration: @escaping (AutoDecodeInput) throws -> Value) {
        self.configuration = configuration
    }
}

// MARK: - Decoder

extension Decoder {
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        path: AutoDecodePath,
        target: String
    ) throws
        -> T {
        switch path.type {
        case .key(let string):
            try decode(
                type,
                key: .init(stringValue: string),
                target: target
            )
        }
    }

    private func decode<T: Decodable>(
        _ type: T.Type = T.self,
        key: DynamicCodingKey,
        target: String
    ) throws
        -> T {
        let container = try container(keyedBy: DynamicCodingKey.self)

        do {
            // Decimal need to handle locale
            if type == Decimal.self {
                if let value = try container.decode(Double.self, forKey: key).decimal as? T {
                    return value
                }
            }
            return try container.decode(T.self, forKey: key)
        } catch DecodingError.typeMismatch(let expectedType, let context) {
            let error = DecodingError.typeMismatch(expectedType, context)

            switch type {
            case is String.Type:
                return try decodeString(
                    from: container,
                    forKey: key,
                    with: error,
                    target: target
                ) as? T ?? {
                    throw error
                }()

            case is Int.Type:
                return try decodeInt(
                    from: container,
                    forKey: key,
                    with: error
                ) as? T ?? {
                    throw error
                }()

            default:
                printDecodingError(error, container: container, target: target)
                throw error
            }
        } catch {
            printDecodingError(error, container: container, target: target)
            throw error
        }
    }

    private func decodeString(
        from container: KeyedDecodingContainer<DynamicCodingKey>,
        forKey key: DynamicCodingKey,
        with error: DecodingError,
        target: String
    ) throws
        -> String {
        do {
            let intValue = try container.decode(Int.self, forKey: key)
            return String(intValue)
        } catch {
            printDecodingError(error, container: container, target: target)
            throw error
        }
    }

    private func decodeInt(
        from container: KeyedDecodingContainer<DynamicCodingKey>,
        forKey key: DynamicCodingKey,
        with error: DecodingError
    ) throws
        -> Int {
        do {
            let stringValue = try container.decode(String.self, forKey: key)
            return Int(stringValue) ?? 0
        } catch {
            printDecodingError(error, container: container, target: "\(key.stringValue)")
            throw error
        }
    }

    func printDecodingError(
        _ error: Error,
        container _: KeyedDecodingContainer<DynamicCodingKey>,
        target: String
    ) {
        #if DEBUG
            switch error {
            case DecodingError.dataCorrupted(let context):
                print("⚠️ \(target) invalid context: \(context.debugDescription), description: \(context.debugDescription)")

            case DecodingError.keyNotFound(let key, _):
                print("⚠️ \(target) \(key.stringValue) missing")

            case DecodingError.valueNotFound(let value, let context):
                print("⚠️ \(target) \(context.codingPath.first?.stringValue ?? "") missing value: \(value)")

            case DecodingError.typeMismatch(let type, let context):
                print(
                    "⚠️ \(target) type missing: expect type is \(type), codingPath: \(context.codingPath.first?.stringValue ?? "")"
                )

            default:
                print("⚠️ \(target) other error:", error)
            }
        #endif
    }
}

// MARK: - Extension

extension LosslessStringConvertible {
    fileprivate var string: String {
        .init(self)
    }
}

extension FloatingPoint where Self: LosslessStringConvertible {
    fileprivate var decimal: Decimal? {
        .init(string: string, locale: Locale.current)
    }
}
