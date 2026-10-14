# Xcode27 VoiceOver 검증 경로
2026-10-14 공식릴리스노트에서 XCUIVoiceOverService 새API 확인. https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes
WWDC26 Accessibility Technologies Group Lab은 새XCTest API의 Simulator지원과당시beta오류가능성설명. https://developer.apple.com/videos/play/wwdc2026/8005/
기존 accessibility testing 문서의 Simulator불가설명과시점차이존재. 최신release및설치SDK우선.
설치SDK XCUIAutomation.framework/Headers/XCUIVoiceOverService.h와XCUIDevice.h: API_AVAILABLE(ios27), XCUIDevice.shared.voiceOverService, enable/disable, isEnabled, moveForward/moveBackward/currentSpeech, Output.utterance. refinedSwift메서드는SDKswiftinterface확인필요.
iOS26.5기본테스트에는호출불가. iOS27 전용새Simulator에서실행할시,정상테스트runner부터확인. 기존DeviceHub CUA타임아웃반복재시도는하지않음. 새API실제speech검증과기존XCUIlabel검증을분리. 실제speech결과전PASS표시금지.

## Swift SDK 타입 확인
임시Swift27시뮬레이터타입검사실제exit0. `try service.enable()`, `try service.moveForward()`가 nonoptional `XCUIVoiceOverService.Output`을반환, `.utterance`, `try service.disable()`컴파일확인. 이결과는API정적호출가능성이지실제VoiceOver활성화나speech관찰증거아님. 신규전용Simulator F226C28A-81D5-4708-B939-81B605AC748E iOS27 bootstatus exit0. 기존기기상태변경없음.
