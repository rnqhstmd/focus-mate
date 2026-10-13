## Trust Ledger

### 통합 감사 (review)
- [ASSUMPTION/MEDIUM] 저장은 메모리 스냅샷으로 파일 전체를 교체한다(AppModel+JourneyStart.swift:25-28, LocalSnapshotStore.swift:32-42).
  - 근거: 같은 AppModel 인스턴스만 쓰면 안전. BR-6(W01과 서로 덮어쓰지 않음)은 모든 쓰기가 AppModel.save를 거친다는 가정에 기댐.
  - 권고: W01 병합 시 저장 호출이 모두 AppModel.save를 거치는지 확인. → 유예(후속 인계)
- [GAP/MEDIUM] 검색 화면 저장 실패 문구가 원인과 무관하게 "다시 눌러 주세요"이고 VoiceOver 알림이 없다(InitialStationSearchView.swift).
  - 권고: 재시도 가능 원인(writeFailed)과 아닌 원인 문구 구분, 접근성 알림. → 유예(동작 변경 동반)
- [ASSUMPTION/MEDIUM] 저장된 정류장 id가 RouteStops에 없으면 시간 선택이 막힌다(RouteData.swift:33-36).
  - 근거: Phase 1 운영 코드는 정류장을 저장한 적이 없어 현재 실제 사용자 데이터에서는 생길 수 없다. 테스트 시드는 순환 정류장 id와 맞다.
  - 권고: W04 이후 재검토(설계 후속 인계 4). → 유예
- [GAP/MEDIUM] 큰 글자에서 후보 정보 축약 → 리뷰 Important 1과 같은 항목. 사용자 결정으로 두 줄 전체 표시로 정리.
- [GAP/MEDIUM] VoiceOver 중복 낭독("25분, 25" — 테스트 식별용 accessibilityValue)·시간 변경 시 선택 해제 알림 없음(TimeSelectionView.swift).
  - 권고: 테스트 값 노출 방식 변경, 접근성 알림 추가. → 유예(테스트 계약 변경 동반)
- [GAP/MEDIUM] 동작 줄이기 대응은 시스템 전환에 맡기고 앱 애니메이션 0건이며 실기기 확인 기록이 없다.
  - 권고: 실기기 확인 기록. → 위험 수용(아래)
- [ASSUMPTION/MEDIUM] confirmInitialStation이 카탈로그 소속 옵션인지 검증하지 않고, StationOption.init이 index 범위를 검사하지 않는다.
  - 근거: 현재 호출자는 검색 결과(카탈로그 상수)뿐.
  - 권고: 다른 호출자가 생기기 전 방어 코드. → 유예(동작 변경 동반)
- 정합 확인: 정류장 1회 저장·영역 보존, 재검색 차단, 저장 실패 시 상태 일관성, W00 원본 보존·쓰기 차단 유지, 검색어 비저장, DEBUG 진단·부트스트랩 Release 제외(SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG는 Debug 구성만), FR-12 메모리 전용.

### 통합 리뷰 Part 2 요약 (reviewer)
- SPEC PASS 26/26. Quality: Critical 0, Important 3, Minor 28.
- Important 1 [동작불변] 큰 글자 후보 정보 축약(TimeSelectionView.swift:60-70) → 사용자 결정: 두 줄로 전부 표시. 정리 모드.
- Important 2 [동작불변] 선택 상태가 시각적으로 구분되지 않음(InitialStationSearchView·TimeSelectionView) → 선택 항목에 체크 표시. 정리 모드.
- Important 3 [동작불변] VoiceOver 1분 증감(AC-23)·동작 줄이기(AC-24) 실기기 수동 확인 기록 없음 → 사용자 결정: 미검증으로 기록(아래 위험 수용).

### 위험 수용
- [실기기 미검증] VoiceOver로 휠 한 칸 = 1분 증감(AC-23)과 시스템 "동작 줄이기" 켠 상태의 화면 전환(AC-24)은 시뮬레이터 자동 테스트로 검증할 수 없어 실기기 확인 없이 진행한다. 실기기 검증은 Phase 6(W14)에서 일괄 수행. (review/Step 4, 사용자 결정 2026-10-13)
- [verify 게이트 생략] 리뷰 정리(큰 글자 후보 두 줄·선택 체크 표시) 후 전체 테스트·gx-verify를 다시 돌리지 않고 커밋·PR. 정리 전 Mechanical Gate(iOS unit 126 + UI 38, node build/test) 통과. 정리 후 영향 UI(LargeText·TimeSelection·FirstStationSearch)는 PR 생성 시점에 실행 중. (complete/Step -1, 사용자 지시 2026-10-13)
