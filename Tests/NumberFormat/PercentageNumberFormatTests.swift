import XCTest

@testable import FMFoundation

final class PercentageNumberFormatTests: XCTestCase {
    func test_postive_zero() {
        let result = 0.formatted(
            strategy: .percentage(
                minimumFractionDigits: 0,
                withPercentileSymbol: true,
                withChangeSymbol: true
            )
        )
        let expect = "0%"

        XCTAssertEqual(result, expect)
    }

    func test_negative_zero() {
        let result = (-0).formatted(
            strategy: .percentage(
                minimumFractionDigits: 0,
                withPercentileSymbol: true,
                withChangeSymbol: true
            )
        )
        let expect = "0%"

        XCTAssertEqual(result, expect)
    }

    func test_postive_60_05() {
        let result = 60.05.formatted(
            strategy: .percentage(
                minimumFractionDigits: 0,
                withPercentileSymbol: true,
                withChangeSymbol: true
            )
        )
        let expect = "+60.05%"

        XCTAssertEqual(result, expect)
    }

    func test_postive_60_005() {
        let result = 60.005.formatted(
            strategy: .percentage(
                minimumFractionDigits: 0,
                withPercentileSymbol: true,
                withChangeSymbol: true
            )
        )
        let expect = "+60%"

        XCTAssertEqual(result, expect)
    }

    func test_negative_60_05() {
        let result = (-60.05).formatted(
            strategy: .percentage(
                minimumFractionDigits: 0,
                withPercentileSymbol: true,
                withChangeSymbol: true
            )
        )
        let expect = "-60.05%"

        XCTAssertEqual(result, expect)
    }

    func test_negative_60_005() {
        let result = (-60.005).formatted(
            strategy: .percentage(
                minimumFractionDigits: 0,
                withPercentileSymbol: true,
                withChangeSymbol: true
            )
        )
        let expect = "-60%"

        XCTAssertEqual(result, expect)
    }

    func test_postive_0_05() {
        let result = 0.05.formatted(
            strategy: .percentage(
                minimumFractionDigits: 0,
                withPercentileSymbol: true,
                withChangeSymbol: true
            )
        )
        let expect = "+0.05%"

        XCTAssertEqual(result, expect)
    }

    func test_postive_0_005() {
        let result = 0.005.formatted(
            strategy: .percentage(
                minimumFractionDigits: 0,
                withPercentileSymbol: true,
                withChangeSymbol: true
            )
        )
        let expect = "0%"

        XCTAssertEqual(result, expect)
    }

    func test_negative_0_05() {
        let result = (-0.05).formatted(
            strategy: .percentage(
                minimumFractionDigits: 0,
                withPercentileSymbol: true,
                withChangeSymbol: true
            )
        )
        let expect = "-0.05%"

        XCTAssertEqual(result, expect)
    }

    func test_negative_0_005() {
        let result = (-0.005).formatted(
            strategy: .percentage(
                minimumFractionDigits: 0,
                withPercentileSymbol: true,
                withChangeSymbol: true
            )
        )
        let expect = "0%"

        XCTAssertEqual(result, expect)
    }

    func test_positive_without_changeSymbol() {
        let result = 0.5.formatted(
            strategy: .percentage(
                minimumFractionDigits: 0,
                withPercentileSymbol: true,
                withChangeSymbol: false
            )
        )
        let expect = "0.5%"

        XCTAssertEqual(result, expect)
    }

    func test_negative_without_changeSymbol() {
        let result = (-0.5).formatted(
            strategy: .percentage(
                minimumFractionDigits: 0,
                withPercentileSymbol: true,
                withChangeSymbol: false
            )
        )
        let expect = "0.5%"

        XCTAssertEqual(result, expect)
    }
}
