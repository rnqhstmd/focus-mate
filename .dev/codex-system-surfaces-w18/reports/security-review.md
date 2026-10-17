# W18 통합 보안·정책 정적 감사

기준: prd.md와 design.md v2 및 T3 검증 seam. 읽기 감사와 이 보고서 작성만 수행했다. 빌드·테스트·시뮬레이터·브라우저 실행, 앱 소스 수정은 하지 않았다. T3 focused 및 UI 수리는 진행 중이며 확정 완료로 판정하지 않는다.

## 발견 사항

확인된 RISK/POLICY/GAP/ASSUMPTION 없음. CRITICAL0/HIGH0/MEDIUM0. 아래 확인은 소스 정합성에 한정하며 실제 등록·서명·통합 검증 통과를 뜻하지 않는다.

## 개인정보 최소 투영

- WidgetSnapshotProjection.make는 snapshot.launchRoute()의 전체 검증 후 W09b 주간 report의 today/week 합계·정확히7일·상위태그/기타만 WidgetAnalytics로 복사한다. 앱 원본 snapshot이나 전체 report를 직렬화하지 않는다.
- 여정은 상태·여정ID·버스번호·목적지·총초·저장경과만 공유한다. 카드ID/task/memo/최근기록/원본recordID목록/노선insights 필드가 공유 DTO에 없다.
- 여정 진도는 저장된 값의 정적 비율이다. WidgetPresentation과 FocusPromptWidget은 ‘저장된 진행’과 기준일을 알리고 벽시계로 경과를 더하지 않는다.
- 원본·기록 입력 오류는 투영 실패로 끝나며 손상 항목을 생략한 0이나 부분 집계를 게시하지 않는다.

## 파일·버전·실패 격리

- WidgetSnapshotStore는 주입된 App Group URL 아래 고정 widget-snapshot-v1.json만 읽고 쓴다. URL nil/read 실패는 unavailable이며 Documents나 원본 저장소 fallback은 없다.
- write는 먼저 검증/encode를 마친 뒤 기본 Data.write(.atomic)를 사용한다. 목적 파일을 먼저 삭제하지 않는다. 이 감사에서 실제 I/O 실패를 새로 실행하지는 않았다.
- Codec은 버전을 먼저 구분하고 나머지 손상은 malformed로 분리한다. 날짜/시간대/7일 연속성·합계·태그수/합·여정 필드·경과 범위와 산술 overflow 검사를 확인했다.
- Freshness는 미래 생성시각을 malformed, 날짜/시간대 변경·30분 만료를 stale로 구분한다. 오류 자료를 validEmpty로 변환하지 않는다.
- Publisher는 projection/write 성공 후에만 reload한다. 공유 실패는 false로 흡수하며 앱 원본 저장 성공을 되돌리거나 원본 파일을 수정하지 않는다. 신선한 동일 payload는 재게시하지 않는다.

## 원본 저장·복원·마이그레이션 경계

- AppModel.persist는 원본 store.save 성공과 snapshot/ready 확정 이후 eligibility를 켜고 게시한다. save 실패 경로는 새 후보를 게시하지 않는다.
- loadSnapshot은 eligibility를 먼저 끄고 성공한 검증 원본만 게시한다. migration 또는 카드 보충이 필요한 복원은 확정 저장 전 게시하지 않는다. migration 저장 실패 뒤 foreground도 eligibility가 false라 미게시다.
- 직접 카드 보충 저장·원본 보존 정리 성공에도 게시 경계가 연결돼 있다. 실패한 읽기·복구·정리로 빈 자료를 게시하는 경로를 발견하지 못했다.
- Root scene active는 확정 원본 재투영만 요청하며 원본에 추가 저장하거나 타이머를 진전시키지 않는다. 게시자는 MainActor이며 위젯 Provider는 공유 읽기만 수행한다.

## 링크·최신 상태·직접 제어 금지

- WidgetLinkCodec은 scheme/host/path/version, 사용자정보·port·fragment 부재, 전체/문자열 길이, 제어문자, 숫자 발급시각, 날짜, period 허용값을 검사한다. 중복 query와 알 수 없는 필드는 거절한다.
- 발급시각은 snapshot.generatedAt에서 생성하며 렌더 시각으로 새로 만들지 않는다. 미래 발급은 invalid, 86400초 이상은 expired다. pending은 raw URL 한 개를 보관하고 실제 consume 시 현재 시각으로 다시 parse하며 적용 전 삭제한다.
- journey/new는 최신 activeID와 UTF-16 단위로 비교하며 nil 불일치도 거절한다. 이미 열린 여정·다른 흐름은 alreadyOpen으로 유지해 강제 pop·중복 진입을 피한다.
- v2대로 running/paused는 showActiveJourney만 반환한다. apply에서 resumeJourney를 호출하지 않으므로 링크 자체로 타이머 재개·저장·resume token 생성이 없다.
- 출발 대기는 기존 여정 화면, 도착은 기존 beginAlighting의 무저장 화면 진입이다. 준비는 진행 여정이 없는 기존 startTripFromMain을 사용한다. 새 여정은 기존 confirmation을 표시하고 사용자 확정 전 destructive 메서드를 호출하지 않는다.
- 분석은 kind/week 맥락을 보존하고 미래/없는 날짜를 오늘로 제한한다. apply 직전 최신 전체 records를 재검증하고 없는 태그를 해제한다. 실패하면 기본 records로만 진입한다.
- malformed/expired/safeHome에는 저장·직접 제어를 추가하지 않는다. 커스텀 URL은 인증수단으로 취급하지 않으며 앱 내부 상태 가드가 실제 동작을 제한한다.

## 위젯 설정·표시·갱신

- 기존 WidgetBundle에 Live Activity와 두 계열을 함께 보존하며 각 계열은 small/medium만 선언한다. small 기본 widgetURL과 medium 분석 Link가 실제 WidgetEntryLinks를 소비한다. 직접제어 AppIntent는 추가하지 않는다.
- 앱/확장 entitlements에 동일 group.app.focusmate.prototype, 앱 URL scheme focusmate, 확장 NSExtensionPointIdentifier=com.apple.widgetkit-extension이 선언돼 있다. pbxproj의 각 Debug/Release 타깃에 entitlement 경로가 연결돼 있다.
- DEVELOPMENT_TEAM은 비어 있다. 선언만으로 등록·프로비저닝·실기기 App Group 접근 성공을 판정하지 않는다.
- Provider는 현재와 다음 경계의 두 Entry를 생성하고 같은 snapshot을 미래 시각으로 classify한다. 분석 재집계·진도 보간·매초 reload를 추가하지 않았다. 오류/이미 stale은 15분 또는 자정 경계로 재요청하며 즉시 반복 루프를 피한다.
- stale은 이전 기준일/해당 주와 업데이트 필요를 표시한다. 오류3종은 불러올 수 없음과 앱 열기로 표현하며 실제0분/0회로 표시하지 않는다.

## 증거 및 남은 한계

- 이번 작업은 정적 감사다. T1/T2 테스트 소스에서 실패격리·TTL·중복query·migration·원본 저장순서 사례를 읽었으나 이를 새로 실행하지 않았다.
- T3 focused/UI 수리 결과는 진행 중이므로 이 보고서의 성공 근거로 집계하지 않는다. 전체 테스트·빌드도 아직 최종 통합 단계에서 확인해야 한다.
- 실제 갤러리 등록·서명·cold/warm URL 전달·실제 위젯 렌더/갱신·VoiceOver 청취는 별도 증거가 필요하다. 코드의 AX요약과 미리보기만으로 통과를 주장하지 않는다.
- 공식 API/등록 근거는 reports/apple-widget-docs.md에 별도로 보존돼 있다. App Group/스킴 문자열은 현재 프로젝트 설정값이며 계정 소유권·프로비저닝 성공을 추정하지 않는다.

## 탐색 추가 항목
- AppSnapshot.launchRoute/validate — 투영 전 전체 원본 검증 경계.
- AppModel+Alighting.beginAlighting, AppModel+Boarding.startTripFromMain — 링크가 기존 무저장 진입·진행 여정 가드를 사용하는지 확인.
- JourneyTimerController — 실행 중 권위 및 기존 checkpoint 정책. 변경하거나 새 검증하지 않았다.

추가 확인 사항 없음. 정적 감사가 완료되었습니다.

```yaml
security_verdict:
  status: PASS_STATIC
  critical: 0
  high: 0
  medium: 0
  risk: 0
  policy: 0
  gap: 0
  assumption: 0
  t3_focused_and_ui: in_progress_unconfirmed
  final_integration_verification: pending
  signing_gallery_device_voiceover: unverified
```
