import XCTest

@testable import FMFoundation

final class UserDefaultCodableTests: XCTestCase {
    struct Mock: Codable, Equatable {
        let text: String
    }

    private var mockDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        mockDefaults = UserDefaults(suiteName: "Mock")
        mockDefaults.removePersistentDomain(forName: "Mock")
    }

    override func tearDown() {
        mockDefaults.removePersistentDomain(forName: "Mock")
        mockDefaults = nil
        super.tearDown()
    }

    // 測試儲存與讀取基本型別
    func testStoreAndLoadCodableValue() throws {
        var mock = UserDefaultCodable<Mock>(
            wrappedValue: .init(text: ""),
            "MockKey",
            structName: "Tests",
            userDefaults: mockDefaults
        )

        mock.wrappedValue = .init(text: "Hello")

        let expect = "Hello"

        let data = try XCTUnwrap(mockDefaults.data(forKey: "Tests_MockKey"))
        let model = try JSONDecoder().decode(Mock.self, from: data)

        XCTAssertEqual(model.text, expect)
    }

    // 測試預設值讀取
    func testDefaultValueWhenNoData() {
        let mock = UserDefaultCodable<Mock>(
            wrappedValue: .init(text: "Default"),
            "MockKey",
            structName: "Tests",
            userDefaults: mockDefaults
        )

        XCTAssertEqual(mock.wrappedValue.text, "Default")
    }

    // 測試清除 optional（nil）時是否會從 UserDefaults 移除
    func testOptionalRemoval() throws {
        var mock = UserDefaultCodable<Mock?>(
            wrappedValue: .init(text: "Default"),
            "MockKey",
            structName: "Tests",
            userDefaults: mockDefaults
        )

        // 先設定
        mock.wrappedValue = .init(text: "Hello")

        // 清除
        mock.wrappedValue = nil

        XCTAssertNil(mockDefaults.data(forKey: "Tests_MockKey"))
    }

    // 測試編碼失敗是否能回傳 defaultValue
    func testCorruptedDataFallsBackToDefault() throws {
        let corruptedData = try XCTUnwrap("invalid json".data(using: .utf8))

        mockDefaults.set(corruptedData, forKey: "Tests_MockKey")

        let mock = UserDefaultCodable<Mock>(
            wrappedValue: .init(text: "Default"),
            "MockKey",
            structName: "Tests",
            userDefaults: mockDefaults
        )

        XCTAssertEqual(mock.wrappedValue.text, "Default")
    }
}
