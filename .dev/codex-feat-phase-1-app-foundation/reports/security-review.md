## 통합 감사 결과

감사 범위: Phase 1 SwiftUI 소스·테스트·Xcode 설정·검증 스크립트·공개 문서 및 1,487줄 branch diff. 테스트와 빌드는 재실행하지 않았으며, 제공된 보고서와 `/tmp/focusmate-review-*` 로그를 읽어 증거를 확인했다.

### 발견 사항

- [GAP/MEDIUM] 저장 파일과 정류장 문자열에 크기 상한이 없어 손상 데이터 처리 경로가 메모리 고갈로 종료될 수 있다.
  - 위치: [LocalSnapshotStore.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/LocalSnapshotStore.swift:15), [AppSnapshot.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/AppSnapshot.swift:20)
  - 근거: `Data(contentsOf:)`로 파일 전체를 먼저 적재하고, `id`와 `name`은 공백 여부만 검사한다. 파일 바이트 수와 문자열 길이를 제한하는 코드·테스트가 없다. 따라서 비정상적으로 큰 로컬 파일은 `.corrupt` 오류 화면까지 도달하기 전에 앱을 종료시킬 수 있다.
  - 범위: 네트워크 공격면은 없지만, PRD가 명시적으로 다루는 “손상 원본”에는 로컬 파일 손상·복원 오류가 포함될 수 있다.
  - 권고: 허용 파일 크기와 필드 길이를 정책으로 확정하고, 한도 초과 시 원본을 변경하지 않은 채 오류로 분류하는 AC와 회귀 테스트를 추가한다.

- [GAP/MEDIUM] 읽기 실패 상태가 영구 종착점이며 안전한 복구 경로가 정의되지 않았다.
  - 위치: [AppModel.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/AppModel.swift:27), [RootView.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/RootView.swift:71)
  - 근거: 첫 로드 실패 후 `hasLoaded`가 유지되어 재시도되지 않고, 오류 화면에는 재시도·내보내기·명시적 초기화 동작이 없다. 손상 파일을 보존하는 것은 확인되지만 사용자는 이후 앱을 사용할 수 없다.
  - 권고: 자동 삭제는 계속 금지하되, 복구 기능의 담당 Phase와 출시 차단 AC를 명시한다. 복구 UI가 후속 Phase라면 Phase 1 문서에 “오류 감지까지만 지원하며 복구 전에는 진행 불가”를 명시한다.

- [ASSUMPTION/MEDIUM] 최초·현재 정류장 데이터의 개인정보 등급과 백업·파일 보호 정책이 정해지지 않았다.
  - 위치: [AppSnapshot.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/AppSnapshot.swift:14), [FocusMateApp.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/FocusMateApp.swift:14), [LocalSnapshotStore.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/LocalSnapshotStore.swift:16)
  - 근거: 정류장 ID·이름·방향을 `Application Support`에 저장하지만, 설계·PRD에는 해당 데이터의 민감도, 기기 백업 포함 여부, 요구 파일 보호 등급이 없다. 코드에도 명시적인 보호·백업 정책이 없다.
  - 판정 경계: 실제 GPS가 아닌 가상 정류장이므로 정책 위반으로 확정하지 않는다. 현재 증거만으로 개인정보 비해당 또는 기본 보호가 충분하다고도 확정할 수 없다.
  - 권고: 출시 전 데이터 분류와 보존·백업·보호 정책을 결정하고 수용 기준에 반영한다.

- [ASSUMPTION/MEDIUM] “저장 실패 시 기존 파일 유지” 증거는 실제 파일 교체 실패를 검증하지 않는다.
  - 위치: [UITestBootstrap.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/UITestBootstrap.swift:42), [Phase1FlowTests.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMateUITests/Phase1FlowTests.swift:123), [AppFoundationTests.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMateTests/AppFoundationTests.swift:180)
  - 근거: 실패 주입 writer는 파일에 접근하기 전에 즉시 예외를 던진다. 따라서 테스트는 모델·안내 상태와 “쓰기 전 실패”의 파일 불변만 증명한다. 설계도 `.atomic` 자체와 전원 장애를 검증하지 않는다고 명시한다(`design.md:35,96`). 반면 `docs/PHASE-1-FOUNDATION.md:11,34`와 `t1-review.md:74`는 저장 실패의 파일 불변을 일반화한다.
  - 권고: 문서 주장을 “주입된 쓰기 전 실패”로 한정하거나, 실제 파일시스템 교체 실패에서 기존 바이트가 유지되는 별도 증거를 마련한다. 전원 장애·다중 writer는 현재 비보장 경계로 계속 명시한다.

### 교차 검증 결과

- [정합] 세 단계 진입 분기는 값 검증, 모델 로드, 실제 UI 테스트에 연결돼 있다: `AppSnapshot.swift:20-35`, `AppModel.swift:27-39`, `Phase1FlowTests.swift:13-41`.
- [정합] 네 기본 화면 탐색은 저장을 호출하지 않으며 후속 완료 버튼이 없다: `AppModel.swift:61-68`, `RootView.swift:24-33,67-70`, `Phase1FlowTests.swift:161-186`.
- [정합] 손상·미지원 버전은 읽기 오류로 분류되고 저장이 차단된다: `LocalSnapshotStore.swift:27-55`, `AppFoundationTests.swift:93-139`.
- [정합] DEBUG 시험 경로는 UUID 하위 디렉터리로 격리되고 소스 전체가 `#if DEBUG`로 제한된다. 제공된 mechanical gate는 Release 바이너리에서 시험 인자·진단 문자열이 발견되지 않았다고 기록한다.
- [정합] 계정·백엔드·네트워크·SSRF·인증/인가 공격면은 이번 변경에 없다. 신규 외부 의존성도 추가되지 않았다.
- [정합] 카드·지도·타이머·기록·설정 등 도메인 iOS FR은 문서에서 부분 연결 또는 미착수로 유지된다. Phase 0 시각 검증 2건도 계속 대기 상태다.
- [미확인] 파일 크기 한도, 데이터 보호·백업 정책, 실제 파일 교체 실패, 전원 장애 복구는 테스트 증거가 없다.
- [검증 증거] 기존 로그에서 native build `BUILD SUCCEEDED`, 제품 Unit 14건과 UI 10건 0 failures, 전체 하네스 포함 26건 및 `TEST SUCCEEDED`를 확인했다. AppIntents 경고 1건은 보고된 기존 메타데이터 경고와 일치한다. 이는 이번 감사에서 재실행한 결과가 아니다.

### 탐색 추가 항목

- `ios/FocusMateTests/HarnessTests.swift` → 코드맵에 개별 기재되지 않은 Unit smoke test.
- `ios/FocusMateUITests/HarnessUITests.swift` → 코드맵에 개별 기재되지 않은 UI smoke test.
- `/tmp/focusmate-review-ios-{build,test}.log` → mechanical gate가 참조한 실제 build/test 결과 로그.

### 확인이 필요한 사항

1. 최초·현재 정류장 데이터를 어떤 보호 등급으로 취급할 것인가?
   - 맥락: 현재 데이터는 실제 GPS가 아니지만 사용자의 출발·현재 위치 성격을 가질 수 있다.
   - 유형: 선택
   - 선택지:
     - (a) 위치 연관 데이터로 취급 (권장) — 백업·파일 보호·보존 정책과 출시 AC를 명시한다.
     - (b) 비민감 가상 상태로 취급 — 판단 근거와 기본 iOS 보호가 충분한 이유를 문서화한다.
     - (c) 직접 입력 — 다른 데이터 분류 및 보호 정책을 지정한다.

2. 손상 데이터 복구 기능의 책임 Phase는 어디인가?
   - 맥락: 현재 Phase 1은 원본을 보호하지만 오류 발생 후 앱 사용을 복구할 수 없다.
   - 유형: 선택
   - 선택지:
     - (a) 후속 Phase의 출시 차단 AC로 등록 (권장) — Phase 1 동작은 유지하되 복구 없이 출시 완료 처리하지 않는다.
     - (b) Phase 1에 최소 복구 추가 — 명시적 확인을 거치는 재시도·내보내기·초기화 경계를 지금 정의한다.
     - (c) 직접 입력 — 다른 복구 책임과 시점을 지정한다.

### 감사 요약

- 총 4건 (CRITICAL: 0, HIGH: 0, MEDIUM: 4)
- 조치 필요
- 확인된 SQL/커맨드 인젝션, XSS, 경로 탐색, 인증 우회, 하드코딩 시크릿, 민감 로그, SSRF, 신규 의존성 취약점은 없다.
- 다만 미확인 정책과 복구·자원 한계 때문에 프로덕션 보안 완료로 승인할 수 없다.

```yaml
security_verdict:
  critical: 0
  high: 0
  medium: 4
```

# 전체 감사 2차

## 통합 감사 결과 — Round 2

### 발견 사항

- [GAP/MEDIUM] 저장 파일과 정류장 문자열의 크기 상한이 없다.
  - 위치: [LocalSnapshotStore.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/LocalSnapshotStore.swift:15), [AppSnapshot.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/AppSnapshot.swift:20)
  - 근거: 파일 전체를 `Data(contentsOf:)`로 적재하며 `id`·`name`은 공백 여부만 검증한다. 크기 제한 코드와 테스트가 없다.
  - 권고: 기록된 방침대로 새 정책·AC를 먼저 확정하고, 한도 초과 시 원본을 보존하는 회귀 검사를 추가한다.

- [GAP/MEDIUM] 저장 오류 후 명시적 복구 수단이 아직 구현되지 않았다.
  - 위치: [AppModel.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/AppModel.swift:27), [RootView.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/RootView.swift:71)
  - 근거: 최초 읽기 실패 후 재시도되지 않으며 재시도·내보내기·명시적 정리 UI가 없다. 문서는 복구 전 진행 불가, Phase 5 정의 및 Phase 6 출시 검증으로 명시했다([PHASE-1-FOUNDATION.md](/Users/bonseung/Documents/ChatGPT/new/docs/PHASE-1-FOUNDATION.md:50)).
  - 권고: Phase 5/6 출시 조건에서 누락되지 않도록 유지한다.

- [ASSUMPTION/MEDIUM] 정류장 데이터의 분류·백업·파일 보호 정책이 미확정이다.
  - 위치: [AppSnapshot.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/AppSnapshot.swift:14), [FocusMateApp.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/FocusMateApp.swift:14)
  - 근거: Application Support에 정류장 ID·이름·방향을 저장하지만 백업 제외 여부나 파일 보호 등급이 설정되지 않았다. 공개 문서도 출시 전 확정 항목으로 남긴다([PHASE-1-FOUNDATION.md](/Users/bonseung/Documents/ChatGPT/new/docs/PHASE-1-FOUNDATION.md:54)).
  - 권고: 출시 전 데이터 분류와 백업·보호 정책을 확정하고 수용 기준에 연결한다.

### 문서 과장 재확인

**ADDRESSED**

- 공개 문서는 파일 불변 증거를 정확히 “주입된 쓰기 전 실패”로 한정했다([PHASE-1-FOUNDATION.md](/Users/bonseung/Documents/ChatGPT/new/docs/PHASE-1-FOUNDATION.md:11), [동일 문서](/Users/bonseung/Documents/ChatGPT/new/docs/PHASE-1-FOUNDATION.md:34)).
- 실제 구현도 writer가 파일 접근 전에 즉시 예외를 발생시킨다([UITestBootstrap.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/UITestBootstrap.swift:42)).
- 실제 atomic 교체 중 실패·전원 손실·다중 writer는 여전히 **미검증**이지만, 문서가 이를 보장한다고 주장하지 않는다. 따라서 이전 “증거 일반화” 발견은 해소됐으며 현재 잔존 발견 수에는 포함하지 않았다.

### 교차 검증 결과

- [정합] 이전 diff와 round-2 diff의 여섯 production Swift 파일 blob ID가 모두 동일하다. production 동작 변경은 확인되지 않았다.
- [정합] UI 테스트 blob prefix도 양쪽 모두 `dd5e9f8`이다. 전체 해시 `dd5e9f8e892afeff9d26746a7462c890dc482d94`는 상태 원장에 유지되지만, `rg` 전용 제한 때문에 이번 감사에서 별도로 재계산하지는 않았다.
- [정합] 보강된 Unit fixture는 directory/write 호출 0회와 `saveFailure == nil`을 실제로 검사한다([AppFoundationTests.swift](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMateTests/AppFoundationTests.swift:239)).
- [검증 증거] focused Unit 14건/0 failures와 전체 Unit 15건·UI 11건/0 failures 및 `TEST SUCCEEDED`를 로그에서 직접 확인했다([focused 로그](/tmp/focusmate-review-cleanup-focused.log:178), [전체 iOS 로그](/tmp/focusmate-review2-ios-test.log:739)).
- [검증 증거] 웹 로그에서 Node 31건/0 failures를 확인했다([웹 테스트 로그](/tmp/focusmate-review2-web-test.log:40)).
- [정합] 신규 외부 의존성, 인증·네트워크 공격면, 하드코딩된 시크릿은 이번 변경에서 확인되지 않았다.

### 탐색 추가 항목

- `.dev/codex-feat-phase-1-app-foundation/reports/review-deferred.md` → 잔존 MEDIUM 3건의 유예 원장.
- `.dev/codex-feat-phase-1-app-foundation/decisions.md` → 동작 변경 없이 유예하기로 한 승인 근거.
- `.dev/codex-feat-phase-1-app-foundation/diff.txt` → round-2 production/UI blob 비교 기준.

### 확인이 필요한 사항

추가 확인 사항 없음. 감사가 완료되었습니다.

### 감사 요약

- 총 3건 (CRITICAL: 0, HIGH: 0, MEDIUM: 3)
- **Phase 1 승인 범위 감사 통과**
- 단, 이는 출시 보안 완료 승인이 아니다. 기록된 MEDIUM 3건은 출시 전 후속 단계에서 해소해야 한다.

```yaml
security_verdict:
  critical: 0
  high: 0
  medium: 3
```
