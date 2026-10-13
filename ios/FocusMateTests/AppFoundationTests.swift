import Foundation
import XCTest
@testable import FocusMate

final class AppFoundationTests: XCTestCase {
    private enum ProbeError: Error { case expected }

    private static let initialStation = StationSnapshot(id: "seongsu", name: "성수", direction: 1)
    private static let currentStation = StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1)

    private static let readySnapshot = stage(true, initialStation, currentStation)
    private static let cardOnlySnapshot = stage(true, nil, nil)
    private static let readyEnvelope = Data(
        #"{"version":1,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seoulForest","name":"서울숲","direction":-1}}}"#.utf8
    )
    private static let corruptBytes = Data("{broken".utf8)
    private static let unsupportedBytes = Data(#"{"version":999,"state":null}"#.utf8)

    func testLaunchRouteAcceptsTheThreeValidStages() throws {
        let cases: [(snapshot: AppSnapshot, route: LaunchRoute)] = [
            (.empty, .cardEntry),
            (Self.cardOnlySnapshot, .initialStationEntry),
            (Self.readySnapshot, .main),
        ]

        for item in cases {
            XCTAssertNoThrow(try item.snapshot.validate())
            XCTAssertEqual(try item.snapshot.launchRoute(), item.route)
        }
    }

    func testValidationRejectsStageAndStationBoundaryViolationsInContractOrder() {
        let blankID = StationSnapshot(id: " \n", name: "성수", direction: 1)
        let blankName = StationSnapshot(id: "seongsu", name: "\n ", direction: 1)
        let zeroDirection = StationSnapshot(id: "seongsu", name: "성수", direction: 0)
        let cases: [(snapshot: AppSnapshot, issue: SnapshotValidationIssue)] = [
            (Self.stage(false, Self.initialStation, Self.currentStation), .inconsistentStage),
            (Self.stage(true, Self.initialStation, nil), .inconsistentStage),
            (Self.stage(true, nil, Self.currentStation), .inconsistentStage),
            (Self.stage(true, blankID, Self.currentStation), .emptyStationID),
            (Self.stage(true, blankName, Self.currentStation), .emptyStationName),
            (Self.stage(true, zeroDirection, Self.currentStation), .invalidDirection(0)),
            (Self.stage(true, Self.initialStation, blankID), .emptyStationID),
            (Self.stage(true, Self.initialStation, blankName), .emptyStationName),
            (Self.stage(true, Self.initialStation, zeroDirection), .invalidDirection(0)),
        ]

        for item in cases {
            assertValidationIssue(item.issue) {
                try item.snapshot.validate()
            }
        }
    }

    func testMissingLoadReturnsNilWithoutDirectoryOrWriteSideEffects() throws {
        var readCalls = 0
        var directoryCalls = 0
        var writeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in
                readCalls += 1
                throw CocoaError(.fileReadNoSuchFile)
            },
            createDirectory: { _ in directoryCalls += 1 },
            writeData: { _, _ in writeCalls += 1 }
        )

        XCTAssertNil(try store.load())
        XCTAssertEqual(readCalls, 1)
        XCTAssertEqual(directoryCalls, 0)
        XCTAssertEqual(writeCalls, 0)
    }

    func testPermissionReadFailureIsUnreadableRatherThanMissing() {
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in throw CocoaError(.fileReadNoPermission) }
        )

        assertStorageIssue(.unreadable) {
            _ = try store.load()
        }
    }

    func testLoadClassifiesMalformedBytesAndUnsupportedVersionBeforePayload() {
        let cases: [(bytes: Data, issue: StorageIssue)] = [
            (Self.corruptBytes, .corrupt),
            (Self.unsupportedBytes, .unsupportedVersion(999)),
        ]

        for item in cases {
            let store = LocalSnapshotStore(
                fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
                readData: { _ in item.bytes }
            )
            assertStorageIssue(item.issue) {
                _ = try store.load()
            }
        }
    }

    func testSaveBlocksOnProtectedExistingFilesAndPreservesExactBytes() throws {
        let cases: [(bytes: Data, issue: StorageIssue)] = [
            (Self.corruptBytes, .corrupt),
            (Self.unsupportedBytes, .unsupportedVersion(999)),
        ]

        for item in cases {
            try withTemporaryFile { fileURL in
                try FileManager.default.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try item.bytes.write(to: fileURL)
                var directoryCalls = 0
                var writeCalls = 0
                let store = LocalSnapshotStore(
                    fileURL: fileURL,
                    createDirectory: { _ in directoryCalls += 1 },
                    writeData: { _, _ in writeCalls += 1 }
                )

                assertStorageIssue(.writeBlocked(item.issue)) {
                    try store.save(Self.readySnapshot)
                }
                XCTAssertEqual(directoryCalls, 0)
                XCTAssertEqual(writeCalls, 0)
                XCTAssertEqual(try Data(contentsOf: fileURL), item.bytes)
            }
        }
    }

    func testInvalidCandidateIsRejectedBeforeReadDirectoryAndWrite() {
        var readCalls = 0
        var directoryCalls = 0
        var writeCalls = 0
        let invalid = Self.stage(
            true,
            StationSnapshot(id: " ", name: "성수", direction: 1),
            Self.currentStation
        )
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in
                readCalls += 1
                return Self.readyEnvelope
            },
            createDirectory: { _ in directoryCalls += 1 },
            writeData: { _, _ in writeCalls += 1 }
        )

        assertStorageIssue(.invalidState(.emptyStationID)) {
            try store.save(invalid)
        }
        XCTAssertEqual(readCalls, 0)
        XCTAssertEqual(directoryCalls, 0)
        XCTAssertEqual(writeCalls, 0)
    }

    func testFirstSaveCreatesNestedDirectoryAndFreshStoreRestoresExactSnapshot() throws {
        try withTemporaryFile { fileURL in
            let store = LocalSnapshotStore(fileURL: fileURL)

            try store.save(Self.readySnapshot)

            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
            let restored = try LocalSnapshotStore(fileURL: fileURL).load()
            XCTAssertEqual(restored, Self.readySnapshot)
        }
    }

    func testDirectoryAndWriteFailuresPropagateAsWriteFailed() {
        var directoryFailureWriteCalls = 0
        let directoryFailureStore = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in throw CocoaError(.fileReadNoSuchFile) },
            createDirectory: { _ in throw ProbeError.expected },
            writeData: { _, _ in directoryFailureWriteCalls += 1 }
        )
        assertStorageIssue(.writeFailed) {
            try directoryFailureStore.save(Self.readySnapshot)
        }
        XCTAssertEqual(directoryFailureWriteCalls, 0)

        var writeFailureDirectoryCalls = 0
        var writeFailureCalls = 0
        let writeFailureStore = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in throw CocoaError(.fileReadNoSuchFile) },
            createDirectory: { _ in writeFailureDirectoryCalls += 1 },
            writeData: { _, _ in
                writeFailureCalls += 1
                throw ProbeError.expected
            }
        )
        assertStorageIssue(.writeFailed) {
            try writeFailureStore.save(Self.readySnapshot)
        }
        XCTAssertEqual(writeFailureDirectoryCalls, 1)
        XCTAssertEqual(writeFailureCalls, 1)
    }

    @MainActor
    func testModelLoadsOnlyOnceAndIgnoresOpenOutsideMain() {
        var readCalls = 0
        var writeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in
                readCalls += 1
                throw CocoaError(.fileReadNoSuchFile)
            },
            writeData: { _, _ in writeCalls += 1 }
        )
        let model = AppModel(store: store)

        model.loadIfNeeded()
        model.loadIfNeeded()
        for destination in Destination.allCases {
            model.open(destination)
        }

        XCTAssertEqual(readCalls, 1)
        XCTAssertEqual(writeCalls, 0)
        XCTAssertEqual(model.snapshot, .empty)
        XCTAssertEqual(model.launchState, .ready(.cardEntry))
        XCTAssertEqual(model.path, [])
    }

    @MainActor
    func testMainDestinationsRoundTripSynchronouslyWithoutWrites() {
        var directoryCalls = 0
        var writeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in Self.readyEnvelope },
            createDirectory: { _ in directoryCalls += 1 },
            writeData: { _, _ in writeCalls += 1 }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()

        for destination in [Destination.preparation, .records, .settings, .profile] {
            model.open(destination)
            XCTAssertEqual(model.path, [destination])
            model.goBack()
            XCTAssertEqual(model.path, [])
        }

        XCTAssertEqual(model.snapshot, Self.readySnapshot)
        XCTAssertEqual(model.launchState, .ready(.main))
        XCTAssertEqual(directoryCalls, 0)
        XCTAssertEqual(writeCalls, 0)
        XCTAssertNil(model.saveFailure)
    }

    @MainActor
    func testFailedSaveKeepsPreviousSnapshotRouteAndPath() {
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in Self.readyEnvelope },
            createDirectory: { _ in },
            writeData: { _, _ in throw ProbeError.expected }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()
        model.open(.records)

        XCTAssertFalse(model.save(Self.cardOnlySnapshot))

        XCTAssertEqual(model.snapshot, Self.readySnapshot)
        XCTAssertEqual(model.launchState, .ready(.main))
        XCTAssertEqual(model.path, [.records])
        XCTAssertEqual(model.saveFailure, .writeFailed)
    }

    @MainActor
    func testSuccessfulSaveClearsPriorFailureAndClearsPathWhenRouteChanges() {
        var shouldFailWrite = true
        var writeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in Self.readyEnvelope },
            createDirectory: { _ in },
            writeData: { _, _ in
                writeCalls += 1
                if shouldFailWrite { throw ProbeError.expected }
            }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()
        model.open(.profile)
        XCTAssertFalse(model.save(Self.readySnapshot))
        XCTAssertEqual(model.saveFailure, .writeFailed)
        XCTAssertEqual(model.path, [.profile])

        shouldFailWrite = false
        XCTAssertTrue(model.save(Self.cardOnlySnapshot))

        XCTAssertEqual(writeCalls, 2)
        XCTAssertNil(model.saveFailure)
        XCTAssertEqual(model.snapshot, Self.cardOnlySnapshot)
        XCTAssertEqual(model.launchState, .ready(.initialStationEntry))
        XCTAssertEqual(model.path, [])
    }

    @MainActor
    func testFailedLoadBlocksLaterSaveWithoutAdditionalFileAccess() {
        var readCalls = 0
        var directoryCalls = 0
        var writeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in
                readCalls += 1
                throw CocoaError(.fileReadNoPermission)
            },
            createDirectory: { _ in directoryCalls += 1 },
            writeData: { _, _ in writeCalls += 1 }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()
        XCTAssertEqual(model.launchState, .failed(.unreadable))

        XCTAssertFalse(model.save(Self.readySnapshot))

        XCTAssertEqual(readCalls, 1)
        XCTAssertEqual(directoryCalls, 0)
        XCTAssertEqual(writeCalls, 0)
        XCTAssertNil(model.snapshot)
        XCTAssertEqual(model.path, [])
        XCTAssertEqual(model.launchState, .failed(.unreadable))
        XCTAssertEqual(model.saveFailure, .writeBlocked(.unreadable))
    }

    private func assertValidationIssue(
        _ expected: SnapshotValidationIssue,
        file: StaticString = #filePath,
        line: UInt = #line,
        operation: () throws -> Void
    ) {
        do {
            try operation()
            XCTFail("Expected SnapshotValidationIssue", file: file, line: line)
        } catch let actual as SnapshotValidationIssue {
            XCTAssertEqual(actual, expected, file: file, line: line)
        } catch {
            XCTFail("Expected SnapshotValidationIssue", file: file, line: line)
        }
    }
}
