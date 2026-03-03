import Foundation

extension NumberFormatStrategy {
    static func percentage(
        minimumFractionDigits: Int = 2,
        withPercentileSymbol: Bool = true,
        withChangeSymbol: Bool = false
    )
        -> Self where Self == PercentageNumberStrategy {
        .init(
            minimumFractionDigits: minimumFractionDigits,
            withPercentileSymbol: withPercentileSymbol,
            withChangeSymbol: withChangeSymbol
        )
    }
}

/// 最多小數點後2位數
struct PercentageNumberStrategy: NumberFormatStrategy {
    let minimumFractionDigits: Int
    let maximumOption: NumberFormattingOption = .value(2)
    /// 要不要 %
    let withPercentileSymbol: Bool
    /// 要不要 +/-
    let withChangeSymbol: Bool

    func format(value: any Numeric) -> String {
        var result = format(value: value, strategy: self)
        let value = Double(result) ?? 0

        if value != 0 {
            // 負數出來就會有負號
            result = value > 0 ? "+" + result : result
        } else {
            // 避免 -0
            result = "0"
        }

        if !withChangeSymbol, value != 0 {
            result.removeFirst()
        }

        if withPercentileSymbol {
            result += "%"
        }

        return result
    }
}
