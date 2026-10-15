import Foundation
import XCTest

/// W07 메인 이어가기/도착 카드와 이어가기 저장 실패 (AC-1, AC-24 카드, AC-25, AC-35 메인).
/// 현재 정류장·카드 내용을 단언하므로 life* 시드만 쓴다(AC-25 손상 시드 예외).
/// 이어가기 성공 후 타이머 동작(AC-3·4)은 JourneyResumeUITests(T5) 범위다.
@MainActor
final class MainActiveJourneyCardUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let tempNotice = "여행 시작하기를 누르면 이 여정은 기록 없이 정리돼요."
    private let saveFailureText = "저장하지 못했어요. 다시 눌러주세요."

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func startButton(_ h: FocusMateUIHarness) -> XCUIElement {
        let button = h.app.buttons["open.preparation"]
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "open.preparation 없음")
        return button
    }

    // MARK: AC-1

    // 깨짐: 카드가 제목·남은 시간·버스·도착지 중 하나라도 빠뜨리거나 임시 안내가 그대로 남는다.
    func testAC1_일시정지_여정은_이어가기_카드로_보인다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))

        let card = h.element("main.activeJourney")
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        for part in ["잠시 멈춘 여정이 있어요.", "24 min 남음", "지선 2014", "서울숲 입구까지"] {
            XCTAssertTrue(card.label.contains(part), "카드 label에 '\(part)' 없음: \(card.label)")
        }
    }

    // 깨짐: 이어가기 버튼 id·라벨이 바뀌거나 카드와 한 요소로 합쳐져 별도 버튼이 아니게 된다.
    func testAC1_이어가기는_카드와_별도의_버튼이다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        let resume = h.app.buttons["main.resumeJourney"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout))
        XCTAssertEqual(resume.label, "이전 여정 이어가기")
        XCTAssertTrue(resume.isHittable)
    }

    // 깨짐: 진행 여정이 있는데 시작 버튼이 여전히 "여행 시작하기"다.
    func testAC1_진행_여정이_있으면_시작_버튼_문구는_새_여정_시작이다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        XCTAssertEqual(startButton(h).label, "새 여정 시작")
    }

    // 깨짐: 옛 임시 안내가 카드와 함께 남는다.
    func testAC1_임시_안내_문구는_더_이상_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.app.staticTexts[tempNotice].exists)
        XCTAssertFalse(h.element("main.activeJourney").label.contains(tempNotice))
    }

    // 깨짐: 카드가 저장된 할 일 또는 태그 경로를 빠뜨린다.
    func testAC1_카드는_저장된_할_일과_태그_경로를_보인다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        let card = h.element("main.activeJourney")
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        for part in ["생명주기 시드", "독서 · 서울숲 입구까지"] {
            XCTAssertTrue(card.label.contains(part), "카드 label에 '\(part)' 없음: \(card.label)")
        }
    }

    // 깨짐: 이어가기 버튼 낭독 라벨이 화살표를 읽거나 "이전 여정 이어가기"가 아니게 되고, 버튼이 누를 수 없거나 44pt 미만이 된다.
    // 보이는 문구 "이전 여정 이어가기 →"의 화살표는 XCUITest로 관측 불가(AC-32로 라벨을 덮어씀) — 코드 리뷰·W14 실기기 시각 점검으로 넘긴다.
    func testAC1_이어가기_버튼_낭독_라벨은_화살표가_없고_누를_수_있다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        let resume = h.app.buttons["main.resumeJourney"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout))
        XCTAssertEqual(resume.label, "이전 여정 이어가기")
        XCTAssertFalse(resume.label.contains("→"))
        XCTAssertTrue(resume.isHittable)
        XCTAssertGreaterThanOrEqual(resume.frame.height, 44)
    }

    // MARK: AC-24 (카드)

    // 깨짐: 도착 여정이 이어갈 수 있는 카드로 보이거나 이어가기 버튼이 노출된다.
    func testAC24_도착_여정은_도착_카드이고_이어가기_버튼이_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifeArrived")
        let card = h.element("main.activeJourney")
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        XCTAssertTrue(card.label.contains("도착한 여정이 있어요"), card.label)
        XCTAssertFalse(h.element("main.resumeJourney").exists)
        XCTAssertTrue(h.app.buttons["open.alighting"].exists)
    }

    // 깨짐: 도착 여정 카드에 하차하기가 없거나 새 여정 시작 경로(open.preparation)·"새 여정 시작"이 남는다.
    func testAC24_도착_여정은_하차하기만_있고_새_여정_시작_경로가_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifeArrived")
        let alight = h.app.buttons["open.alighting"]
        XCTAssertTrue(alight.waitForExistence(timeout: timeout))
        XCTAssertEqual(alight.label, "하차하기")
        XCTAssertFalse(h.element("open.preparation").exists)
        XCTAssertFalse(h.app.buttons["새 여정 시작"].exists)
    }

    // MARK: AC-25

    // 깨짐: 손상 여정(분 361)이 카드로 되살아나거나 시작 버튼이 "새 여정 시작"이 된다.
    func testAC25_손상_여정은_카드도_새_여정_문구도_없다() throws {
        let h = FocusMateUIHarness.launch(
            seed: "v3InvalidMinutes", extraArguments: FocusMateUIHarness.manualClockArguments
        )
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("main.activeJourney").exists)
        XCTAssertEqual(startButton(h).label, "여행 시작하기")
        XCTAssertGreaterThan(try h.cardCount(), 0)
    }

    // 깨짐: 웹식 "불러오지 못했어요" 안내나 옛 임시 안내가 손상 여정에 나온다.
    func testAC25_손상_여정에_불러오기_실패_문구가_없다() throws {
        let h = FocusMateUIHarness.launch(
            seed: "v3InvalidMinutes", extraArguments: FocusMateUIHarness.manualClockArguments
        )
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.app.staticTexts["이전 여정을 불러오지 못했어요."].exists)
        XCTAssertFalse(h.app.staticTexts[tempNotice].exists)
    }

    // 깨짐: 손상 여정을 버리면서 완료 기록을 지우거나 현재 정류장 표시가 저장값과 어긋난다.
    func testAC25_손상_여정_버림은_기록_수와_현재_정류장을_바꾸지_않는다() throws {
        let h = FocusMateUIHarness.launch(
            seed: "v3InvalidMinutes", extraArguments: FocusMateUIHarness.manualClockArguments
        )
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        let station = h.element("main.currentStation")
        XCTAssertTrue(station.waitForExistence(timeout: timeout))
        let recordsAtStart = try h.persistedRecordCount()
        let persisted = try h.persistedCurrentStation()
        let shown = station.value as? String

        XCTAssertNotNil(persisted.id)
        XCTAssertNotEqual(shown ?? "", "", "main.currentStation value 비어 있음")
        XCTAssertFalse(h.element("main.activeJourney").exists)
        XCTAssertEqual(try h.persistedRecordCount(), recordsAtStart)
        XCTAssertEqual(try h.persistedCurrentStation().id, persisted.id)
        XCTAssertEqual(station.value as? String, shown)
    }

    // MARK: AC-35 (메인 부분)

    // 깨짐: 저장 실패인데 여행 화면으로 이동하거나 실패 안내가 메인에 없다.
    func testAC35_이어가기_저장_실패는_메인에_머물고_실패_안내를_보인다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))

        h.failNextMainSave {
            h.app.buttons["main.resumeJourney"].tap()
        }

        let failure = h.element("main.saveFailure")
        XCTAssertTrue(failure.waitForExistence(timeout: timeout))
        XCTAssertEqual(failure.label, saveFailureText)
        XCTAssertFalse(h.element("screen.journey").waitForExistence(timeout: 1))
        XCTAssertTrue(h.element("screen.main").exists)
        XCTAssertTrue(h.element("main.activeJourney").exists)
    }

    // 깨짐: 실패한 시도가 저장값(경과 90, paused=true)을 바꾸거나 시도 수가 1이 아니다(예약 소비 증명).
    func testAC35_이어가기_저장_실패는_저장값을_바꾸지_않고_시도는_정확히_1회다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let before = try h.writeAttempts()

        h.failNextMainSave {
            h.app.buttons["main.resumeJourney"].tap()
        }
        XCTAssertTrue(h.element("main.saveFailure").waitForExistence(timeout: timeout))

        XCTAssertEqual(try h.writeAttempts(), before + 1)
        XCTAssertEqual(try h.persistedElapsed(), 90)
        XCTAssertEqual(try h.persistedPaused(), true)
    }

    // 깨짐: 실패했는데 "이어갑니다" 낭독이 나간다.
    func testAC35_이어가기_저장_실패에는_이어가기_낭독이_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))

        h.failNextMainSave {
            h.app.buttons["main.resumeJourney"].tap()
        }
        XCTAssertTrue(h.element("main.saveFailure").waitForExistence(timeout: timeout))

        XCTAssertFalse(try h.diagnostic("test.announcements").contains("이전 여정을 남은 시간부터 이어갑니다."))
    }
}
