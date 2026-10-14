# W10 최종 리뷰 R1 — I1 안내 delta 재리뷰

이전 final-review.md의 I1 수정만 재리뷰했다. 실제 두 생산 파일 diff, CardCustomizationNoticeMessageTests.swift, corrected RED/ GREEN 원문을 직접 읽었다. 나머지33AC는 이전 판정·근거를 유지하며 전체를 다시 검토하지 않았다. 아래 이전 코드 위치는 최초 리뷰 시점 위치다. Controller=CardCustomizationController, View=CardCustomizationView, NoticeMessageTests=CardCustomizationNoticeMessageTests. 빌드·테스트·기기·Git 변경 없이 이 보고서만 작성했다.

## Part 1: 최종 AC 충족 매트릭스

| AC-W10 | 충족도 | 코드·시험 및 실행 근거 |
|---|---|---|
| 01 | ✅ 충족 | AppModel.swift:262 / CardCustomizationAppModelTests.swift:51 — 저장 외형 초안·정체성 |
| 02 | ✅ 충족 | AppModel.swift:262 / CardCustomizationAppModelTests.swift:77 — 미발급 진입 거부 |
| 03 | ✅ 충족 | CardCustomizationController.swift:74 / ControllerTests:59 — 초안 색만 변경 |
| 04 | ✅ 충족 | CardCustomizationController.swift:125 / ControllerTests:80 — 실제 추가·선택 |
| 05 | ✅ 충족 | 기존 입력 정책 근거 유지. CardCustomizationController.swift:32–46의 message가 8MiB·비율0.1~10 원인을 안내. View.swift:53,120에서 실제 Text·VoiceOver 연결. 새 NoticeMessageTests:6,13,19,52,65 및 GREEN8 PASS. |
| 06 | ✅ 충족 | ControllerTests:98 / CardCustomizationView.swift:177 — 6장 제한 |
| 07 | ✅ 충족 | ControllerTests:111 / Controller.swift:143 — 남은 자리·순서 |
| 08 | ✅ 충족 | ControllerTests:135 / View.swift:126 — 빈 선택 no-op |
| 09 | ✅ 충족 | ControllerTests:155,168 / Controller.swift:173 — 부분 성공 |
| 10 | ✅ 충족 | ControllerTests:179 / View.swift:329 — 모두 실패 유지·다시 선택 |
| 11 | ✅ 충족 | ControllerTests:210 / View.swift:255 — 선택 대상만 위치·크기 |
| 12 | ✅ 충족 | CardStyle.swift:84 / ControllerTests:222,232 — 경계 clamp |
| 13 | ✅ 충족 | ControllerTests:254,264,274 / Controller.swift:94 — 한 단계·끝 제한 |
| 14 | ✅ 충족 | ControllerTests:285 / Controller.swift:103 — 한 장 삭제·재추가 |
| 15 | ✅ 충족 | ControllerTests:301 / Controller.swift:111 — 역순 복원 |
| 16 | ✅ 충족 | ControllerTests:335,349 / Controller.swift:223 — 20회·no-op |
| 17 | ✅ 충족 | ControllerTests:381 / Controller.swift:117 — 기본 복원·한 번 undo |
| 18 | ✅ 충족 | PassFace.swift:26–55 / PassFaceAccessibilityTests.swift / T5 R2 실제 PNG 증거 — 기본 문구·고정 장식·clip |
| 19 | ✅ 충족 | ControllerTests:403 / Controller.swift:185 — 무변경 종료 |
| 20 | ✅ 충족 | ControllerTests:411 / View.swift:123 — 계속 편집 |
| 21 | ✅ 충족 | ControllerTests:424 / RootView.swift:178 — 버리기·원본 유지 |
| 22 | ✅ 충족 | ControllerTests:590,612,634,656,678,700 — 세대가드 late completion |
| 23 | ✅ 충족 | ControllerTests:515 / Controller.swift:68 / View.swift:26 — 입력 중 lock |
| 24 | ✅ 충족 | CardCustomizationAppModelTests.swift:263 / CardStyleStorageTests.swift:36 / RootView.swift:49 — 실제 파일 6장 복원·성공 뒤 안내 |
| 25 | ✅ 충족 | CardStyleStorageTests.swift:72 / .build/photos-probe/runtime-final-O01.log:444 — 소유 Data·실제 원본삭제 후 재실행 |
| 26 | ✅ 충족 | CardCustomizationAppModelTests.swift:390 / LocalSnapshotStore.swift:105 — 실제 쓰기 실패 원본 보존·재시도 |
| 27 | ✅ 충족 | 기존 저장 경계·원본 보존 근거 유지. Controller.swift:48–56,67–69에서 장당1MiB·전체6MiB 안내와 초안 유지/재시도. 새 NoticeMessageTests:33,42 및 GREEN8 PASS. |
| 28 | ✅ 충족 | LocalSnapshotStore.swift:93–109 / CardCustomizationAppModelTests.swift:344,366 — 손상 원본 유지·writeBlocked |
| 29 | ✅ 충족 | SnapshotCodec.swift:49–83 / CardCustomizationAppModelTests.swift:442 / CardSupplementTests.swift:25,45 — v1/v2 보존·보충 |
| 30 | ✅ 충족 | AppModel.swift:268–281 / CardCustomizationAppModelTests.swift:146,179,243 — 최신 상태 중 외형만 저장 |
| 31 | ✅ 충족 | View.swift:192–236 / runtime-final-J01.log:563,566 및 T5 R2 원문 검토 — 선택·현재값·disabled·X/Y |
| 32 | ✅ 충족 | SimulatorLargeTextRecoveryTests.swift:13 — XXXL 60분/2014/목적지 유지; 기존 T1 실행 증거 |
| 33 | ✅ 충족 | SimulatorLargeTextRecoveryTests.swift:129 — XXXL 본문 끝·발급; 기존 T1 실행 증거 |
| 34 | ✅ 충족 | RootView.swift:37–69,169 / ProfileUITests.swift:178 — profile 실제 편집·저장·복귀; 최신 focused 포함 |
| 35 | ✅ 충족 | ProfileUITests.swift:321 / w03-integration-focused.log:3032 — XXXL 접근·복귀 최신 PASS |

[Must] 34/34 충족, [Should] 1/1 충족. 총35/35. 이는 AC 구현·해당 증거 판정이며 전체 UI 회귀 실행 완료가 아니다.

## 설계 범위 이탈

없음. 기존 notice 표현만 enum.message로 옮겨 typed 원인을 유지한다. View의 Text와 announcer가 같은 속성을 사용한다. 상태·저장·입력 정책·레이아웃은 delta에 없다.

## Part 1 판정

**SPEC PASS** — AC05·27 누락이 보완되어 최종35개 충족. 이 판정을 먼저 확정한다.

## 재리뷰 판정

| 이전 항목 | 판정 | 근거 |
|---|---|---|
| I1 typed 정책 실패 안내 소실 | ADDRESSED | Controller.swift:32–70에 입력8MiB/비율/변환/보존1MiB/총6MiB 분기. 부분실패와6장생략 이유 동시보존·중복제거. View.swift:53,120 실제 화면/VO공유. corrected RED8cases/21assertion failures → GREEN8/0failure 원문 확인. |

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (0건)
없음. I1 CLOSED. 새 확정 결함 없음. storageReason은 기존 writeBlocked 원인도 탐색하며 실패 유형을 용량초과로 잘못 일반화하지 않는다. encodingFailed는 변환 실패로 구분한다. unreadable-only와 일반 saveFailed의 기존 안내 문구는 그대로다. 순수 출력 속성은 새로운 저장/편집 부작용을 만들지 않는다.

### Minor (4건, 비차단·기존 유예)

1. CardPhotoProcessor.swift:50 — 극단비율 축소 반올림 관찰, 미재현.
2. CardPhotoProcessorTests.swift:111 — 균일색 orientation fixture 검증력.
3. CardStyleStorageTests.swift:243,292 — 성공 경계 시험의 미사용 관측값.
4. CardCustomizationView.swift:206 — native VoiceOver width 증가 bonus 미확정.

위4건을 이번 delta에서 확대 재검토하거나 새로운 차단 사유로 승격하지 않았다.

## 시험 품질 및 실행 증거

- 새8unit의 기대값은 PRD 숫자·오류 의미이며 생산 상수를 oracle로 재사용하지 않는다. 전체 문구 고정 대신 이유·경계·재시도 의미를 검사한다. 부분실패의 여러 원인/6장 생략을 동시에 요구하고 중복 제거 검사는 필수 이유의 존재도 확인한다.
- 사전 oracle 수정2건은 encodingFailed를 용량초과로 잘못 해석한 부분과 save unreadable에 입력용 읽기 문구를 강제한 부분이다. 입력/비율/저장한도 oracle은 유지했다. corrected RED 원문 notice-policy-author-red.log:226–231은 실제8cases/21assertion failures/0unexpected이고 컴파일 실패가 아니다. notice-policy-green.log 말미는8cases/0failure 및 TEST SUCCEEDED다.
- View 실제 Text/announcer 연결을 직접 읽어 unit formatter만 성공한 것을 UI 연결 성공으로 가정하지 않았다. 이번 문구 delta의 실제 VoiceOver 재조작은 실행하지 않았고, 이전 native 관찰을 새 문구 관찰이라고 주장하지 않는다.
- 기존 최신통합539unit+6UI PASS, W03 이전 native 관찰과 source 동일성 근거는 이전 보고서를 유지한다. 사용자 중단 전체 UI108개 미완료도 유지한다. 후속 notice-final-unit.log의547unit/0failure·TEST SUCCEEDED와 notice-final-release.log의 BUILD SUCCEEDED도 직접 확인했다. exit code 집계는 부모 최종 verification 기록을 따른다. 이 리뷰 자체는 전체 UI PASS 선언이 아니다.

## Part 2 판정

**QUALITY PASS — Critical0, Important0, Minor4.** I1 ADDRESSED/CLOSED. 이 delta를 이유로 추가 광범위 회귀나 제품 범위 확장을 요청하지 않는다.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 35
  ac_met: 35
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
