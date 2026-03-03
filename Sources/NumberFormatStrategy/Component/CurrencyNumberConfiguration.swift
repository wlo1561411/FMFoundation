import Foundation

struct CurrencyNumberConfiguration {
    /// 貨幣符號, 預設為空
    var symbol = ""
    /// 分位符號, 預設為 ","
    var groupingSeparator = ","
    /// 分位間隔, 預設為 3
    var groupingSize = 3
}
