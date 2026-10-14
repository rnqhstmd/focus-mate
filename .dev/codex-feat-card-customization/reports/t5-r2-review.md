# T5 R2 scoped 재리뷰

역할: gx-dev `references/codex-roles/reviewer.md`의 Part 1 → Part 2 순서, task 재리뷰 모드. 기준: PRD, 최종 설계·서체/XXXL artwork 부록·W11 합류 계약, codemap, 961행 `reports/t5-diff-r2.txt`, 실제 소스/테스트, 이전 `reports/t5-review.md`, 지정 원문 로그와 실제 캡처. testing-anti-patterns.md와 frontend-testing.md를 적용했다. 실제 설치 SDK `XCUIVoiceOverService.h:38–52`의 moveForward/currentSpeech 계약을 직접 읽었다. currentSpeech는 현재 초점 요소 발화이며 진단 announcement 문자열과 구분한다.

이 리뷰는 AC-W10-18·31·34·35 네 건에 한정한다. source/tests/Git/기기 변경, 빌드·테스트·시뮬레이터 조작·추가 agent 호출은 하지 않았다. 결과 보고서만 작성했다. 부모가 보유한 전체 테스트 22파일 잠금 검증은 부모 증거이며, 여기서는 W11 두 테스트의 실제 SHA를 whitelist의 after SHA와 직접 대조해 일치 확인했다. `final-root-production-manifest-W11.json`의 39개 source/resources는 현재 ROOT와 독립 runtime clone 양쪽 SHA를 직접 다시 계산해 모두 일치했다.

## Part 1: AC 충족 매트릭스

| AC | 충족도 | Given / When / Then 및 직접 근거 |
|---|---|---|
| AC-W10-18 [Must] | ✅ 충족 | PRD:130–133의 기본/꾸민 공통 카드 표시 계약. `CardStyle.swift:59`는 기본색+사진0만 standard로 구분하고 `PassFace.swift:26–38`는 기본 브랜드·이름·문구만 그린다. 사진 `39–46`, IC/비접촉 `47–51`, 경계 clip `54`이며 번호 출력은 없다. artwork만 `13`에서 `.large`로 고정한다. `RootView.swift:157`, `ProfileView.swift:63`은 currentCardStyle을 공급한다. 실제 `t5-artwork-green.log:236,740,754`에서 component unit1+XXXL UI1 각각 PASS 및 TEST SUCCEEDED를 확인했다. 직접 연 `reports/simulator/final/t5-artwork-fixed-xxxl-basic-start.png`는 기본 카드 이름·문구 전체가 분리되어 보이며 주변 제목·본문·저장 버튼은 XXXL이다. 실제 `t5-actual-r40-overlap-handle.png`에서는 꾸민 카드 내부 글자가 숨겨지고 샌드/겹침/경계 clip/IC/비접촉/선택선/핸들을 확인했다. H01 실제 picker B lifecycle 원문 log1360의 123.988초 PASS는 입력·제스처 선택 유지·저장·재실행에 대한 보강 증거다. |
| AC-W10-31 [Should] | ✅ 충족 | PRD:195–198의 이름·선택·사용 가능 여부·현재값과 비드래그 위치 변경. `CardCustomizationView.swift:192–195`의 사진 이름/selected trait, `206–210`의 크기 현재값, `220–236`의 X/Y 이름·값·경계 disable, `217`의 lock을 실제 발화와 대조했다. H01 log1474 실제 `선택됨 사진 2 버튼`, 1482/1742 실제 `사진 크기 60퍼센트 조절 가능...`, 1484–1491/1510–1517 축 이름·50퍼센트·늘리기 버튼을 직접 확인했다. 실제 초점 뒤 X/Y 각각 doubleTap이며 log1530에서 선택 B centerX=.55, centerY=.55, width=.6, 다른 사진=.5/.5/.6이다. J01 log252/258/276/278에서 선택됨 사진1·60퍼센트·앞으로/뒤로 흐리게 표시됨을 실제로 구분한다. C01 held import의 저장 비활성 actual speech는 보조 증거다. 최신 J01 log84/313/482의 실제 가져오기/저장 실패/프로필 저장 성공 발화, log563 세 결과 true 및 log566 해당 case 56.290초 PASS도 직접 확인했다. width swipe 후 증가 bonus는 미확정이며 이 AC의 필수 Then에 추가하지 않는다. |
| AC-W10-34 [Must] | ✅ 충족 | PRD 최신 W11 합류 항목은 기존 Must 확장으로 명시됐다. `RootView.swift:37,169–174` callback, `DestinationScreen.swift:8,13`, `ProfileView.swift:70–71`이 실제 편집을 연다. `RootView.swift:183–190`은 modal만 닫아 profile path를 유지하고 `39–59`는 현재 NavigationStack 아래 성공 안내를 노출한다. `AppModel.swift:222–235`는 대상 카드 외형만 저장/current style로 공급한다. `ProfileUITests.swift:178–244` 실제 open/save/close/reopen, 카드 ID·발급일·기록 전체 비교 및 독립 통계 3/1 h 5 min assertion을 읽었다. W11 GREEN log695/759에서 UI24·25 PASS, log529–547 unit7 PASS를 직접 확인했다. 최신 J01 성공 발화 및 직접 연 `t5-final-profile-save-success-vo.png`에서 저장된 꾸민 카드·현재 프로필·안내 전체·VO 초점사각형을 확인했다. |
| AC-W10-35 [Must] | ✅ 충족 | PRD의 조건은 ‘필요한 경우 실제 스크롤’이다. `ProfileView.swift:57–79` ScrollView, `ProfileUITests.swift:321–338,367–379`는 실제 XXXL 진단 accessibility5, 완전히 viewport에 포함되고 hittable인 진입점/행, 실제 swipe, open/close profile 복귀, 최종 accessibility5·정체성/기록 보존을 요구한다. GREEN log810–826 실제 profile Swipe up 및 보이는 행 Tap, log827–857 실제 편집 진입·닫기·복귀와 case21.342초 PASS를 확인했다. main entry는 이 실행에서 이미 완전히 가시/탭 가능해 main swipe는 필요하지 않았다. 본문 축소나 화면 밖 강제 좌표 tap은 없다. 이는 해당 소유27/seed의 실제 경로 증거이며 모든 기기 크기에 대한 포괄 보장은 아니다. |

[Must] 3건 중 3건 충족, [Should] 1건 중 1건 충족. 총 4건 충족.

## 설계 범위 이탈

이탈 없음. 기본 PassFace/편집 화면/진입/폰트/DEBUG testability는 기존 T5 범위다. `AppModel+Profile.swift`, `DestinationScreen.swift`, `ProfileView.swift` 및 RootView 통합은 design.md:251–253의 최신 main W11 합류에 명시됐다. cardStudio/customize placeholder enum의 폐기는 해당 합류 계약이며 새로운 W11 기능 확장이 아니다. `CardIssuanceController.swift` actor constant 수정 및 기존 TimeSelectionView 기계 수리는 전달된 범위로만 확인하고 다른 AC 품질을 확대 평가하지 않았다.

## Part 1 판정

**SPEC PASS.** 네 AC의 필수 상태·조작을 코드와 실제 실행/시각 증거로 확인했다. Part 1 판정을 먼저 확정한 뒤 아래 품질 판정을 수행한다.

## 재리뷰 판정

| 이전 항목 | 판정 | 근거 |
|---|---|---|
| F1 고정 카드 artwork와 Dynamic Type 확대 충돌: 기본 카드명/문구 겹침·잘림 (Important1, AC18) | ADDRESSED | `PassFace.swift:13`의 artwork 한정 `.large`, 실제 unit1+UIXXXL1 GREEN 원문, fixed XXXL 캡처에서 카드명/문구 전체 분리. 바깥 편집 본문은 실제 확대 상태다. |
| AC31 사진 selected trait/X·Y/크기 현재값 실제 보조기술 탐색 증거 부족 (이전 spec 부분 및 검증 필요) | ADDRESSED | `CardCustomizationView.swift:193–194,209,228–234`와 H01 실제 VO 발화/DoubleTap, log1530 .50→.55·width/다른사진 불변, J01 실제 disabled/값/선택 발화 및 현재 profile 성공 안내 대조. DEBUG selected ID 하나를 AX 증명으로 치환하지 않았다. |

## Part 2: 코드 품질 리뷰

### Critical (0건) — 전부 [동작결함]

없음.

### Important (0건)

없음. 현재 scoped 수정 diff에서 새 차단 결함을 확인하지 못했다. `.exclusively(before:)`는 실제 drag/resize와 tap deselection의 중복 처리를 막으며, `t5-parent-gesture-green.log:434–448`의 소유27 test13 PASS와 최신 H01 B의 선택 유지/수정 저장·재실행으로 보강됐다. 테스트는 native 사용자 조작에 연결되고 상태·바이트 비교는 그 결과 oracle이다. W11 tests는 placeholder 계약 whitelist 교체 범위와 동일 SHA이며 독립 expected 기록/색/통계를 사용한다. artwork invariant pixel test는 design.md의 고정 그래픽 비교를 위한 명시적 시각 회귀다. 이를 UI 동작이나 보조기술 성공의 대체 근거로 쓰지 않았다.

### Minor (1건) — 전부 [동작불변], 비차단

1. **실제 VO width 증가 bonus는 확인되지 않았다.** `CardCustomizationView.swift:206–210`, H01 log1742–1792 — 실제 60퍼센트 adjustable 발화에 도달했지만 native `slider.swipeUp()` 이후 증가 assertion이 timeout했다. SDK에는 별도 VoiceOver increment/swipe API가 없고 synthetic 일반 swipe 전달과 제품 slider 동작을 분리하지 못했다. 확신 낮은 관찰이며 제품 결함으로 확정하지 않는다. 필수 AC31의 값 식별·X/Y 비드래그 경로는 별도 실제 PASS다.
   - 권고: `[검증 필요]` 부모가 후속 단독 슬롯에서 실제 VO 증가 입력 전달을 독립 확인할 때 width bonus를 다시 판정한다. 현재 reviewer는 실행하지 않았다. 성공 또는 실패를 미리 제품 주장으로 바꾸지 않는다.

## 증거 경계·남은 게이트

- `t5-parent-green.log:619,4962,10169,10181`의 245 unit+12 T5 UI+2 T1 UI=259 PASS는 F1/gesture fix와 W11 합류 이전 실행이다. 이를 최신 전체 브랜치 PASS로 치환하지 않았다.
- F1은 실제 RED→unit1+UI1 GREEN, gesture는 실제 selection RED→소유27 test13 GREEN, W11은 unit7/UI3 중 실제 assertion4 RED→같은 scoped 10 PASS다. 이 건수를 누적 전체 최신 검증 수로 합산하지 않는다.
- H01 전체는 width bonus 때문에 4cases/1failure, J01 전체는 범위 밖 Photos metadata/RGB case 실패가 포함된다. 각각의 B 123.988초, C02 56.290초 **해당 case PASS만** 인용했다. runtime xcresult 존재 및 실제 원문·첨부 화면을 확인했으며 전체 invocation PASS로 표시하지 않는다.
- C01 DEBUG manual release 이후 focus artifact는 원인 미확정이다. 최신 no-manual C02의 actual currentSpeech와 profile 성공 시각초점으로 필수 증거를 보완했지만, import 지속 시각초점/자동스크롤 전체를 PASS로 일반화하지 않는다. 삭제 글자 잘림은 이전 독립 미확정 상태이며 새 Important로 만들지 않았다.
- RootView 메인은 현재 ScrollView가 아니다. 본 AC35의 검증 entry는 이미 가시/탭 가능했고 profile 실제 스크롤은 수행됐다. 다른 viewport에서의 main reach는 여기서 미실행이므로 제품 결함이나 모든 화면 성공으로 단정하지 않는다.
- 실제 Photos 원본 삭제/커스텀 RGB 최종 보존 검증은 네 AC 범위 밖이다. 해당 AC를 매트릭스에 추가하지 않았다. 실제 Reduce Motion=true/PhotosPicker 결과와 fixture 오류 보강 경로를 구분한다.
- **이 결과는 T5 재리뷰 scoped PASS이며 full-branch mechanical review, 최신 전체 회귀, 최종 accept/배포 승인이 아니다.** 부모가 남은 전체 검증 게이트를 별도로 완료해야 한다.

## Part 2 판정

**QUALITY PASS.** Critical 0, Important 0, Minor 1. 이전 확인된 차단 결함과 실제 접근성 증거 공백은 모두 ADDRESSED다.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 4
  ac_met: 4
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
  minor: 1
```
