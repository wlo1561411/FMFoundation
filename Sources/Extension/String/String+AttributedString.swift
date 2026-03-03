import UIKit

extension String {
    public var attributed: NSMutableAttributedString {
        .init(string: self)
    }
}

extension NSMutableAttributedString {
    public func textColor(_ color: UIColor) -> NSMutableAttributedString {
        addAttribute(
            .foregroundColor,
            value: color,
            range: .init(location: 0, length: length)
        )
        return self
    }

    public func font(_ font: UIFont) -> NSMutableAttributedString {
        addAttribute(
            .font,
            value: font,
            range: .init(location: 0, length: length)
        )
        return self
    }

    public func characterSpacing(_ spacing: CGFloat) -> NSMutableAttributedString {
        addAttribute(
            .kern,
            value: spacing,
            range: .init(location: 0, length: length - 1)
        )
        return self
    }

    public func textAlignment(_ alignment: NSTextAlignment) -> NSMutableAttributedString {
        if let pre = attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSMutableParagraphStyle {
            pre.alignment = alignment
            return self
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment

        addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: .init(location: 0, length: length)
        )
        return self
    }

    public func lineSpacing(_ spacing: CGFloat) -> NSMutableAttributedString {
        if let pre = attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSMutableParagraphStyle {
            pre.lineSpacing = spacing
            return self
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = spacing

        addAttribute(
            NSAttributedString.Key.paragraphStyle,
            value: paragraphStyle,
            range: NSMakeRange(0, length)
        )
        return self
    }

    public func highlight(
        font: UIFont,
        color: UIColor,
        rangeSubString: String
    )
        -> NSMutableAttributedString {
        for item in string.ranges(of: rangeSubString) {
            addAttributes(
                [.font: font, .foregroundColor: color],
                range: NSRange(item, in: string)
            )
        }
        return self
    }

    public func highlights(
        font: UIFont,
        color: UIColor,
        rangeSubStrings: [String?]
    )
        -> NSMutableAttributedString {
        rangeSubStrings
            .compactMap { $0 }
            .forEach { string in
                let _ = highlight(font: font, color: color, rangeSubString: string)
            }
        return self
    }
}
