import Foundation

/// 處理專案所有小數後的邏輯
/// 規則如果顯示位數有變, 不應該來改這裡
/// 除非判斷邏輯有變
enum NumberFormattingOption {
    /// 容許小數後 18 位, 應該不會更小了
    static let maximum = 18

    /// greaterThanOne: 大於0時, 最多小數點
    /// lessThanOne: 小於0時, 最多小數點
    /// 如果取小數後顯示為0, 則全展示
    case `internal`(greaterThanOne: Int, lessThanOne: Int)
    /// 按照帶進來的值設定, 一般來說是虛擬幣允許的小數位
    case value(Int)

    func digits(value: any Numeric) -> Int {
        switch self {
        case .internal:
            var converted: Decimal = 0

            if let decimal = value as? Decimal {
                converted = decimal
            } else if let double = value as? Double {
                converted = Decimal(double)
            }

            if converted != 0 {
                return getInternalDigits(value: converted)
            } else {
                return 0
            }

        case .value(let value):
            return value
        }
    }

    /// 去取套用內部邏輯後的小數位
    private func getInternalDigits(value: Decimal) -> Int {
        guard case .internal(let greaterThanOne, let lessThanOne) = self
        else {
            return generalMaximumFractionDigits
        }

        if value >= 1 {
            return greaterThanOne
        } else {
            let threshold = 1 / pow(10.0, lessThanOne)

            // 如果數值小於 threshold, maximumFractionDigits 就要重新設定
            // 會設定為 NumberFormattingOption 最大值
            if value < threshold, value != 0 {
                return Self.maximum
            } else {
                return lessThanOne
            }
        }
    }
}
