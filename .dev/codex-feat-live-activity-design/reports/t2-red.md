# W17 T2 RED 1차 — 기존 표시 API

Status: DONE_WITH_CONCERNS. 테스트 작성 완료. 실행 증거 없음.

## 실행 및 실패 예상
사용자 지시로 테스트/빌드/시뮬레이터/브라우저를 실행하지 않았다. 실패 메시지·컴파일 결과는 미확보다. 부모가 focused를 직접 실행한다.
```sh
python3 scripts/check-ios.py test ios/FocusMateTests/JourneyActivityDisplayTests.swift
```
예상 assertion RED **5건**: 기존 paused accessibilityLabel 계약 수정2건 + 신규 missing-end displayStatus/accessibilityLabel2건 + 신규 긴 한글 paused summary1건.
신규 테스트 함수6건과 기존 계약 갱신3건(Mirror1·paused label2)을 작성했다. 나머지 기존 테스트는 유지했다.
신규 presentation/remainingSeconds/progressFraction/accessibilitySummary API를 호출하지 않으므로, 부재한 API의 컴파일 오류를 RED로 사용하지 않는다. 총시간 프로퍼티도 직접 참조하지 않는다.

## RED 케이스
- testW17_위젯_일시정지_summary는_별도시간을_중복하지_않는다: summary의 시간 중복 제거(승인된 expected 갱신).
- testW17_stale이어도_일시정지_summary는_상태만_한번_제공한다: stale paused도 상태 유지·시간 중복 제거(승인된 expected 갱신).
- testW17_종료시각없는_running의_표시상태는_도착이다: missing-end 상태 정규화.
- testW17_종료시각없는_running의_접근성은_도착이다: missing-end 낭독 정규화.
- testW17_일시정지_summary는_긴한글이름_전체와_상태만_보존한다: 전체 노선·종류·목적지 보존 및 별도 시간 소유.
각 본문 앞 깨짐 주석을 작성했고 독립 문자열·고정 Date 기대값을 사용했다. 모의·sleep·스타일/위치 assertion 없음.

## 별도 호환 케이스 — RED 수 제외
1. 승인된 T1 계약 반영: 표시 데이터 exact7→8, 허용 필드는 기존7개+totalSeconds뿐. 민감 카드·태그·할 일 필드 금지 유지. T1 완료 후 통과 예상.
2. 정상 running의 긴 한글 노선·종류·목적지 전체 유지. 통과 예상.
3. pausedTime의5/599/5999/7200/21600초→0:05/9:59/99:59/120:00/360:00. 테이블1건,5입력. 통과 예상.
4. stale paused timeContent의 동일5입력 fixed 시간 보존. 테이블1건,5입력. 통과 예상.
legacy accessibilityDescription 유닛은 그대로 유지했다. timeContent의 existing missing-end 만료 문구, stale/arrived/paused 우선순위, countdown 회귀도 유지했다.

## 다음 단계와 증거 한계
부모가 기존 API focused assertion RED 확인 후 표시 타입을 추가하면, T2 2차에서 새 presentation/remaining/progress API의 AC1~5 RED를 별도로 추가한다. 이번 잠금 대상 테스트를 그 과정에서 변경하지 않는다.
이 단위 테스트는 실제 네 표면 렌더·장시간 가독성·VoiceOver 단일 낭독·Reduce Motion 장치 검증을 대신하지 않는다.

## 참조한 파일 전체
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-dev/references/codex-roles/red-writer.md (같은 에이전트의 T1에서 읽은 역할 계약 재사용)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md (T1에서 읽은 규칙 재사용)
- .dev/codex-feat-live-activity-design/prd.md
- .dev/codex-feat-live-activity-design/design.md
- ios/FocusMateTests/JourneyActivityDisplayTests.swift
생산 소스 읽기·쓰기 없음. 이번 수정은 위 테스트1개와 이 보고서뿐이다.

## 테스트 전문
```swift
import Foundation
import XCTest
@testable import FocusMate

/// 라이브 액티비티 한국어 문구(AC-26)와 표시 데이터 최소화(AC-30). 기댓값은 PRD가 정한 리터럴이다.
final class JourneyActivityDisplayTests: XCTestCase {
    private func accessibilityText(
        status: JourneyActivityStatus, paused: Int? = nil
    ) -> String {
        JourneyActivityDisplay.accessibilityDescription(
            busNumber: "343", busKind: "간선", destination: "서울역",
            status: status, pausedRemainingSeconds: paused
        )
    }

    // 깨짐: 상태 이름 문구가 바뀌거나 case가 서로 뒤바뀌면 실패한다.
    func testV15_AC26_세_상태의_이름이_정해진_문구다() {
        XCTAssertEqual(JourneyActivityDisplay.statusName(.running), "운행 중")
        XCTAssertEqual(JourneyActivityDisplay.statusName(.paused), "일시정지")
        XCTAssertEqual(JourneyActivityDisplay.statusName(.arrived), "도착")
    }

    // 깨짐: 만료 안내 문구가 "도착했어요"와 달라지면 실패한다.
    func testV15_AC26_만료_안내_문구는_도착했어요다() {
        XCTAssertEqual(JourneyActivityDisplay.expiredText, "도착했어요")
    }

    // 깨짐: 분:초 계산·0 패딩이 틀리면(3000, 65, 0, 3600) 실패한다.
    func testV15_AC26_일시정지_시간은_분_콜론_초_형식이다() {
        XCTAssertEqual(JourneyActivityDisplay.pausedTime(seconds: 3000), "50:00")
        XCTAssertEqual(JourneyActivityDisplay.pausedTime(seconds: 65), "1:05")
        XCTAssertEqual(JourneyActivityDisplay.pausedTime(seconds: 0), "0:00")
        XCTAssertEqual(JourneyActivityDisplay.pausedTime(seconds: 3600), "60:00")
    }

    // 깨짐: 음수를 0으로 보정하지 않으면 "-1:-5" 등이 나와 실패한다.
    func testV15_AC26_음수_초는_0으로_표기한다() {
        XCTAssertEqual(JourneyActivityDisplay.pausedTime(seconds: -5), "0:00")
    }

    // 깨짐: 번호·종류·도착지·상태 조합 문구 형식이 바뀌면 실패한다.
    func testV15_AC26_운행_중_접근성_설명() {
        XCTAssertEqual(accessibilityText(status: .running), "343번 간선 버스, 도착지 서울역, 운행 중")
    }

    // 깨짐: 남은 시간을 "분 초"로 풀어쓰지 않거나 3000초를 50분 0초로 계산하지 못하면 실패한다.
    func testV15_AC26_일시정지_3000초_접근성_설명() {
        XCTAssertEqual(
            accessibilityText(status: .paused, paused: 3000),
            "343번 간선 버스, 도착지 서울역, 일시정지, 남은 시간 50분 0초"
        )
    }

    // 깨짐: 65초를 1분 5초가 아닌 형식(예: 01분 05초, 65초)으로 쓰면 실패한다.
    func testV15_AC26_일시정지_65초_접근성_설명() {
        XCTAssertEqual(
            accessibilityText(status: .paused, paused: 65),
            "343번 간선 버스, 도착지 서울역, 일시정지, 남은 시간 1분 5초"
        )
    }

    // 깨짐: 도착 상태에도 남은 시간 문구를 붙이면 실패한다.
    func testV15_AC26_도착_접근성_설명() {
        XCTAssertEqual(accessibilityText(status: .arrived), "343번 간선 버스, 도착지 서울역, 도착")
    }

    // 깨짐: 승인된 totalSeconds 외에 카드·할 일·태그 등 민감 정보를 표시 데이터에 추가한다.
    func testW17_AC30_표시_데이터는_총시간만_추가한_8필드로_제한한다() {
        let attributes = JourneyActivityAttributes(
            journeyID: "j-1", busNumber: "343", busKind: "간선", destinationName: "서울역"
        )
        let state = JourneyActivityAttributes.ContentState(
            status: .running, endDate: nil, pausedRemainingSeconds: nil
        )
        let labels = Set(Mirror(reflecting: attributes).children.compactMap(\.label))
            .union(Mirror(reflecting: state).children.compactMap(\.label))
        XCTAssertEqual(
            labels,
            ["journeyID", "busNumber", "busKind", "destinationName",
             "status", "endDate", "pausedRemainingSeconds", "totalSeconds"]
        )
    }

    // MARK: - T8 위젯 시간 콘텐츠 / 접근성 라벨

    private let widgetNow = Date(timeIntervalSince1970: 1_791_882_000)

    private func widgetState(
        _ status: JourneyActivityStatus, endDate: Date? = nil, paused: Int? = nil
    ) -> JourneyActivityAttributes.ContentState {
        JourneyActivityAttributes.ContentState(
            status: status, endDate: endDate, pausedRemainingSeconds: paused
        )
    }

    private var widgetAttributes: JourneyActivityAttributes {
        JourneyActivityAttributes(
            journeyID: "j-1", busNumber: "343", busKind: "간선", destinationName: "서울역"
        )
    }

    // 깨짐: 일시정지에서 남은 초를 "M:SS"로 고정 표기하지 않으면 실패한다.
    func testV15_위젯_일시정지는_고정_분초_문자열이다() {
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.paused, paused: 3000), isStale: false, now: widgetNow
        )
        XCTAssertEqual(content, .fixed("50:00"))
    }

    // 깨짐: stale을 paused보다 먼저 검사해 만료 문구를 내면 실패한다.
    func testV15_위젯_stale이어도_일시정지가_우선한다() {
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.paused, paused: 3000), isStale: true, now: widgetNow
        )
        XCTAssertEqual(content, .fixed("50:00"))
    }

    // 깨짐: stale 운행을 카운트다운으로 두면 실패한다.
    func testV15_위젯_stale_운행은_만료_문구다() {
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.running, endDate: widgetNow.addingTimeInterval(3000)),
            isStale: true, now: widgetNow
        )
        XCTAssertEqual(content, .fixed("도착했어요"))
    }

    // 깨짐: arrived인데 카운트다운을 내면 실패한다.
    func testV15_위젯_도착_상태는_만료_문구다() {
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.arrived), isStale: false, now: widgetNow
        )
        XCTAssertEqual(content, .fixed("도착했어요"))
    }

    // 깨짐: 범위 시작을 now가 아닌 값으로 잡거나 endDate를 틀리게 쓰면 실패한다.
    func testV15_위젯_운행_중은_지금부터_종료까지_카운트다운이다() {
        let end = widgetNow.addingTimeInterval(3000)
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.running, endDate: end), isStale: false, now: widgetNow
        )
        XCTAssertEqual(content, .countdown(widgetNow...end))
    }

    // 깨짐: now > endDate로 ClosedRange를 만들어 트랩하거나 범위를 보정하지 않으면 실패한다.
    func testV15_위젯_종료시각이_과거여도_트랩_없이_종료시각_범위다() {
        let end = widgetNow.addingTimeInterval(-10)
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.running, endDate: end), isStale: false, now: widgetNow
        )
        XCTAssertEqual(content, .countdown(end...end))
    }

    // 깨짐: endDate가 없을 때 카운트다운을 만들려 하거나 빈 문자열을 내면 실패한다.
    func testV15_위젯_운행_중인데_종료시각이_없으면_만료_문구다() {
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.running), isStale: false, now: widgetNow
        )
        XCTAssertEqual(content, .fixed("도착했어요"))
    }

    // 깨짐: 일시정지 summary가 시간 요소와 별개로 남은 시간을 합성하여 중복 낭독한다.
    func testW17_위젯_일시정지_summary는_별도시간을_중복하지_않는다() {
        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: widgetAttributes, state: widgetState(.paused, paused: 3000), isStale: false
        )
        XCTAssertEqual(label, "343번 간선 버스, 도착지 서울역, 일시정지")
    }

    // 깨짐: stale이 일시정지 summary를 도착으로 덮거나 남은 시간을 중복 합성한다.
    func testW17_stale이어도_일시정지_summary는_상태만_한번_제공한다() {
        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: widgetAttributes, state: widgetState(.paused, paused: 3000), isStale: true
        )
        XCTAssertEqual(label, "343번 간선 버스, 도착지 서울역, 일시정지")
    }

    // 깨짐: stale 운행이 "운행 중"으로 읽히면 실패한다.
    func testV15_위젯_stale_접근성_라벨은_도착이다() {
        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: widgetAttributes,
            state: widgetState(.running, endDate: widgetNow.addingTimeInterval(3000)),
            isStale: true
        )
        XCTAssertEqual(label, "343번 간선 버스, 도착지 서울역, 도착")
    }

    // 깨짐: arrived가 "도착"으로 읽히지 않으면 실패한다.
    func testV15_위젯_도착_상태_접근성_라벨은_도착이다() {
        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: widgetAttributes, state: widgetState(.arrived), isStale: false
        )
        XCTAssertEqual(label, "343번 간선 버스, 도착지 서울역, 도착")
    }

    // 깨짐: 정상 운행 라벨이 "운행 중"이 아니면 실패한다.
    func testV15_위젯_운행_중_접근성_라벨은_운행_중이다() {
        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: widgetAttributes,
            state: widgetState(.running, endDate: widgetNow.addingTimeInterval(3000)),
            isStale: false
        )
        XCTAssertEqual(label, "343번 간선 버스, 도착지 서울역, 운행 중")
    }

    // MARK: - 리뷰 fix R1: 위젯 리터럴을 순수 함수로 이동

    // 깨짐: 번호와 종류 순서·구분 공백이 바뀌면 실패한다.
    func testV15_위젯_카드_제목은_번호_공백_종류다() {
        XCTAssertEqual(JourneyActivityDisplay.busTitle(busNumber: "343", busKind: "간선"), "343 간선")
    }

    // 깨짐: "번 버스" 접미 문구가 바뀌면 실패한다.
    func testV15_위젯_축약_접근성_라벨은_번호번_버스다() {
        XCTAssertEqual(JourneyActivityDisplay.compactAccessibilityLabel(busNumber: "343"), "343번 버스")
    }

    // 깨짐: stale 운행을 운행 중으로 두면 실패한다.
    func testV15_위젯_stale_운행의_표시_상태는_도착이다() {
        let status = JourneyActivityDisplay.displayStatus(
            state: widgetState(.running, endDate: widgetNow.addingTimeInterval(3000)), isStale: true
        )
        XCTAssertEqual(status, .arrived)
    }

    // 깨짐: 정상 운행을 도착으로 바꾸면 실패한다.
    func testV15_위젯_정상_운행의_표시_상태는_운행_중이다() {
        let status = JourneyActivityDisplay.displayStatus(
            state: widgetState(.running, endDate: widgetNow.addingTimeInterval(3000)), isStale: false
        )
        XCTAssertEqual(status, .running)
    }

    // 깨짐: stale이 일시정지를 덮어쓰면 실패한다.
    func testV15_위젯_stale_일시정지의_표시_상태는_일시정지다() {
        let status = JourneyActivityDisplay.displayStatus(
            state: widgetState(.paused, paused: 3000), isStale: true
        )
        XCTAssertEqual(status, .paused)
    }

    // 깨짐: 일시정지를 다른 상태로 바꾸면 실패한다.
    func testV15_위젯_정상_일시정지의_표시_상태는_일시정지다() {
        let status = JourneyActivityDisplay.displayStatus(
            state: widgetState(.paused, paused: 3000), isStale: false
        )
        XCTAssertEqual(status, .paused)
    }

    // 깨짐: 도착 상태를 그대로 두지 않으면 실패한다.
    func testV15_위젯_도착_상태의_표시_상태는_도착이다() {
        let status = JourneyActivityDisplay.displayStatus(state: widgetState(.arrived), isStale: false)
        XCTAssertEqual(status, .arrived)
    }
    // MARK: W17 T2 1차 — 기존 공개 API의 정규화·단일 시간 소유

    // 깨짐: 종료시각 없는 running을 운행 중 심볼 상태로 남겨 만료 시간과 모순시킨다.
    func testW17_종료시각없는_running의_표시상태는_도착이다() {
        let status = JourneyActivityDisplay.displayStatus(
            state: widgetState(.running), isStale: false
        )

        XCTAssertEqual(status, .arrived)
    }

    // 깨짐: 종료시각 없는 running을 접근성에서 운행 중으로 설명한다.
    func testW17_종료시각없는_running의_접근성은_도착이다() {
        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: widgetAttributes, state: widgetState(.running), isStale: false
        )

        XCTAssertEqual(label, "343번 간선 버스, 도착지 서울역, 도착")
    }

    // 깨짐: 긴 이름을 축약하거나, 일시정지 summary에 18:42를 다시 합성한다.
    func testW17_일시정지_summary는_긴한글이름_전체와_상태만_보존한다() {
        let attributes = JourneyActivityAttributes(
            journeyID: "long-journey", busNumber: "서울도심순환심야광역급행12345",
            busKind: "심야광역급행", destinationName: "서울특별시성동구성수동복합문화체육센터정문앞"
        )

        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: attributes, state: widgetState(.paused, paused: 1122), isStale: false
        )

        XCTAssertEqual(label, "서울도심순환심야광역급행12345번 심야광역급행 버스, 도착지 서울특별시성동구성수동복합문화체육센터정문앞, 일시정지")
    }

    // 호환 회귀. 깨짐: 정상 running의 긴 노선·목적지를 접근성에서도 축약한다.
    func testW17_호환_running_접근성은_긴한글이름을_축약하지_않는다() {
        let attributes = JourneyActivityAttributes(
            journeyID: "long-journey", busNumber: "서울도심순환심야광역급행12345",
            busKind: "심야광역급행", destinationName: "서울특별시성동구성수동복합문화체육센터정문앞"
        )

        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: attributes,
            state: widgetState(.running, endDate: Date(timeIntervalSince1970: 1_791_883_122)),
            isStale: false
        )

        XCTAssertEqual(label, "서울도심순환심야광역급행12345번 심야광역급행 버스, 도착지 서울특별시성동구성수동복합문화체육센터정문앞, 운행 중")
    }

    // 호환 회귀. 깨짐: 장시간을 시 단위로 바꾸거나 분·초 경계의 0패딩을 잃는다.
    func testW17_호환_정지시간은_5초부터360분까지_분초를_유지한다() {
        let examples: [(Int, String)] = [
            (5, "0:05"), (599, "9:59"), (5999, "99:59"),
            (7200, "120:00"), (21600, "360:00")
        ]

        for (seconds, expected) in examples {
            XCTAssertEqual(JourneyActivityDisplay.pausedTime(seconds: seconds), expected)
        }
    }

    // 호환 회귀. 깨짐: stale 입력에서 정지 고정 시간을 도착 문구·countdown으로 바꾼다.
    func testW17_호환_stale정지도_모든길이의_고정시간을_유지한다() {
        let examples: [(Int, String)] = [
            (5, "0:05"), (599, "9:59"), (5999, "99:59"),
            (7200, "120:00"), (21600, "360:00")
        ]

        for (seconds, expected) in examples {
            let content = JourneyActivityDisplay.timeContent(
                state: widgetState(.paused, paused: seconds), isStale: true, now: widgetNow
            )
            XCTAssertEqual(content, .fixed(expected))
        }
    }

}

```

## 부모 직접 실행
T2 1차 focused94건 중 assertion5실패,89통과. 컴파일오류0. t2-red-run.log, exit65.


# 2차 RED — 새 Presentation/Progress 인터페이스

Status: DONE_WITH_CONCERNS. 신규 테스트 작성 완료, 실행 증거 없음.

## 실행 상태와 예상 결과
부모가 새 타입·시그니처와 최소 몸체를 추가했다고 전달한 뒤 작성했다. 생산 소스는 읽지 않았다. 테스트·빌드·시뮬레이터·브라우저 실행 없음. 실제 컴파일/실패 메시지 미확보.
기존 잠긴 JourneyActivityDisplayTests.swift와 T1 테스트는 읽거나 수정하지 않았다.
```sh
python3 scripts/check-ios.py test ios/FocusMateTests/JourneyActivityPresentationTests.swift
```
총 신규14건: **현재 assertion RED 예상10건**, **통과 예상 호환 회귀4건**. 수치는 부모가 전달한 최소 몸체(progress hidden / remaining0 / fraction nil) 기준 추정이다.

## assertion RED 예상10건
1. remaining1122/total1800→0.3766667 (허용오차0.000001).
2. remaining135/total1800→0.925.
3. running native 진행 범위1791881322...1791883122, 시간 범위1791882000...1791883122.
4. 관찰60초후 잔여1062.
5. 관찰60초후 진행률0.41와 원래 native 진행 날짜 범위 보존.
6. stale paused1122의300초후 fixed18:42와 fixed0.3766667 채움, sampled fraction 보존.
7. stale paused1122의300초후 잔여1122 보존.
8. paused 잔여1900→진행률0 clamp.
9. paused 잔여-5→진행률1 clamp.
10. running 잔여1.2초→2초 ceil.

각 테스트 앞 깨짐 명명. 날짜·문자열·비율·잔여 기대값은 생산 헬퍼로 계산하지 않고 literal로 지정했다. 모의 없음. paused fixed(Double)는 case를 확인하고 오차로 비교한다.

## 별도 호환 회귀4건 — RED 수 제외
- nil/0/-1 total: hidden 및 nil fraction, 기존 running 시간·상태 보존(3입력).
- missing-end/stale running/arrived: arrived·도착했어요·hidden으로 정규화(3입력).
- paused7200/21600, stale true: fixed120:00/360:00과 paused 보존(2입력).
- long paused7200/21600 summary: 전체 한글 노선·종류·목적지·상태만 포함하고 잔여시간 미합성(2입력).

실제 네 표면 시스템 렌더·카운트다운 갱신·VoiceOver 청취·Reduce Motion 장치 동작은 이번 순수 함수 테스트가 증명하지 않는다.

## 2차 참조한 파일 전체
- .dev/codex-feat-live-activity-design/design.md (2차에서 재열람)
- .dev/codex-feat-live-activity-design/prd.md (앞선 T2 1차에서 열람한 AC 재사용)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-dev/references/codex-roles/red-writer.md (동일 에이전트가 읽은 역할 재사용)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md (동일 에이전트가 읽은 규칙 재사용)
- ios/FocusMateTests/JourneyActivityPresentationTests.swift (이번 신규 작성)
- .dev/codex-feat-live-activity-design/reports/t2-red.md (1차 내용 수정 없이 append)

## 2차 테스트 전문
```swift
import Foundation
import XCTest
@testable import FocusMate

final class JourneyActivityPresentationTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_791_882_000)

    private func state(
        _ status: JourneyActivityStatus = .running,
        end: Date? = nil, paused: Int? = nil, total: Int? = 1800
    ) -> JourneyActivityAttributes.ContentState {
        JourneyActivityAttributes.ContentState(
            status: status, endDate: end, pausedRemainingSeconds: paused, totalSeconds: total
        )
    }

    // 깨짐: 잔여/총 시간을 진행률로 그대로 반환하거나 전체 시간으로 나누지 않는다.
    func testW17_잔여1122초의_진행률은_0점3766667이다() throws {
        let input = state(end: Date(timeIntervalSince1970: 1_791_883_122))

        let value = try XCTUnwrap(JourneyActivityDisplay.progressFraction(state: input, isStale: false, now: now))

        XCTAssertEqual(value, 0.3766667, accuracy: 0.000001)
    }

    // 깨짐: 종료 근처에도 시작 진행률을 고정하거나 잔여초를 잘못 계산한다.
    func testW17_잔여135초의_진행률은_0점925다() throws {
        let input = state(end: Date(timeIntervalSince1970: 1_791_882_135))

        let value = try XCTUnwrap(JourneyActivityDisplay.progressFraction(state: input, isStale: false, now: now))

        XCTAssertEqual(value, 0.925, accuracy: 0.000001)
    }

    // 깨짐: 진행 막대를 now...end로 만들어 현재 잔여 시간 전체를 새 세션으로 취급한다.
    func testW17_running_진행막대는_종료에서총1800초를뺀_날짜범위다() {
        let input = state(end: Date(timeIntervalSince1970: 1_791_883_122))

        let result = JourneyActivityDisplay.presentation(state: input, isStale: false, now: now)

        XCTAssertEqual(result.progress, .timer(
            Date(timeIntervalSince1970: 1_791_881_322)...Date(timeIntervalSince1970: 1_791_883_122)
        ))
        XCTAssertEqual(result.time, .countdown(
            Date(timeIntervalSince1970: 1_791_882_000)...Date(timeIntervalSince1970: 1_791_883_122)
        ))
    }

    // 깨짐: now가 60초 이동해도 잔여를 시작 표본1122초로 고정한다.
    func testW17_60초후_잔여는1062초다() {
        let input = state(end: Date(timeIntervalSince1970: 1_791_883_122))

        let result = JourneyActivityDisplay.remainingSeconds(
            state: input, isStale: false, now: Date(timeIntervalSince1970: 1_791_882_060)
        )

        XCTAssertEqual(result, 1062)
    }

    // 깨짐: 관찰 시각이 지나도 진행률을 고정하거나 날짜 기반 진행 범위를 이동시킨다.
    func testW17_60초후_진행률은0점41이며_진행날짜범위는_유지된다() throws {
        let input = state(end: Date(timeIntervalSince1970: 1_791_883_122))
        let observed = Date(timeIntervalSince1970: 1_791_882_060)

        let fraction = try XCTUnwrap(JourneyActivityDisplay.progressFraction(state: input, isStale: false, now: observed))
        let result = JourneyActivityDisplay.presentation(state: input, isStale: false, now: observed)

        XCTAssertEqual(fraction, 0.41, accuracy: 0.000001)
        XCTAssertEqual(result.progress, .timer(
            Date(timeIntervalSince1970: 1_791_881_322)...Date(timeIntervalSince1970: 1_791_883_122)
        ))
    }

    // 깨짐: stale을 정지보다 우선하거나 정지 중 진행 채움을 계속 움직인다.
    func testW17_stale정지의_진행채움은300초후에도_0점3766667이다() throws {
        let input = state(.paused, paused: 1122)

        let result = JourneyActivityDisplay.presentation(
            state: input, isStale: true, now: Date(timeIntervalSince1970: 1_791_882_300)
        )

        XCTAssertEqual(result.status, .paused)
        XCTAssertEqual(result.time, .fixed("18:42"))
        guard case .fixed(let fraction) = result.progress else {
            XCTFail("정지 진행 채움은 fixed여야 한다")
            return
        }
        XCTAssertEqual(fraction, 0.3766667, accuracy: 0.000001)
        let sampled = try XCTUnwrap(JourneyActivityDisplay.progressFraction(state: input, isStale: true, now: now))
        XCTAssertEqual(sampled, 0.3766667, accuracy: 0.000001)
    }

    // 깨짐: 정지 남은 시간에서 관찰 시각300초를 차감하거나 stale 때문에0을 반환한다.
    func testW17_stale정지의_잔여1122초는300초후에도_유지된다() {
        let input = state(.paused, paused: 1122)

        let result = JourneyActivityDisplay.remainingSeconds(
            state: input, isStale: true, now: Date(timeIntervalSince1970: 1_791_882_300)
        )

        XCTAssertEqual(result, 1122)
    }

    // 깨짐: 잔여가 총 시간보다 클 때 음수 진행률을 그대로 반환한다.
    func testW17_잔여1900초는_진행률0으로_제한한다() throws {
        let input = state(.paused, paused: 1900)

        let result = try XCTUnwrap(JourneyActivityDisplay.progressFraction(state: input, isStale: false, now: now))

        XCTAssertEqual(result, 0, accuracy: 0.000001)
    }

    // 깨짐: 음수 잔여로 진행률이1을 넘거나 진행률을 숨긴다.
    func testW17_잔여음수5초는_진행률1로_제한한다() throws {
        let input = state(.paused, paused: -5)

        let result = try XCTUnwrap(JourneyActivityDisplay.progressFraction(state: input, isStale: false, now: now))

        XCTAssertEqual(result, 1, accuracy: 0.000001)
    }

    // 깨짐: 소수 잔여초를 버림하여 종료까지 남은 시간을1초 짧게 표시한다.
    func testW17_잔여1점2초는_2초로_올림한다() {
        let input = state(end: Date(timeIntervalSince1970: 1_791_882_001.2))

        let result = JourneyActivityDisplay.remainingSeconds(state: input, isStale: false, now: now)

        XCTAssertEqual(result, 2)
    }

    // 호환 회귀. 깨짐: nil/0/음수 총 시간에서 허위 진행률·진행 막대를 제공한다.
    func testW17_호환_유효하지않은총시간은_진행을숨기고_시간을보존한다() {
        let totals: [Int?] = [nil, 0, -1]
        for total in totals {
            let input = state(end: Date(timeIntervalSince1970: 1_791_883_122), total: total)

            let result = JourneyActivityDisplay.presentation(state: input, isStale: false, now: now)

            XCTAssertEqual(result.status, .running)
            XCTAssertEqual(result.time, .countdown(
                Date(timeIntervalSince1970: 1_791_882_000)...Date(timeIntervalSince1970: 1_791_883_122)
            ))
            XCTAssertEqual(result.progress, .hidden)
            XCTAssertNil(JourneyActivityDisplay.progressFraction(state: input, isStale: false, now: now))
        }
    }

    // 호환 회귀. 깨짐: 만료·도착·종료누락 중 하나에서 문구·상태·진행이 서로 어긋난다.
    func testW17_호환_missingend_stale_arrived는_도착으로_정규화한다() {
        let examples: [(JourneyActivityAttributes.ContentState, Bool)] = [
            (state(), false),
            (state(end: Date(timeIntervalSince1970: 1_791_883_122)), true),
            (state(.arrived), false)
        ]
        for (input, stale) in examples {
            let result = JourneyActivityDisplay.presentation(state: input, isStale: stale, now: now)

            XCTAssertEqual(result.status, .arrived)
            XCTAssertEqual(result.time, .fixed("도착했어요"))
            XCTAssertEqual(result.progress, .hidden)
        }
    }

    // 호환 회귀. 깨짐: 장시간 정지 표시가 시간 단위로 바뀌거나 stale을 도착으로 덮는다.
    func testW17_호환_장시간정지는_120분과360분을_유지한다() {
        let examples: [(Int, String)] = [(7200, "120:00"), (21600, "360:00")]
        for (remaining, expected) in examples {
            let input = state(.paused, paused: remaining, total: nil)

            let result = JourneyActivityDisplay.presentation(state: input, isStale: true, now: now)

            XCTAssertEqual(result.status, .paused)
            XCTAssertEqual(result.time, .fixed(expected))
            XCTAssertEqual(result.progress, .hidden)
        }
    }

    // 호환 회귀. 깨짐: summary가 긴 이름을 축약하거나 별도 시간 요소와 시간을 중복한다.
    func testW17_호환_장시간정지summary는_전체이름과_상태만_제공한다() {
        let attributes = JourneyActivityAttributes(
            journeyID: "long-journey", busNumber: "서울도심순환심야광역급행12345",
            busKind: "심야광역급행", destinationName: "서울특별시성동구성수동복합문화체육센터정문앞"
        )
        for remaining in [7200, 21600] {
            let result = JourneyActivityDisplay.presentation(
                state: state(.paused, paused: remaining, total: nil), isStale: true, now: now
            )

            let summary = JourneyActivityDisplay.accessibilitySummary(attributes: attributes, presentation: result)

            XCTAssertEqual(summary, "서울도심순환심야광역급행12345번 심야광역급행 버스, 도착지 서울특별시성동구성수동복합문화체육센터정문앞, 일시정지")
        }
    }
}

```

## T2 1차 GREEN / 2차 준비
기존 API 표시 focused34건 0fail(t2-green-display.log). 실패 확인 후 승인된 presentation 인터페이스를 최소 몸체로 추가했으며 progress=.hidden/remaining=0/fraction=nil 동작은 후속 assertion RED 후 구현한다. 네 표면은 이 단일 presentation을 소비하도록 연결 중.

## 2차 부모 직접 실행
Presentation focused14건 중 예상10assertion실패,4회귀통과. exit65, 컴파일오류0. t2-red-presentation.log. 두 테스트 파일 SHA256 기준 저장.
