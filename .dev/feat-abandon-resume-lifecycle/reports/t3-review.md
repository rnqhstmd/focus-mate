## Part 1: AC 충족 매트릭스 (태스크 범위: 모델 수준)

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-4 | ✅ | AppModel+JourneyLifecycle.swift:42-52 (저장값은 경과 유지·paused=false, 쓰기 1회, path=[.journey]). 테스트 testAC4_이어가기는_경과_90_paused_false... |
| AC-5 | ✅ | :43 `path.isEmpty` 가드. 첫 탭이 path를 동기적으로 바꾸므로 두 번째는 .rejected. testAC5 (attempts 1) |
| AC-8 | ✅ | :63-71 `endingActiveJourney`로 도달 정류장(뚝섬역)·여정 삭제를 쓰기 1회로 저장하고 `open(.time)`. testAC8 |
| AC-10 | ✅ | :66 `.saveFailed`, 상태·path 불변, 일반 saveFailure 미남김. testAC10 ×2 (재시도 포함) |
| AC-11 | ✅ | path 가드로 두 번째는 .rejected, .time은 1회. testAC11 |
| AC-12 | ✅ | AppModel+Boarding.swift:50-56. 여정이 없으면 쓰기 0·.time, 있으면 false. testAC12 ×2 |
| AC-16 | ✅ | :75-83 쓰기 1회, 뚝섬역·방향 유지·여정 삭제·records 불변·path=[]·abandonNotice. testAC16 |
| AC-19 | ✅ | 경과 0초에도 `reachedStation`이 성수역을 돌려준다. testAC19 |
| AC-20 (모델 불변) | ✅ | :79 실패 시 path·snapshot·notice 불변, saveFailure nil, 재시도 시 AC-16 결과. testAC20 ×2 |
| AC-23 | ✅ | :45 `phase == .departed`일 때만 저장하므로 출발 대기는 쓰기 0. 확정 시 현재 정류장은 출발지 그대로. testAC23 ×2 |
| AC-24 | ✅ | :44 `!isArrived` 가드로 이어가기는 .rejected. 확정 시 현재 정류장은 도착지(`reachedStation`의 isArrived 분기). testAC24 ×2 |
| AC-31 | ✅ | resume·confirm·abandon의 성공 테스트가 records 1건 유지를 단언한다. 실패·취소 경로는 snapshot 동일성으로 간접 확인한다. |
| AC-35 | ✅ | :47 `.saveFailed`, 이동 없음, 저장값 (90, paused=true) 유지, `consumeResumeEntry`는 false. testAC35 ×2. `main.saveFailure` 표시는 뷰 몫으로 이번 범위 밖 |
| BR-1 | ✅ | `reachedStation` 사용 (JourneyReach.swift:20-29, 이전 태스크) |
| BR-2 | ✅ | `reachedStation`이 `direction`을 유지한다. |
| BR-3 | ✅ | 모든 경로가 records를 건드리지 않는다. |
| BR-4 | ✅ | `endingActiveJourney` 후보 1개를 저장 1회로 처리한다. |
| BR-5 | ✅ | 모델에 확인 상태가 없고 확정 호출 전에는 변경이 없다. |
| BR-6 | ✅ | :76 `timerPaused`·`path.last == .journey`·departed·!arrived 가드. testBR6 ×4 |
| BR-7 | ✅ | `saveHandlingFailure`가 실패 시 false를 돌려주고 상태 변경이 없다. |
| BR-8 | ✅ | 시간 디바운스 없이 path·active 상태 가드로 막는다. |
| BR-10 | ✅ | AppModel.swift `open`(+118)과 `beginCardCustomization`(+135)이 notice를 지운다. testBR10 ×2 |
| BR-11 | ✅ | :46 저장 시 paused=false로 풀린다. |

[Must] 전체 충족, [Should] BR-10 충족.

## 설계 범위 이탈
이탈 없음. design.md의 AppModel.swift 변경 항목(abandonNotice, resumeEntryJourneyID, saveHandlingFailure, open/beginCardCustomization의 notice 지움, goBack 주석)과 line 152의 saveHandlingFailure 의미(성공 시 saveFailure=nil, 실패 시 미남김)에 일치한다. `startTripFromMain`이 여정이 있으면 false를 돌려주도록 바뀐 것은 AC-12와 일치하며, 이 메서드를 호출하는 뷰는 이후 태스크에서 바꾼다.

## Part 1 판정
모두 ✅ → **SPEC PASS**

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (0건)
없음.

### Minor (6건) — 전부 [동작불변], 비차단
- AppModel+JourneyLifecycle.swift:43,63,76 — `launchState == .ready(.main)`·`let snapshot` 가드가 세 메서드에 반복된다. 작은 private 헬퍼로 묶을 수 있다.
- AppModel+JourneyLifecycle.swift:42-52 — 이어가기로 `resumeEntryJourneyID`를 설정했는데 타이머가 소비하지 않고 포기·새 여정으로 떠나면 값이 남는다. 다음 여정 id가 달라 실해는 없을 것으로 본다(확신 낮음). 확정 시 nil로 지우면 더 안전하다.
- AppModel.swift:80 — `abandonNotice`의 "설정은 lifecycle 확장에서만" 규칙이 주석뿐이다. 다른 파일 확장이라 `private(set)`을 쓸 수 없다는 설계(line 150)에 따른 것으로 수용 가능하다.
- AppModel.swift:276 — `open`이 가드 통과 후 목적지 거부(예: `.journey`인데 active 없음)와 무관하게 notice를 지운다. 거부된 이동에서도 안내가 사라진다. 영향은 작다.
- AppModel+JourneyLifecycle.swift:68 — `confirmNewJourney`만 `discardConfirmedPreparation()`을 부른다. `abandonJourney`는 부르지 않는다. 출발 후에는 확정값이 없을 것으로 보이지만 코드로 확인하지 못했다(확신 낮음).
- JourneyLifecycleModelTests.swift — 다른 id로 `consumeResumeEntry`를 부르면 소비되지 않고 false를 돌려주는 케이스가 없다. 이 케이스는 이 라운드 필수가 아니다. 테스트 주석의 "(T4)" 표기는 태스크 번호가 t3와 어긋난다. 안티패턴(모의 동작 검증, 테스트 전용 메서드)은 발견하지 못했다. [검증 필요] 없음.

## Part 2 판정
Critical 0 + Important 0 → **QUALITY PASS** (Minor 6건, 비차단)

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 13
  ac_met: 13
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
  minor: 6
```