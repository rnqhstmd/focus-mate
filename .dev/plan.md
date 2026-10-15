# 작업 계획

| ID | 작업 | 도메인 | 요구사항 | 의존 | 작업 위치 | 상태 |
|----|------|--------|----------|------|-----------|------|
| W00 | 도메인 저장 구조 확장(버전 1→2) | 공통 | Phase 1 `app-state.json` 확장 | - | feat/domain-storage-schema-v2 | 완료 |
| W01 | [P2] 카드 발급·접촉 카드 | card | card FR-3 | W00 | feat/card-issuance-contact-card | 완료 |
| W02 | [P2] 첫 출발지·시간·버스·도착지 선택 | journey | journey FR-7, FR-8 | W00 | feat/first-station-time-bus-destination | 완료 |
| W03 | [P2] 준비 허브·태그·소리 | journey | journey FR-9, FR-10 | W02 | codex/feat-preparation-tags-sound | 완료 |
| W04 | [P2] 승차권·승차 태그 | journey | journey FR-11 | W01, W03 | feat/boarding-pass-tag | 완료 |
| W05 | [P3] 실제 분 타이머·일시정지 | journey | journey FR-5 | W04 | feat/real-minute-timer-pause | 완료 |
| W06 | [P3] MapKit 가상 코스 | journey | journey FR-6 | W05 | feat/mapkit-virtual-course | 완료 |
| W07 | [P3] 포기·이어가기·생명주기 | journey | journey FR-13, NFR-2(Simulator) | W05 | feat/abandon-resume-lifecycle | 완료 |
| W08 | [P4] 완료·메모 저장 모델 | records | records FR-5, NFR-1 | W00 | codex/feat-completed-record-memo | 완료 |
| W09 | [P4] 하차 태그·요약·기록·분석 | 통합 | journey FR-12, records FR-6 | W05, W08 | feat/alighting-summary-records | 진행 |
| W10 | [P5] 카드 꾸미기 | card | card FR-4, NFR-2 | W01 | codex/feat-card-customization | 완료 |
| W11 | [P5] 마이페이지 | card | card FR-5 | W01, W08 | feat/my-page | 완료 |
| W12 | [P5] 접근성·동작 설정 | preferences | preferences FR-3 | - | - | 폐기 |
| W13 | [P5] 저장 오류 복구 | preferences | preferences FR-4 | W00 | codex/feat-storage-error-recovery | 완료 |
| W14 | [P6] 실기기 QA·출시 준비 | 통합 | journey NFR-2(실기기), preferences NFR-2 | W04, W06, W07, W09, W10, W11, W13 | - | 대기 |
| W15 | [P3] 다이나믹 아일랜드·잠금 화면 진행 표시(Live Activity) | journey | journey FR-5 보조(2026-10-15 사용자 요청) | W05 | feat/live-activity-progress | 완료 |
| W16 | [P3] 서울 전체 실데이터 번들(정류장·노선·버스·구간 시간) | journey | journey FR-7·FR-8·FR-6 데이터 교체(2026-10-15 사용자 요청) | W02, W06 | - | 대기 |

요구사항 ID는 `context/{도메인}/status.md`의 원장을 따른다. `[P2]`는 [개발 단계](../docs/DEVELOPMENT-PHASES.md)의 Phase다.

실행 묶음(위 `의존` 열에서 계산한 순서다. 의존을 바꾸면 이 표도 다시 계산한다):

| 묶음 | 병렬 실행 가능 | 선행 묶음 |
|------|----------------|-----------|
| 1 | W00 | - |
| 2 | W01 · W02 · W08 · W13 | 1 (W00) |
| 3 | W03 · W10 · W11 | 2 |
| 4 | W04 | 3 (W03) |
| 5 | W05 | 4 |
| 6 | W06 · W07 · W09 | 5 |
| 7 | W14 | 6 |
| 8 | W16 | 6 (W06) · 2 (W02) — W09와 동시 진행 금지(아래) |

- 가장 긴 경로: W00 → W02 → W03 → W04 → W05 → W06/W07/W09 → W14 (7단계).
- 같은 묶음이라도 W03·W04는 아래 Phase 0 확인이 끝나야 착수한다.
- 묶음 2의 W08·W13은 W00이 만든 저장 섹션만 고치고 저장 파일 구조를 다시 바꾸지 않는다.

묶음 5~6 진행 순서(2026-10-15 결정):
- W04 → W05는 순차다. W05와 병렬로 돌릴 수 있는 작업은 없다(W06·W07·W09 모두 W05 선행).
- W05 완료 후 **W07 + W06을 병렬**로 먼저 진행하고, **W09는 W07 머지 뒤** 시작한다.
  - W07 우선: W04의 임시 동작(메인 '여행 시작하기'가 진행 여정을 확인 없이 폐기)을 이어가기·포기로 바꾼다. 사용자가 여정을 잃을 수 있는 유일한 지점이다. 생명주기 안전(NFR-2 Simulator)도 여기서 다룬다.
  - W06 병렬: 여행 화면 위 지도 중심의 화면 작업이라 저장·진행 여정 로직과 겹침이 적다.
  - W09 후순위: W07과 진행 여정 제거·현재 정류장 변경·메인 진입을 함께 고쳐 동시 진행 시 충돌 위험이 크다. W07이 정한 여정 정리 방식 위에 하차를 얹는다.
- 출시는 W05·W07까지 끝낸 뒤 묶어서 한다(W04 단독이면 '시작' 이후 여정을 끝낼 수단이 없다).
- 병렬 세션은 작업마다 워크트리·시뮬레이터·빌드 폴더를 따로 쓰고, 한 세션 안에서 빌드를 겹치지 않는다(디스크 부족 전력).

W16 범위(2026-10-15 사용자 결정):
- 예시 데이터(`RouteData.swift`: 버스 3개, 가상 순환 정류장 9개)를 **서울 전체 실제 데이터**로 바꾼다. 필요한 것은 정류장 정보·노선 정보(노선별 정류장 순서)·버스 정보·정류장 사이 소요 시간 네 가지뿐이다.
- **번들 정적 데이터**로 간다. 실제 GPS(현재 위치)와 실시간 버스 API는 영구 범위 밖이다. 첫 출발 정류장은 지금처럼 사용자가 검색해 고른다.
- 원천: 서울 열린데이터광장 OA-1095 `서울시버스노선별정류소정보(날짜).xlsx`(매월 갱신, 약 3MB)와 정류소 위치·노선 기본 정보. 공유자원포털 API는 2025-09-26 화재 이후 신규 키 발급 불가라 쓰지 않는다. 공공누리 출처 표기를 앱 안에 둔다.
- 정류장 사이 소요 시간은 공개 파일이 없다(BMS 내부 자료). 연속 정류장 좌표 거리 ÷ 평균 버스 속도(정차 포함, 버스 종류별 차등 가능)로 구간 분을 미리 계산한다.
- 변환 스크립트(xlsx → 앱용 압축 데이터)를 저장소에 두고, 산출 파일을 앱 번들에 넣는다.
- 다시 정할 것: 왕복형 실제 노선의 방향·회차(지금은 순환), 버스·도착지 후보 규칙(지금은 시간이 정류장 간격으로 나누어떨어지는 버스만), 수천 개 정류장 검색과 동명 정류장 방면 표시, 지도 코스(W06 좌표 근사 → 실제 좌표), 기존 저장 정류장·버스 id 이전.
- W09(하차)와 동시 진행 금지: 둘 다 정류장 id·`reachedStation`·도착지 규칙을 고친다. 먼저 머지된 쪽 위에 나중 작업을 얹는다.

착수 조건:
- W03은 Phase 0의 **태그 선택 중간 화면** 확인, W04는 **최신 승차 단말기** 확인이 끝나야 착수한다([Phase 0 남은 확인](../docs/PHASE-0-BASELINE.md#남은-확인)).
- W14는 서명·배포 정보와 실기기가 준비돼야 착수한다.
- 모든 작업은 새 화면에 VoiceOver·Dynamic Type·동작 줄이기를 적용한다(preferences FR-3). 별도 점검 작업(W12)은 두지 않는다.

의존 근거:
- W00: Phase 1 버전 1 스냅샷을 확장해 카드·여정·기록 저장 섹션과 마이그레이션을 먼저 만든다. 여러 작업이 같은 저장 파일을 동시에 고치지 않게 하기 위한 선행이다.
- W02→W03→W04: 시간·버스·도착지 선택값을 준비 허브가, 완성된 준비를 승차권이 소비한다. W04는 W01의 카드 뷰도 사용한다.
- W05: 승차 접촉으로 생성된 진행 여정이 있어야 타이머가 돈다. W06은 W05가 만드는 집중 화면 위에 지도를 올린다.
- W09: 진행 여정(W05)과 완료·메모 저장 모델(W08)이 있어야 하차 완료를 만든다.
- W11: 마이페이지의 완료 여정 수·시간은 W08의 집계를 읽는다.
- W12(폐기, 2026-10-13): 앱 내 동작 줄이기 토글 없이 시스템 설정만 따르기로 하면서 사용자에게 보이는 기능이 남지 않았다. 시스템 값은 SwiftUI `accessibilityReduceMotion`으로 바로 읽고, 접근성은 각 작업이 새 화면에 적용한다.

완료 인계:
- W04(승차권·승차 태그·출발 안내, feat/boarding-pass-tag): 준비 확정 → 승차권 → 승차 태그(30% 겹침 놓기 전 인식, 0.3초 뒤 진행 여정 1회 저장, 1.4초+0.45초 뒤 여행) → 출발 안내('시작' = 출발 확인 저장) → 임시 '여행' 화면. 메인 진행 여정 안내와 '여행 시작하기' 자동 폐기(임시 동작). 기준선에서 W10 사진 UI 9건 실패(픽스처가 저장소에 없음)를 함께 고쳤다. 상세는 [W04 리뷰 유예](feat-boarding-pass-tag/reports/review-deferred.md).
  - W05 완료 인계(2026-10-15): 저장 v4(`paused`), 타이머 `JourneyTimerController`. W07 항목(재실행 뒤 메인 진입점, 타이머 화면 나가기·포기, 메인 정리 확인)은 해결됨(아래 W07 완료 인계). W06: 타이머 화면 위에 지도를 올린다(남은 시간 하단 좌측). W15: 컨트롤러의 status·remainingSeconds로 종료 시각을 계산해 Live Activity에 넘긴다(진도 계산은 바꾸지 않음).
  - (W04 인계, 처리됨) W05: 진행 여정(`JourneySnapshot`, 버전 3 `journey.active`)에 새 필수 필드를 추가하면 currentVersion을 4로 올린다(W04 앱은 모르는 키를 버리고 다시 쓴다). 착수 전 처리할 것: ① 손상·검증 실패 active는 읽을 때 버려지고 다음 저장에서 사본 없이 사라짐 → 원본 `.backup` 보관 또는 안내 결정, ② 승차 성공 뒤에도 확정값이 남아 재승차가 진행 여정을 덮을 수 있음 → 진도가 생기기 전 정책 결정, ③ minutes·elapsedSeconds 상한과 카탈로그에 없는 정류장·버스 id 처리. 여행 임시 화면(`JourneyView` 시작 후 `journey.placeholder`)과 `DepartureBriefingController`의 '시작' 이후 자리에 실제 타이머를 넣는다.
  - (W07 인계, 처리됨) 메인 자동 폐기와 임시 안내를 이어가기·포기로 바꿨다. 남은 항목: 카드 교체 기능이 생기면 `activeJourney.cardID == currentCard.id` 불변식 처리(폐기/갱신)를 함께 정한다.
  - W07 완료 인계(2026-10-15): 이어가기 카드·새 여정 확인·일시정지 중 포기 구현, 저장 형식 변경 없음. W09: 도착 여정의 메인 처리(도착지를 현재 정류장으로 하는 '새 여정 시작')는 임시다. 하차 저장은 `endingActiveJourney(at:)`와 `reachedStation`(도착이면 저장된 도착지)을 재사용하고 `ActiveJourneyCardContent.Kind.arrived`를 하차 진입으로 바꾼다. W06: 머지 후 AC-3·V7 AC29·AC-33을 재실행하고, 하단 `safeAreaInset` 포기 바와 지도 도구 배치를 조정하며, 포기 호출은 `abandonJourney(timerPaused:)` 계약을 지킨다. W15: 변경 없음. 출시 게이트: 도착 화면(`journey.arrived`)에는 나가는 길이 없어 앱을 다시 켜야 메인으로 간다 — W09 하차 전 외부 배포(TestFlight 포함) 금지. Release 빌드의 DEBUG 코드 제외 확인과 확인 창 첫 VoiceOver 포커스는 W14.
  - W09: 승차 태그(`BoardingTagController`·`BoardingRules`·`BoardingTagView`)를 하차에 재사용할 수 있다. 하차 LCD는 카드 이름(FLOWS 2차).
  - W14: 실제 VoiceOver 포커스('시작' 버튼)·카드 활성화(VoiceOver/Full Keyboard Access)·승차 햅틱 체감, 제스처 시스템 취소 후 재태그, Release 산출물에 `fm-ui` 문자열 부재를 실기기에서 확인. Phase 0 '최신 승차 단말기' 브라우저 확인은 사용자 결정으로 보류.
- W06(MapKit 가상 코스, feat/mapkit-virtual-course, [#18](https://github.com/rnqhstmd/focus-mate/pull/18)): 여행 화면 배경 지도, 정류장 id별 좌표의 가상 코스, 진도 기반 버스 이동, 따라가기/자유 탐색, 지도 테마 시트, 하단 남은 시간·정류장·거리. 저장 형식 변경 없음.
  - W07: 여행 화면 나가기를 만들면 `JourneyView.onDisappear`의 `map.leave()`가 시트를 닫는다(AC-23 UI 검증은 W07에서 추가). 일시정지 버튼은 왼쪽 위 원형으로 옮겼다.
  - W09: 저장 도착지가 계산 도착지와 다르면 지도를 생략한다(`CourseJourney.init?`) — 도착 안내도 같은 규칙. 도착 상태에서 지도 도구 활성 여부와 정류장 목록 펼침을 함께 정한다.
  - W14: 실기기 M-1(법적 표기 가림)·M-2(VoiceOver 낭독·초기 포커스)·M-3(제스처 충돌, 가만히 둬도 따라가기 유지)·M-4(큰 글자 겹침·값 잘림)·M-5(어두운 지도·위성 모양)·M-6(오프라인)·M-7(렌더), 배터리 부담(1초 카메라 애니메이션), 앱 개인정보 라벨(타일 요청 시 IP·지도 영역).
  - 후속 과제(유예): 시각적 "가상 코스" 표기 여부(사용자 결정), 좌표 없는 정류장 추가 시 크래시 대신 지도 생략, CourseJourney 입력 불변식(direction ±1·minutesPerStop>0), 따라가기 아이콘이 '내 위치'로 오해될 수 있음.
- W10(구현·리뷰·제한 범위 검증 완료, [#15](https://github.com/rnqhstmd/focus-mate/pull/15)): 카드 외형·사진 편집, 단일 버전 3 저장과 버전 1·2 호환, 실패/취소 보존, W11 마이페이지 실제 편집 연결·공통 외형 표시를 구현했다. 최종 단위547건·Release 빌드·웹31건과 edge QA 통과, 제품 인수 ACCEPT. 전체 UI115건 중108건은 사용자 요청으로 중단하여 미완료다. [W10 최종 검증](codex-feat-card-customization/reports/final-verification.md)에 실행 범위를 구분했다.
  - W04: PassFace(style: model.currentCardStyle)에서 저장 외형을 읽는다. 카드 도메인은 접촉 성공·여행 완료를 결정하지 않으며 LCD에는 기존 이름·체크 정책을 유지한다.
  - W14: 실제 iPhone의 PhotosPicker·앱 생명주기·큰 글자·VoiceOver 조작·햅틱 및 출시 QA가 남아 있다. VO width swipe 추가 경로와 가져오기 안내의 지속 시각 초점도 미확정이다.
- W11(완료, PR #13 — W10보다 먼저 머지): 마이페이지(ProfileView)와 records 누적 집계(RecordSection.lifetimeSummary)를 추가했다. 기준선에서 발견한 W02 큰 글자 회귀(시간 화면 첫 후보 잘림)도 함께 고쳤다.
  - W10 합류 완료: 마이페이지 꾸미기 행은 실제 편집 세션으로 연결했고 자리표시 cardStudio/customize 매핑을 제거했다. PassFace는 현재 저장 외형을 읽으며 profileRecords 시드는 버전 3 호환을 유지한다. ProfileSeedTests·ProfileUITests 및 큰 글자 메인→프로필→편집→복귀를 확인했다. 실행 시점과 최종 미완료 회귀는 [W10 최종 검증](codex-feat-card-customization/reports/final-verification.md)을 참조한다.
  - W09: 하차 완료가 기록으로 저장되면 마이페이지 통계가 자동으로 늘어난다(별도 연결 불필요). `ProfileModelTests` AC-17이 저장 후 갱신을 검증한다.
  - W14: 마이페이지 VoiceOver 실제 읽기(통계 한 요소 낭독)·동작 줄이기는 실기기 미검증으로 남겼다. W10 합류 후 가장 큰 글자에서 메인의 "마이페이지" 진입점과 프로필 편집 행 도달·복귀를 시뮬레이터에서 확인했다. 실제 iPhone에서는 다시 확인한다.
- W02(완료, PR #11): W03의 선행이 충족됐다. W03은 Phase 0 **태그 선택 중간 화면** 확인만 남았다.
  - W01: 저장은 최신 `snapshot` → `updating…` → `AppModel.save`, 기능별 `AppModel+기능.swift` 확장 관례를 맞춘다. `--fm-ui-save fail`은 이제 모든 진입 상태에 쓰기 실패를 주입하고, 시드 실패 저장은 메인에서만 일으킨다. 공용 저장 실패 문구는 최초 정류장 설정 화면에서 숨긴다(`RootView` 조건).
  - W03: 메인 "여행 준비"(`open.preparation`)는 시간 선택을 거쳐 준비 진입점으로 간다. 여정 선택은 `AppModel.preparedJourney` 하나에서 읽는다. 준비 화면 "완료 버튼 없음" 검증은 `PreparationFlowUITests`에 있으니 버튼을 추가하면 함께 고친다.
  - W04: 카탈로그 밖 정류장 id(시간 선택이 막힘)와 실행 중 현재 정류장이 바뀔 때 `journeyPlan` 선택 무효화를 다시 본다.
  - W14: VoiceOver 휠 1칸=1분, 동작 줄이기 상태는 실기기 미검증으로 남겼다.

- W03(2026-10-14): 사용자 지시로 Phase0 브라우저 선확인 보류. 실제 웹 화면 미검증, 네이티브 기능 검증 별도 수행.
