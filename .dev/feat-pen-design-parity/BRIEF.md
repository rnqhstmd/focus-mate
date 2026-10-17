# Pen 시안 일치 작업 공통 지침 (모든 구현 단계 공통)

## 목표
main 앱의 기존 화면을 designs/focus-mate.pen "개선 R01~R42" 시안과 디테일까지 똑같이 맞춘다.

## 사용자 결정 (변경 금지)
1. 글꼴: 서울알림체 → **Noto Sans KR**(400/600/700) 교체. SF(시스템 폰트) 직접 사용도 시안 글꼴로.
2. 범위: **기존 화면 모양만** 맞춘다. 앱에 없는 새 기능은 이번에 만들지 않는다:
   설정 화면 신규 구현, 여행 중 소리 재생+실패 안내(R22), 다음 정류장 패널(R14), 지도 실패 배너(R21), 하차 후 홈 메모 카드(R25/R18 카드), 기록·분석을 한 패널+탭으로 재구성, 요약 화면 메모 접기/별도 저장 같은 동작 변경.
   → diff 문서의 [기능] 항목 중 "새 기능/동작 재구성"은 건너뛰고 목록에 남긴다. 단 순수 표시 변경(문구, 요소 보이기/숨기기, 배치)은 한다.
3. 기존 규칙과 시안 충돌 시 **시안을 따른다**: 카드 번호 표시(BR-4 변경), 승차권에 버스 번호·여행 시간 표시, 승차 화면 뒤로가기 숨김(AC-14 변경), 진행 중 여정의 "새 여정 시작" 노출(AC-21 변경), 시안에 없는 '데이터 출처' 줄은 마이페이지에서 빼되 접근 경로는 설정(현재 자리표시 화면) 안으로 옮겨 유지(공공데이터 출처 표기 의무).
   규칙을 바꾸면 관련 단위/UI 테스트 기대값도 함께 고친다.
4. 지도: 3D 항공사진 `.imagery(elevation: .realistic)` + 검정 33% 덮개, 경로선 초록 등 시안 표현.

## 시안 문구 처리
- "예시", "가상 노선/가상 정류장", "예시 여정 · 실제로 저장하지 않아요", 웹 프로토타입 전용 문구(예: "30초 압축 시간의 프로토타입")는 넣지 않는다. 예: "예시 여행을 마쳤어요." → "여행을 마쳤어요."
- 그 외 고정 문구는 시안 그대로.
- 예시 데이터 값(정류장명·숫자)은 맞출 대상이 아니다.

## 자료
- 시안 PNG: scratchpad/pen/<R..>.png, 수치: scratchpad/spec/<R..>.txt
  (scratchpad = /private/tmp/claude-501/-Users-bonseung-projects-focus-mate/14fef95d-d406-4015-b86e-eb6e4d215e53/scratchpad)
- 현재 앱 캡처: scratchpad/app/<R..>.png, INDEX.md
- 차이 분석: .dev/feat-pen-design-parity/diff/{G-global,A,B,C,D,E,F}.md
- 진행 기록: .dev/feat-pen-design-parity/PROGRESS.md (각 단계가 끝날 때 한 섹션 추가: 한 것/건너뛴 것(이유)/테스트 결과/남은 것)

## 작업 규칙
- 작업 경로: /Users/bonseung/projects/focus-mate/next-step-w19 만. next-step, next-step-w12 절대 금지. git stash 금지. 커밋은 하지 않는다(오케스트레이터가 함).
- 시뮬레이터: FM-W19 (UDID D1E8B30B-81E0-45F4-B3D5-ED9559500342)만. derivedData: next-step-w19/.build
- xcodebuild 동시 실행 금지(한 번에 하나).
- **테스트는 최소로(사용자 지시: 오래 걸림)**: 반복 확인은 빌드 + 바꾼 화면의 PenParityCaptureTests 개별 메서드만. 기존 UI/단위 테스트는 바꾼 문구·식별자·규칙을 직접 참조하는 테스트 메서드만 골라 **한 번의 xcodebuild 호출로 묶어 단계 끝에 1회**. 넓은 스위트·같은 테스트 반복 실행 금지. 전체 회귀는 맨 마지막에 오케스트레이터가 1회.
- 캡처 재실행 후 scratchpad/app/<R..>.png를 시안과 직접 비교해 남은 차이를 고친다(최소 1회 반복).
- 상태바 9:41 고정: `xcrun simctl status_bar D1E8B30B-81E0-45F4-B3D5-ED9559500342 override --time 9:41` (재부팅 후 재적용)
- Xcode synced folder라 새 Swift/리소스 파일은 pbxproj 수정 없이 ios/FocusMate/ 아래 두면 된다(폰트는 Info.plist UIAppFonts 확인).
- 접근성 식별자(accessibilityIdentifier)는 가능한 유지. 없애야 하면 해당 테스트 수정.
- 큰 글자(Dynamic Type) 대응은 기존 수준 유지(깨뜨리지 않기).
