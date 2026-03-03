import Foundation

/// 專案通用的最大小數位數
let generalMaximumFractionDigits = 8

private let formatter = NumberFormatter()

protocol NumberFormatStrategy {
    /// 預設為 .down
    var roundingMode: NumberFormatter.RoundingMode { get }
    /// 預設為 .decimal
    var numberStyle: NumberFormatter.Style { get }
    /// 只要設定
    ///
    /// NumberFormatter.numberStyle 就會設定為 .currency
    var currencyConfiguration: CurrencyNumberConfiguration? { get }

    var minimumFractionDigits: Int { get }
    var maximumOption: NumberFormattingOption { get }

    func format(value: any Numeric) -> String
}

// MARK: - Default Implement

extension NumberFormatStrategy {
    var roundingMode: NumberFormatter.RoundingMode {
        .down
    }

    var numberStyle: NumberFormatter.Style {
        .decimal
    }

    var currencyConfiguration: CurrencyNumberConfiguration? {
        nil
    }

    func format(value: any Numeric) -> String {
        format(value: value, strategy: self)
    }
}

// MARK: - Format

extension NumberFormatStrategy {
    func format(value: any Numeric, strategy: NumberFormatStrategy) -> String {
        let scale = strategy.maximumOption.digits(value: value)

        let converted: Decimal

        switch value {
        case let decimal as Decimal:
            converted = decimal.rounded(scale: scale)
        case let double as Double:
            converted = Decimal(double).rounded(scale: scale)
        case let int as Int:
            converted = Decimal(int)
        default:
            return "\(value)"
        }

        formatter.apply(decimal: converted, strategy: self)

        return PrecisionHandler.trimIfNeeded(value: converted, formatter: formatter)
    }
}

// MARK: - NumberFormatter

extension NumberFormatter {
    fileprivate func apply(decimal: Decimal, strategy: NumberFormatStrategy) {
        roundingMode = strategy.roundingMode
        locale = Locale.current

        minimumFractionDigits = strategy.minimumFractionDigits
        maximumFractionDigits = max(strategy.maximumOption.digits(value: decimal), minimumFractionDigits)

        if let configuration = strategy.currencyConfiguration {
            numberStyle = .currency
            currencySymbol = configuration.symbol
            currencyGroupingSeparator = configuration.groupingSeparator
            groupingSize = configuration.groupingSize
            usesGroupingSeparator = true
        } else {
            numberStyle = strategy.numberStyle
            currencySymbol = ""
            usesGroupingSeparator = false
        }
    }
}

// MARK: - Numeric

extension Numeric {
    func formatted(strategy: NumberFormatStrategy) -> String {
        strategy.format(value: self)
    }
}

// MARK: - String

extension String {
    func formatted(strategy: NumberFormatStrategy) -> String? {
        let extraNumber = match("-?[0-9]*+(?:\\.[0-9]+)?").joined()
        return Decimal(string: extraNumber)?.formatted(strategy: strategy)
    }
}

// MARK: - Decimal

extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, (value.sign == .plus) ? .down : .up)
        return result
    }
}
