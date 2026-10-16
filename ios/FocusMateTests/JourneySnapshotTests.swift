import Foundation
import XCTest
@testable import FocusMate

final class JourneySnapshotTests: XCTestCase {
    private typealias F = BoardingFixtures

    // MARK: - 생성 (AC-11 저장 내용, AC-19)

    // 깨짐: boarding이 위치·이름·버스·도착지·시간·할 일·소리 중 하나라도 빠뜨리거나 잘못 복사하면 실패.
    func testAC11_승차값은_출발_버스_도착_시간_할일_소리를_담는다() {
        let journey = F.awaiting()

        XCTAssertEqual(journey.id, "journey-1")
        XCTAssertEqual(journey.cardID, "FM-01234567")
        XCTAssertEqual(journey.originStopID, "seongsu")
        XCTAssertEqual(journey.originName, "성수역")
        XCTAssertEqual(journey.minutes, 60)
        XCTAssertEqual(journey.busID, "2014")
        XCTAssertEqual(journey.busNumber, "2014")
        XCTAssertEqual(journey.busKind, "지선")
        XCTAssertEqual(journey.destinationStopID, "seongdongSportsCenter")
        XCTAssertEqual(journey.destinationName, "성동구민체육센터")
        XCTAssertEqual(journey.task, "책 읽기")
        XCTAssertEqual(journey.sound, .bus)
        XCTAssertEqual(journey.boardedAt, F.boardedAt)
    }

    // 깨짐: 태그 정의(id·이름·아이콘·색) 중 하나라도 복사하지 않으면 실패.
    func testAC11_승차값은_태그_정의_전체를_복사해_담는다() {
        let tag = F.awaiting().tag

        XCTAssertEqual(tag, JourneySnapshot.Tag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand))
    }

    // 깨짐: 초기 phase가 awaitingDeparture가 아니거나 진도가 0이 아니면 실패.
    func testAC19_승차값은_출발확인_전이고_진도0이다() {
        let journey = F.awaiting()

        XCTAssertEqual(journey.phase, .awaitingDeparture)
        XCTAssertEqual(journey.progress.elapsedSeconds, 0)
        XCTAssertEqual(journey.progress, JourneySnapshot.Progress.start)
    }

    // MARK: - 출발 확인 (AC-20)

    // 깨짐: confirmingDeparture가 phase를 바꾸지 않으면 실패.
    func testAC20_출발확인은_phase를_departed로_바꾼다() {
        XCTAssertEqual(F.awaiting().confirmingDeparture().phase, .departed)
    }

    // 깨짐: confirmingDeparture가 진도를 올리거나 다른 필드를 바꾸면 실패.
    func testAC20_출발확인은_phase_외_값을_바꾸지_않고_진도는_0이다() {
        let before = F.awaiting()
        let after = before.confirmingDeparture()

        XCTAssertEqual(after.progress.elapsedSeconds, 0)
        XCTAssertEqual(after, F.journey(phase: .departed, elapsedSeconds: 0))
    }

    // MARK: - 구조 검증 (설계 A-1)

    // 깨짐: 유효한 대기 상태 여정을 검증이 거절하면 실패.
    func testA1_유효한_여정은_검증을_통과한다() throws {
        XCTAssertNoThrow(try F.awaiting().validate(currentCardID: F.cardID))
        XCTAssertNoThrow(try F.awaiting().confirmingDeparture().validate(currentCardID: F.cardID))
    }

    // 깨짐: 빈 문자열 필드 중 하나라도 검증하지 않으면 실패.
    func testA1_빈_문자열_필드는_emptyField로_거절된다() {
        let candidates: [JourneySnapshot] = [
            F.journey(id: ""),
            F.journey(cardID: ""),
            F.journey(originStopID: ""),
            F.journey(originName: " "),
            F.journey(busID: ""),
            F.journey(busNumber: ""),
            F.journey(busKind: "\n"),
            F.journey(destinationStopID: ""),
            F.journey(destinationName: ""),
            F.journey(tag: JourneySnapshot.Tag(id: "", name: "독서", icon: .reading, color: .sand)),
        ]
        for (index, candidate) in candidates.enumerated() {
            do {
                try candidate.validate(currentCardID: candidate.cardID)
                XCTFail("후보 \(index) 가 통과함")
            } catch ActiveJourneyValidationIssue.emptyField {
            } catch {
                XCTFail("후보 \(index) 에서 emptyField 대신 \(error)")
            }
        }
    }

    // 깨짐: 빈 값 필드의 이름을 emptyField에 담지 않으면 실패.
    func testA1_빈_도착지_이름은_필드명과_함께_거절된다() {
        assertIssue(.emptyField("destinationName"), F.journey(destinationName: "  "))
        assertIssue(.emptyField("busNumber"), F.journey(busNumber: ""))
    }

    // 깨짐: 이름류 길이 상한(UTF-16 500)을 검사하지 않거나 500을 거절하면 실패.
    func testA1_이름류가_500초과면_nameTooLong으로_거절된다() {
        let long = String(repeating: "가", count: 501)
        assertIssue(.nameTooLong("originName"), F.journey(originName: long))
        assertIssue(.nameTooLong("destinationName"), F.journey(destinationName: long))
        assertIssue(.nameTooLong("busNumber"), F.journey(busNumber: long))
        assertIssue(.nameTooLong("busKind"), F.journey(busKind: long))
        XCTAssertNoThrow(try F.journey(originName: String(repeating: "가", count: 500)).validate(currentCardID: F.cardID))
    }

    // 깨짐: 카탈로그에 없는 id를 검증이 거절하면 실패(카탈로그 검사 없음).
    func testA1_카탈로그_밖_id도_구조가_맞으면_통과한다() {
        XCTAssertNoThrow(
            try F.journey(originStopID: "gone-stop", busID: "gone-bus", destinationStopID: "gone-dest")
                .validate(currentCardID: F.cardID)
        )
    }

    // 깨짐: minutes <= 0을 통과시키면 실패.
    func testA1_분이_0이하면_거절된다() {
        assertIssue(.invalidMinutes(0), F.journey(minutes: 0))
        assertIssue(.invalidMinutes(-5), F.journey(minutes: -5))
        XCTAssertNoThrow(try F.journey(minutes: 1).validate(currentCardID: F.cardID))
    }

    // 깨짐: 분 상한 360을 넘는 361을 통과시키거나 360을 거절하면 실패. (AC-20, BR-2)
    func testAC20_분이_361이면_거절되고_360은_허용된다() {
        assertIssue(.invalidMinutes(361), F.journey(minutes: 361))
        XCTAssertNoThrow(try F.journey(minutes: 360).validate(currentCardID: F.cardID))
    }

    // 깨짐: 할 일 trim 불일치·빈 값·UTF-16 80 초과 중 하나라도 통과시키면 실패.
    func testA1_할일이_공백포함_빈값_80초과면_거절된다() {
        assertIssue(.invalidTask, F.journey(task: " 책 읽기"))
        assertIssue(.invalidTask, F.journey(task: "책 읽기\n"))
        assertIssue(.invalidTask, F.journey(task: ""))
        assertIssue(.invalidTask, F.journey(task: String(repeating: "a", count: 81)))
        XCTAssertNoThrow(try F.journey(task: String(repeating: "a", count: 80)).validate(currentCardID: F.cardID))
    }

    // 깨짐: 태그 이름 빈값(공백)·20 초과를 통과시키면 실패.
    func testA1_태그이름이_공백뿐이거나_20초과면_거절된다() {
        func tag(_ name: String) -> JourneySnapshot.Tag {
            JourneySnapshot.Tag(id: "t", name: name, icon: .reading, color: .sand)
        }
        assertIssue(.invalidTag, F.journey(tag: tag("   ")))
        assertIssue(.invalidTag, F.journey(tag: tag(String(repeating: "a", count: 21))))
        XCTAssertNoThrow(try F.journey(tag: tag(String(repeating: "a", count: 20))).validate(currentCardID: F.cardID))
    }

    // 깨짐: 음수 elapsedSeconds를 통과시키면 실패.
    func testA1_진도가_음수면_거절된다() {
        assertIssue(.invalidProgress, F.journey(phase: .departed, elapsedSeconds: -1))
        XCTAssertNoThrow(try F.journey(phase: .departed, elapsedSeconds: 0).validate(currentCardID: F.cardID))
    }

    // 깨짐: awaitingDeparture에서 진도 != 0을 통과시키면 실패.
    func testAC19_출발확인_전에_진도가_0이_아니면_거절된다() {
        assertIssue(.invalidProgress, F.journey(phase: .awaitingDeparture, elapsedSeconds: 1))
    }

    // 깨짐: departed에서 진도 양수를 거절하면 실패(대기 상태에만 0 강제).
    func testAC19_출발확인_후에는_진도_양수가_허용된다() {
        XCTAssertNoThrow(try F.journey(phase: .departed, elapsedSeconds: 30).validate(currentCardID: F.cardID))
    }

    // 깨짐: cardID 불일치(다른 카드·카드 없음)를 통과시키면 실패.
    func testA1_카드가_다르거나_없으면_cardMismatch로_거절된다() {
        let journey = F.journey()
        XCTAssertThrowsError(try journey.validate(currentCardID: "FM-76543210")) {
            XCTAssertEqual($0 as? ActiveJourneyValidationIssue, .cardMismatch)
        }
        XCTAssertThrowsError(try journey.validate(currentCardID: nil)) {
            XCTAssertEqual($0 as? ActiveJourneyValidationIssue, .cardMismatch)
        }
    }

    // MARK: - 팩토리

    // 깨짐: 팩토리가 주입한 makeID를 쓰지 않거나 cardID·세부값을 넘기지 않으면 실패.
    func testFactory_주입한_ID로_대기상태_여정을_만든다() {
        let factory = ActiveJourneyFactory(makeID: { "fixed-id" }, now: { F.boardedAt })

        let journey = factory.make(details: F.details, cardID: F.cardID)

        XCTAssertEqual(journey.id, "fixed-id")
        XCTAssertEqual(journey.cardID, F.cardID)
        XCTAssertEqual(journey.phase, .awaitingDeparture)
        XCTAssertEqual(journey.minutes, 60)
    }

    // 깨짐: boardedAt을 초 단위로 내리지 않고 소수 초를 보존하거나 올림하면 실패.
    func testFactory_boardedAt은_초단위로_내림된다() {
        let factory = ActiveJourneyFactory(
            makeID: { "x" },
            now: { Date(timeIntervalSince1970: 1_791_882_000.999) }
        )

        XCTAssertEqual(factory.make(details: F.details, cardID: F.cardID).boardedAt.timeIntervalSince1970, 1_791_882_000)
    }

    // MARK: - helpers

    private func assertIssue(
        _ expected: ActiveJourneyValidationIssue,
        _ journey: JourneySnapshot,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try journey.validate(currentCardID: journey.cardID), file: file, line: line) {
            XCTAssertEqual($0 as? ActiveJourneyValidationIssue, expected, file: file, line: line)
        }
    }
}
