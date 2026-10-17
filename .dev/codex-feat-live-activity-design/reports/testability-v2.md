## Testability 평가 (test-architect)

### 컴포넌트별 테스트 전략

| 컴포넌트 | 레이어·러너·격리 전략 | AC |
|---|---|---|
| ContentState | 동작·XCTest. 실제 Codable 누락/null/정상 값과 외부 JSON 계약. 외부모의·앱 저장 migration 없음 | AC3 |
| Policy·Sync | 동작·XCTest. 고정Date·ManualJourneyClock·FakeProgressSaver·RecordingLiveActivityGateway로 payload·호출수 관찰 | AC1~3 |
| Presentation/remaining/progress | 동작·XCTest. 주입 now·독립 literal 기대값, countdown/fixed 및 timer/fixed/hidden, missing-end/stale/paused 정규화 | AC1~4 |
| AccessibilitySummary | 동작·XCTest. 전체 이름·상태 보존, 잔여 숫자 중복 없음. 단일 presentation.time 사용 | AC4~5 |
| 표면 렌더 분기 | 동작 경로는 빌드/미리보기/실제 렌더링. native/fixed/arrived 시간 요소 연결을 확인 | AC1~5 |
| 색·눈금 간격·glyph·폰트 | 표현 — 단위 assert 대상 아님. 승인 시안과 실제 캡처를 대조 | 시각 검증 |

### 격리 RED 데이터

total1800, remaining1122/135→0.3766667/0.925; 시간 범위min(now,end)...end·진행 범위(end-1800)...end; 60초 후1062·0.41·추가gateway요청0; pause300초후불변·resume새종료시각; nil/0/-1total hidden;1900/-5remaining0/1; 소수초ceil; legacy누락/null; missing-end/stale/arrived; stale paused; fixed5/599/5999/7200/21600→0:05/9:59/99:59/120:00/360:00.
생산 포맷으로 expected 생성·sleep 금지. 새 계약 승인 후 HhMM 전용 테스트는 만들지 않는다. native 타이머의 실제 장시간 표시는 범위 단위 테스트와 렌더 검증을 나눈다.

### 런타임 검증 게이트

- compact120:00/360:00의 실제 가독성·잘림.
- native 진행 채움의 실제 갱신·정지·재개.
- minimal Image.accessibilityValue(nativeTimerText)의 SDK 수용·시간 경과 후 재낭독. 실패 시 별도 native 시간 요소를 검증하며 정적 잔여로 대체하지 않는다.
- 모든 표면 running/paused/arrived의 실제 이름·상태·시간 단일 낭독.
- Reduce Motion 전후 실제 정보 보존. 입력 없는 pure함수 두 번 비교로 설정 검증을 대체하지 않는다.

### Testability Score: 8/10

조건부 TESTABILITY PASS. 테스트 가능성은 충족하며 현재 RED 진입 차단은 PRD 변경 승인이다. 실제 SDK·렌더·VoiceOver 통과는 아직 주장하지 않는다. 이번 평가에서 테스트·빌드·파일 수정을 하지 않았다.
