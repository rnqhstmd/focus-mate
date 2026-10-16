# W17 설계 비판 검토 1차

읽기 전용 oh-my-gx:design-critic. 빌드/테스트/실기기 실행 없음.

## MUST-ADDRESS
장시간 compact HhMM과 compact/minimal VoiceOver가 시작 표본을 계속 제공할 수 있다. 360분 세션에서 실제 잔여10분에도6h/시작시간을 제공할 수 있어 정확한 남은 시간 계약과 충돌한다. 단위 함수의 고정 시각 테스트나 미검증 기록으로 이 문제가 해소되지 않는다. 자동으로 갱신되는 표현 또는 명시적인 제품 계약 수정이 필요하다.

## CONSIDER
- 자동 진행 채움과 정지된 버스가 같은 눈금에서 다른 진도를 가리킬 수 있다. 현재 위치로 오인하지 않도록 단일한 계약이 필요하다.
- missing endDate는 새 presentation의 arrived와 기존 displayStatus/accessibility의 running이 달라질 수 있다. 모든 신규 표시 경로는 같은 상태를 사용해야 한다.
- presentation의 시간 상태와 별도 timeContent 인자의 불일치 가능성. 시간 소유권과 같은 관찰 시각 조건을 단순화할 필요가 있다.

optional total·legacy JSON·pause 우선·resume 시각 이동·clamp는 승인 범위와 일치한다. 위 차단 요소 해소 뒤 확정을 권고한다.
