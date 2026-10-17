# W18 T1 품질 리뷰

최종 판정: PASS. 기존 P2 2건 모두 수정 확인, 잔여 finding 0건. PRD와 design.md v2를 먼저 읽고 지정된 Shared 생산 파일 4개만 검토했다. T2/T3 구현은 범위 밖이다. 아래 최초 발견 이력은 보존한다.

## 재리뷰 결과
- stale 표현: WidgetPresentation.swift:40–42에서 stale에는 `기준일`/`해당 주`, fresh에는 `오늘`/`이번 주`를 사용한다. 기존 기준일·업데이트 필요 및 수치는 유지한다. 첫 finding ADDRESSED.
- 태그 구조: WidgetSnapshot.swift:78–83에서 4개는 앞 3개 named와 마지막 remainder만, 3개 이하는 named만 허용한다. 기존 중복 ID·양수 분/횟수·합계 검증도 유지한다. 두 번째 finding ADDRESSED.
- 부모 보고 실행 근거: t1-fix-red-run.log 23건/9 assertion failures → t2-red-t1-fix-green.log 관련 23건/0실패 → t2-green-run.log Widget 전체 단위 68건/0실패. 로그를 이번 리뷰에서 직접 재검증하거나 테스트를 재실행하지 않았다.
- 최초 리뷰 뒤 별도 RED-writer 역할에서 회귀 8개를 추가했으며 기존 28개 본문은 변경하지 않았다. 해당 역할의 생산 코드 사전 노출 한계는 t1-fix-red.md에 기록했다. 이번 재리뷰에서는 테스트를 수정하지 않았다.

## Findings

### P2 — stale 접근성 요약이 이전 날짜 값을 오늘/이번 주로 설명한다
- 위치: `ios/Shared/WidgetPresentation.swift:40-42`
- `content(.stale(snapshot))`도 항상 `오늘 N분`과 `이번 주 N분`을 합성한다. 예를 들어 일요일 공유본을 월요일에 읽으면 이전 일요일·이전 주 합계를 현재 오늘·이번 주로 낭독한다.
- 앞에 기준일과 업데이트 필요를 붙여도 같은 요약 내부의 상대 날짜 표현은 잘못된 현재 시점 주장을 남긴다. PRD의 자정 이후 자료를 오늘 현재값으로 설명하지 않는 계약에 어긋난다.
- 요구: stale 상태의 분석 날짜 표현을 저장 기준일/해당 주의 값으로 일관되게 구분하고 자정 및 주 경계 사례를 검증한다.

### P2 — 상위 3개와 기타의 구조를 위반한 공유본도 valid로 승인한다
- 위치: `ios/Shared/WidgetSnapshot.swift:75-90`
- 검증은 태그 수 <= 4와 ID 중복·합계만 검사한다. 네 항목 모두 `.named`인 공유본, 또는 상위 태그 없이 `.remainder`만 있는 비어 있지 않은 공유본도 합계가 맞으면 통과한다.
- 계약은 전체 태그 배열이 아니라 상위 3개와 필요한 경우 나머지 기타를 공유하며, malformed 자료는 접근 불가여야 한다. 현재 검증은 이 구조적 손상을 정상 분석으로 노출할 수 있다.
- 요구: named/remainder 구성과 기타 위치에 대한 상위 3+기타 계약을 검증 경계에 반영한다. 원본을 재집계할 필요는 없다.

## 확인한 경계
- DTO에는 task/memo/cardID/recordID 목록이 없다.
- 저장은 유효성 인코딩 후 `.atomic` 쓰기이며 선삭제가 없다. 읽기 실패 unavailable과 디코딩 malformed를 구분한다.
- URL은 중복/알 수 없는 필드, 미래 발급, 24시간 만료를 검사하고 period 누락은 week로 유지한다.
- freshness는 기준일/시간대/30분을 판정하고 오류 표시에는 snapshot/진행값을 제공하지 않는다.
- validEmpty에서도 여정 정보를 보존한다.

## 최초 리뷰 검증 한계
테스트·빌드를 실행하지 않았고 테스트 파일을 변경하지 않았다. 부모가 전달한 30건/0실패 결과는 재검증하지 않았다. 실제 원자 교체 실패·시스템 위젯 표시·VoiceOver 결과를 이 정적 리뷰로 주장하지 않는다.
