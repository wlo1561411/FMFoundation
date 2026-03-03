import Foundation

public struct AutoDecodePath {
    enum `Type` {
        case key(String)
    }

    private(set) var type: `Type` = .key("")
}
