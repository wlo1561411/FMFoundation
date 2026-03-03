import XCTest

@testable import FMFoundation

final class KeyPathOperatorTests: XCTestCase {
    struct Person {
        var name: String
        var age: Int
    }

    let people = [
        Person(name: "Alice", age: 30),
        Person(name: "Bob", age: 25),
        Person(name: "Charlie", age: 35),
        Person(name: "Diana", age: 28)
    ]

    // Test for '=='
    func testEqualityOperator() {
        let filtered = people.filter(\.age == 30)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Alice")
    }

    // Test for '>='
    func testGreaterThanOrEqualOperator() {
        let filtered = people.filter(\.age >= 30)
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains(where: \.name == "Alice"))
        XCTAssertTrue(filtered.contains(where: \.name == "Charlie"))
    }

    // Test for '<='
    func testLessThanOrEqualOperator() {
        let filtered = people.filter(\.age <= 28)
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains(where: \.name == "Bob"))
        XCTAssertTrue(filtered.contains(where: \.name == "Diana"))
    }

    // Test for '>'
    func testGreaterThanOperator() {
        let filtered = people.filter(\.age > 28)
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains(where: \.name == "Alice"))
        XCTAssertTrue(filtered.contains(where: \.name == "Charlie"))
    }

    // Test for '<'
    func testLessThanOperator() {
        let filtered = people.filter(\.age < 30)
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains(where: \.name == "Bob"))
        XCTAssertTrue(filtered.contains(where: \.name == "Diana"))
    }

    // Test for '~='
    func testBetweenOperator() {
        let filtered = people.filter(\.age ~= (20, 30))
        XCTAssertEqual(filtered.count, 3)
        XCTAssertTrue(filtered.contains(where: \.name == "Alice"))
        XCTAssertTrue(filtered.contains(where: \.name == "Bob"))
        XCTAssertTrue(filtered.contains(where: \.name == "Diana"))
    }

    // Test for '&&'
    func testAndAndOperator() {
        let filtered = people.filter(\.age >= 30 && \.name ~= "A")
        XCTAssertEqual(filtered.count, 1)
        XCTAssertTrue(filtered.contains(where: \.name == "Alice"))
    }
}
