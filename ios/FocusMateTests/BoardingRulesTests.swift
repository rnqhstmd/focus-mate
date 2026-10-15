import CoreGraphics
import Foundation
import XCTest
@testable import FocusMate

final class BoardingRulesTests: XCTestCase {
    private let geometry = BoardingGeometry()
    private let tagArea = CGRect(x: 0, y: 0, width: 238, height: 160)

    /// 태그 영역과 폭이 같은 카드를 아래쪽 가장자리에서 `overlapHeight`만큼만 걸치게 둔다.
    private func card(overlapHeight: CGFloat) -> CGRect {
        CGRect(x: 0, y: 160 - overlapHeight, width: 238, height: 168)
    }

    private func restingCard(width: CGFloat) -> CGRect {
        CGRect(x: 119 - width / 2 + 7, y: 300, width: width, height: 168)
    }

    // MARK: AC-6/7/9, BR-7

    // 깨짐: 임계를 0.30에서 0.299 이하로 낮추면 29.9% 케이스가 접촉으로 판정되어 실패
    func testAC6_겹침_29_9퍼센트는_접촉이_아니다() {
        let c = card(overlapHeight: 47.84) // 238*47.84 / 38080 = 0.299
        XCTAssertEqual(geometry.overlapRatio(card: c, tagArea: tagArea), 0.299, accuracy: 0.0005)
        XCTAssertFalse(geometry.isContact(card: c, tagArea: tagArea))
    }

    // 깨짐: 비교를 > 로 바꾸면(경계 제외) 정확히 30%에서 실패
    func testAC6_겹침_정확히_30퍼센트는_접촉이다() {
        let c = card(overlapHeight: 48) // 238*48 = 11424 = 38080 * 0.30
        XCTAssertEqual(geometry.overlapRatio(card: c, tagArea: tagArea), 0.30, accuracy: 0.0001)
        XCTAssertTrue(geometry.isContact(card: c, tagArea: tagArea))
    }

    // 깨짐: 임계를 0.301 이상으로 올리면 실패
    func testAC6_겹침_30_1퍼센트는_접촉이다() {
        let c = card(overlapHeight: 48.16) // 0.301
        XCTAssertTrue(geometry.isContact(card: c, tagArea: tagArea))
    }

    // 깨짐: 분모를 카드 면적으로 바꾸면(268x168 카드는 0.30 이하가 됨) 실패 (BR-7)
    func testBR7_겹침_비율은_태그_영역_면적을_분모로_한다() {
        let wide = CGRect(x: -15, y: 80, width: 268, height: 168) // 교집합 238x80 = 19040
        XCTAssertEqual(geometry.overlapRatio(card: wide, tagArea: tagArea), 0.5, accuracy: 0.0001)
    }

    // 깨짐: 교집합이 없을 때 음수나 NaN을 돌려주면 실패
    func testAC6_겹치지_않으면_비율은_0이다() {
        let far = CGRect(x: 0, y: 400, width: 238, height: 168)
        XCTAssertEqual(geometry.overlapRatio(card: far, tagArea: tagArea), 0, accuracy: 0.0001)
    }

    // 깨짐: 탭 한계를 <= 로 바꾸면 8.0에서 실패, 한계를 8보다 크게 하면 8.0에서 실패
    func testAC9_이동_8_0은_탭이_아니다() {
        XCTAssertFalse(geometry.isTap(CGSize(width: 8.0, height: 0)))
    }

    // 깨짐: 한계를 8 미만으로 줄이면 7.9에서 실패
    func testAC9_이동_7_9는_탭이다() {
        XCTAssertTrue(geometry.isTap(CGSize(width: 7.9, height: 0)))
    }

    // 깨짐: 거리를 x 성분만으로 재면 (6,6) 이동(거리 8.49)이 탭으로 판정되어 실패
    func testAC9_대각선_이동은_거리로_판정한다() {
        XCTAssertFalse(geometry.isTap(CGSize(width: 6, height: 6)))
    }

    // MARK: AC-8 (주 검증)

    private var rest: CGRect { restingCard(width: 268).offsetBy(dx: 0, dy: 0) }

    // 깨짐: 좌우 한계를 제거하거나 26이 아닌 값으로 바꾸면 실패
    func testAC8_오른쪽으로_100_끌면_26으로_제한된다() {
        let r = geometry.clampedOffset(CGSize(width: 100, height: 0), cardRest: rest, tagArea: tagArea)
        XCTAssertEqual(r.width, 26, accuracy: 0.001)
    }

    // 깨짐: 왼쪽 한계를 비대칭으로 두면 실패
    func testAC8_왼쪽으로_100_끌면_마이너스_26으로_제한된다() {
        let r = geometry.clampedOffset(CGSize(width: -100, height: 0), cardRest: rest, tagArea: tagArea)
        XCTAssertEqual(r.width, -26, accuracy: 0.001)
    }

    // 깨짐: 위쪽 한계를 tagArea.minY - cardRest.minY 대신 0이나 고정값으로 두면 실패 (300 - 0 = -300)
    func testAC8_위로_넘치게_끌면_카드_위쪽이_태그_위쪽에_멈춘다() {
        let r = geometry.clampedOffset(CGSize(width: 0, height: -900), cardRest: rest, tagArea: tagArea)
        XCTAssertEqual(r.height, -300, accuracy: 0.001)
    }

    // 깨짐: 아래 한계를 제거하거나 20이 아닌 값으로 바꾸면 실패
    func testAC8_아래로_100_끌면_20으로_제한된다() {
        let r = geometry.clampedOffset(CGSize(width: 0, height: 100), cardRest: rest, tagArea: tagArea)
        XCTAssertEqual(r.height, 20, accuracy: 0.001)
    }

    // 깨짐: 범위 안 값까지 자르거나 x/y를 뒤바꾸면 실패
    func testAC8_범위_안의_이동은_그대로_둔다() {
        let r = geometry.clampedOffset(CGSize(width: 10, height: -50), cardRest: rest, tagArea: tagArea)
        XCTAssertEqual(r.width, 10, accuracy: 0.001)
        XCTAssertEqual(r.height, -50, accuracy: 0.001)
    }

    // MARK: AC-10

    private func assertActivation(width: CGFloat, file: StaticString = #filePath, line: UInt = #line) {
        let rest = restingCard(width: width)
        let offset = geometry.activationOffset(cardRest: rest, tagArea: tagArea)
        let moved = rest.offsetBy(dx: offset.width, dy: offset.height)
        XCTAssertTrue(geometry.isContact(card: moved, tagArea: tagArea), "폭 \(width)", file: file, line: line)
        XCTAssertGreaterThanOrEqual(moved.minY, tagArea.minY, file: file, line: line)
        XCTAssertLessThanOrEqual(moved.minY, tagArea.maxY, file: file, line: line)
        XCTAssertEqual(moved.midX, tagArea.midX, accuracy: 0.001, file: file, line: line)
    }

    // 깨짐: 활성 위치가 마진 없이 정확히 30%에 못 미치거나 카드 폭 의존을 무시하면 실패
    func testAC10_활성_위치는_카드_폭_268에서_접촉_임계_이상이다() { assertActivation(width: 268) }

    // 깨짐: min(카드폭, 태그폭) 대신 카드폭만 쓰면 238 이하 카드에서 실패
    func testAC10_활성_위치는_카드_폭_238에서_접촉_임계_이상이다() { assertActivation(width: 238) }

    // 깨짐: 분모를 태그 폭으로 고정하지 않고 카드 폭으로 쓰면 300에서 겹침 부족 또는 과다로 실패
    func testAC10_활성_위치는_카드_폭_300에서_접촉_임계_이상이다() { assertActivation(width: 300) }

    // 깨짐: 카드 위쪽을 tagArea.maxY - h 대신 다른 기준에 두면 실패 (h = 48 + 8 = 56 → 104)
    func testAC10_활성_위치의_카드_위쪽은_태그_아래_가장자리에서_56만큼_위다() {
        let rest = restingCard(width: 238)
        let offset = geometry.activationOffset(cardRest: rest, tagArea: tagArea)
        XCTAssertEqual(rest.minY + offset.height, 104, accuracy: 0.001)
    }

    // MARK: AC-22

    // 깨짐: reduceMotion을 무시하면 실패
    func testAC22_동작_줄이기면_접촉_지연은_0이다() {
        XCTAssertEqual(BoardingTiming.standard.contact(reduceMotion: true), .zero)
    }

    // 깨짐: 기본 접촉 시간을 300ms 이외로 바꾸면 실패
    func testAC22_동작_줄이기가_아니면_접촉_지연은_300ms다() {
        XCTAssertEqual(BoardingTiming.standard.contact(reduceMotion: false), .milliseconds(300))
    }

    // 깨짐: fade에서 reduceMotion을 무시하면 실패
    func testAC22_동작_줄이기면_페이드는_0이다() {
        XCTAssertEqual(BoardingTiming.standard.fade(reduceMotion: true), .zero)
    }

    // 깨짐: 기본 fade를 450ms 이외로 바꾸면 실패
    func testAC22_동작_줄이기가_아니면_페이드는_450ms다() {
        XCTAssertEqual(BoardingTiming.standard.fade(reduceMotion: false), .milliseconds(450))
    }

    // 깨짐: 동작 줄이기에서 hold까지 0으로 만들면 실패
    func testAC22_유지_시간은_동작_줄이기와_무관하게_1400ms다() {
        XCTAssertEqual(BoardingTiming.standard.hold, .milliseconds(1400))
    }

    // MARK: AC-5

    // 깨짐: 타임존을 무시하고 .current/UTC를 쓰면 Asia/Seoul 케이스에서 실패
    func testAC5_UTC에서는_0900으로_표기한다() {
        let text = BoardingClock.text(for: Date(timeIntervalSince1970: 1_791_882_000), timeZone: TimeZone(identifier: "UTC")!)
        XCTAssertEqual(text, "09:00")
    }

    // 깨짐: 타임존 적용을 빼면 실패
    func testAC5_서울에서는_1800으로_표기한다() {
        let text = BoardingClock.text(for: Date(timeIntervalSince1970: 1_791_882_000), timeZone: TimeZone(identifier: "Asia/Seoul")!)
        XCTAssertEqual(text, "18:00")
    }

    // 깨짐: hh(12시간제)나 앞자리 0 생략을 쓰면 실패 (UTC 15:05)
    func testAC5_24시간제로_앞자리_0을_채운다() {
        let text = BoardingClock.text(for: Date(timeIntervalSince1970: 1_791_882_000 + 6 * 3600 + 5 * 60), timeZone: TimeZone(identifier: "UTC")!)
        XCTAssertEqual(text, "15:05")
    }
}
