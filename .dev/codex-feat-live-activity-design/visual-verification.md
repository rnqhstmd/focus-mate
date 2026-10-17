# W17 검증 증거 구분

## 자동 검사
부모가 전용 iOS26.5 시뮬레이터에서 W17 관련6개 XCTest 파일을 직접 실행:108pass/0fail. 로그 reports/t2-green-run.log. 시간범위/정지/total호환/정규화/summary를 검증하며 실제 표면 렌더·낭독을 증명하지 않는다. 확장과 네 DEBUG preview의 SDK 컴파일 통과.

## 미리보기 시각 대조
승인 시안 designs/system-surfaces-2026-10-16/island-timeline-v2.png를 열어 확인했다. 사용자 승인 변경대로 이동 버스를 트랙 밖 고정 심볼로 바꾸고 native 진행 막대를 사용했다. 차콜/오프화이트, 상단 노선/시간, 하단 눈금/목적지, paused 중복 심볼 배제를 구현했다.
생산 SwiftUI 컴포넌트를 재사용하는 별도 preview host를 빌드하고 전용 iOS26.5 시뮬레이터에서 캡처 reports/w17-native-preview.png를 직접 열어 시안과 대조했다. running/paused/종료직전의 차콜 정보 계층, 가로 눈금, 시스템 진행 채움, 고정 심볼과 긴 한국어 잠금 컴포넌트의 축약 및 360:00 읽힘을 확인했다. running18:42 초기값이 캡처18:08로 흐르고 paused18:42는 유지되는 native preview 결과를 관측했다. 이 host는 시스템 Island 크기/카메라 배치와 다른 검토용 화면이며 실제 ActivityKit 검증이 아니다. DEBUG Preview에는 running/paused/arrived,5/599/5999/7200/21600초,긴한국어를 포함했다.

## 실제 Dynamic Island·잠금 화면
미확보. SDK 컴파일과 preview host는 시스템 ActivityKit의 실제 배치/카메라 여백/compact360:00 가독성/자연 경과 진행 갱신을 입증하지 않는다. 기존 UI테스트는 recording gateway를 사용하며 실제 ActivityKit 표시를 발생시키지 않는다. 물리 iPhone 연결·서명 계정이 확보되지 않아 실제 시스템 표면 검증을 완료하지 않았다. 미리보기 결과와 별개로 후속 기기 검증 필요.

## 실제 VoiceOver
미확보. 테스트는 전체 이름/상태/시간 소유권 모델만 확인했다. 실제 expanded/lock/compact/minimal의 단일 낭독, 특히 minimal accessibilityValue(native timer Text)의 시간 경과 후 동적 재낭독은 실기기 VoiceOver 청취 증거가 없다. 정적 잔여값 fallback은 추가하지 않았다. 기기 청취 전 접근성 완료로 주장하지 않는다.

## Reduce Motion·큰 글자
코드는 custom 이동 애니메이션을 추가하지 않아 시간/상태/막대 입력은 설정에 의존하지 않는다. 실제 설정 전후 큰 글자/Reduce Motion 렌더 대조는 미확보이므로 pure모델 테스트로 설정 검증을 대신하지 않는다.

## 전체 회귀
사용자 지시로 W18까지 구현 후 실행. 본 문서의 focused 성공은 전체 verify 통과가 아니다.
