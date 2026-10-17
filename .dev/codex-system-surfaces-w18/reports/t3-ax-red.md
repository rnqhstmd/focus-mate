# W18 T3 접근성 회귀 RED

Status: DONE_WITH_CONCERNS — 작성 완료, 실행 증거 없음.

승인 계약: 유효total1800/elapsed678의 axSummary는 시각퍼센트 반올림과 같은 **저장된 진행 38%**를 포함한다. progress nil인 오류/ready는 저장된 진행 숫자를 제공하지 않는다. children.ignore 화면에서 빠진 저장진행을 순수요약계약으로 검사한다.

## 추가 테스트와 intended RED
- 신규2건만 WidgetPresentationTests.swift 말미에 추가. 기존 본문은 수정하지 않았다.
- positive1건: valid/stale/validEmpty(정지여정유지) 모두 '저장된 진행 38%' 포함. 현재 누락 결함에 대해 assertion RED 예상.
- negative1건: unavailable/malformed/unsupported2/ready progress nil 및 저장진행숫자 패턴 없음. 현재 통과 가능한 호환 회귀이며 RED 수에서 제외.
- 예상 RED1 / 호환1. 실제 실행/컴파일/실패 메시지 미확보.

테스트·빌드·시뮬레이터·브라우저 실행 및 생산소스 접근 없음. 부모가 focused를 직접 실행한다. 단순 문구 전수검사가 아니라 저장진행 입력678/1800에 의존한 반올림 수치와 진행 없음 분기를 검사한다. 기대38은 literal이며 생산진행계산으로 산출하지 않는다.

## 참조한 파일 전체
- ios/FocusMateTests/WidgetPresentationTests.swift (현재 테스트만 읽음)
- ios/FocusMateTests/WidgetFixtures.swift (앞선동일agent작업에서읽은DTO/1800·678픽스처재사용)
- .dev/codex-system-surfaces-w18/design.md (앞선v2계약재사용,추가38%계약은부모명시승인)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-dev/references/codex-roles/red-writer.md (역할재사용)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md (규칙재사용)

## 추가 테스트 전문
```swift

    // 깨짐: children.ignore 표면의 요약이 저장진행숫자를누락하거나 시각38%와다르게버림한다.
    func testW18_접근성요약은_저장진행678초를_38퍼센트로_제공한다() {
        let states: [WidgetReadState] = [
            .valid(F.snapshot()), .stale(F.snapshot()), .validEmpty(F.snapshot(empty: true))
        ]
        for state in states {
            let result = WidgetPresentation.content(state: state)
            XCTAssertTrue(result.axSummary.contains("저장된 진행 38%"), result.axSummary)
        }
    }

    // 호환회귀. 깨짐: 진도없는오류/새준비상태를 저장진행0%로꾸며낭독한다.
    func testW18_진도없는_오류와ready는_저장진행숫자를_제공하지않는다() {
        let base = F.snapshot(empty: true)
        let ready = WidgetSnapshot(
            version: base.version, generatedAt: base.generatedAt, basisDay: base.basisDay,
            timeZoneID: base.timeZoneID,
            journey: WidgetJourney(phase: .ready, journeyID: nil, busNumber: nil, destination: nil, totalSeconds: nil, elapsedSeconds: nil),
            analytics: base.analytics
        )
        let states: [WidgetReadState] = [.unavailable, .malformed, .unsupportedVersion(2), .validEmpty(ready)]
        for state in states {
            let result = WidgetPresentation.content(state: state)
            XCTAssertNil(result.progress)
            XCTAssertNil(result.axSummary.range(of: "저장된 진행[[:space:]]*[0-9]+%", options: .regularExpression), result.axSummary)
        }
    }

```
