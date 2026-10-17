import Foundation
import XCTest
@testable import FocusMate

final class WidgetSnapshotStoreTests: XCTestCase {
    private typealias F = WidgetFixtures
    private func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("w18-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: url) }
        return url
    }
    private func file(_ directory: URL) -> URL {
        directory.appendingPathComponent("widget-snapshot-v1.json")
    }

    // 깨짐: 유효공유본을 실제파일로 쓰지않거나 두번째쓰기를기존파일에 덧붙인다.
    func testW18_실제임시파일은_두번째공유본으로_원자교체된다() throws {
        let directory = try folder()
        let store = WidgetSnapshotStore(containerURL: { directory })
        try store.write(F.snapshot())
        try store.write(F.snapshot(empty: true))
        XCTAssertEqual(store.read(now: F.generated, timeZone: F.utc), .validEmpty(F.snapshot(empty: true)))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["widget-snapshot-v1.json"])
    }

    // 깨짐: write실패전에 목적파일을 지워 이전공유본을 잃거나 실패를 삼킨다.
    func testW18_주입쓰기실패는_이전bytes를_보존한다() throws {
        let directory = try folder()
        let old = try JSONEncoder().encode(F.snapshot())
        try old.write(to: file(directory), options: .atomic)
        let store = WidgetSnapshotStore(
            containerURL: { directory }, atomicWrite: { _, _ in throw WidgetDataIssue.writeFailed }
        )
        XCTAssertThrowsError(try store.write(F.snapshot(empty: true))) {
            XCTAssertEqual($0 as? WidgetDataIssue, .writeFailed)
        }
        XCTAssertEqual(try Data(contentsOf: file(directory)), old)
    }

    // 깨짐: 올바른파일을읽지않거나 decode된정상값을 unavailable로 삼킨다.
    func testW18_기존유효파일을_정상공유상태로_읽는다() throws {
        let directory = try folder()
        let snapshot = F.snapshot()
        try JSONEncoder().encode(snapshot).write(to: file(directory), options: .atomic)
        let store = WidgetSnapshotStore(containerURL: { directory })
        XCTAssertEqual(store.read(now: F.generated, timeZone: F.utc), .valid(snapshot))
    }

    // 호환 회귀. 깨짐: 읽기실패를 정상0으로 위장한다.
    func testW18_주입읽기실패는_unavailable이다() throws {
        let directory = try folder()
        let store = WidgetSnapshotStore(containerURL: { directory }, readData: { _ in throw WidgetDataIssue.readFailed })
        XCTAssertEqual(store.read(now: F.generated, timeZone: F.utc), .unavailable)
    }

    // 호환 회귀. 깨짐: AppGroup없음을 정상빈공유본으로 대체한다.
    func testW18_공유컨테이너없으면_읽기는_unavailable이다() {
        let store = WidgetSnapshotStore(containerURL: { nil })
        XCTAssertEqual(store.read(now: F.generated, timeZone: F.utc), .unavailable)
    }

    // 깨짐: AppGroup없을때 쓰기를성공처리하거나 Documents로 우회한다.
    func testW18_공유컨테이너없으면_쓰기는_containerUnavailable이다() {
        let store = WidgetSnapshotStore(containerURL: { nil })
        XCTAssertThrowsError(try store.write(F.snapshot())) {
            XCTAssertEqual($0 as? WidgetDataIssue, .containerUnavailable)
        }
    }
}
