# W10 전체 브랜치 최종 리뷰

읽기 전용 리뷰. PRD 전체, design 변경 범위/최종 부록, codemap, config, diff/stat, 핵심 생산 코드·선별 테스트 본문, 이전 scoped 리뷰 및 실제 로그를 확인했다. 빌드·테스트·기기 조작·Git 변경은 하지 않았다. 현재 main 합류 HEAD 8bf0b922 + staged W10 대상이다. 표의 ControllerTests는 ios/FocusMateTests/CardCustomizationControllerTests.swift, Controller/View는 ios/FocusMate/CardCustomizationController.swift/CardCustomizationView.swift를 뜻한다.

## Part 1: AC 충족 매트릭스

✅는 구현·해당 테스트/기존 실행 증거의 충족이다. 최신 전체 UI 회귀 완료를 뜻하지 않는다. 사용자 중단으로 제한된 전체 검증을 미구현으로 분류하지 않았다.

| AC-W10 | 충족도 | 직접 코드·시험 및 실행 근거 |
|---|---|---|
| 01 | ✅ 충족 | AppModel.swift:262 / CardCustomizationAppModelTests.swift:51 — 저장 외형 초안·정체성 |
| 02 | ✅ 충족 | AppModel.swift:262 / CardCustomizationAppModelTests.swift:77 — 미발급 진입 거부 |
| 03 | ✅ 충족 | CardCustomizationController.swift:74 / ControllerTests:59 — 초안 색만 변경 |
| 04 | ✅ 충족 | CardCustomizationController.swift:125 / ControllerTests:80 — 실제 추가·선택 |
| 05 | ⚠️ 부분 | CardPhotoProcessor.swift:33에서 정책 거절은 구현. CardCustomizationView.swift:329–331은 inputTooLarge/unsupportedAspectRatio를 일반 읽기 실패로 치환하여 요구한 이유 안내 누락 |
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
| 27 | ⚠️ 부분 | CardStyle.swift:74–83 및 CardStyleStorageTests.swift:234,258,283,307의 경계 저장/거절은 구현. View.swift:332가 photoTooLarge/totalPhotosTooLarge를 일반 저장 실패로 치환하여 용량 안내 누락 |
| 28 | ✅ 충족 | LocalSnapshotStore.swift:93–109 / CardCustomizationAppModelTests.swift:344,366 — 손상 원본 유지·writeBlocked |
| 29 | ✅ 충족 | SnapshotCodec.swift:49–83 / CardCustomizationAppModelTests.swift:442 / CardSupplementTests.swift:25,45 — v1/v2 보존·보충 |
| 30 | ✅ 충족 | AppModel.swift:268–281 / CardCustomizationAppModelTests.swift:146,179,243 — 최신 상태 중 외형만 저장 |
| 31 | ✅ 충족 | View.swift:192–236 / runtime-final-J01.log:563,566 및 T5 R2 원문 검토 — 선택·현재값·disabled·X/Y |
| 32 | ✅ 충족 | SimulatorLargeTextRecoveryTests.swift:13 — XXXL 60분/2014/목적지 유지; 기존 T1 실행 증거 |
| 33 | ✅ 충족 | SimulatorLargeTextRecoveryTests.swift:129 — XXXL 본문 끝·발급; 기존 T1 실행 증거 |
| 34 | ✅ 충족 | RootView.swift:37–69,169 / ProfileUITests.swift:178 — profile 실제 편집·저장·복귀; 최신 focused 포함 |
| 35 | ✅ 충족 | ProfileUITests.swift:321 / w03-integration-focused.log:3032 — XXXL 접근·복귀 최신 PASS |

[Must] 34건 중 32건 충족·2건 부분, [Should] 1건 중 1건 충족. 총 35건 중 33건 충족.

## 설계 범위 이탈

이탈 없음. W11 진입 및 성공 안내 연결은 최종 design 부록에 명시됐다. W03 상류 합류와 동일 bytes 폰트 중복 제거는 maintenance 통합이며 W10 신규 제품 범위 확대가 아니다. 원본 보존 복구 순서는 유지한다.

## Part 1 판정

**SPEC FAIL — AC05·27의 오류 이유/용량 안내가 미완료다.** 입력/보존 제한, 초안·원본 보존은 구현되어 있다. 전체 검증 중단 때문에 내린 실패 판정이 아니다. 이 판정을 먼저 확정한 뒤 품질을 검토했다.

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (1건)

- **I1: typed 정책 실패의 사용자 안내 소실 — `ios/FocusMate/CardCustomizationView.swift:329–332` → [동작결함] (재구현 대상 AC05·27).** 실제 8MiB 초과 입력이면 processor가 inputTooLarge를 던지고 controller가 importFailed에 보존하지만 View는 원인을 무시한 “사진을 읽지 못했어요”만 표시한다. 비율 범위 밖도 동일하다. 저장의 invalidState(invalidCardStyle(photoTooLarge/totalPhotosTooLarge)) 또한 일반 저장 실패로 소실된다. 실패 배열이 partialImport에 섞여도 이유는 사라진다. 같은 noticeMessage를 실제 텍스트와 VoiceOver 안내에 사용하므로 두 경로 모두 해당한다. 이는 새 정책 요구가 아니라 PRD의 명시된 ‘이유 안내’와 ‘용량 안내’ 누락이다.
  - 권고: 기존 typed errors를 사용해 입력 용량·비율 및 저장 용량 실패를 구분해 안내하고 기존 초안/원본/재시도 동작은 유지한다. 정상·부분 실패와 저장 용량 안내의 관찰 가능한 회귀를 focused로 확인한다. 광범위 전체 재실행을 요구하지 않는다.

### Minor (4건, 비차단)

1. `CardPhotoProcessor.swift:50` — 기존 T2 M1, 축소되는 극단 비율의 정수 반올림 후 거절 가능성은 재현 근거가 없어 Minor 유지. 새 결함으로 확정하지 않았다.
2. `CardPhotoProcessorTests.swift:111–123` — 기존 T2 M2, 균일 색 orientation fixture는 반대 회전/거울 변환을 구별하지 못한다. WithTransform 코드의 결함 증거는 없다.
3. `CardStyleStorageTests.swift:243–246,292–295` — 기존 T2 M3, 성공 경계 시험의 불필요한 원본 읽기와 미assert 디렉토리 카운터. 핵심 저장·재로드 equality는 유효하다.
4. `CardCustomizationView.swift:206–210` — 기존 T5 Minor, native VO width swipe 증가 bonus는 미확정. 필수 현재값 식별과 X/Y 대체 조작은 별도 증거가 있으므로 AC31 실패로 전환하지 않았다.

## 검증 증거와 범위

- `w03-integration-focused.log:2135,2137`에서 최신 단위539/0failure, 말미 UI6/0failure 및 :3046 TEST SUCCEEDED를 직접 읽었다. 이 545 PASS는 전체 UI115 PASS가 아니다.
- `final-ios-full-test.log`는 중단된 실행으로 정상 완료 footer가 없다. 부모 정리대로 단위539·완료UI7 PASS, 잔여108 미완료 및 사용자 SIGINT exit130을 기록한다. 최신 전체 PASS라 주장하지 않는다. Release는 리뷰 도중 부모가 새 실행 exit0 완료를 전달했다. final-ios-release-build.log 말미의 BUILD SUCCEEDED를 직접 확인했다.
- Node test 원문 말미 edge QA PASS 확인. Debug 성공 및 Node build/test exit0은 final-verification.md의 실행 기록과 구분해 인용한다.
- O01 원문 :444 실제 삭제 후 읽기 전용 재실행 case31.072초 PASS, J01 :563 안내3종 true/:566 해당 case56.290초 PASS를 직접 읽었다. runtime probe 묶음 전체가 PASS라는 뜻이 아니다. 실제 소유 원본2개 삭제/기존6개 보존과 동일 사진내용·배치의 증거를 지원한다. 전체 snapshot bytes 비교는 삭제 후 두 cold launch 사이뿐이다.
- 과거 scoped 리뷰의 actual Photos/VO/PNG 증거는 W03 합류 전 관찰이다. protected source hashes 및 최신 focused 통합 회귀로 연결되며 합류 후 재관찰로 바꾸지 않는다. 실제 iPhone·햅틱 W14, VO import 지속 시각초점 및 width bonus 한계 유지.
- 테스트 경계 검토: 실제 임시파일 store/새 AppModel 복원과 쓰기 경계 실패 주입을 확인했다. byte 경계의 no-op validator는 구조 경계용으로 명시되어 있고 실제 이미지 증거와 분리한다. controller mock은 외부 saver/processor 격리이며 저장 파일 성공 증거로 대체하지 않는다.

## Part 2 판정

**QUALITY FAIL — Critical 0, Important 1([동작결함]), Minor 4.** I1의 제한된 안내 수정 후 scoped 재리뷰가 필요하다. 그 외 확정 merge-blocking 결함은 발견하지 않았다.

```yaml
spec_verdict:
  verdict: FAIL
  ac_total: 35
  ac_met: 33
  ac_partial: 2
  ac_unmet: 0
  unmet_ids: [AC-W10-05, AC-W10-27]
```

```yaml
quality_verdict:
  verdict: FAIL
  critical: 0
  important: 1
  important_behavior: 1
  minor: 4
```
