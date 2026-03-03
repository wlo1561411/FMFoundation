import Foundation

/// 處理 NumberFormatter 過多小數位 ( > 14) 會遺失精度的問題
struct PrecisionHandler {
    private static let digitsPrecisionLimit = 14

    /// - Parameters:
    ///   - formatter: 只用來處理整數位
    static func trimIfNeeded(value: Decimal, formatter: NumberFormatter) -> String {
        let components = "\(value)".components(separatedBy: ".")

        guard
            components.count == 2,
            let digits = components.last?.count,
            digits > digitsPrecisionLimit,
            digits >= formatter.maximumFractionDigits
        else {
            return formatter.string(from: value as NSDecimalNumber) ?? "0"
        }

        let integerPart = components[0]

        let integerDecimal = Decimal(string: integerPart)
        let formattedInteger = integerDecimal
            .flatMap { formatter.string(from: $0 as NSDecimalNumber) }

        guard let formattedInteger
        else {
            return "\(value)"
        }

        let fullDecimalPart = components[1]
        let limitedDecimalPart = String(fullDecimalPart.prefix(formatter.maximumFractionDigits))

        return "\(formattedInteger).\(limitedDecimalPart)"
    }
}
