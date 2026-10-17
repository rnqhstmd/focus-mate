# Testability 평가 1차

읽기 전용 oh-my-gx:test-architect. 테스트/빌드 실행 없음.

## 컴포넌트별 전략
- ContentState: 동작. 실제 Codable의 누락/null/정상값 호환과 round-trip; 외부모의없음. AC3.
- Policy: 동작. 고정Date/리터럴로 endDate/paused/total/cleanup 검증. AC1~3.
- Sync: 동작. ManualJourneyClock/FakeProgressSaver와 gateway경계의 RecordingLiveActivityGateway. 수동 advance와 호출수·payload로 pause/resume/background/reuse/거절 회귀. AC1~3.
- Presentation/포맷: 동작. 주입now·고정 입력으로 순수 검증; sleep/생산포맷터expected금지. AC1~4.
- Accessibility: 동작. 전체 이름·상태/시간 소유권. 실제 뷰의 hidden/합치기·낭독은 기기확인. AC4~5.
- SwiftUI: 조건부 노출은 동작, glyph/색/폰트/눈금간격은 표현. 스타일assert금지, 미리보기·시안대조·실제장치검증 분리.

## 러너
.config ios-swiftui XCTest와 scripts/check-ios.py의 파일별 only-testing 확인. 선택 테스트 명령: python3 scripts/check-ios.py test {files}. RED에 Sync Rig의 정확한 makeRig(minutes:)와 gateway관찰 계약을 전달. 기존 Mirror7필드 검사는 total추가만8로 갱신; 신규JSON호환은 외부인코딩계약 검사.

## Testability Score: 8/10
TESTABILITY PASS. 단 장시간 compact snapshot과 자동채움/버스 위치 계약은 설계 확정의 차단 요소이며 점수 통과로 해소되지 않는다. 같은 pure함수 두번호출로 ReduceMotion을 검증했다고 하지 않는다. 실제 UI/VoiceOver 결과를 별도남긴다.
