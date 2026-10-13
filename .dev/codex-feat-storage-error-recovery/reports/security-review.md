# W13 저장 오류 복구 통합 보안 감사

## 통합 감사 결과

감사 입력: `prd.md`, `design.md`, `codemap.md`, `branch-diff.txt`, 실제 운영 파일 및 관련 테스트 소스. 소스 수정·빌드·테스트는 수행하지 않았다. 부모가 제공한 Mechanical Gate(native 124 + 웹 31 + edge, 0 failures, build PASS)는 보고받은 근거이며 이 감사의 직접 실행 결과가 아니다.

### 발견 사항

- **[POLICY/MEDIUM] S-01 — 정리 실패 후 확인을 다시 열고 취소하면 근거 없는 원본 불변 안내가 복원된다.**
  - 위치: `ios/FocusMate/RootView.swift:100`, `ios/FocusMate/AppModel.swift:39`, `ios/FocusMate/LocalSnapshotStore.swift:78`.
  - 근거: 저장소는 실제 제거 후 완료 확인 읽기가 실패하면 `cleanupFailed`를 반환한다(78–80행). 따라서 이 오류는 활성 원본이 이미 삭제된 상태를 포함한다. `AppRecoveryTests.swift:310`과 `StorageRecoveryTests.swift:344`도 실제 제거 후 읽기 실패를 주입하는 시나리오를 명시한다.
  - 재현 경로(소스 추적): 확인 실행 → 원본 제거 성공 → 완료 확인 읽기 실패 → 오류 화면의 정리 완료 미확인 안내 → 저장 데이터 정리 재선택 → `requestCleanup()`가 `recoveryFailure=nil`로 해제 → 취소 → RootView의 nil 분기가 `기존 데이터는 변경하지 않았어요.` 표시. 원본은 이미 없을 수 있고, 읽기 불가가 계속되면 재시도 경로에서도 같은 안내가 복원된다.
  - 정책 대조: `design.md:112`는 삭제 후 확인 실패·외부 변경에 대해 원본이 바뀌지 않았다는 잘못된 보장을 금지한다. 현재 구현은 실패 직후만 이를 지키며 후속 확인/취소에서 보장을 다시 표시한다. 이는 제품 데이터 안내 정책의 불일치이며 법규 위반을 주장하는 항목은 아니다.
  - 영향: 검증된 내부 백업은 유지되고 추가적인 무확인 삭제는 발생하지 않는다. 다만 사용자는 이미 제거되었거나 상태가 확인되지 않은 활성 원본이 그대로 있다고 오해할 수 있다.
  - 권고: 실패 안내 수명을 초기화한 후에도 근거 없는 원본 불변 문구가 재등장하지 않도록 안내 조건을 정합하게 하고, 삭제 후 확인 실패 → 새 확인 → 취소 및 실패한 재시도의 후속 표시를 회귀 검증한다. 구체적인 구현 방식은 구현 담당자가 결정한다.

### 교차 검증 결과

- **[정합] 명시적 확인·중복 실행 차단** — `AppModel.swift:39–67`에서 실패 상태와 확인 캡처를 요구하고, 실행 전에 캡처를 소비하며 `isRecovering`으로 재진입을 차단한다. `RootView.swift:90–111`의 destructive 버튼으로 확인을 분리한다. 자동 시작 경로 `FocusMateApp.swift:48–60`은 정리를 실행하지 않는다.
- **[정합] 재시도·확인 진입·취소의 무쓰기 경계** — `AppModel.swift:31–49`는 로드·원본 읽기·캡처 해제만 수행한다. `LocalSnapshotStore.swift:38–41,84–89`에는 쓰기·삭제가 없다. 복구 중 저장도 `AppModel.swift:93`에서 거부한다.
- **[정합] 동일 바이트 백업 후 정리** — `LocalSnapshotStore.swift:65–80`은 별도 내부 파일에 원본 Data를 기록하고 readback의 정확한 동등성을 확인한 다음 원본을 재확인하고 삭제한다. 백업을 decode/re-encode하지 않아 미래 형식의 알 수 없는 필드도 그대로 보존한다.
- **[정합] 백업 충돌·실패 시 삭제 차단** — 기본 `writeBackup`은 `.withoutOverwriting`을 사용한다(`LocalSnapshotStore.swift:27`). 쓰기/readback 실패는 삭제 코드 전에 종료한다(67–70행). 기존 백업 삭제·덮어쓰기 경로는 없다.
- **[정합] 확인 이후 변경·소실·정상화 보호** — `LocalSnapshotStore.swift:46–64,72–76`은 변경과 소실을 분리하고 정상 v1/v2에 `notRequired`를 반환한다. 오류 파일로 확인했어도 이후 정상화된 파일을 삭제하지 않는다.
- **[정합] 삭제 실패를 성공으로 처리하지 않음** — `LocalSnapshotStore.swift:78–81`은 remove 오류·삭제 확인 실패를 거부한다. `AppModel.swift:58–67`은 저장소 성공 이후에만 empty/cardEntry로 전환한다.
- **[정합] 기존 버전 경계** — 변경하지 않은 `SnapshotCodec.swift:18–39`에서 v1 변환, v2 읽기, 나머지 Int 버전 거부, 비숫자 버전 손상 분류, v2 저장이 유지된다. `LocalSnapshotStore.swift:92–101`의 기존 오류 원본 덮어쓰기 차단도 유지된다.
- **[정합] 내부 경로·내보내기 제외** — 운영 파일 경로는 Application Support 아래 고정 구성이다(`FocusMateApp.swift:14–22`). 백업 파일명은 고정 접두사와 타입이 UUID인 값으로 구성된다(`LocalSnapshotStore.swift:65–66`). 사용자 문자열을 경로로 받지 않는다. 변경 범위에 공유·내보내기·네트워크 전송 경로가 없다.
- **[정합] DEBUG seam 격리** — `UITestBootstrap.swift` 전체가 `#if DEBUG`로 감싸져 있고, UUID 및 seed/recovery 값 allowlist를 사용한다(1,17–27,105행). 테스트 경로는 운영 경로와 구분된다. 진단은 테스트 bootstrap이 존재할 때만 DEBUG overlay에서 제공된다(`RootView.swift:47–60`). Release 프로젝트 설정에는 DEBUG compilation condition이 없다(`project.pbxproj:54–57`). 이는 소스/설정 확인이며 Release 바이너리 직접 검사는 수행하지 않았다.
- **[정합] 추가 의존성·인젝션 표면** — diff의 변경 파일 목록은 앱 Swift 4개와 테스트 Swift 4개이며 패키지·라이브러리 추가가 없다. 변경 범위에 shell/SQL/HTML 평가, 서버 엔드포인트, 외부 URL 요청, 하드코딩 인증정보가 없다. 따라서 새 의존성의 CVE·라이선스 감사 대상도 없다.
- **[불일치] 실패 후 원본 불변 안내 금지** — S-01의 후속 경로에서 설계 계약이 유지되지 않는다.

### 명시된 한계와 미확인 근거

- 단일 MainActor 작성자 가정과 최종 비교/삭제의 비트랜잭션 경계는 `design.md:77–78`에 이미 명시되어 있다. 현재 운영 진입은 `FocusMateApp`과 `AppModel`의 MainActor를 통과한다. 외부 프로세스 경쟁 쓰기 보호를 보장한 것으로 해석하지 않는다.
- 전원 손실 내구성은 `design.md:79`에서 보장하지 않는다. readback 비교가 영구 저장 매체의 내구성까지 검증한 것은 아니며, 강제종료 시점별 실측은 이 감사에서 수행하지 않았다. 새로운 누락/취약점으로 중복 계상하지 않는다.
- VoiceOver 포커스 변경 코드와 header trait는 존재한다(`RootView.swift:39–46,87–102`). 실제 보조기술 포커스 이동 실측은 미확인이다. 접근성 관련 법적 의무나 위반을 추정하지 않으며 기능 검증 기록으로 유지한다.
- 모든 OS 백업 정책이나 앱 컨테이너 밖의 공격자에 대한 방어를 검증한 것은 아니다. 승인 범위인 앱 내부 보존·외부 내보내기 미제공 계약을 감사했다.

### 탐색 추가 항목

- `ios/FocusMateTests/AppRecoveryTests.swift` → 모델 복구 상태·실패 후 재시도·삭제 후 확인 실패 테스트.
- `ios/FocusMateTests/StorageRecoveryTests.swift` → 실제 임시 파일, 백업 충돌·readback·삭제 후 확인 실패 테스트.
- `ios/FocusMateTests/RecoveryBootstrapTests.swift` → DEBUG 실패 주입 경계 테스트.
- `ios/FocusMateUITests/StorageRecoveryFlowTests.swift` → 실제 복구 화면·원본과 백업·재실행 UI 테스트.

### 확인이 필요한 사항

추가 확인 사항 없음. 감사가 완료되었습니다. S-01은 추가 사용자 결정 없이 구현 담당자가 해소할 수 있는 계약 불일치다.

### 감사 요약

- 총 **1건** — CRITICAL: **0**, HIGH: **0**, MEDIUM: **1**.
- 분류별: RISK **0**, POLICY **1**, GAP **0**, ASSUMPTION **0**. 이미 명시된 한계는 별도 기록했으며 발견 건수에 중복 계상하지 않았다.
- **조치 필요: S-01 안내 정합성 보완.** 데이터 보존 순서·내부 경로·버전 보호·DEBUG 경계에서 배포 차단 수준의 보안 취약점은 발견하지 못했다.
