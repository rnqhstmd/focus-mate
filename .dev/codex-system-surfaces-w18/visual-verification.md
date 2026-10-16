# W18 시각·시스템 검증

## 네이티브 컴포넌트 직접 확인
`reports/w18-native-four-widgets.png`와 `reports/w18-native-stale-unavailable.png`를 실제 iOS Simulator에서 캡처하고 부모가 직접 열었다. 확장에 쓰는 FocusPromptWidgetView/AnalyticsHomeWidgetView를 임시 native host에 그대로 넣었다. 시스템 WidgetKit gallery 위에 배치된 화면은 아니다. readonly widgetFamily는 host에서 주입할 수 없어 optional familyOverride로 같은 실제 View의 small/medium을 선택했으며 production은 환경값을 사용한다.

## 승인 시안 대조
`designs/system-surfaces-2026-10-16/analytics-widgets-v2.png`와 승인방향을 직접 확인했다. 차콜/오프화이트, 큰 오늘·주간 수치, 완료횟수, 월~일 7막대, 태그 합계/분석 링크, 집중 안내·앱 진입을 구현했다. 풍선곡선·반복 앱심볼 없음. small은핵심합계/행동, medium은주7일·태그맥락. 샘플수치는공용fixture에명시된날짜별25분/5회로이미지의예시48분을복사하지않는다. large는계획상제외.

## 상태
정지여정678/1800→저장된진행38%,노선2014/목적지표시. 정상빈기록0분과자료접근불가를구별한다. stale는기준일과업데이트필요/해당주를표시하며현재날짜값으로설명하지않는다. 캡처에서문구·CTA·기준줄겹침없음을확인했다.

## 실행과 한계
테스트빌드에서실제위젯확장컴파일/임베드성공. AppInfo scheme/plist/양쪽동일AppGroup entitlement정적검사성공. 임시host빌드에는SDK linker sysroot warning1줄이있으며제품Xcode빌드경고와구분한다.
실제갤러리두종류노출/OS위젯탭/개발자계정AppGroup등록·서명/실기기/VoiceOver청취/OS ReduceMotion설정전환은미확보. 현재nativehost캡처나XCTest가이를대체하지않는다. URL DEBUG진입테스트및공용AX문구검증은별도로그에기록한다. 큰글자/긴이름추가경계캡처예정.

## 큰 글자·긴 이름 경계 보완
임시host에accessibility3/긴노선·목적지/태그4개를주입했다. `reports/w18-native-accessibility3-before.png`에서실제영역넘침을발견했다. focus는고밀도정보를줄이고큰상태/저장진도/CTA/기준을유지하는compact배치,분석은위젯고정영역안의제어된타이포그래피로수치·7일·모든4태그를보존했다. medium완료횟수는제목줄에통합했다. `reports/w18-native-accessibility3-after.png`를직접열어넘침없음/4태그/수치/CTA/기준줄을확인했다. small에서생략한긴노선·목적지는동일axSummary에전체이름그대로포함한다. 이테스트는SwiftUI환경주입이며OS설정화면조작/실제VO청취아님.

## OS URL scheme 인식 범위
빌드된Info.plist에focusmate scheme등록확인. simctl openurl실행시`reports/w18-os-url-system-confirmation.png`의‘FocusMate에서열겠습니까’시스템확인창까지직접확인했다. 외부URL확인창을수락하지않았으므로실제onOpenURL전달완료라고주장하지않는다. fixture를쓴DEBUG URL실제앱진입은별도UI5건/0fail(t2-ui-final-focused.log)로검증했다. 전체회귀전전용시뮬레이터를재시작해확인창상태를정리한다.

## 2026-10-16 후속 검증
Release Simulator 일반 실행·실제 App Group 게시(0분/150분6회)·Release 진단 제외를 추가 확인했다. 실제 WidgetKit gallery/확장읽기/탭·OS접근성은 Device Hub 제어 차단으로 미확보, 실기기는 사용자 선택으로 범위 제외다. 계정 프로비저닝 성공으로 해석하지 않는다. [상세](reports/system-verification-followup.md).
