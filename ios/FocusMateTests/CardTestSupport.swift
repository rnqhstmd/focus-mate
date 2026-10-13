import Foundation
import XCTest
@testable import FocusMate

/// 주어진 값을 호출마다 순서대로 돌려준다. 다 쓰면 마지막 값을 반복한다.
final class SequenceRandom {
    private var values: [UInt32]
    private var index = 0

    init(_ values: [UInt32]) {
        precondition(!values.isEmpty)
        self.values = values
    }

    func next() -> UInt32 {
        let value = values[min(index, values.count - 1)]
        index += 1
        return value
    }
}

private struct MemoryWriteError: Error {}

/// 메모리 바이트를 readData/writeData 클로저로 연결한 실제 LocalSnapshotStore.
/// writeFails(n)이 true면 n번째(1부터) 쓰기를 던진다. 던진 쓰기는 바이트를 바꾸지 않는다.
func memoryStore(
    initial: Data?,
    writeFails: @escaping (Int) -> Bool = { _ in false }
) -> (store: LocalSnapshotStore, bytes: () -> Data?, writeCount: () -> Int) {
    final class Box {
        var data: Data?
        var writes = 0
    }
    let box = Box()
    box.data = initial
    let store = LocalSnapshotStore(
        fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
        readData: { _ in
            guard let data = box.data else { throw CocoaError(.fileReadNoSuchFile) }
            return data
        },
        createDirectory: { _ in },
        writeData: { data, _ in
            box.writes += 1
            if writeFails(box.writes) { throw MemoryWriteError() }
            box.data = data
        }
    )
    return (store, { box.data }, { box.writes })
}
