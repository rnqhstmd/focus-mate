# W03 전체 브랜치 최종 코드 리뷰

최신 main `8ac11c35504249370e4a39b414197e395cb3a32c` 통합 후 실제 작업트리와 staged diff를 다시 읽고 판정했다. 앞선 구 스냅샷 한계는 이 최종 코드 판정으로 대체한다. W03 신규 소스·리소스와 관련 테스트는 통합 전 보존 stash와 diff가 없어 그대로 유지되었음을 직접 확인했다. 소스·테스트 수정과 테스트·시뮬레이터 실행은 하지 않았다.

## Part 1: AC 충족 매트릭스

경로 축약: View=ios/FocusMate/PreparationView.swift, Draft=ios/FocusMate/PreparationDraft.swift, Model=ios/FocusMate/AppModel.swift, Controller=ios/FocusMate/SoundPreviewController.swift. Editor=ios/FocusMateUITests/PreparationEditorUITests.swift. 나머지 테스트 파일은 ios/FocusMateTests 아래다. 줄 번호는 통합 후 현재 기준이다.

| AC | 충족도 | 구현 및 테스트 근거 |
|---|---|---|
|1|✅|Draft:94, View:30,71,185; Editor:10 초기값/입력 숨김/확정 차단|
|2|✅|Draft:101, View:38; Editor:21 단일 선택/자동 입력 없음|
|3|✅|Draft:99, Model:34; PreparationModelTests:51,57 공백 차단|
|4|✅|Draft:106, View:73; PreparationDraftTests:52, Editor:36 UTF16 상한|
|5|✅|View:54,218; Editor:58 편집 기본값|
|6|✅|Draft:120, View:299; Editor:64 빈 이름 오류/편집 유지|
|7|✅|Draft:122; PreparationDraftTests:114,123 대소문자/NFKC 중복|
|8|✅|Draft:121; PreparationDraftTests:132,141 20/21 경계|
|9|✅|Draft:126, View:300; Editor:75 메타데이터/할 일 보존|
|10|✅|View:128,227; Editor:96 취소 미저장/복귀 연결|
|11|✅|Model:34; PreparationModelTests:91,109, Editor:106 왕복/시간 무효화|
|12|✅|Model:34,47,57, Draft:134; PreparationModelTests:127, Editor:36 payload/진행 생성 없음|
|13|✅|Model:34,47,57; PreparationModelTests:242,257,313 직접 호출 가드|
|14|✅|View:159,349, Controller:93; Editor:116 다섯 선택/자동 재생 없음|
|15|✅|View:338,410; Editor:127 취소 확정값 유지|
|16|✅|View:389; Editor:133 rainBus 확정/현재값|
|17|✅|Controller:57, AVSoundPreviewPlayer:11; SoundPreviewControllerTests:74, AudioResourceTests:10 반복/fade/번들|
|18|✅|Controller:31,51,77; SoundPreviewControllerTests:97,131,138 종료/겹침 방지|
|19|✅|Controller:38, View:386; Editor:143 none 무음/확정|
|20|✅|Controller:59,68, View:371,389; SoundPreviewControllerTests:166, Editor:156 실패 후 계속|
|21|✅|Controller:46,52,69,101, View:352,401,410; SoundPreviewControllerTests:194 이후 늦은 결과 차단|
|22|✅|Controller:89,93, View:136,145,401; SoundPreviewControllerTests:135,250, Editor:172 이탈/복귀|
|23|✅|준비 변경 경로 저장 호출 없음; PreparationModelTests:285,291,344, Editor:208 바이트/재실행|
|24|✅|View:50,63,87,171,269,293,366,387; Editor:186 접근성 속성/숨김|
|25|✅|View:28,106,130,141,233,332,345; Editor:186 실제 accessibility5 도달/입력/확정. 장식 이동 추가 없음|

Must 25/25 충족, Should 없음. AC24/25는 코드 및 자동 접근성 계약 판정이며 실제 VoiceOver·시스템 동작 줄이기 수동 QA 완료 판정이 아니다.

## 설계 범위 이탈

기능 범위 확장 없음. 세션 준비값과 W04 요청 경계까지만 제공한다. FocusMateApp/UITestBootstrap은 후속 T3 설계의 실패 주입 계약에 해당한다. 폰트와 TimeSelectionView:82 버튼 모양은 표현 변경이다. TimeSelectionView는 최초 파일 열거 밖의 표현 변경이므로 최종 범위 문서에 명시하는 것이 적절하며 기능 명세 위반은 아니다.

## Part 1 판정

SPEC PASS — 통합 후 코드 기준 25개 AC 모두 유효.

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (0건)
없음. 이전 T2 종료 장벽 테스트는 SoundPreviewControllerTests:138에서 A 종료 gate를 보류한 상태로 B factory 결과를 반환하고 조기 play 금지 이벤트를 관찰하도록 보강되어 있다.

### Minor (3건) — 비차단, 머지 전 필수 수정으로 승격하지 않음

1. PreparationDraftTests.swift:94 — editor 생성에 쓰이지 않는 불변 draft와 before의 비교는 초안 보존 증거가 아니다. 기본값 검사와 별도 UI 왕복 검사가 있으므로 중복 assertion 정리는 후속 가능.
2. PreparationView.swift:128,301 — 성공 시 task 키보드 포커스를 요청하지만 공통 dismiss가 추가 버튼에 접근성 포커스를 요청한다. 실제 VoiceOver 관측 없는 포커스 불일치 가능성으로 유지. 취소/성공 포커스 분리와 수동 확인 권고.
3. PreparationView.swift:387,429 — 사용자 접근성 값이 stopped/loading/playing으로 DEBUG 표현과 공유된다. 한국어 상태값 분리 권고. 이름·상태 자체는 제공하므로 비차단.

### 최신 main과의 통합 확인

- AppModel.swift:7,15의 cardStudio와 :31의 준비 초안, :34의 현재 유효성, :80의 단일 soundPreview, :83 생성자 주입이 함께 존재한다.
- DestinationScreen.swift:11의 profile 전용 외부 분기와 :22의 preparation 분기가 공존한다. :33~34의 준비 여백/제목 설정은 placeholderOrTime 내부에 있어 profile 전용 화면에 적용되지 않는다.
- TimeSelectionView.swift:17,20,43,49,53의 main 큰 글자 보정과 :82의 W03 버튼 모양이 함께 존재한다.
- UITestBootstrap.swift:143의 profileRecords와 :8,28~30,92의 소리 실패 인자/주입이 함께 존재한다.
- PreparationDraft/View, SoundPreviewController, AVSoundPreviewPlayer, 리소스, W03 단위/UI 테스트를 통합 전 stash와 비교한 diff는 비어 있다.

통합에서 발견한 새 코드 결함은 없다. 공존 여부는 실제 소스로 확인했지만 실행 결과는 별도다.

## 실행 증거 및 한계

기존 mechanical-ios-build.log:336 BUILD SUCCEEDED, mechanical-ios-test.log:1230 단위321/0fail, :6944 UI78/0fail, :6954 TEST SUCCEEDED를 읽었다. 이 399건은 구 base 실행 결과다. 최신 main 통합본 전체 기계 Gate는 부모가 새로 진행 중이며 이 리뷰 시점에는 pending이다. 웹 build/edge QA 기존 PASS 역시 통합본 최종 완료 주장으로 사용하지 않는다. 시안·VoiceOver·실기기 청취 완료를 주장하지 않는다.

## Part 2 판정

QUALITY PASS — Critical 0 / Important 0 / Minor 3. 코드 리뷰 통과이며 통합본 전체 실행 게이트의 완료를 뜻하지 않는다.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 25
  ac_met: 25
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
  minor: 3
```

## 통합 실행 후속 증거

부모가 통합 기계Gate 새 직접 실행: 단위366·UI99=465/0fail, 웹31+edgeQA/0fail, 빌드 모두exit0. reports/mechanical-gate.md 참조. 위 읽기 리뷰 시점pending과 구399결과를 통합본 완료 주장으로 재사용하지 않고 별도신선실행을확인.
