import Foundation

final class WidgetSnapshotStore {
    private let containerURL: () -> URL?
    private let readData: (URL) throws -> Data
    private let atomicWrite: (Data, URL) throws -> Void

    init(containerURL: @escaping () -> URL?, readData: @escaping (URL) throws -> Data = { try Data(contentsOf: $0) },
         atomicWrite: @escaping (Data, URL) throws -> Void = { try $0.write(to: $1, options: .atomic) }) {
        self.containerURL = containerURL
        self.readData = readData
        self.atomicWrite = atomicWrite
    }
    func read(now: Date, timeZone: TimeZone) -> WidgetReadState {
        guard let container = containerURL(), let data = try? readData(container.appendingPathComponent("widget-snapshot-v1.json")) else { return .unavailable }
        return WidgetFreshness.classify(WidgetSnapshotCodec.decode(data), now: now, timeZone: timeZone)
    }
    func write(_ snapshot: WidgetSnapshot) throws {
        guard let container = containerURL() else { throw WidgetDataIssue.containerUnavailable }
        let data = try WidgetSnapshotCodec.encode(snapshot)
        do { try atomicWrite(data, container.appendingPathComponent("widget-snapshot-v1.json")) }
        catch { throw WidgetDataIssue.writeFailed }
    }
}
