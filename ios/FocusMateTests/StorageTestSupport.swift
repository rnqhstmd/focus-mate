import Foundation
import XCTest
@testable import FocusMate

/// 저장 계층 테스트가 함께 쓰는 헬퍼.
extension XCTestCase {
    static func stage(_ issued: Bool, _ initial: StationSnapshot?, _ current: StationSnapshot?) -> AppSnapshot {
        AppSnapshot.empty.updatingStage(cardIssued: issued, initialStation: initial, currentStation: current)
    }

    func assertStorageIssue(
        _ expected: StorageIssue,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line,
        operation: () throws -> Void
    ) {
        do {
            try operation()
            XCTFail("Expected StorageIssue \(expected) \(message)", file: file, line: line)
        } catch let actual as StorageIssue {
            XCTAssertEqual(actual, expected, message, file: file, line: line)
        } catch {
            XCTFail("Expected StorageIssue \(expected) but got \(error) \(message)", file: file, line: line)
        }
    }

    func withTemporaryFile(_ operation: (URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusMate-\(type(of: self))-\(UUID().uuidString)", isDirectory: true)
        let fileURL = root
            .appendingPathComponent("nested", isDirectory: true)
            .appendingPathComponent("FocusMate", isDirectory: true)
            .appendingPathComponent("app-state.json", isDirectory: false)
        defer { try? FileManager.default.removeItem(at: root) }
        try operation(fileURL)
    }
}
