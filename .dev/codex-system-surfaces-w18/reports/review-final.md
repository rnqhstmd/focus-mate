# W18 phase-review

판정: PASS_REVIEW — 수정이 필요한 미해결 finding 0건. 전체 검증 완료/서명/실기기 출시는 별도 판정이다.

## Part 1 — PRD·설계 적합성

PRD AC1~7, design.md v2와 T3 seam을 먼저 읽고 T1/T2/T3 생산 코드, 개별 리뷰 및 시각 기록을 확인했다. 소스·테스트를 변경하거나 빌드/테스트를 실행하지 않았다.

| 기준 | 판정과 근거 |
|---|---|
| AC1 네 조합·최소 공유 | 두 kind가 small/medium을 지원한다. WidgetSnapshot은 최소 여정과 today/week/7일/topTags만 가지며 task/memo/cardID/recordID 목록/전체 report가 없다. 기존 Live Activity를 bundle에 보존한다. |
| AC2 게시·실패 격리 | AppSnapshot.launchRoute가 원본 전체 validate를 먼저 수행한다. persist·직접 supplement·검증 복원·cleanup 경계를 확인했다. migration 저장 전 eligibility 보류, 실패 후보 미게시, atomic write 성공 뒤만 reload, 공유 실패가 원본 성공을 뒤집지 않는다. |
| AC3 분석 일치·자정 | 앱 투영은 W09b 주간 report의 값을 복사한다. Provider는 순수 계획의 두 entry를 실제 소비하며 자정/30분 뒤 같은 snapshot을 stale로 분류한다. 위젯 계산은 차트 스케일뿐이며 도메인 재집계는 없다. |
| AC4 상태 구분 | unavailable/malformed/unsupported는 접근불가 화면이며 0분으로 대체하지 않는다. validEmpty는 여정을 보존한다. stale에 기준일·업데이트 필요·해당 주 표현이 유지된다. |
| AC5 안전 진입 | URL은 원 발급시각·TTL·period를 유지한다. pending은 실제 소비 시 다시 parse한다. 최신 ID 불일치/열린 흐름을 보존하고 running/paused는 showActiveJourney만 수행한다. 자동 resume 없음. new는 기존 확인 UI만 요청하며 분석 tag는 최신 report로 검증한다. |
| AC6 권위·빈도 | 저장 elapsed/total의 정적 진행이며 시계 외삽과 매초 reload가 없다. 읽기 실패를 새 빈 공유본으로 게시하지 않는다. |
| AC7 접근성·증거 | 진행률 AX 누락은 수정·회귀 확인 완료. 정상/빈/오류/stale 및 긴 이름/accessibility3의 네이티브 컴포넌트 캡처를 직접 열었다. 실제 갤러리·서명·기기·VO·OS Reduce Motion의 미확보 사유가 visual-verification.md에 명시되어 ‘결과 또는 사유’ 계약을 충족한다. 실제 검증 통과로 전환하지 않는다. |

## Part 2 — 품질·회귀 검토

- Codable 검증 경계는 version 먼저 구분, 7일 연속성·합계·top3/remainder 구조·journey 값 일관성을 검사한다. 원본 손상을 일부 집계로 숨기지 않는다.
- 파일 writer는 `.atomic`이며 목적파일 선삭제/fallback 경로가 없다. MainActor publisher와 읽기 전용 extension의 경계가 유지된다.
- URI는 URLComponents·명시적 허용 필드·ID UTF16 비교를 사용한다. small/medium 실제 링크가 WidgetEntryLinks를 소비한다. remainder는 실제 이름 기타의 필터와 구분된다.
- production publisher만 App Group store를 주입하고 UI bootstrap은 기본 nil을 유지한다. 앱/확장 entitlement, kind, scheme 문자열이 맞는다.
- T1 기존 2건, T3 AX 기존 1건은 수정된 현재 소스에서 닫힘을 확인했다. 신규 actionable finding은 발견하지 못했다.
- 큰 글자에 고밀도 정보를 줄이는 집중 small은 상태·저장진도·CTA·기준을 유지하고 생략된 전체 노선/목적지는 AX summary에 남는다. 분석은 7일·네 태그·합계·횟수·기준을 유지한다.

## 직접 확인한 시각 범위

- `w18-native-accessibility3-after.png`: 네 조합이 경계 안에 들어오며 핵심 숫자·행동·기준줄이 겹치지 않는다. medium 분석의 태그4행과 7막대가 함께 보인다.
- `w18-native-four-widgets.png`: 정상 38%/오늘25분/주125분 및 정상 빈 분석0의 표현을 확인했다. 긴 스크롤 호스트의 일부 카드가 화면 경계에 걸린 캡처이므로 이를 독립 시스템 위젯 잘림 증거로 보지 않는다.
- `w18-native-stale-unavailable.png`: 이전 기준·업데이트 필요와 접근불가를 0과 분리한다.
- 모두 실제 위젯 View를 임시 iOS 호스트에 배치한 캡처다. WidgetKit 갤러리/OS 실제 배치/탭 실행 증거가 아니다. familyOverride 기본 nil은 production 환경값을 유지한다.

## 실행 증거 구분

- T3 AX 회귀: 제공 로그를 직접 읽어 assertion RED 뒤 focused 단위 18개/0 failures를 확인했다.
- T2 단위 32개 통과는 부모 보고 상태다. 이 최종 리뷰에서 해당 단위 로그를 새로 직접 대조하지 않았다.
- `t2-ui-final-focused.log`에서 기존 실패였던 새 여정 확인·취소 사례가 실제 alert 버튼을 눌러 원본 유지까지 확인하고 passed로 끝난 것을 직접 읽었다. 보고서 작성 중 마지막 UI 사례가 진행 중이므로 최종 5개 전체 통과는 아직 이 문서에서 주장하지 않는다.
- 전체 suite는 사용자 지시대로 아직 실행 전이다. 이 PASS는 구현 리뷰 통과이며 전체 검증 게이트를 대체하지 않는다.
- DEVELOPMENT_TEAM/App Group provisioning, 실제 갤러리, 실제 위젯 탭, 실기기, 실제 VoiceOver 청취, OS Reduce Motion 설정 전환은 미확보다. 기록된 사유를 유지한다.

결론: 다음 통합 검증 단계로 진행 가능. 실행 중 UI 최종 결과 및 전체 검증 결과는 별도 원장에 확정한다.
