# 여정 구현 추적

수정일: 2026-10-15(W06 반영). 도메인 구성은 사용자 확인으로 확정했고 담당자·사용자 규모는 ❓입니다. ID와 AC 번호는 이 도메인 안에서만 유일합니다. `[웹]`과 `[iOS]`는 별도 구현 범위입니다. `[iOS·P2]`의 P 번호는 [개발 단계](../../docs/DEVELOPMENT-PHASES.md)의 담당 Phase입니다.

## 범례

- ✅ 반영됨 — `[웹]`은 현재 웹 코드, `[iOS]`는 네이티브 코드와 Simulator 자동 테스트로 구현됨. VM·Simulator 검사는 실기기 완료를 의미하지 않음
- ⬜ 미반영 — 네이티브 구현 또는 실기기 검증 전
- 🚫 폐기 — 사용자 확인 후 범위에서 제거한 항목

## 요구사항 원장

| ID | 요구사항 | AC | 상태 | PR |
|---|---|---|---|---|
| FR-1 | [웹] 시간·여정 선택 | AC-1: 15~360 min을 1분 단위로 입력하고 유효한 버스·도착지를 선택해야 준비로 진행한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-2 | [웹] 준비 확정 | AC-2: 태그 미선택으로 시작하고 공백 할 일은 차단하며 편집 왕복에서 초안을 유지한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-3 | [웹] 승하차 접촉 | AC-3: 승차 접촉 체크포인트·하차 완료를 각각 1회만 반영한다. 승차만 인식 1400ms·페이드 450ms이고 하차는 기존 타이밍이다. 중복·장면/숨김 지연 전환 취소를 유지한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-4 | [웹] 진행·중단·재개 | AC-4: 30초 압축 시연에서 일시정지·포기·수동 재개를 지원하고 앱 밖 시간은 진도에 더하지 않는다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| NFR-1 | [웹/VM] 상태·비동기 안전 | AC-5: 21장면·441 포커스·882 취소 및 정/역방향·늦은 오디오 decode 회귀가 종료 코드 0이다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-5 | [iOS·P3] 실제 분 타이머 | AC-6: 선택한 실제 분을 진행하며 pause/resume 및 로컬 체크포인트를 구현한다. | ✅ | [#17](https://github.com/rnqhstmd/focus-mate/pull/17) |
| FR-6 | [iOS·P3] MapKit 가상 코스 | AC-7: 기본 지도와 승인된 앱 내 가상 코스를 표시한다. 실제 GPS·버스 API는 범위 밖이다. | ✅ | W06 [#18](https://github.com/rnqhstmd/focus-mate/pull/18) |
| NFR-2 | [iOS·P3/P6] 생명주기 안전 | AC-8: 잠금·종료·복귀에서 저장 손실·중복·앱 밖 진도 증가가 없는지 실기기로 검증한다. P3는 Simulator 구현·검사, P6는 실기기 검증이다. | ⬜ | - |
| FR-7 | [iOS·P2] 첫 출발 정류장 | AC-9: 최초 설정에서만 가상 정류장을 검색해 이름·방면을 선택하고 현재 정류장으로 저장한다. 결과 없음은 선택 불가이며 이후 앱 안 재검색·초기화는 없다. | ✅ | [#11](https://github.com/rnqhstmd/focus-mate/pull/11) |
| FR-8 | [iOS·P2] 시간·버스·도착지 선택 | AC-10: 15~360 min을 1분 단위로 고르고 정확히 맞는 버스·도착지를 선택해야 준비로 진행한다. 시간 변경 시 후보 선택을 해제한다. | ✅ | [#11](https://github.com/rnqhstmd/focus-mate/pull/11) |
| FR-9 | [iOS·P2] 준비 허브·태그 | AC-11: 태그 미선택으로 시작하고 공백 할 일을 차단한다. 새 태그의 빈 이름·중복을 검사하고 편집 왕복에서 초안을 유지한다. | ✅ | [#14](https://github.com/rnqhstmd/focus-mate/pull/14) |
| FR-10 | [iOS·P2] 소리 선택·재생 | AC-12: 소리 없음과 라이선스 확인한 샘플 4종의 미리듣기·반복·시작/중지 페이드를 제공한다. 취소는 확정값을 유지하고 재생 실패 시 무음으로 계속한다. | ✅ | [#14](https://github.com/rnqhstmd/focus-mate/pull/14) |
| FR-11 | [iOS·P2] 승차권·승차 태그 | AC-13: 미완성 준비는 승차권 진입을 차단한다. 카드가 태그 영역과 30% 이상 겹치면 놓기 전에 인식(진동)하고, 인식 접촉 성공 시 진행 여정을 1회 저장하고 1400ms 유지·450ms 전환 후 여행 화면의 출발 안내로 간다. 확인 전에는 진행·남은 시간이 멈춘다. 이탈·숨김은 전환만 취소하고 저장은 유지한다. | 🟡 | [#16](https://github.com/rnqhstmd/focus-mate/pull/16) |
| FR-12 | [iOS·P4] 도착 안내·하차 태그 | AC-14: 진행이 끝나면 도착 안내를 보여주고 확인 뒤 하차 태그로 간다. 하차 접촉 성공 1회에만 완료를 records에 전달하고 도착 정류장을 저장하며 재개 정보를 제거한다. 중복 접촉은 무시한다. | ⬜ | - |
| FR-13 | [iOS·P3] 포기·이어가기 | AC-15: 포기는 확인 후 도달 정류장을 저장하고 완료 기록 없이 재개 정보를 제거한다. 메인에서 남은 여정을 수동 재개하고, 새 여정은 기존 여정 정리를 확인한다. | ⬜ | - |

## 근거와 개발 연결

- FR-1 / AC-1: selectTime / currentTimeJourney.
- FR-2 / AC-2: syncPreparation / completePreparation.
- FR-3 / AC-3: completeFareTag / 신규 VM hold 회귀.
- FR-4 / AC-4: tick / checkpointJourney / resumePreviousJourney.
- NFR-1 / AC-5: prototype-edge-qa.cjs 직접 실행 결과.
- FR-5 / AC-6: W05 PR #17 — 실제 분 타이머·일시정지·10초 체크포인트·저장 v4 구현. 백그라운드에서도 진행(사용자 결정), 종료 후 일시정지 복원. 이어가기·나가기는 W07, 실기기 확인은 W14. 보조(W15): 잠금 화면·다이나믹 아일랜드 진행 표시(Live Activity) — 위젯 확장 `FocusMateWidgets`, 컨트롤러 옵저버 알림 → `JourneyLiveActivitySync`, 앱 시작 정리. 실기기 렌더·VoiceOver 확인은 W14.
- FR-6 / AC-7: W06(PR #18). `JourneyCourse`(정류장 id별 실제 위치 근사 좌표, 서울 경계)·`JourneyCourseProgress`(진도 → 버스 위치·남은 정류장·거리)·`JourneyMapState`·`JourneyMapController`(저장자 없음)·`JourneyMapView`(SwiftUI Map, POI 숨김, 라벨 있는 위성)·`JourneyMapThemeSheet`. 하단 남은 시간·정류장·거리, 따라가기/자유 탐색, 일시정지 중 도구 잠금, 지도 상태 미저장. 단위 `JourneyCourseTests`·`JourneyCourseProgressTests`·`JourneyMapDisplayTests`·`JourneyMapStateTests`·`JourneyMapControllerTests`·`AppInfoLocationTests`, UI `JourneyMapUITests`·`JourneyMapAccessibilityUITests`. 실기기 확인 M-1~M-7(법적 표기·VoiceOver·제스처·큰 글자·지도 모양·오프라인·렌더)은 W14. 정류장 목록 펼침은 후속.
- NFR-2 / AC-8: 실기기 검사 전.
- FR-7 / AC-9: W02(PR #11). `InitialStationSearchView`·`StationSearchState`·`StationCatalog`(가상 정류장 3건, 이름·별칭·방면 검색), `AppModel+JourneyStart.confirmInitialStation`이 최초 정류장 화면에서만 1회 저장. 단위 `StationCatalogTests`·`StationSearchStateTests`·`JourneyStartModelTests`, UI `FirstStationSearchUITests`·`StationSaveFailureUITests`·`PreparationFlowUITests`(재실행 후 재검색 진입점 없음).
- FR-8 / AC-10: W02(PR #11). `TimeSelectionView`(15~360분 휠)·`JourneyPlanDraft`·`JourneyPlanner`(정류장 간격으로 나누어떨어지는 버스만 후보, 9개 순환 정류장 위 도착지). 시간 변경 시 선택 해제, 선택값은 실행 중 메모리만. 단위 `JourneyPlannerTests`·`JourneyPlanDraftTests`, UI `TimeSelectionUITests`·`PreparationFlowUITests`·`LargeTextUITests`. VoiceOver 1분 조절·동작 줄이기는 실기기 미검증(W14).
- FR-9 / AC-11: W03(PR #14). 준비 허브의 태그 단일 선택·할 일 검증·사용자 태그 이름/중복/상한·왕복 보존을 구현. 유효한 준비값 전달까지만 제공하며 진행·기록 저장은 하지 않음.
- FR-10 / AC-12: W03(PR #14). 승인 번들 WAV4종과 소리 없음, 임시 선택의 저장/취소, 반복 미리듣기·시작/중지 페이드·오류 후 계속·늦은 재생 차단. 단위366+UI99=465 및 웹31+edge QA 실패0, 빌드 통과·경고0. 실제 시안7상태 대조91/pass. 실제 VoiceOver·실기기 청취는 W14 미검증.
- FR-11 / AC-13: W04 PR #16 — 승차권·승차 태그·진행 여정 저장·출발 안내(시작) 구현, 실기기 VoiceOver·햅틱은 W14. FR-12~FR-13 / AC-14~AC-15: 네이티브 구현 전. 승차권·진행·하차·포기 등은 후속 작업. W03은 기존 여정 선택과 준비 초안을 W04가 소비할 요청 경계에 제공한다.

[현재 동작](../../docs/CURRENT-STATE.md) · [화면 계약](../../docs/FLOWS.md) · [개발 단계](../../docs/DEVELOPMENT-PHASES.md). 현재 요구사항 원장은 코드와 마지막 직접 VM 검사로 작성했으며 자동 git 동기화는 아직 실행하지 않았습니다.

<!-- gx-sync
git-head: -
svn-revision: -
pr-merged-at: -
-->
