# W13 저장 오류 복구 통합 보안 재감사 — Round 2

## 통합 감사 결과

**감사 통과. 이전 S-01은 ADDRESSED이며 신규 발견은 없다.**

감사 입력은 최신 main 통합 기준 `branch-diff-r2.txt`, `reports/review-fix-diff.txt`, 이전 `reports/security-review.md`, 현재 AppModel/LocalSnapshotStore/RootView/DEBUG seam, 새 이력 회귀 테스트와 기존 PRD·설계 계약이다. 소스 수정·테스트·빌드는 수행하지 않았다. 아래 실행 근거는 저장된 로그를 직접 읽어 확인한 결과이며 감사자가 새로 실행한 결과가 아니다.

### 이전 발견 재판정

#### S-01 [POLICY/MEDIUM] — ADDRESSED

- 이전 문제: 활성 원본 삭제는 성공했으나 완료 확인 읽기가 실패한 뒤, 정리 확인을 다시 열고 취소하면 `recoveryFailure=nil`로 인해 `기존 데이터는 변경하지 않았어요.`가 재등장했다.
- 수정 근거: `ios/FocusMate/AppModel.swift:25`의 `hasAttemptedCleanup`은 초기 false다. `confirmCleanup()`의 실패 상태·유효 캡처·비실행 guard를 통과한 뒤에만 true가 된다(53–57행). `retryLoad`·`requestCleanup`·`cancelCleanup`은 이 값을 해제하지 않는다(32–50행).
- 표시 근거: `ios/FocusMate/RootView.swift:100–106`은 최신 실패 안내가 있으면 이를 표시하고, 실패 안내가 해제되어도 정리 시도 이력이 있으면 중립적인 복구 선택 안내를 표시한다. 이력이 없는 최초 오류 화면만 기존 원본 불변 안내를 사용한다.
- 삭제 후 확인 실패 검증: `ios/FocusMateTests/RecoveryHistoryTests.swift:11`은 실제 임시 파일을 삭제한 다음 활성 URL 읽기에 권한 오류를 주입한다. `cleanupFailed`, 실제 원본 없음, 동일 바이트 백업, 재확인·취소·실패한 재시도 뒤 이력 유지까지 검증한다(33–51행).
- guard 검증: 같은 파일 56행 테스트는 loading/ready/확인 없는 failed 호출이 이력을 생성하지 않고 추가 읽기·삭제도 수행하지 않는지 확인한다.
- 화면 검증: `ios/FocusMateUITests/RecoveryHistoryFlowTests.swift:14`는 정리 실패 → 새 확인 → 취소 후 원본 불변 문구가 없고, 복구 선택지가 남으며 원본과 검증 백업 바이트가 보존되는지 확인한다(33–48행). UI의 remove 실패와 단위의 실제 삭제 후 확인 실패를 구분해 검증한다.
- RED/GREEN 근거: `t4-red.log:580–583,662,685`에 이력 assertion 및 해당 UI 문구 assertion의 실제 실패가 있다. `t4-green.log:220–223,310–324`에 같은 테스트 통과와 `TEST SUCCEEDED`가 있다. 단순 컴파일 실패만을 RED 근거로 삼지 않았다.
- 통합 근거: `integrated-ios-test.log:682–686,1447–1449`에도 신규 단위 2개와 UI 1개가 통과했다. 따라서 최초 발견의 후속 상태 경로가 코드 및 실행 로그에서 해소되었다.

### 신규 발견 사항

없음. 확인 범위에서 새 RISK/POLICY/GAP/ASSUMPTION 항목을 뒷받침하는 근거를 발견하지 못했다.

### 교차 검증 결과

- **[정합] 보존 선행·삭제 완료 판정** — `LocalSnapshotStore.swift:65–81`은 기존 백업을 덮어쓰지 않는 별도 파일에 원본 바이트를 기록하고, 정확한 readback 비교 및 활성 원본 재확인 이후 삭제한다. 삭제 후 파일 없음 확인까지 성공해야 반환한다. S-01 수정은 이 I/O 절차를 변경하지 않는다.
- **[정합] 명시적 확인·실패 상태 유지** — `AppModel.swift:53–69`의 확인 guard·캡처 소비·복구 중 차단·성공 시에만 ready 전환이 유지된다. 이력 추가는 확인 권한이나 파일 접근 권한을 넓히지 않는다.
- **[정합] 정상 데이터·미지원 버전 보호** — `LocalSnapshotStore.swift:46–64`의 변경/소실 검증과 정상 v1/v2 삭제 거부, `SnapshotCodec.swift:18–39`의 버전/내용 검증 및 v2 저장이 유지된다. 최신 main의 기록 정렬은 decode 결과에 적용되지만 백업은 decode 결과를 재직렬화하지 않고 원본 Data를 그대로 쓴다.
- **[정합] 최신 기록 모델과 저장 차단 통합** — 현재 `AppModel.swift:113–152`의 기록 변경 진입은 ready snapshot을 요구한다. 복구는 failed 상태에서 실행되며 기존 `save`도 `isRecovering`을 확인한다(94–104행). 읽은 통합 경로에서 복구 중 기록 쓰기가 오류 원본을 우회해 변경하는 경로는 발견하지 못했다.
- **[정합] 내부 경로 유지** — 운영 경로는 Application Support 하위 고정 경로이며 백업명은 UUID로만 구성된다. W13 diff와 수정 diff에 공유·내보내기·외부 전송 또는 사용자 문자열 기반 경로 추가가 없다.
- **[정합] DEBUG 경계 유지** — `UITestBootstrap.swift:1–105`의 DEBUG 조건과 UUID/옵션 allowlist, `RootView.swift:47–60`의 테스트 bootstrap 조건부 진단이 유지된다. `FocusMateApp.swift`의 DEBUG 분기와 `project.pbxproj:54–57`의 Release 설정에도 테스트 진단을 Release에 포함시키는 변경은 없다. Release 바이너리 직접 검사는 수행하지 않았다.
- **[정합] 새 의존성·권한 없음** — Round 2 diff는 앱 Swift 4개와 테스트 Swift 6개다. 추가 패키지, 외부 서비스, 권한, 인증정보 또는 명령 실행 경로는 없다. 새 의존성 CVE/라이선스 감사 대상은 추가되지 않았다.

### 실행 근거 및 기존 한계

- `integrated-ios-test.log:781–783,2067–2077`: Unit **141**, UI **21**, 합계 **162**, **0 failures**, `TEST SUCCEEDED`.
- `integrated-ios-build.log:310`: `BUILD SUCCEEDED`.
- `integrated-node-test.log:40–43`: **31 tests / 31 pass / 0 fail**. 후속 edge 점검의 PASS 출력도 확인했다.
- `integrated-node-build.log`: 기존 prototype 패키징 완료 출력 확인. exit 0은 부모의 실행 결과로 전달받았다.
- 단일 MainActor 작성자 경계, compare/delete 비트랜잭션, 전원 손실·강제종료 시점별 내구성 미실측, VoiceOver 실제 포커스 이동 미실측은 기존에 공개된 한계다. 이력 수정이 이를 해결했다고 주장하지 않으며 신규 발견으로 중복 집계하지 않는다.

### 탐색 추가 항목

- `ios/FocusMateTests/RecoveryHistoryTests.swift` → 실제 삭제 후 확인 실패와 후속 동작에서 이력 유지, guard 무동작 검증.
- `ios/FocusMateUITests/RecoveryHistoryFlowTests.swift` → 실패 후 재확인·취소의 안내 정합성과 실제 저장물 보존 검증.

### 확인이 필요한 사항

추가 확인 사항 없음. 감사가 완료되었습니다.

### 감사 요약

- 이전 발견: **1건 ADDRESSED / 0건 NOT ADDRESSED**. S-01의 원래 등급은 POLICY/MEDIUM이며 해소 이력을 유지한다.
- 신규 발견: **0건** — CRITICAL **0**, HIGH **0**, MEDIUM **0**.
- 현재 미해소 발견: **0건** — RISK **0**, POLICY **0**, GAP **0**, ASSUMPTION **0**.
- **감사 통과.** 기존에 명시한 검증 한계는 그대로 유지한다.
