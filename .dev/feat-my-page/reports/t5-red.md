# t5 RED report

Status: DONE_WITH_CONCERNS

## 파일
- ios/FocusMateTests/ProfileStatsDisplayTests.swift (3 케이스: 0건, 3회/65분, unavailable)
- ios/FocusMateUITests/ProfileUITests.swift (21 케이스: 진입/제목, 순서, 헤드라인·서브헤드, 카드명·태그라인, 통계 라벨, 카드 라벨·FM- 미노출, 스냅샷 트리 FM- 검사, 0건 값, 3건 값, 한국어 접근성 라벨, statsError 없음, 저장 불변, 뒤로, 버튼 쿼리, 카드꾸미기 열기/뒤로, 설정 열기/뒤로, 버튼 구성, XXXL 가시영역, XXXL 설정 탭)
- ios/FocusMateUITests/Phase1FlowTests.swift: destinations에서 마이페이지 1줄만 제거

코드 전문은 위 파일 경로 참조 (각 테스트 위 `// 깨짐 명명:` 주석 포함).

## 실패 확인
명령: FOCUSMATE_SIMULATOR_ID=7815DB9D-633D-441D-B3B5-C7DABF274EB8 FOCUSMATE_DERIVED_DATA=.build/ios-red python3 scripts/check-ios.py test ios/FocusMateTests/ProfileStatsDisplayTests.swift ios/FocusMateUITests/ProfileUITests.swift

결과: 컴파일 에러 (ProfileStatsDisplay 미존재) - 정상적인 사전 RED.
```
Testing failed:
	Cannot find 'ProfileStatsDisplay' in scope  (x3)
	Testing cancelled because the build failed.
```
UI 테스트 파일은 컴파일 오류 없음(에러는 단위 테스트 파일만). 단, 단위 타깃 빌드 실패로 UI 테스트 개별 실행 실패는 확인 못함 - 오케스트레이터가 뼈대로 확인 필요.

## 우려
- 마이페이지 순서 테스트: 통계 두 칸이 같은 행이면 minX 비교, profile.settings는 그 아래.
- AC-8의 profile.statsError 부재, AC-32는 부재 단언이라 구현 전에도 통과 가능(진입 단계에서 실패하므로 실제로는 RED).
- Phase1FlowTests의 기존 테스트에는 open.profile 미사용.

## 참조 파일
ios/FocusMateUITests/UITestLaunchSupport.swift, LargeTextUITests.swift, Phase1FlowTests.swift(일부), ios/FocusMateTests/AppFoundationTests.swift(상단 15줄, 스타일), scripts/check-ios.py 실행 로그
