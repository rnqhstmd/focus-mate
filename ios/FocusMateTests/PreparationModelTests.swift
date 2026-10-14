import Foundation
import XCTest
@testable import FocusMate

final class PreparationModelTests: XCTestCase {
    private enum ProbeError: Error { case expected }
    private final class Probe {
        var writes = 0
        var shouldFail = false
    }
    private static let station = StationSnapshot(id: "seongsu", name: "성수역", direction: 1)
    private static let expectedJourney = JourneySelection(
        origin: StopPosition(index: 0, direction: 1), minutes: 60,
        busID: "2014", busNumber: "2014", destination: "성동구민체육센터", stops: 12
    )

    // Break: a fresh model inherits preparation values or enables an incomplete preparation.
    @MainActor
    func test유효_W02로_처음_진입한_준비는_초기값이고_확정할_수_없다() throws {
        try withReadyModel { model, probe, _, _ in
            try enterPreparation(model)
            XCTAssertEqual(model.path, [.time, .preparation])
            XCTAssertNil(model.preparation.selectedTag)
            XCTAssertEqual(model.preparation.task, "")
            XCTAssertEqual(model.preparation.sound, .bus)
            XCTAssertFalse(model.canConfirmPreparation)
            XCTAssertFalse(model.confirmPreparation())
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertEqual(probe.writes, 0)
        }
    }

    // Break: choosing a tag generates a task or enables confirmation without user input.
    @MainActor
    func test독서만_선택하면_할_일은_비어있고_확정_요청은_생성되지_않는다() throws {
        try withReadyModel { model, _, _, _ in
            try enterPreparation(model)
            XCTAssertTrue(model.preparation.chooseTag(id: "reading"))
            XCTAssertEqual(model.preparation.selectedTag?.name, "독서")
            XCTAssertEqual(model.preparation.task, "")
            XCTAssertFalse(model.canConfirmPreparation)
            XCTAssertFalse(model.confirmPreparation())
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    // Break: empty input leaves an old confirmed request usable.
    @MainActor
    func test빈_할_일로_변경한_후_직접_확정해도_전달은_0이다() throws {
        try assertInvalidTask("")
    }

    // Break: whitespace input is accepted by the AppModel confirmation boundary.
    @MainActor
    func test공백과_줄바꿈_할_일로_변경한_후_직접_확정해도_전달은_0이다() throws {
        try assertInvalidTask(" \n\t ")
    }

    // Break: the AppModel guard rejects a capped valid 80-unit task.
    @MainActor
    func test81단위_입력은_80단위로_확정되어_한번_전달된다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            model.preparation.setTask(String(repeating: "가", count: 81))
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertEqual(try XCTUnwrap(model.consumePreparationRequest()).task, String(repeating: "가", count: 80))
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    // Break: successful custom-tag save loses the W02 journey or task.
    @MainActor
    func test새_태그_저장은_기존_할_일과_W02_여정을_유지한다() throws {
        try withReadyModel { model, probe, _, _ in
            try configureValidPreparation(model)
            let tag = try model.preparation.saveTag(TagEditorDraft(name: " \n개발 메모 \t", icon: .development, color: .green)).get()
            XCTAssertEqual(model.preparation.selectedTag, tag)
            XCTAssertEqual(tag.name, "개발 메모")
            XCTAssertEqual(model.preparation.task, "책 읽기")
            XCTAssertEqual(model.preparedJourney, Self.expectedJourney)
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertEqual(probe.writes, 0)
        }
    }

    // Break: returning to preparation resets the existing session draft.
    @MainActor
    func test시간_화면_왕복은_세션_태그_할_일_확정_소리를_보존한다() throws {
        try withReadyModel { model, probe, _, _ in
            try configureValidPreparation(model)
            _ = try model.preparation.saveTag(TagEditorDraft(name: "개발", icon: .development, color: .blue)).get()
            model.preparation.setSound(.rainBus)
            let before = model.preparation
            model.goBack()
            XCTAssertEqual(model.path, [.time])
            XCTAssertTrue(model.proceedToPreparation())
            XCTAssertEqual(model.preparation, before)
            XCTAssertEqual(model.preparedJourney, Self.expectedJourney)
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertEqual(probe.writes, 0)
        }
    }

    // Break: changing time keeps the old W02 selection/request usable.
    @MainActor
    func test시간_변경으로_후보가_해제되면_getter와_소비_전달은_0이다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            model.goBack()
            model.journeyPlan.setMinutes(25)
            XCTAssertNil(model.journeyPlan.selectedBusID)
            XCTAssertFalse(model.canConfirmPreparation)
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertFalse(model.confirmPreparation())
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    // Break: confirmation omits/changes journey, tag, trimmed task, or sound; persists a journey.
    @MainActor
    func test준비_확정은_전체_payload를_전달하고_진행_여정과_기록을_생성하지_않는다() throws {
        try withReadyModel { model, probe, fileURL, bytes in
            try configureValidPreparation(model)
            let tag = try model.preparation.saveTag(TagEditorDraft(name: " \nMy Focus \t", icon: .writing, color: .pink)).get()
            model.preparation.setTask("  책 읽기  ")
            model.preparation.setSound(.subway)
            let expected = PreparedJourneyDetails(journey: Self.expectedJourney, tag: tag, task: "책 읽기", sound: .subway)
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertEqual(model.confirmedPreparation, expected)
            XCTAssertEqual(model.preparationRequest, expected)
            XCTAssertEqual(model.consumePreparationRequest(), expected)
            XCTAssertEqual(model.confirmedPreparation, expected)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.snapshot?.journey.active)
            XCTAssertEqual(model.snapshot?.records.items.count, 0)
            XCTAssertEqual(probe.writes, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), bytes)
        }
    }

    // Break: repeated confirm enqueues multiple identical requests or consume replays one.
    @MainActor
    func test같은_payload_확정_연타의_요청은_한번만_소비된다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertNotNil(model.consumePreparationRequest())
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertNotNil(model.confirmedPreparation)
        }
    }

    // Break: consume permanently prevents a new explicit confirmation request.
    @MainActor
    func test소비한_뒤_다시_확정하면_새_요청을_한번_전달한다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            let first = try XCTUnwrap(model.consumePreparationRequest())
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertEqual(model.consumePreparationRequest(), first)
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertEqual(model.confirmedPreparation, first)
        }
    }

    // Break: selecting a different tag allows the old tag payload to be consumed.
    @MainActor
    func test태그_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다() throws {
        try assertStaleMutation { model in
            XCTAssertTrue(model.preparation.chooseTag(id: "study"))
            XCTAssertEqual(model.preparation.selectedTagID, "study")
        }
    }

    // Break: entering a different nonempty task allows the old task payload to be consumed.
    @MainActor
    func test할_일_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다() throws {
        try assertStaleMutation { model in
            model.preparation.setTask("새 할 일")
            XCTAssertEqual(model.preparation.task, "새 할 일")
        }
    }

    // Break: saving a different sound allows the old sound payload to be consumed.
    @MainActor
    func test확정_소리_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다() throws {
        try assertStaleMutation { model in
            model.preparation.setSound(.forest)
            XCTAssertEqual(model.preparation.sound, .forest)
        }
    }

    // Break: invalid consume only hides a request and resurrects it when input is restored.
    @MainActor
    func test무효_상태에서_소비한_요청은_입력을_복원해도_되살아나지_않는다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            model.preparation.setTask(" \n ")
            XCTAssertNil(model.consumePreparationRequest())
            model.preparation.setTask("책 읽기")
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertNotNil(model.consumePreparationRequest())
        }
    }

    // Break: merely reading an invalid getter destroys an otherwise unconsumed request.
    @MainActor
    func test무효_getter_읽기는_부작용없이_숨기며_소비전_입력복원은_기존요청을_유지한다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            let expected = try XCTUnwrap(model.preparationRequest)
            model.preparation.setTask("다른 할 일")
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            model.preparation.setTask("책 읽기")
            XCTAssertEqual(model.confirmedPreparation, expected)
            XCTAssertEqual(model.preparationRequest, expected)
            XCTAssertEqual(model.consumePreparationRequest(), expected)
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    // Break: invalid W02 input bypasses the direct-call confirmation guard.
    @MainActor
    func test여정이_없는_직접_확정은_준비값과_요청을_생성하지_않는다() throws {
        try withReadyModel { model, _, _, _ in
            XCTAssertTrue(model.preparation.chooseTag(id: "reading"))
            model.preparation.setTask("책 읽기")
            XCTAssertTrue(model.preparation.isComplete)
            XCTAssertFalse(model.canConfirmPreparation)
            XCTAssertFalse(model.confirmPreparation())
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    // Break: a nonempty task bypasses the missing-tag confirmation guard.
    @MainActor
    func test태그가_없는_직접_확정은_준비값과_요청을_생성하지_않는다() throws {
        try withReadyModel { model, _, _, _ in
            try enterPreparation(model)
            model.preparation.setTask("책 읽기")
            XCTAssertEqual(model.preparation.task, "책 읽기")
            XCTAssertNil(model.preparation.selectedTag)
            XCTAssertFalse(model.canConfirmPreparation)
            XCTAssertFalse(model.confirmPreparation())
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    // Break: no sound blocks confirmation or substitutes the bus identifier.
    @MainActor
    func test소리_없음은_유효한_준비를_차단하지_않고_none으로_전달된다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            model.preparation.setSound(.none)
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertEqual(try XCTUnwrap(model.consumePreparationRequest()).sound, .none)
        }
    }

    // Break: W03 accidentally writes session input or restores it in a new AppModel.
    @MainActor
    func test정상_저장_환경에서도_W03_쓰기0_원본동일_새모델_초안초기화다() throws {
        try assertSessionOnly(shouldFail: false)
    }

    // Break: a write-failing store is touched by W03 or session input leaks into new models.
    @MainActor
    func test쓰기_실패_환경에서도_W03_쓰기시도0_원본동일_새모델_초안초기화다() throws {
        try assertSessionOnly(shouldFail: true)
    }

    @MainActor
    private func enterPreparation(_ model: AppModel) throws {
        model.open(.time)
        model.journeyPlan.setMinutes(60)
        _ = model.journeyPlan.choose(busID: "2014", from: StopPosition(index: 0, direction: 1))
        XCTAssertTrue(model.proceedToPreparation())
        XCTAssertEqual(model.preparedJourney, Self.expectedJourney)
    }

    @MainActor
    private func configureValidPreparation(_ model: AppModel) throws {
        try enterPreparation(model)
        XCTAssertTrue(model.preparation.chooseTag(id: "reading"))
        model.preparation.setTask("책 읽기")
        XCTAssertTrue(model.canConfirmPreparation)
    }

    @MainActor
    private func assertInvalidTask(_ task: String) throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            model.preparation.setTask(task)
            XCTAssertFalse(model.canConfirmPreparation)
            XCTAssertFalse(model.confirmPreparation())
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    @MainActor
    private func assertStaleMutation(_ mutate: (AppModel) -> Void) throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertNotNil(model.preparationRequest)
            mutate(model)
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertNotNil(model.consumePreparationRequest())
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    @MainActor
    private func assertSessionOnly(shouldFail: Bool) throws {
        try withReadyModel(shouldFail: shouldFail) { model, probe, fileURL, bytes in
            try configureValidPreparation(model)
            _ = try model.preparation.saveTag(TagEditorDraft(name: "세션 태그", icon: .development, color: .purple)).get()
            model.preparation.setTask("세션 할 일")
            model.preparation.setSound(.rainBus)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertNotNil(model.consumePreparationRequest())
            XCTAssertEqual(probe.writes, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), bytes)
            XCTAssertEqual(try SnapshotCodec.encode(try XCTUnwrap(model.snapshot)), bytes)
            let relaunched = makeModel(fileURL: fileURL, probe: probe)
            try enterPreparation(relaunched)
            XCTAssertEqual(relaunched.preparation.tags.count, 4)
            XCTAssertFalse(relaunched.preparation.tags.contains { $0.name == "세션 태그" })
            XCTAssertNil(relaunched.preparation.selectedTag)
            XCTAssertEqual(relaunched.preparation.task, "")
            XCTAssertEqual(relaunched.preparation.sound, .bus)
            XCTAssertFalse(relaunched.canConfirmPreparation)
            XCTAssertNil(relaunched.confirmedPreparation)
            XCTAssertNil(relaunched.preparationRequest)
            XCTAssertNil(relaunched.snapshot?.journey.active)
            XCTAssertEqual(relaunched.snapshot?.records.items.count, 0)
            XCTAssertEqual(probe.writes, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), bytes)
        }
    }

    @MainActor
    private func withReadyModel(shouldFail: Bool = false, _ body: (AppModel, Probe, URL, Data) throws -> Void) throws {
        try withTemporaryFile { fileURL in
            let bytes = try SnapshotCodec.encode(Self.stage(true, Self.station, Self.station))
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try bytes.write(to: fileURL, options: .atomic)
            let probe = Probe()
            probe.shouldFail = shouldFail
            let model = makeModel(fileURL: fileURL, probe: probe)
            XCTAssertEqual(model.launchState, .ready(.main))
            XCTAssertEqual(probe.writes, 0, "Fixture loading must not write; counting starts before W03 mutations.")
            try body(model, probe, fileURL, bytes)
        }
    }

    @MainActor
    private func makeModel(fileURL: URL, probe: Probe) -> AppModel {
        let store = LocalSnapshotStore(
            fileURL: fileURL,
            readData: { try Data(contentsOf: $0) },
            createDirectory: { try FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true) },
            writeData: { data, url in
                probe.writes += 1
                if probe.shouldFail { throw ProbeError.expected }
                try data.write(to: url, options: .atomic)
            }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()
        return model
    }
}
