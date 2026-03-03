import Foundation

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringLiteral value: StaticString) {
        self.stringValue = value.description
    }

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}
