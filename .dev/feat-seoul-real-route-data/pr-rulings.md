## Rulings
- ±1분 도착 규칙 유지 — 후보 0건 비율 전수 평균 10.7%(노선 1개 정류장 17~27%, 5개 이상 0%) 수용 (사용자 2026-10-15)
- AC-36은 하차 경로로 검증 — W09 규칙상 도착 여정은 하차로만 끝남 (사용자 2026-10-15)
- 스크립트 보안 보강을 W16b T1에 포함 (사용자 2026-10-15)
- 옛 저장(v1~v4) 이전 시 원본 백업 없음, 진행 여정 소실을 PRD에 명시 (Q4 결정 근거, security MEDIUM 권고 미수용)
- `AppModel.init(routeData:)` 기본값은 옵셔널 nil → 본문에서 생성(메인 액터 기본 인자 제약)
- main.bound 빈 값 요소 유지(AC-42 UI 검증이 요소 존재를 봄)

## Deferred
- [security MEDIUM] 스크립트·로더 이름/id 공백·500자 검증(현재 실데이터 회귀 테스트로 감시) — 월별 갱신 전
- [security MEDIUM] xlsx 합계 압축 해제 상한, sharedStrings iterparse, MemoryError 변환
- [security LOW] 공유 문자열 음수 인덱스, 입력 해시 TOCTOU, --base-date/--min-join-rate 검증, NODE_ID 이름·좌표 불일치 보고, StationSnapshot 이름 상한
- [reviewer Minor] retryLoad 복구 후 BR-16 재확인 없음, RouteCatalogStore 로드 오류 진단 로그, 오프라인 테스트 URLProtocol 한계 주석, nameTooLong 중복 단언, 로딩 중 메인 '새 여정' 버튼 비활성화
- [W14] 실기기 VoiceOver·큰 글자·지도 확인
