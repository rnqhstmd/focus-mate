# W18 T3 review

판정: 코드 finding CLOSED — 기존 P2 1건 해결 확인, 시각 검증 pending. 생산 코드 수정·빌드·테스트 실행 없이 설계 v2/T3 seam과 현재 소스 및 제공된 실행 로그를 읽어 검토했다.

## Finding

### CLOSED P2: 집중 위젯의 저장 진행률을 VoiceOver에서도 제공해야 한다
- 위치: `ios/FocusMateWidgets/FocusPromptWidget.swift:42-43` (표시 수치는 26-28행).
- running/paused의 시각 UI는 저장된 진행 38%처럼 수치를 표시하지만, 루트의 `.accessibilityElement(children: .ignore)`가 ProgressView와 숫자 Text를 모두 숨긴다. 대체 `content.axSummary`는 `WidgetPresentation.swift`에서 “저장된 진행”이라는 명칭만 추가하므로 비율을 알 수 없다.
- 결과: 집중 유도 small/medium 모두 진행 수치가 접근성에서 빠져 AC7의 핵심정보 제공에 미달한다.
- 권장: 루트 accessibilityValue 또는 단일 대체 label에 같은 정적 `content.progress`의 반올림 퍼센트를 제공한다. 실시간 값으로 외삽하지 않으며, 숫자 중복 낭독을 만들지 않는다. nil progress에서는 값 없음. 표시/접근성 수치가 동일한 순수 계약을 focused 검사하고 실제 VO 청취는 별도 증거로 남긴다.
- 재검토: `WidgetPresentation.swift:40`은 동일 progress에서 반올림한 “저장된 진행 38%”를 대체 label에 포함한다. nil에서는 생략한다. 시각 숫자와 같은 산식이며 시간 외삽 없음. 기존 children ignore 유지로 숫자 중복 요소도 만들지 않는다.
- 제공 로그 직접 확인: `t3-green-ax-red.log:1679-1682`에서 회귀 테스트 한 개의 세 상태 assertion 실패, `t3-green-ui-recheck.log:469-470`에서 해당 테스트 통과, `:489-491`에서 focused 단위 18개/0 failures. 이 finding은 닫는다.
- 두 실제 위젯 뷰의 `familyOverride: WidgetFamily? = nil`과 `displayFamily = familyOverride ?? family`를 확인했다. production 기본 환경을 유지하면서 시각 호스트가 동일 컴포넌트의 크기 분기를 선택하는 seam이다. 실제 렌더 성공을 의미하지 않는다.

## 설계 일치 확인

- 두 kind가 각 small/medium을 지원하고 기존 Live Activity도 bundle에 유지된다.
- Provider는 실제 WidgetTimelinePlan을 소비한다. 현재/다음 entry에서 동일 snapshot을 미래 시각으로 classify하며 분석 재집계·진도 외삽이 없다.
- 오류는 snapshot nil 경로로 들어가 0분 통계 대신 불러오기 안내를 표시한다. stale은 이전 기준일/업데이트 필요 및 해당 주/기준일 표현을 유지한다.
- 분석 화면은 공유 today/week/7일/topTags 값만 소비한다. 최대값 계산은 막대 스케일용이며 도메인 집계 중복이 아니다.
- 실제 tag/day Link가 WidgetEntryLinks를 사용한다. 원래 generatedAt, 주간 period, named 태그를 보존하고 remainder는 전체 분석으로 연결된다.
- App Group 문자열은 앱/확장 entitlement와 production publisher/provider에서 동일하다. 두 Debug/Release 타깃에 entitlement 경로가 있고 앱 URL scheme이 등록됐다. 테스트 bootstrap은 production publisher 주입을 받지 않는다.
- production 실패 경로에 preview 데이터를 넣지 않는다. 정보 원문이나 전체 report를 새로 공유하는 코드는 이 T3 범위에서 발견하지 못했다.

## 아직 확보하지 않은 증거

- 제공된 재검사 로그에서 focused 단위 18개/0 failures를 확인했다. 같은 실행의 UI는 5개 중 1 failure이며 전체 로그가 TEST FAILED로 끝난다. 단위 GREEN과 실행 전체/UI 상태를 구분한다. reviewer는 빌드/테스트를 직접 실행하지 않았다.
- 실제 네 조합 렌더링, 긴 이름/상위3+기타 4행의 medium 높이, 큰 글자, stale 기준문구 잘림, 링크 hit area는 네이티브 시각 검증이 남는다. 현재 preview fixture는 긴 이름·4개 태그·큰 글자 전체 조합을 제공하지 않는다.
- 9pt 고정 텍스트와 제한된 높이의 가독성/큰 글자 대응은 렌더 결과 없이 합격으로 판단하지 않는다.
- 갤러리 등록·App Group provisioning·실기기 URL 진입·실제 VoiceOver는 미확보다. DEVELOPMENT_TEAM 빈 값은 서명 성공 증거가 아니다.

검토 범위는 T3다. T2의 게시/안전 진입 내부 전체에 대한 재검토 판정은 포함하지 않는다.
