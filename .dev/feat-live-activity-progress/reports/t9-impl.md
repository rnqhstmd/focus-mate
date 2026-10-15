# T9 IMPLEMENT (세션) + T10 위젯 UI (표현 레이어, RED 없음 — 빌드로만 판정)

## 구현 내용
- `project.pbxproj`: 위젯 확장 타깃 `FocusMateWidgets`(A5…04, app-extension, bundle id app.focusmate.prototype.widgets, SKIP_INSTALL, APPLICATION_EXTENSION_API_ONLY, INFOPLIST_FILE=FocusMateWidgets/Info.plist + GENERATE_INFOPLIST_FILE), 동기화 그룹 FocusMateWidgets(A4…06, Info.plist 멤버십 예외 A8…01) + Shared(A4…07) 연결, 앱에 Embed Foundation Extensions(A6…31, dstSubfolderSpec 13) + 타깃 의존성(A7…03/A3…03), 앱 INFOPLIST_KEY_NSSupportsLiveActivities = YES(Debug/Release), 프로젝트 MARKETING_VERSION 1.0 / CURRENT_PROJECT_VERSION 1.
- 신규 `ios/FocusMateWidgets/Info.plist`(NSExtensionPointIdentifier = com.apple.widgetkit-extension), `FocusMateWidgetsBundle.swift`(@main).
- T10: `JourneyLiveActivityWidget.swift` — 잠금 화면(버스 번호·종류, 도착지, 상태 이름, 시간), Dynamic Island(expanded leading 버스/trailing 시간/bottom 도착지·상태, compact, minimal). 시간·문구·접근성 라벨은 모두 JourneyActivityDisplay 함수. 진행 막대 없음.

## GREEN 증거
- `check-ios.py test AppInfoLiveActivityTests.swift JourneyActivityDisplayTests.swift` → Executed 26 tests, 0 failures (AppInfo 5 RED → GREEN)
- 완료 조건: `check-ios.py test ios/FocusMateUITests/HarnessUITests.swift` → 1 test, 0 failures (서명 없이 확장 임베드 앱 설치 확인)
- T10 후 `check-ios.py build` → BUILD SUCCEEDED

## REFACTOR 내역
정리 없음

## self-review 결과
설계 pbxproj 표의 ID·설정과 일치. 스킴 무수정(buildImplicitDependencies).

## 우려사항
- 잠금 화면 컨테이너는 `.combine` + 설명 라벨이라, 운행 중 카운트다운이 VoiceOver에서 따로 읽히지 않을 수 있다(M-9 실기기 점검 항목으로 확인).

## fix R1
- `JourneyActivityDisplay`에 `busTitle`, `compactAccessibilityLabel`, `displayStatus` 추가, `accessibilityLabel`이 displayStatus 재사용.
- 위젯: compact 라벨·제목·상태를 Display 함수로 교체(위젯 문자열 리터럴 제거), 잠금 화면은 설명 그룹(.ignore + 라벨)과 카운트다운 Text를 별도 접근성 요소로 분리.
- GREEN: Display 33 + AppInfo 5 → 0 failures. 테스트 해시 갱신 9b9f4e87….
