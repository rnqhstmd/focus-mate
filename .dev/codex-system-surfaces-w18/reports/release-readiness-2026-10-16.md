# Focus Mate 출시 준비 판단 — 2026-10-16

## 결론

현재 기능 구현과 출시 준비는 다른 작업이다. **기존 W14(실기기 QA·출시 준비)를 별도 실행 단위로 진행하는 것이 맞다.** 새 기능 대규모 개발이 항상 필요한 것은 아니지만, 이 앱에도 정책 안내 경로 등 추가 앱 개발과 배포 설정·문서·검증이 남아 있다. 아래 묶음은 조사 제안이며 plan.md에 새 작업을 임의 추가하거나 출시를 시작하지 않았다.

## 현재 앱에서 남은 것

| 우선 | 해야 할 일 | 성격과 확인 근거 |
|---|---|---|
| P0 | 개인정보처리방침을 공개하고 앱 안에서 열 수 있게 연결, 실제 연락 가능한 지원 URL 준비 | 앱 개발+공개 문서/운영. 현재 앱에 정책 경로가 없고 설정 목적지는 placeholder. 지원 사이트와 앱 안 정책 링크는 심사 요건. [심사5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy)·[스토어지원URL](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/) |
| P0 | 최종 앱/확장 식별자·개발팀·App Group·배포 프로파일 확정 | 설정/계정. repo DEVELOPMENT_TEAM 빈값, app.focusmate.prototype 사용. 실제 계정 등록은 미확인. 로컬 Release Simulator 공유 성공은 배포 서명 증명이 아니다. [capabilities](https://developer.apple.com/help/account/identifiers/enable-app-capabilities) |
| P0 | 개인정보 라벨·API 사유·SDK/최종 archive 개인정보 보고서 대조 | 검토, 필요할 때 manifest 개발. PrivacyInfo.xcprivacy 없지만 그 사실만으로 결함이라고 단정하지 않는다. 현 소스에 해당 API 직접호출은 확인되지 않았고 ContinuousClock은 Apple SystemBootTime 목록에 명시되지 않는다. [API목록](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype) |
| P0 | 폰트·데이터·오디오 사용/배포권리 증거와 고지 확정 | 자료 검토, 필요한 고지만 개발. 특히 서울알림체 공식 페이지의 자유사용/무단배포금지 문구만으로 TTF 앱 임베딩 허가를 확정하지 못했다. [서울시서체](https://www.seoul.go.kr/seoul/font.do) |
| P0 | 최종 기기 Archive→Validate→실기기 핵심 흐름/위젯/Island/접근성 QA | 검증, 발견한 결함만 개발. Simulator Release는 통과했지만 실제 갤러리/탭·기기·계정서명은 미확보. [배포절차](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases) |
| P1 | 버전·빌드번호·지원기기/OS·아이콘/런치, 스토어 문구·실제 캡처·연령/암호화 응답·심사 안내 | 설정/자산/운영. 현재1.0(1), iOS17+, iPhone, 1024아이콘. 실제버스ETA/GPS앱으로 오인되는 설명을 피한다. [배포준비](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution)·[스토어정보](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/) |
| P1 | TestFlight 배포→피드백/수정→정식심사→공개 | 계정/운영. 최초 외부 베타 심사와 정식심사는 별개. [TestFlight](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/) |

## 출시 작업의 묶음

1. **출시 기반·정책:** 배포 식별자/팀·권한, 정책·지원 URL, 라이선스·필요한앱안내. 종료 근거는 실제 설정·접근 가능한 페이지·앱경로와 권리증빙이다.
2. **출시 후보 검증:** 최종 Release 기기 archive/Validate, 설치·업그레이드·복구·사진·오디오·지도·집중생명주기·위젯/Island·VoiceOver/큰글자/ReduceMotion. 종료 근거는 빌드/기기별 실제 결과와 미해결 결함0이다.
3. **스토어·TestFlight·제출:** 실제 캡처/설명·연령/개인정보/암호화/연락처/심사절차, 베타 피드백, 심사제출/승인/공개상태. 업로드/초대/계약/제출은 아직 실행하지 않았다.

1의 계정/정책 준비와3의 문구/자산 초안은 병행할 수 있다. 2는 최종 코드·지원 범위·서명이 확정돼야 끝낼 수 있다. 심사 처리 시간을 포함한 일정은 현재 자료로 산정하지 않았다.

## 오해하기 쉬운 요건

- 현재 업로드는2026-04-28부터 iOS26 SDK 이상이 요구된다. 설치된 Xcode27/SDK27은 버전 숫자 조건을 만족하지만 업로드/심사 통과를 의미하지 않는다. 최소 실행 OS를26으로 올리라는 요건은 아니다. [Apple SDK공지](https://developer.apple.com/news/?id=ueeok6yw)
- 로컬 완료기록/메모의 기기 내 처리는 수집에서 제외될 수 있다. MapKit 및 포함SDK가 있으므로 실제 처리와 Apple 자체 수집/개발자 수집을 구분한 뒤 답해야 한다. [App Privacy](https://developer.apple.com/app-store/app-privacy-details/)
- 계정이 없는 현재 앱에 계정 삭제 기능을 새로 만들 의무가 자동 발생하지 않는다. 로컬 자료·공유본·OS백업의 보관/삭제 설명은 별개다. [심사5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy)
- 개인정보 manifest는 실제 API/SDK 사용에 맞춰 결정한다. 모든 타이머앱에 SystemBootTime 사유를 일괄 추가하지 않는다. 개인정보 라벨과 API 사유는 다른 항목이다.
- App Store 접근성 표시는 검증한 일반 작업 범위만 답한다. 현재 공식 안내는 초기 자율제공이며 무조건 의무라고 단정하지 않는다. [접근성라벨](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/)
- Icon Composer로 교체하거나 스플래시 영상을 새로 만드는 것이 출시 필수는 아니다. 기존 asset catalog를 사용하는 경로도 공식 배포 문서에 있다.

## 조사 근거와 한계

Apple 공식 문서의 현재 요건과 로컬 코드/설정을 대조했다. 정책은 권위기관 단일출처이며 서로 다른 블로그로 검증한 것처럼 표현하지 않는다. 계정 가입/만료·실제프로파일·App Store Connect 답변·국가별계약·폰트 앱임베딩허가·기기QA·업로드/심사 결과는 미확보다. 서울서체는 서울시 공식 원문을 추가 확인했다. 법률 준수 완료 판정이 아니다.

현재 실행 결과는 [후속검증](system-verification-followup.md)에 분리했다. 상세 조사 원문은 로컬 .research/app-store-policy-20261016.md, app-store-distribution-20261016.md, focusmate-release-code-audit-20261016.md에 있다. .research는 ignore 대상이며 본 문서는 PR에 보존하는 요약이다.
