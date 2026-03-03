import Foundation

extension NumberFormatStrategy {
    static func general(
        minimumFractionDigits: Int = 0,
        maximumOption: NumberFormattingOption = .value(0),
        currencyConfiguration: CurrencyNumberConfiguration? = nil,
        roundingMode: NumberFormatter.RoundingMode = .down,
        numberStyle: NumberFormatter.Style = .decimal
    )
        -> Self where Self == GeneralNumberFormatStrategy {
        .init(
            minimumFractionDigits: minimumFractionDigits,
            maximumOption: maximumOption,
            currencyConfiguration: currencyConfiguration,
            roundingMode: roundingMode,
            numberStyle: numberStyle
        )
    }
}

struct GeneralNumberFormatStrategy: NumberFormatStrategy {
    let minimumFractionDigits: Int
    let maximumOption: NumberFormattingOption
    let currencyConfiguration: CurrencyNumberConfiguration?
    let roundingMode: NumberFormatter.RoundingMode
    let numberStyle: NumberFormatter.Style
}
