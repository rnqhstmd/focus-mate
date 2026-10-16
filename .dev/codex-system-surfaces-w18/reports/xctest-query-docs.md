# XCTest/XCUIAutomation 요소 binding 공식 확인

확인일 2026-10-16. Apple Developer 공식 문서와 해당 문서의 Apple-hosted JSON metadata만 읽었다. 프로젝트 소스·테스트 수정, 테스트 실행은 하지 않았다.

## 두 배열 API의 차이

- `allElementsBoundByAccessibilityElement: [XCUIElement]`는 query를 즉시 평가하고 결과 AX요소에 binding된 배열을 반환한다. [공식 문서](https://developer.apple.com/documentation/xcuiautomation/xcuielementquery/allelementsboundbyaccessibilityelement)
- `allElementsBoundByIndex: [XCUIElement]`도 즉시 평가하지만 각 결과의 index에 binding된다. [공식 문서](https://developer.apple.com/documentation/xcuiautomation/xcuielementquery/allelementsboundbyindex)
- 적용 판단: 후보를 열거한 뒤 각 후보의 하위구조를 검사할 때 index 대신 특정 AX요소에 연결하는 첫 API를 사용할 수 있다. 재조회 결과 순서가 바뀌었을 때 ‘같은 index의 다른 요소’를 선택하는 결합을 피하려는 목적과 맞는다.
- 한계: 공식 설명은 UI가 삭제·재생성된 뒤에도 같은 요소를 영구 추적한다고 보장하지 않는다. 오래 보관한 배열·후보를 재사용하는 대신 실제 선택 직전 현재 query에서 열거하고 leaf 유일성을 확인해야 한다. 이것은 문서 의미에서 도출한 적용 판단이며 테스트로 검증한 보장은 아니다.

## 하위 Button 조회와 leaf 유일성

- `XCUIElement.descendants(matching: .button)`은 해당 요소의 모든 하위 Button에 대한 query를 반환한다. 자기 자신을 포함하는 API가 아니다. `children(matching:)`는 직계 자식만 조회한다. [descendants(matching:)](https://developer.apple.com/documentation/xcuiautomation/xcuielement/descendants(matching:))
- `.buttons`는 해당 유형에 대한 descendants 조회의 shorthand다. [XCUIElementTypeQueryProvider](https://developer.apple.com/documentation/xcuiautomation/xcuielementtypequeryprovider)
- 따라서 동일identifier의 ancestor Button/child Button이 함께 발견되면 각 candidate에 대해 같은 identifier(필요 시 같은 label까지)의 descendant Button이 없는 후보를 고르는 leaf 판정을 구성할 수 있다. Button 아닌 wrapper가 끼어 있어도 descendants는 하위 전체를 본다.
- 서로 독립된 실제 leaf Button 두 개는 둘 다 남아야 한다. leaf count가 정확히1일 때만 선택하고 그 외에는 기존 모호성 실패를 보존해야 한다. `firstMatch`나 `allElements...first`로 두 실제 버튼 중 하나를 임의로 택하는 방식과 구분한다.
- `count`는 query를 평가해 match 수를 반환하며 `element`는 단일 match 접근이다. [count](https://developer.apple.com/documentation/xcuiautomation/xcuielementquery/count), [XCUIElementQuery](https://developer.apple.com/documentation/xcuiautomation/xcuielementquery)

## Deprecated·지원 버전 확인

- 현재 공식 두 배열 API와 descendants 문서/metadata에는 deprecated 표시 또는 deprecatedAt 필드가 없다. See Also 하단의 Deprecated는 `element(at:)`에 붙은 설명이므로 이를 배열 API의 폐기로 읽으면 안 된다.
- 세 문서의 Apple JSON metadata는 지원 플랫폼 iOS/iPadOS/Mac Catalyst/macOS/tvOS/visionOS/watchOS 및 `Xcode introducedAt:16.3`을 제공하며 개별 iOS introducedAt는 제공하지 않는다.
- Apple Xcode16.3 릴리스 노트는 기존 XCTest UI automation API를 새 `XCUIAutomation` framework로 이동했고 XCTest가 이를 re-export하므로 `import XCTest`가 계속 동작한다고 명시한다. 따라서 metadata의 Xcode16.3을 이 API 자체가 처음 만들어진 시점 또는 iOS 최소 버전으로 해석하면 안 된다. [Xcode16.3 Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes)
- 이번 공식 자료만으로 역사적 iOS 최초 도입 버전을 확정하지 않았다. 현재 XCUIAutomation 문서 계약과 XCTest re-export 사용 가능성은 확인했으며 로컬 SDK 빌드 확인은 수행하지 않았다.

## Metadata 출처

- https://developer.apple.com/tutorials/data/documentation/xcuiautomation/xcuielementquery/allelementsboundbyaccessibilityelement.json
- https://developer.apple.com/tutorials/data/documentation/xcuiautomation/xcuielementquery/allelementsboundbyindex.json
- https://developer.apple.com/tutorials/data/documentation/xcuiautomation/xcuielement/descendants(matching:).json

계획된 alertButton 수리의 API 선택을 뒷받침하는 문서 확인이며, 실제 ancestor/child 선택 수리 또는 회귀 통과 증거는 아니다.
