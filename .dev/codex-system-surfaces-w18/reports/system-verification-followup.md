# W18 후속 시스템·Release 검증 — 2026-10-16

기준 코드 HEAD551ba7c. 사용자 요청으로 남은 검증을 진행했고, 실기기는 사용자가 ‘지금은 시뮬레이터까지 진행’으로 제한했다. 소스/테스트/프로젝트 설정은 변경하지 않았다. 이번 실행에 전체 테스트를 반복하지 않았다.

| 항목 | 직접 결과 | 경계 |
|---|---|---|
| Release 구성 | Xcode27.0/SDK27, iOS26.5 전용 Simulator, Release build exit0(46.92초) | iPhoneOS archive/Validate/업로드 결과가 아님 |
| 설치·일반 실행 | 로컬 ad-hoc 서명을 포함한 Release 앱 설치·일반 실행 성공, 카드 발급 첫 화면 캡처 직접 확인 | DEBUG bootstrap을 사용하지 않음 |
| App Group 게시 | 실제 OS 컨테이너 등록과 widget-snapshot-v1.json 생성 확인. 초기0분/0회와 테스트 기록150분/6회 게시를 각각 확인 | 계정의 App Group 등록/배포 프로비저닝 또는 실제 위젯 확장 읽기 완료로 보지 않음 |
| 최소 공유 | 실제 게시 JSON의 일별7일·주간150분/6회·태그75+75분 확인. memo/task/cardID/completedAt/기록ID/회고 문자열 없음 | 입력은 전용 Simulator의 기존 테스트 fixture. 사용자 실제 기록을 사용하지 않음 |
| 확장 설정 | 빌드 산출물의 App/Widget 양쪽 Simulated.xcent가 동일 group.app.focusmate.prototype을 포함 | codesign 표준 entitlement 출력은 Simulator 특성상 빈 dict였으며, 실제 linker가 포함한 Simulated.xcent와 OS 컨테이너를 별도로 확인 |
| Release 진단 제외 | strings로 --fm-ui-test-id, test.persistedBytes, test.writeAttempts, test.main.failNextSave, UITestBootstrap 부재 확인 | 이5개 문자열 범위의 검사이며 모든민감문자열/전송감사 완료는 아님 |
| 실제 갤러리·위젯 탭·확장 읽기 | 미검증 — Device Hub UI 자동 제어 차단 | 실제 홈 위젯 표시/탭/확장 프로세스 실행 성공을 주장하지 않음 |
| OS VoiceOver·Reduce Motion | 미검증 — 동일 UI 제어 차단 | 기존 native View AX/크기·자동회귀 증거와 구분 |
| 실기기·배포 서명 | 이번 범위 제외/미확보 | 연결 가능한 물리 기기 없음, 사용자도 Simulator 한정 선택. 로컬 개발 인증서1개 존재만 확인 |

## 실제 게시 절차

기존 자동 테스트 빌드는 CODE_SIGNING_ALLOWED=NO여서 설치 앱의 GroupContainers가 비어 있었다. 이것을 제품 설정 누락으로 판단하지 않고, project를 바꾸지 않은 채 Release·CODE_SIGN_IDENTITY=-·CODE_SIGNING_ALLOWED=YES·CODE_SIGN_STYLE=Manual 오버라이드로 빌드했다. 새 설치에서 OS App Group 컨테이너를 관측했다.

먼저 아무 DEBUG 인자 없이 앱을 실행해0분 공유를 읽었다. 이후 해당 전용 Simulator 앱의 기존 UI테스트가 생성한150분/6회 fixture를 operational app-state.json에 준비하고, 앱을 일반 Release 경로로 다시 실행했다. 게시 파일의 합계와 최소 필드만 확인했다. 테스트 파일 배치는 검증 입력 준비이며 실제 사용자 완료 동작을 대체하지 않는다. fixture의 가상 정류장 ID는 실노선 번들에 없으므로 setup 여정 상태로 표시됐으며 이를 정상 여행 이어가기 성공으로 집계하지 않는다.

## Device Hub 차단 근거

현재 Xcode27은 예전 Developer/Applications/Simulator.app을 제공하지 않고 Contents/Applications/DeviceHub.app(com.apple.dt.Devices)을 제공한다. Apple 공식 경로(Xcode > Open Developer Tool > Device Hub)를 실행하고 해당 워크트리 프로젝트의 실행 대상을 FocusMate W17으로 선택했다. 전용 기기 부팅·simctl 스크린샷·Release 프로세스는 정상이다. 그러나 CUA가 Device Hub 앱에 연결할 때 accessibility 조회가 반복 timeout이고 Xcode screenshot도 unavailable이다. Xcode 메뉴 AX 자체는 동작한다. 숨은 URL/인자·다른 세션 기기·전역 앱 재시작으로 우회하지 않았다.

[Apple Device Hub](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub)의 공식 UI 경로를 확인했다. 기기 화면 제어가 복구되면 다음을 이어서 확인한다: 갤러리2종 노출 → 각 small/medium 배치 →0/150분표시 → 집중/분석·날짜/태그탭 → 앱의최신상태·기간/필터와 원본보존 → 실제OS접근성설정. 미확보 상태를 유지한다.

## 파일 증거

system-release-build-result.json·system-release-appgroup-result.json·system-release-widget-snapshot.json·system-release-widget-snapshot-records.json·system-release-diagnostic-scan.json·system-release-launch.png. 원문 빌드 로그는 system-release-build.log(로컬 ignore 대상)다.
