import Foundation

struct AutoDecoderContext {
    let givenPath: AutoDecodePath?
    var inferredPath: AutoDecodePath?

    var preferredPath: AutoDecodePath {
        if let givenPath {
            givenPath
        } else if let inferredPath {
            inferredPath
        } else {
            AutoDecodePath()
        }
    }
}
