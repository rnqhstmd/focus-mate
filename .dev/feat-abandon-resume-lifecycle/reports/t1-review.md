## Part 1: AC 충족 매트릭스 (태스크 범위: 순수 규칙/값)

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-1 (카드 필드) | ✅ | ActiveJourneyCardContent.swift:26-36은 제목, 할 일, 버스 텍스트 "지선 2014", 남은 시간, "{태그} · {도착지}까지" 경로를 만든다. 테스트는 ActiveJourneyCardContentTests:140-149. 버튼 문구 `resumeButton`은 JourneyLifecycleText:52에 정의돼 있다. 시작 버튼 문구와 임시 안내 제거는 View 몫이라 이 태스크 범위 밖이다. |
| AC-2 (올림 표기) | ✅ | `JourneyTimerDisplay.remainingMinutes`(올림)를 재사용한다. 테스트 :152-160이 0, 1, 60, 61, 1499초를 확인한다. |
| AC-17 (경계값) | ✅ | JourneyReach.swift:84-86과 :98-107. 테스트 JourneyReachTests:218-229(칸 수), :250-266(0, 299, 300, 600, 1499초와 강남02/343번 경계)가 뒷받침한다. |
| AC-18 (가·나 = 900초) | ✅ | 역방향 `wrap`을 쓴다. 테스트 :269-274가 (가) 성수사거리와 방향 -1을, :277-282가 (나) 성수역과 방향 1을 확인한다. |
| AC-19 (진도 0초) | ✅ | 테스트 :285-287. 안내 문구 "성수역에서 여행을 마쳤어요…"는 `abandonNotice`(JourneyLifecycleText:66)에 있다. |
| AC-23 (카드 25 min, 출발 대기) | ✅ | 테스트 :163-169. 출발 대기는 경과 0이라 남은 시간이 전체 시간이고 resumable이다. |
| AC-24 (arrived 카드, 도착 정류장) | ✅ | ActiveJourneyCardContent:28-33에서 arrived이면 `remainingText`가 nil, `showsResume`가 false다. JourneyReach:99-101은 저장된 도착지를 쓴다. 테스트 :172-179와 JourneyReachTests:296-302(식과 다른 도착지 픽스처)가 확인한다. |
| BR-1 | ✅ | 몫과 총 정류장 수 상한(JourneyReach:85)이 구현돼 있고, 카탈로그 밖 출발지는 nil이다. |
| BR-2 | ✅ | `StationSnapshot`의 direction에 여정 방향을 그대로 넣는다. |
| BR-3 | ✅ | `endingActiveJourney`는 records, cards, initialStation을 보존한다. 테스트 :310-331. |
| BR-4 | ✅ | 현재 정류장 변경과 여정 삭제가 하나의 `AppSnapshot` 후보로 만들어진다(JourneyReach:112-115). 실제 저장 호출은 이후 태스크 범위다. |

[Must] 해당 AC·BR 11건 중 11건 충족. [Should] 해당 없음.

## 설계 범위 이탈
이탈 없음. 신규 3개 파일(ActiveJourneyCardContent, JourneyLifecycleText, JourneyReach)과 테스트 2개뿐이다. 기존 파일은 수정하지 않았다. design.md는 읽기 예산 초과로 전문을 읽지 못했고, 인터페이스는 PRD와 코드로 대조했다.

## Part 1 판정
모두 ✅ → SPEC PASS

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (0건)
없음.

### Minor (4건) — 전부 [동작불변], 비차단
- JourneyLifecycleText.swift:28 — `saveFailure`가 `JourneyTimerDisplay.transitionFailureText`의 단순 별칭이다. 문구가 한 곳에서 나오는 점은 좋지만, 호출부가 두 이름 중 무엇을 쓸지 혼동할 수 있다. 사용처를 하나로 통일하는 것을 권고한다.
- JourneyLifecycleText.swift:52 — `resumeButton`("이전 여정 이어가기 →")의 값을 검증하는 테스트가 없다. AC-1의 버튼 문구는 View 태스크에서 검증될 것이다. 확신이 낮은 관찰이다.
- JourneyReach.swift:84-86 — `minutesPerStop`이 0이면 0으로 나눈다. 현재 카탈로그는 5, 6, 8분이라 도달하지 않는다. 방어는 선택이다. 확신이 낮은 관찰이다.
- ActiveJourneyCardContentTests:127 — 주석의 "지선" 가정은 설계서 예시 기준이다. `bus.kind` 값은 BusLine 카탈로그와 일치하는지 한 번 확인하면 좋다.

테스트 품질: 모의 객체나 테스트 전용 메서드 없이 순수 값을 직접 단언한다. 각 테스트에 "깨짐:" 설명이 있고 경계값을 다룬다. testing-anti-patterns 위반은 없다. `[검증 필요]` 항목도 없다.

## Part 2 판정
Critical 0 + Important 0 → QUALITY PASS

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 11
  ac_met: 11
  ac_partial: 0
  ac_unmet: 0
  unmet_ids: []
```

```yaml
quality_verdict:
  verdict: PASS
  critical: 0
  important: 0
  important_behavior: 0
  minor: 4
```