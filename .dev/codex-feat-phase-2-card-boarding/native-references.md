# Phase2 네이티브 근거 후보

2026-10-13. 설계 전에 확인한 Apple 공식 문서다. 이번 단계에서 API 구현 또는 플랫폼 동작 검증을 완료한 것으로 보고하지 않는다.

|자료|용도|
|---|---|
|[SwiftUI ScenePhase](https://developer.apple.com/documentation/swiftui/scenephase)|승차 인식·미리듣기의 장면 비활성/백그라운드 경계|
|[Data.WritingOptions.atomic](https://developer.apple.com/documentation/foundation/data/writingoptions/atomic)|기존 원자 저장 옵션과 새 저장 필드의 보호 경계|
|[AVAudioPlayer.numberOfLoops](https://developer.apple.com/documentation/avfaudio/avaudioplayer/numberofloops)|파일 오디오 반복·stop 수명 설계 후보|

검색 결과의 비공식 포럼 자료는 근거에 사용하지 않았다. ScenePhase와 numberOfLoops 페이지는 JavaScript 문서 shell로 응답했다. atomic 세부 페이지는 웹 도구에서 접근 실패해 본문을 검증하지 못했다. 위 링크는 설계 근거 후보이며 세부 구현·OS17/27 API 적용은 공식 Markdown·로컬 SDK에서 다시 확인해야 한다. 전원 장애·실기기 청취·햅틱 검증을 이 문서로 대체하지 않는다.

공식 Markdown 링크는 존재하나 현재 web 도구가 text/markdown content-type을 처리하지 못했다. 이 오류를 API 본문 검토 성공으로 취급하지 않았다. 구현 전 공식 본문 또는 로컬 SDK 근거를 추가로 확보해야 한다.

## 공식 DocC 본문 확인
2026-10-13 Apple 공식 DocC JSON을 직접 읽었다. ScenePhase는 View의 environment scenePhase로 장면 상태 변경을 관찰하는 예시를 제공한다. AVAudioPlayer.numberOfLoops는 음수일 때 stop 호출까지 반복한다고 설명한다. 해당 내용만 구현 근거로 사용하며 실기기 재생 품질이나 전원 장애 원자성을 확인한 것으로 취급하지 않는다.
- https://developer.apple.com/tutorials/data/documentation/swiftui/scenephase.json
- https://developer.apple.com/tutorials/data/documentation/avfaudio/avaudioplayer/numberofloops.json
