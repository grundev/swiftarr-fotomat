#if !canImport(ObjectiveC)
import XCTest

extension AppTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__AppTests = [
        ("testNothing", testNothing),
    ]
}

extension FotomatTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__FotomatTests = [
        ("testImageType", testImageType),
        ("testProcessForum", testProcessForum),
        ("testProcessProfile", testProcessProfile),
        ("testProcessTwitarr", testProcessTwitarr),
        ("testProcessWatermark", testProcessWatermark),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AppTests.__allTests__AppTests),
        testCase(FotomatTests.__allTests__FotomatTests),
    ]
}
#endif
