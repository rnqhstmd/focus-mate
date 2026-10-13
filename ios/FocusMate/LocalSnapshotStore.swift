import Foundation

indirect enum StorageIssue: Error, Equatable {
    case unreadable, corrupt, unsupportedVersion(Int), invalidState(SnapshotValidationIssue)
    case writeFailed, writeBlocked(StorageIssue), notReady
}

enum RecoverySource: Equatable { case bytes(Data), unreadable, missing }
enum StorageRecoveryIssue: Error, Equatable {
    case backupFailed, cleanupFailed, sourceChanged, sourceMissing, notRequired
}

final class LocalSnapshotStore {
    let fileURL: URL
    private let readData: (URL) throws -> Data
    private let createDirectory: (URL) throws -> Void
    private let writeData: (Data, URL) throws -> Void
    private let backupID: () -> UUID
    private let writeBackup: (Data, URL) throws -> Void
    private let removeData: (URL) throws -> Void

    init(fileURL: URL,
         readData: @escaping (URL) throws -> Data = { try Data(contentsOf: $0) },
         createDirectory: @escaping (URL) throws -> Void = { try FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true) },
         writeData: @escaping (Data, URL) throws -> Void = { try $0.write(to: $1, options: .atomic) },
         backupID: @escaping () -> UUID = UUID.init,
         writeBackup: @escaping (Data, URL) throws -> Void = { try $0.write(to: $1, options: .withoutOverwriting) },
         removeData: @escaping (URL) throws -> Void = { try FileManager.default.removeItem(at: $0) }) {
        self.fileURL = fileURL
        self.readData = readData
        self.createDirectory = createDirectory
        self.writeData = writeData
        self.backupID = backupID
        self.writeBackup = writeBackup
        self.removeData = removeData
    }

    func recoverySource() -> RecoverySource {
        do { return .bytes(try readData(fileURL)) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { return .missing }
        catch { return .unreadable }
    }

    func backupAndClear(expectedSource: RecoverySource) throws -> URL {
        let original: Data
        switch recoverySource() {
        case let .bytes(data): original = data
        case .missing: throw StorageRecoveryIssue.sourceMissing
        case .unreadable: throw StorageRecoveryIssue.backupFailed
        }
        switch expectedSource {
        case let .bytes(expected) where expected != original: throw StorageRecoveryIssue.sourceChanged
        case .missing: throw StorageRecoveryIssue.sourceChanged
        default: break
        }
        do {
            _ = try SnapshotCodec.decode(original)
            throw StorageRecoveryIssue.notRequired
        } catch let issue as StorageIssue {
            switch issue {
            case .corrupt, .unsupportedVersion, .invalidState: break
            default: throw StorageRecoveryIssue.backupFailed
            }
        }
        let backupURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent("app-state.recovery-\(backupID().uuidString).backup")
        do {
            try writeBackup(original, backupURL)
            guard try readData(backupURL) == original else { throw StorageRecoveryIssue.backupFailed }
        } catch { throw StorageRecoveryIssue.backupFailed }

        switch recoverySource() {
        case let .bytes(current) where current == original: break
        case .bytes: throw StorageRecoveryIssue.sourceChanged
        case .missing: throw StorageRecoveryIssue.sourceMissing
        case .unreadable: throw StorageRecoveryIssue.cleanupFailed
        }
        do { try removeData(fileURL) }
        catch { throw StorageRecoveryIssue.cleanupFailed }
        guard recoverySource() == .missing else { throw StorageRecoveryIssue.cleanupFailed }
        return backupURL
    }

    func load() throws -> AppSnapshot? {
        let data: Data
        do { data = try readData(fileURL) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { return nil }
        catch { throw StorageIssue.unreadable }
        return try SnapshotCodec.decode(data)
    }

    func save(_ snapshot: AppSnapshot) throws {
        do { try snapshot.validate() }
        catch let issue as SnapshotValidationIssue { throw StorageIssue.invalidState(issue) }
        do { _ = try load() }
        catch let issue as StorageIssue { throw StorageIssue.writeBlocked(issue) }
        do {
            let data = try SnapshotCodec.encode(snapshot)
            try createDirectory(fileURL.deletingLastPathComponent())
            try writeData(data, fileURL)
        } catch { throw StorageIssue.writeFailed }
    }
}
