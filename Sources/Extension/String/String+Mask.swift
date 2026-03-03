import Foundation

extension String {
    public enum Mask {
        case left(Int)
        case email
        /// It wil escape "$"
        case allMasked
    }

    public func masked(_ type: Mask) -> String {
        switch type {
        case .left(let count):
            return enumerated()
                .map { key, value -> String in
                    if count > 0, (self.count - key - 1) < count {
                        return "\(value)"
                    } else {
                        return "*"
                    }
                }
                .joined()

        case .email:
            var count = 0
            var detectAt = false

            return enumerated()
                .map { _, value -> String in
                    if !detectAt {
                        detectAt = "\(value)" == "@"
                    }

                    if detectAt {
                        return "\(value)"
                    } else {
                        if count < 3 {
                            count += 1
                            return "\(value)"
                        } else {
                            return "*"
                        }
                    }
                }
                .joined()

        case .allMasked:
            let currency = "$"

            return map { characters -> String in
                if "\(characters)" == " " || currency == "\(characters)" {
                    return "\(characters)"
                }
                return "*"
            }
            .joined()
        }
    }
}
