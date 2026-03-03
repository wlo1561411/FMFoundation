import XCTest

@testable import FMFoundation

final class DefaultCodableTests: XCTestCase {
    struct Mock: AutoCodable {
        @DefaultCodable("test")
        var stringValue: String

        @DefaultCodable("", path: "stringValue")
        var test: String

        @DefaultCodable(0)
        var intValue: Int

        @DefaultCodable(false)
        var boolValue: Bool

        @DefaultCodable(0.0)
        var doubleValue: Double

        @DefaultCodable([])
        var arrayValue: [String]

        @DefaultCodable([:])
        var dictValue: [String: Int]
    }

    func testDefaultValues() throws {
        let json = "{}"
        let data = try XCTUnwrap(json.data(using: .utf8))
        let mock = try JSONDecoder().decode(Mock.self, from: data)

        XCTAssertEqual(mock.stringValue, "test")
        XCTAssertEqual(mock.intValue, 0)
        XCTAssertEqual(mock.boolValue, false)
        XCTAssertEqual(mock.doubleValue, 0.0)
        XCTAssertEqual(mock.arrayValue, [])
        XCTAssertEqual(mock.dictValue, [:])
    }

    func testOverriddenValues() throws {
        let json = """
        {
            "stringValue": "hello",
            "intValue": 999,
            "boolValue": true,
            "doubleValue": 3.14,
            "arrayValue": ["a", "b"],
            "dictValue": { "x": 1 }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let mock = try JSONDecoder().decode(Mock.self, from: data)

        XCTAssertEqual(mock.stringValue, "hello")
        XCTAssertEqual(mock.intValue, 999)
        XCTAssertEqual(mock.boolValue, true)
        XCTAssertEqual(mock.doubleValue, 3.14)
        XCTAssertEqual(mock.arrayValue, ["a", "b"])
        XCTAssertEqual(mock.dictValue, ["x": 1])
    }

    func testBackendReturnIntButNeedString() throws {
        let json = """
        {
            "stringValue": 1
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let mock = try JSONDecoder().decode(Mock.self, from: data)

        XCTAssertEqual(mock.stringValue, "1")
    }

    func testBackendReturnStringButNeedInt() throws {
        let json = """
        {
            "intValue": "999"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let mock = try JSONDecoder().decode(Mock.self, from: data)

        XCTAssertEqual(mock.intValue, 999)
    }

    func testDecodeUser_whenHasDuplicateKeyForRealName_thenBothPropertiesAreFilledFromSameJSONKey() throws {
        let json = """
        {
            "stringValue": "hello",
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let mock = try JSONDecoder().decode(Mock.self, from: data)

        // 兩個屬性都從 "reallyName" 這個 key decode 而來
        XCTAssertEqual(mock.stringValue, "hello")
        XCTAssertEqual(mock.test, "hello")
    }

    /// 測試定義有同名 Key 的 Encode
    func testEncodeUser_whenBothRealNamePropertiesHaveValue_thenOutputExpectedJSONString() throws {
        let mock = Mock()
        mock.stringValue = "hello"
        mock.test = "hello"

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let jsonData = try encoder.encode(mock)
        let jsonString = String(data: jsonData, encoding: .utf8)

        // Encode 時 key 會是屬性名稱，而不是 path
        XCTAssertEqual(jsonString, """
        {"arrayValue":[],"boolValue":false,"dictValue":{},"doubleValue":0,"intValue":0,"stringValue":"hello","test":"hello"}
        """)
    }
}
