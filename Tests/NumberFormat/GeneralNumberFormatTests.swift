import XCTest

@testable import FMFoundation

final class GeneralNumberFormatTests: XCTestCase { }

// MARK: - Int

extension GeneralNumberFormatTests {
    func test_int_format() {
        let result = 1000.formatted(
            strategy: .general(
                minimumFractionDigits: 0,
                maximumOption: .value(0)
            )
        )
        let expect = "1000"

        XCTAssertEqual(result, expect)
    }

    func test_int_format_with_currency() {
        let result = 1000.formatted(
            strategy: .general(
                minimumFractionDigits: 0,
                maximumOption: .value(0),
                currencyConfiguration: .init(symbol: "$")
            )
        )
        let expect = "$1,000"

        XCTAssertEqual(result, expect)
    }

    func test_int_format_with_minimum2() {
        let result = 1000.formatted(
            strategy: .general(
                minimumFractionDigits: 2,
                maximumOption: .value(0),
                currencyConfiguration: .init()
            )
        )
        let expect = "1,000.00"

        XCTAssertEqual(result, expect)
    }
}

// MARK: - Floating Value

extension GeneralNumberFormatTests {
    func test_decimal_format() {
        let result = Decimal(string: "1000")?.formatted(
            strategy: .general(
                minimumFractionDigits: 0,
                maximumOption: .value(0)
            ))
        let expect = "1000"

        XCTAssertEqual(result, expect)
    }

    func test_decimal_format_with_currency() {
        let result = Decimal(string: "1000")?.formatted(
            strategy: .general(
                minimumFractionDigits: 0,
                maximumOption: .value(0),
                currencyConfiguration: .init()
            ))
        let expect = "1,000"

        XCTAssertEqual(result, expect)
    }

    func test_decimal_format_with_minimum2() {
        let result = Decimal(string: "1000")?.formatted(
            strategy: .general(
                minimumFractionDigits: 2,
                maximumOption: .value(0),
                currencyConfiguration: .init()
            ))
        let expect = "1,000.00"

        XCTAssertEqual(result, expect)
    }

    func test_decimal_format_internal_greaterThanOne() {
        let result = Decimal(string: "1000.12345678")?.formatted(
            strategy: .general(
                minimumFractionDigits: 0,
                maximumOption: .internal(greaterThanOne: 2, lessThanOne: 0),
                currencyConfiguration: .init()
            ))
        let expect = "1,000.12"

        XCTAssertEqual(result, expect)
    }

    func test_decimal_format_internal_lessThanOne8() {
        let result = Decimal(string: "0.12345678912")?.formatted(
            strategy: .general(
                minimumFractionDigits: 0,
                maximumOption: .internal(greaterThanOne: 2, lessThanOne: 8),
                currencyConfiguration: .init()
            ))
        let expect = "0.12345678"

        XCTAssertEqual(result, expect)
    }

    func test_decimal_format_internal_lessThanOne18() {
        let result = Decimal(string: "0.1234567891234567891")?.formatted(
            strategy: .general(
                minimumFractionDigits: 0,
                maximumOption: .internal(greaterThanOne: 2, lessThanOne: 18),
                currencyConfiguration: .init()
            ))
        let expect = "0.123456789123456789"

        XCTAssertEqual(result, expect)
    }

    func test_decimal_format_internal_lessThanOne18_smallValue() {
        let result = Decimal(string: "0.000000000000001001000")?.formatted(
            strategy: .general(
                minimumFractionDigits: 0,
                maximumOption: .internal(greaterThanOne: 2, lessThanOne: 18),
                currencyConfiguration: .init()
            ))
        let expect = "0.000000000000001001"

        XCTAssertEqual(result, expect)
    }

    func test_decimal_format_value18() {
        let result = Decimal(string: "1000.1234567891234567891")?.formatted(
            strategy: .general(
                minimumFractionDigits: 0,
                maximumOption: .value(18),
                currencyConfiguration: .init()
            ))
        let expect = "1,000.123456789123456789"

        XCTAssertEqual(result, expect)
    }

    func test_decimal_format_value8() {
        let result = Decimal(string: "1000.1234567891234567891")?.formatted(
            strategy: .general(
                minimumFractionDigits: 0,
                maximumOption: .value(8),
                currencyConfiguration: .init()
            ))
        let expect = "1,000.12345678"

        XCTAssertEqual(result, expect)
    }

    func test_decimal_format_serial0() {
        let result = Decimal(string: "0.000000000000001001000")?.formatted(
            strategy: .general(
                minimumFractionDigits: 0,
                maximumOption: .value(18),
                currencyConfiguration: .init()
            ))
        let expect = "0.000000000000001001"

        XCTAssertEqual(result, expect)
    }
}
