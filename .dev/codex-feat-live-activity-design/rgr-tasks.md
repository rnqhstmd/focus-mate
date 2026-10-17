# W17 RGR 태스크

| 순서 | AC | RED | IMPLEMENT | 파일 소유 |
|---|---|---|---|---|
| T1 | AC1~3 데이터·동기화 | legacy Codable, 총시간 전달, pause/resume, 추가 요청 없음·종료 회귀 | 선택적 totalSeconds와 기존 동기화 연결 | Attributes, Policy, Sync 및 Policy/Sync/Cleanup 테스트 |
| T2 | AC1~5 표시·접근성 | 시간/진행 표현·경계값·상태 정규화·전체 이름 | Display, 네 Live Activity 표면, 미리보기 | Display, Widget, Preview 및 Display/Presentation 테스트 |

T1→T2 순차. 같은 파일을 여러 태스크에 중복 배정하지 않는다. 시각 대조·실제 Island·VoiceOver 청취 증거는 단위 테스트와 별도로 기록한다.
