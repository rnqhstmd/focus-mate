# Phase 1 공식 참고와 실행 전제

공식 문서를 읽는 document-specialist가 조사했으며 소스/테스트/프로젝트를 수정하지 않았다. 최소 iOS17은 사용자 승인 우선 작업 기준이다. 출시 서명/Team은 미정이다.

## 플랫폼/하네스

Xcode 기본 iOS App + SwiftUI + 연결된 Unit Testing Bundle을 제안한다. 앱 타깃·@main App/WindowGroup·테스트 타깃·scheme Test action과 실제 Simulator destination이 필요하다. 라이선스, 전체 도구체인, iOS SDK/플랫폼, Simulator 런타임은 각각 확인한다. 러너 미실행이나 SDK/프로젝트 실패는 behavioral RED가 아니다. 빈 앱/테스트 번들의 smoke pass는 하네스 연결 근거만 된다.

- [앱 프로젝트 생성](https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app)
- [Xcode 구성요소](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components)
- [테스트 타깃](https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project)
- [테스트 실행/결과](https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results)
- [SwiftUI App](https://developer.apple.com/documentation/swiftui/app)

## 라우팅/저장 경계

NavigationStack의 경로는 가벼운 Hashable 값으로 관리한다. 뷰의 @State는 영속 저장소가 아니다. 작은 상태의 Codable→JSON Data→UserDefaults 단일 키 저장을 제안한다. JSON encode/decode 실패를 구분하고 손상·미지원 버전의 원본은 삭제/기본값 덮어쓰기 없이 보존한다. 테스트는 별도 고유 UserDefaults suite를 사용해 운영 저장과 분리한다. UserDefaults 디스크 쓰기는 비동기이므로 같은 프로세스의 round-trip과 재실행 복원 증거를 구분한다.

- [NavigationStack](https://developer.apple.com/documentation/swiftui/understanding-the-navigation-stack)
- [UI 상태](https://developer.apple.com/documentation/swiftui/managing-user-interface-state)
- [JSONEncoder](https://developer.apple.com/documentation/foundation/jsonencoder/encode(_:))
- [JSONDecoder](https://developer.apple.com/documentation/foundation/jsondecoder/decode(_:from:))
- [UserDefaults suite](https://developer.apple.com/documentation/foundation/userdefaults/init(suitename:))
- [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)

## 설계용 파일 저장 근거 보강

Phase 1의 저장 실패를 구분하기 위해 architect는 버전 JSON 파일 저장을 선택했다. 아래는 document-specialist가 추가 확인한 공식 근거다. 앞의 UserDefaults는 초기 제안이며 구현 결정이나 검증 결과가 아니다.

- [Data.write(to:options:)](https://developer.apple.com/documentation/foundation/data/write(to:options:))는 throws → Void다. 인코딩을 마친 Data를 기록하고, 실패 오류를 호출자에게 전달할 수 있다.
- [atomic](https://developer.apple.com/documentation/foundation/nsdata/writingoptions/atomic)은 보조 파일 기록 성공 후 원본을 교체한다. 원본을 먼저 삭제하지 않는다. 부분 파일 방지와 전원 손실 내구성·동시 작성자 충돌 해결은 별개다.
- [Application Support 경로](https://developer.apple.com/documentation/foundation/filemanager/url(for:in:appropriatefor:create:))를 구하고 앱 하위 폴더에 저장한다. [파일 시스템 지침](https://developer.apple.com/documentation/foundation/using-the-file-system-effectively)에서 지원 파일의 저장 위치를 확인했다.
- 읽기·디코딩·미지원 버전 오류에서 원본 보존은 앱이 구현할 정책이다. atomic 옵션만으로 JSON 유효성이나 버전 정책이 제공되지 않는다.
- 실제 임시 파일 + 새 저장소 인스턴스 읽기는 파일 round-trip 검사다. 프로세스 재실행 검사는 [XCUIApplication](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication)의 terminate/launch와 동일 Application Support 파일을 사용한다. 테스트의 1회 seed가 두 번째 실행의 파일을 덮어쓰지 않아야 한다.
- [temporaryDirectory](https://developer.apple.com/documentation/foundation/filemanager/temporarydirectory)는 앱 미실행 중 제거될 수 있으므로 실제 재실행 영속성 검사에 쓰지 않는다.

## 약관 오류 원인 — 2026-10-12 추가 확인

선택된 도구체인은 /Applications/Xcode.app/Contents/Developer이며 앱 버전은 27.0, LicenseInfo.plist의 licenseID는 EA2002다. 시스템 동의 기록은 26.3/EA1990만 있다. CUA에서 Xcode and Apple SDKs Agreement 대화상자와 Agree 버튼을 확인하고 창을 앞으로 표시했다. 새 약관을 동의하거나 시스템 동의 기록을 수정하지 않았다. xcrun swift --version은 여전히 라이선스 오류로 실행되지 않았다.

## 현재 확인

PR1은 main e0adabc로 squash merge했고 로컬 main을 동일 revision으로 갱신했다. Phase1 작업 브랜치 생성, 3AC 사용자 승인 및 gx-tdd 요청을 기록했다. 사용자 동의 완료 응답 뒤에도 xcrun swift/xcodebuild SDK/simctl은 라이선스 오류 exit69를 반환했다. Xcode 창을 앞으로 띄웠으며 사용자 실제 약관 처리를 기다린다. 아직 native source/scaffolding/behavioral RED/test/build 증거는 없다.

## 환경 준비 해결 — 2026-10-13

사용자 직접 새 약관 동의 후 Swift6.4, iOS27 SDK 명령이 exit0으로 실행됐다. iOS26.5 및 iOS27.0 Simulator runtime available을 확인했다. 사용자가 요청한 iOS27 iPhone18Pro (529B88AF-5286-43EA-938A-4233F6B226CD)를 로컬 검증 대상으로 사용한다. 환경 준비 통과와 제품 테스트 통과는 별개다.
