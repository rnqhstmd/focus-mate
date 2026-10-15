# T9+T10 태스크 리뷰 (sonnet, scoped) — R0
SPEC FAIL(설계 요구 '위젯 리터럴 없음' 부분 충족) · QUALITY FAIL · C0 · Important 3 (1 [동작결함]) · Minor 4
I1 compactLeading 접근성 라벨 리터럴 [동작불변] / I2 제목 조합·displayStatus 위젯 중복 [동작불변] / I3 .combine+label이 운행 중 카운트다운을 VoiceOver에서 가림 [동작결함, SwiftUI — 실기기 M-9로 확인]
Minor: expanded 접근성 정책 / minimal 폭 / 배경색 매직값 / pbxproj 그룹 순서
처리: 재현 RED R1(Display 함수 3종) → 세션 수정 → 재리뷰. I3는 단위 테스트 불가(SwiftUI 접근성 트리) — 구조 수정 + M-9 점검 항목 보강

## 재리뷰 R1
I1·I2·I3 ADDRESSED · SPEC PASS · QUALITY PASS · Minor 3 (유예)
- 일시정지·만료 때 설명 라벨과 시간 텍스트가 이중으로 읽힘(정지 시간 숨김 고려)
- 위젯 private statusName 이름이 Display.statusName과 같음
- Display 테스트 접근성 문자열 중복 검증
