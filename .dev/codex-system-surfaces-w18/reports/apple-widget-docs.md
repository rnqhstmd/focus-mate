# W18 Apple WidgetKit 공식 문서 근거

확인일: 2026-10-16. Apple Developer의 공식 문서만 사용했다. 앱 소스 변경·빌드·테스트·서명·갤러리 등록 검증은 수행하지 않았다. 아래 W18 적용 판단은 문서에서 도출한 구현 확인 기준이며 실행 증거가 아니다.

## StaticConfiguration과 번들

- `StaticConfiguration(kind:provider:content:)`은 사용자 편집 설정이 없는 위젯 구성이다. `kind`는 고유 식별 문자열, provider는 `TimelineProvider`, content는 해당 Entry를 받는 SwiftUI View다. 고정 종류의 자료가 동적으로 바뀌는 위젯도 static 구성에 해당한다. [공식 initializer](https://developer.apple.com/documentation/widgetkit/staticconfiguration/init(kind:provider:content:))
- `.configurationDisplayName`, `.description`, `.supportedFamilies([.systemSmall, .systemMedium])`로 갤러리 이름·설명·두 크기를 선언할 수 있다. 앱 설치 후 포함 앱을 최소 한 번 실행해야 갤러리에 나타난다는 전제도 있다. [Creating a widget extension](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension)
- 한 확장에서 여러 위젯은 단일 `@main WidgetBundle`의 body에 함께 나열한다. W18 두 계열과 기존 Live Activity를 같은 번들에 보존하는 방식의 공식 근거다. 새 @main 진입점을 추가하는 요구가 아니다. [WidgetBundle](https://developer.apple.com/documentation/swiftui/widgetbundle)

## TimelineProvider와 갱신

- 기본 계약은 `placeholder(in:)`, `getSnapshot(in:completion:)`, `getTimeline(in:completion:)`, `Entry: TimelineEntry`다. placeholder는 동기 반환하고, snapshot은 현재 상태나 갤러리 미리보기, timeline은 현재/미래 날짜의 Entry를 제공한다. [TimelineProvider](https://developer.apple.com/documentation/widgetkit/timelineprovider)
- `getSnapshot`의 `context.isPreview`가 true면 갤러리 용도이며 신속히 completion을 호출한다. 샘플 자료를 쓸 경우 실제 사용자 분석과 구분한다. [getSnapshot](https://developer.apple.com/documentation/widgetkit/timelineprovider/getsnapshot(in:completion:))
- `Timeline(entries:policy:)`의 `.after(date)`는 다음 timeline 요청의 가장 이른 시각이며 정확한 실행 시각 보장이 아니다. `.atEnd`는 마지막 Entry 이후, `.never`는 앱의 WidgetCenter 요청까지 자동 timeline 요청을 하지 않는다. Entry 날짜에도 늦게 표시될 수 있다. [Timeline](https://developer.apple.com/documentation/widgetkit/timeline)
- 위젯 확장은 계속 실행되는 프로세스가 아니다. 예측 가능한 변화를 timeline으로 제공하고 자료 변경 때 WidgetCenter로 reload를 요청한다. OS는 예산·노출 빈도 등에 따라 reload를 조정한다. 매초 reload 또는 정확한 자정 표시를 보장하는 설명은 공식 계약에 맞지 않는다. [Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)
- W18 적용 판단: 자정 Entry가 이전 기준 자료를 ‘업데이트 필요’로 바꿀 수 있어도 현재 분석값을 재계산한 것으로 취급하면 안 된다. 게시 자료의 기준 날짜와 최신성 판정은 제품 계약이며 WidgetKit이 대신 제공하지 않는다.

## App Group 공유와 entitlement

- 앱과 확장은 같은 개발팀의 App Group에 가입해 공유 컨테이너를 사용할 수 있다. iOS App Group ID는 `group.` 접두사이며 개발자 계정 등록과 각 타깃의 App Groups capability 설정이 필요하다. [Configuring app groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- 실제 entitlement 키는 `com.apple.security.application-groups`, 값은 group ID의 문자열 배열이다. 앱과 위젯 확장 양쪽이 동일한 그룹을 포함해야 공유 자료를 읽는 전제가 성립한다. [App Groups Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.application-groups)
- 공유 경로는 `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`로 구한다. 인자는 entitlement 값과 정확히 일치해야 하며 iOS에서 유효하지 않은 그룹은 nil을 반환한다. 디렉터리 경로를 하드코딩하거나 nil을 원본 저장소·빈 분석으로 대체하지 않는다. [containerURL](https://developer.apple.com/documentation/foundation/filemanager/containerurl(forsecurityapplicationgroupidentifier:))
- W18의 `group.app.focusmate.prototype`는 로컬 설정 후보다. 문법에 맞는 문자열이나 entitlement 파일 존재만으로 해당 팀의 등록·프로비저닝·실기기 접근 성공을 주장할 수 없다. 이 문서는 계정 상태를 확인하지 않았다.

## widgetURL, Link, 앱 진입

- 모든 위젯의 기본 전체 탭에는 `.widgetURL(url)`을 사용한다. 한 View hierarchy에 widgetURL을 여러 개 넣으면 동작이 정의되지 않는다. medium에는 복수 `Link`와 전체 기본 widgetURL을 함께 사용할 수 있다. Link 영역은 해당 URL, 나머지는 기본 URL로 진입한다. [Creating a widget extension](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension)
- 시스템은 URL을 포함 앱의 `onOpenURL(perform:)` 등 앱 생명주기 핸들러로 전달한다. 이 전달 자체가 여정 재개·진입 권한 검증을 수행하는 것은 아니다. W18에서는 최신 앱 상태 재검증과 기존 확인 흐름이 별도로 필요하다. [Linking to specific app scenes](https://developer.apple.com/documentation/widgetkit/linking-to-specific-app-scenes-from-your-widget-or-live-activity)
- 최신 linking 문서는 small도 Link 대상에 언급하지만 생성 문서는 medium 이상을 명시한다. W18 최소 계약은 small=전체 widgetURL 한 개, medium=필요한 Link+기본 widgetURL로 두면 두 문서가 공통으로 설명하는 경로를 따른다. small 다중 Link 지원을 추가로 약속하지 않는다.
- custom scheme은 포함 앱의 `CFBundleURLTypes` 배열 안 `CFBundleURLSchemes`에 등록한다. URL 타입 이름과 scheme은 별개다. `focusmate`는 앱 설정값이며 타이머 직접 제어 명령이 아니다. [Core Foundation URL keys](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html)

## 확장 Info.plist와 iOS SwiftUI 표시

- 위젯 확장 Info.plist의 `NSExtension` 사전에 `NSExtensionPointIdentifier` 문자열을 두며 WidgetKit 확장 값은 `com.apple.widgetkit-extension`이다. 기존 Today Extension의 `com.apple.widget-extension`과 구분한다. 이 키만으로 확장 임베드·서명·설치를 증명하지는 않는다. [NSExtensionPointIdentifier](https://developer.apple.com/documentation/bundleresources/information-property-list/nsextension/nsextensionpointidentifier)
- iOS17 경로에서는 `.containerBackground(for: .widget) { ... }`로 위젯 배경을 구분한다. 시스템이 배경을 제거할 수 있는 환경이 있으며 이를 무조건 일반 `.background`와 같다고 취급하지 않는다. 배경을 명시적으로 nonremovable로 하면 일부 갤러리 환경에서 제외될 수 있다. [Displaying the right widget background](https://developer.apple.com/documentation/widgetkit/displaying-the-right-widget-background)

## 남은 실제 확인

- 해당 Xcode SDK에서 API 경로 컴파일, 포함 앱/확장 타깃 등록 및 임베드.
- 팀·프로비저닝·양쪽 entitlement·실제 공유 컨테이너 접근.
- 앱 첫 실행 뒤 갤러리 두 계열·각 소형/중형 노출.
- small 전체 탭, medium Link와 기본 탭, cold/warm onOpenURL 진입 및 앱 상태 재검증.
- 정상/빈/오래됨/손상/접근 불가, 자정 이후 및 foreground 재게시, 실제 VoiceOver와 긴 텍스트.

현재 문서 확인은 위 실행·실기기 항목의 통과를 뜻하지 않는다.
