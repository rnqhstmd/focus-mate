# 작업 계획

| ID | 작업 | 도메인 | 요구사항 | 의존 | 작업 위치 | 상태 |
|----|------|--------|----------|------|-----------|------|
| W00 | 도메인 저장 구조 확장(버전 1→2) | 공통 | Phase 1 `app-state.json` 확장 | - | feat/domain-storage-schema-v2 | 완료 |
| W01 | [P2] 카드 발급·접촉 카드 | card | card FR-3 | W00 | - | 대기 |
| W02 | [P2] 첫 출발지·시간·버스·도착지 선택 | journey | journey FR-7, FR-8 | W00 | - | 대기 |
| W03 | [P2] 준비 허브·태그·소리 | journey | journey FR-9, FR-10 | W02 | - | 대기 |
| W04 | [P2] 승차권·승차 태그 | journey | journey FR-11 | W01, W03 | - | 대기 |
| W05 | [P3] 실제 분 타이머·일시정지 | journey | journey FR-5 | W04 | - | 대기 |
| W06 | [P3] MapKit 가상 코스 | journey | journey FR-6 | W05 | - | 대기 |
| W07 | [P3] 포기·이어가기·생명주기 | journey | journey FR-13, NFR-2(Simulator) | W05 | - | 대기 |
| W08 | [P4] 완료·메모 저장 모델 | records | records FR-5, NFR-1 | W00 | codex/feat-completed-record-memo | 완료 |
| W09 | [P4] 하차 태그·요약·기록·분석 | 통합 | journey FR-12, records FR-6 | W05, W08 | - | 대기 |
| W10 | [P5] 카드 꾸미기 | card | card FR-4, NFR-2 | W01 | - | 대기 |
| W11 | [P5] 마이페이지 | card | card FR-5 | W01, W08 | - | 대기 |
| W12 | [P5] 접근성·동작 설정 | preferences | preferences FR-3 | - | - | 폐기 |
| W13 | [P5] 저장 오류 복구 | preferences | preferences FR-4 | W00 | codex/feat-storage-error-recovery | 완료 |
| W14 | [P6] 실기기 QA·출시 준비 | 통합 | journey NFR-2(실기기), preferences NFR-2 | W04, W06, W07, W09, W10, W11, W13 | - | 대기 |

요구사항 ID는 `context/{도메인}/status.md`의 원장을 따른다. `[P2]`는 [개발 단계](../docs/DEVELOPMENT-PHASES.md)의 Phase다.

실행 묶음(위 `의존` 열에서 계산한 순서다. 의존을 바꾸면 이 표도 다시 계산한다):

| 묶음 | 병렬 실행 가능 | 선행 묶음 |
|------|----------------|-----------|
| 1 | W00 | - |
| 2 | W01 · W02 · W08 · W13 | 1 (W00) |
| 3 | W03 · W10 · W11 | 2 |
| 4 | W04 | 3 (W03) |
| 5 | W05 | 4 |
| 6 | W06 · W07 · W09 | 5 |
| 7 | W14 | 6 |

- 가장 긴 경로: W00 → W02 → W03 → W04 → W05 → W06/W07/W09 → W14 (7단계).
- 같은 묶음이라도 W03·W04는 아래 Phase 0 확인이 끝나야 착수한다.
- 묶음 2의 W08·W13은 W00이 만든 저장 섹션만 고치고 저장 파일 구조를 다시 바꾸지 않는다.

착수 조건:
- W03은 Phase 0의 **태그 선택 중간 화면** 확인, W04는 **최신 승차 단말기** 확인이 끝나야 착수한다([Phase 0 남은 확인](../docs/PHASE-0-BASELINE.md#남은-확인)).
- W14는 서명·배포 정보와 실기기가 준비돼야 착수한다.
- 모든 작업은 새 화면에 VoiceOver·Dynamic Type·동작 줄이기를 적용한다(preferences FR-3). 별도 점검 작업(W12)은 두지 않는다.

의존 근거:
- W00: Phase 1 버전 1 스냅샷을 확장해 카드·여정·기록 저장 섹션과 마이그레이션을 먼저 만든다. 여러 작업이 같은 저장 파일을 동시에 고치지 않게 하기 위한 선행이다.
- W02→W03→W04: 시간·버스·도착지 선택값을 준비 허브가, 완성된 준비를 승차권이 소비한다. W04는 W01의 카드 뷰도 사용한다.
- W05: 승차 접촉으로 생성된 진행 여정이 있어야 타이머가 돈다. W06은 W05가 만드는 집중 화면 위에 지도를 올린다.
- W09: 진행 여정(W05)과 완료·메모 저장 모델(W08)이 있어야 하차 완료를 만든다.
- W11: 마이페이지의 완료 여정 수·시간은 W08의 집계를 읽는다.
- W12(폐기, 2026-10-13): 앱 내 동작 줄이기 토글 없이 시스템 설정만 따르기로 하면서 사용자에게 보이는 기능이 남지 않았다. 시스템 값은 SwiftUI `accessibilityReduceMotion`으로 바로 읽고, 접근성은 각 작업이 새 화면에 적용한다.
