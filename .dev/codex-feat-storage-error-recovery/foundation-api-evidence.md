# Foundation 백업 쓰기 옵션 근거

- Apple Data.WritingOptions: https://developer.apple.com/documentation/foundation/data/writingoptions — NSData.WritingOptions 별칭.
- Apple withoutOverwriting: https://developer.apple.com/documentation/foundation/nsdata/writingoptions/withoutoverwriting — 목적지 존재 시 오류, atomic 옵션과 함께 사용 불가.
- 로컬 Apple SDK NSData.h: /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS27.0.sdk/System/Library/Frameworks/Foundation.framework/Headers/NSData.h:41-44 — iOS 6부터 사용 가능.

확인: document-specialist가 공식 검색 결과 및 로컬 Apple SDK 헤더 직접 검토. Apple 웹 직접 열기는 JavaScript 안내만 반환됨. UUID 백업 이름과 withoutOverwriting을 쓰되 atomic과 조합하지 않는다. 동일 바이트 read-back 확인 전 원본 삭제 금지.

## SwiftUI 접근성 포커스·변경 관찰
- https://developer.apple.com/documentation/swiftui/accessibilityfocusstate — 활성 VoiceOver 등 접근성 기술의 포커스를 읽고 쓰는 property wrapper. optional/Bool 상태를 사용한다.
- https://developer.apple.com/documentation/swiftui/view/accessibilityfocused(_:equals:) — enum 상태를 특정 값으로 설정하면 대응 요소로 접근성 포커스 이동.
- https://developer.apple.com/documentation/swiftui/view/onchange(of:perform:) — deprecated one-parameter 대신 zero/two-parameter onChange(of:initial:_:) 사용 안내.
공식 Apple 검색 결과 본문 확인. 실제 VoiceOver 포커스 이동은 별도 직접 확인 사항이며 코드 적용/자동 UI 결과와 구분한다.
