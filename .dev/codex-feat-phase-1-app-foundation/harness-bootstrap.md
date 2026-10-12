# Phase 1 빈 iOS 하네스 부트스트랩

작성: 2026-10-13. 이 배치는 gx-dev의 하네스 인프라 준비이며 Phase 1 제품 동작의 RED/GREEN 구현을 대체하지 않는다.

## 배치 파일

- `ios/FocusMate.xcodeproj/project.pbxproj`
- `ios/FocusMate.xcodeproj/xcshareddata/xcschemes/FocusMate.xcscheme`
- `ios/FocusMate/FocusMateApp.swift`
- `ios/FocusMateTests/HarnessTests.swift`
- `ios/FocusMateUITests/HarnessUITests.swift`
- 이 문서 `.dev/codex-feat-phase-1-app-foundation/harness-bootstrap.md`

## 구조·설정

앱은 SwiftUI `WindowGroup`의 `Text("Focus Mate")`만 표시한다. 단위 테스트는 `testHarnessLoads`의 `XCTAssertTrue(true)` 한 개다. UI 테스트는 앱 실행 후 `Focus Mate` 텍스트 존재 확인 한 개다. 이는 테스트 타깃 연결 확인일 뿐 기능 수용 기준 충족 증거가 아니다.

공유 스킴 `FocusMate`가 앱·단위·UI 테스트 타깃을 연결한다. 수동 PBXGroup/SourcesBuildPhase 구조이므로 후속 Swift 파일은 해당 타깃 Sources에 등록한다. deployment iOS 17.0, Swift language 5.0, SDK iphoneos, iPhone family 1, generated Info.plist, `SWIFT_STRICT_CONCURRENCY=minimal`이다. 기본 MainActor isolation 설정은 추가하지 않았다. UI 테스트 메서드만 플랫폼 UI 호출을 위해 MainActor에 둔다.

개발 팀은 빈 값이며 로컬 번들 ID는 `app.focusmate.prototype`다. 출시 Bundle ID/서명을 확정한 것이 아니다. 시뮬레이터 검증은 `CODE_SIGNING_ALLOWED=NO`를 사용한다. unit target의 TEST_HOST/BUNDLE_LOADER와 UI target의 TestTargetID/TEST_TARGET_NAME을 앱에 연결했다. 외부 패키지·앱 아이콘·비즈니스 리소스는 추가하지 않았다.

## 실행 상태

배치 담당은 **빌드·테스트를 실행하지 않았다**. 검증은 별도 담당이 아래 명령으로 수행한다.

```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate -destination 'platform=iOS Simulator,id=529B88AF-5286-43EA-938A-4233F6B226CD' -derivedDataPath .build/ios test CODE_SIGNING_ALLOWED=NO
```

## 제한

라우트·스토어·모델·여정·카드·기록·설정·권한·실제 기능은 구현하지 않았다. 환경 변경·의존성 설치·README/설계/상태 문서 수정·웹/Pen 변경·커밋/푸시는 수행하지 않았다. 후속 Phase 1 동작은 확정된 설계와 실패 테스트를 먼저 작성하는 별도 TDD 단계다.

## 실제 하네스 확인

iOS27 iPhone18Pro 529B88AF-5286-43EA-938A-4233F6B226CD에서 xcodebuild test exit0, Unit1/UI1,0fail. /tmp/focusmate-harness-test.log 및 /tmp/focusmate-phase1-derived/Logs/Test/*.xcresult. 앱기능없음, smokewire증거만. native config/check-ios.py추가후기준선을별도실행한다.
