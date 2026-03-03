import UIKit

extension String {
    public var orEmpty: String? {
        isEmpty ? nil : self
    }

    public var urlEncoded: String? {
        addingPercentEncoding(withAllowedCharacters: NSCharacterSet(charactersIn: "!*'();:@&=+$,/?%#[] ").inverted)
    }

    public var urlDecoded: String? {
        removingPercentEncoding
    }

    public var urlQueryFormatted: String? {
        addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)?.replacingOccurrences(of: "+", with: "%2b")
    }

    public var halfWidth: String {
        let string = NSMutableString(string: self) as CFMutableString
        CFStringTransform(string, nil, kCFStringTransformFullwidthHalfwidth, false)
        return string as String
    }

    public func formated(_ arguments: [CVarArg?] = []) -> String {
        if arguments.count > 0 {
            String(format: self, arguments: arguments.compactMap { $0 })
        } else {
            self
        }
    }

    public func ranges(of occurrence: String) -> [Range<String.Index>] {
        var indices = [Int]()
        var position = startIndex

        while let range = range(of: occurrence, range: position..<endIndex) {
            let offset = occurrence.distance(from: occurrence.startIndex, to: occurrence.endIndex) - 1
            guard
                let after = index(
                    range.lowerBound,
                    offsetBy: offset,
                    limitedBy: endIndex
                )
            else {
                break
            }

            indices.append(distance(from: startIndex, to: range.lowerBound))
            position = index(after: after)
        }

        let count = occurrence.count
        return indices.map { index(startIndex, offsetBy: $0)..<index(startIndex, offsetBy: $0 + count) }
    }

    public func width(with font: UIFont) -> CGFloat {
        ceil(
            NSString(string: self)
                .boundingRect(
                    with: CGSize(
                        width: CGFloat.greatestFiniteMagnitude,
                        height: font.lineHeight
                    ),
                    options: .usesLineFragmentOrigin,
                    attributes: [NSAttributedString.Key.font: font],
                    context: nil
                ).size.width
        )
    }

    public func height(with font: UIFont, width: CGFloat) -> CGFloat {
        ceil(
            NSString(string: self)
                .boundingRect(
                    with: CGSize(
                        width: width,
                        height: CGFloat.greatestFiniteMagnitude
                    ),
                    options: .usesLineFragmentOrigin,
                    attributes: [NSAttributedString.Key.font: font],
                    context: nil
                ).size.height
        )
    }

    public func htmlStripped() -> String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    public func spaceByFour(suffix: Int?) -> String {
        let fixed = replacingOccurrences(of: " ", with: "")
        var temp = ""
        for (key, value) in fixed.enumerated() {
            if let suffix {
                if key >= count - suffix {
                    temp += "\(value)"
                } else {
                    temp += "*"
                }
            } else {
                temp += "\(value)"
            }

            if (key + 1) % 4 == 0, key != 0 {
                temp += " "
            }
        }
        return temp
    }

    public func versionCompare(_ otherVersion: String?) -> ComparisonResult {
        compare(otherVersion ?? "", options: .numeric)
    }

    public var digits: Int? {
        guard let dotIndex = firstIndex(of: ".")
        else {
            return nil
        }

        let decimalPart = self[index(after: dotIndex)...]

        return decimalPart.count
    }
}
