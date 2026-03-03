import Foundation

extension Decimal {
    public var digits: Int? {
        "\(self)".digits
    }

    public init?(string: String) {
        self.init(string: string, locale: .init(identifier: "zh_CN"))
    }
}
