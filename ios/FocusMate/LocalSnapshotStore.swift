import Foundation

indirect enum StorageIssue: Error, Equatable {
    case unreadable, corrupt, unsupportedVersion(Int), invalidState(SnapshotValidationIssue)
    case writeFailed, writeBlocked(StorageIssue), notReady
}

final class LocalSnapshotStore {
    let fileURL: URL
    private let readData: (URL) throws -> Data
    private let createDirectory: (URL) throws -> Void
    private let writeData: (Data, URL) throws -> Void

    init(fileURL: URL,
         readData: @escaping (URL) throws -> Data = { try Data(contentsOf: $0) },
         createDirectory: @escaping (URL) throws -> Void = { try FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true) },
         writeData: @escaping (Data, URL) throws -> Void = { try $0.write(to: $1, options: .atomic) }) {
        self.fileURL = fileURL
        self.readData = readData
        self.createDirectory = createDirectory
        self.writeData = writeData
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
