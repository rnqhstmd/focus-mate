## Trust Ledger

### 위험 수용
- [AC-19M 수동 확인으로 분리 — 사용자 결정] 장식 비노출·완료 후 포커스. [AC-19 장식 비노출 자동 검증 불가] iOS 27 XCUITest가 accessibilityHidden SwiftUI 하위 요소도 자동화 트리에 노출해 card.face descendants 수로 VoiceOver 노출을 판정할 수 없음(덤프 2회 확인). 구현은 그림 전체 accessibilityHidden + 단일 요소. 수동 VoiceOver 확인 필요 (implement/T5 fix R2)
- [AC-19 완료 후 포커스 이동 자동 검증 불가] @AccessibilityFocusState 바인딩은 XCUITest로 관찰 불가. focusTarget 로직만 단위 검증 — 수동 VoiceOver 확인 필요 (design/test-architect)
- [발급 진동 체감 미검증] 그라데이션 패턴(약→강+끝 탭)은 구조만 단위 검증. 실기기 체감·미지원 기기 무오류는 수동 확인 필요 (design)

## 통합 감사 (review)
security-auditor: CRITICAL 0 · HIGH 0 · MEDIUM 5
- [GAP/MEDIUM] 발급 화면 중 파일이 외부 손상되면(writeBlocked) 재시도가 영구 실패하고 탈출 경로 없음. 원본은 보존(BR-6). 권고: W13 이관 명시 또는 storageError 전환.
- [GAP/MEDIUM] 보충·발급 재저장이 v1 원본을 덮어쓰고 v2 미지 키를 버림. 권고: 같은 버전에 필드 추가 시 미지 키 보존 정책을 W10 전 결정.
- [ASSUMPTION/MEDIUM] BR-4는 W01 화면에서만 검증. PassIdentity.numberText 공개·String(describing:) 노출 가능. 권고: W04·W11 AC에 AC-16식 전체 요소 순회.
- [ASSUMPTION/MEDIUM] HarnessUITests가 운영 저장소 사용 → 보충 쓰기 발생 가능, 실행 순서 의존. 권고: --fm-ui-test-id 사용.
- [ASSUMPTION/MEDIUM] issuedAt 범위·오프셋/소수초 관용성 미검증, ID는 기기 로컬 의미만(10^8 공간). 권고: PRD 가정 추가, AC-13 변형 테스트.
- 정합 확인: DEBUG 장치 Release 유출 없음, UI 테스트 경로 격리, BR-5·BR-6 원본 보존, 실패 시 무변경, 연타 직렬화, BR-4 노출 경로 없음(로그 0), CSPRNG.

reviewer Part 2: Critical 0 · Important 2 ([동작불변]) · Minor 23
- [Important/동작불변] IssuanceFeedback 햅틱 엔진 재생 후 계속 실행(isAutoShutdownEnabled 미설정) → 정리 모드 수정
- [Important/동작불변] CardIssuanceFlowTests testAC19 깨짐 명명 주석이 제거된 단언을 언급, 안내 순서 미검증 → red-writer 수정

## 통합 감사 (review R2)
security-auditor R2: CRITICAL 0 · HIGH 0 · MEDIUM 3 잔존 (신규 0). 1회차 #1·#2 수용·이관, #5 ID 부분 해소(A10).
- [MEDIUM 잔존→이관] #3 BR-4 후속 화면 검증 — W04·W11 AC에 AC-16식 전체 순회 검사 이관(prd.md 이관 항목)
- [MEDIUM 잔존→유예] #4 HarnessUITests 운영 저장소 사용 — `--fm-ui-test-id` 추가는 후속 정리(테스트 하네스, Phase1 헬퍼 통합과 함께)
- [MEDIUM 잔존→이관] #5 issuedAt 오프셋·소수초·극단값 — PRD 가정 A11, W13 이관
reviewer R2: SPEC PASS (AC 21/21) · QUALITY PASS · 1회차 Important 2건 ADDRESSED · 신규 Minor 2
- [기존 실패 — W01 무관] LargeTextUITests.testTimeScreenAtLargestTextSizeKeepsProceedReachableAndCompletesSixtyMinuteFlow (W02 시간 선택 화면, XXXL에서 후보 탭 후 진행 버튼이 "버스와 도착지를 선택하세요"로 남음). origin/main(2c40748) 단독 실행에서도 동일하게 실패 확인 — W01 병합과 무관. 사용자 "다 진행" 지시로 진행, W02 후속 수정 필요 (complete/병합 후 검증, 2026-10-14)
