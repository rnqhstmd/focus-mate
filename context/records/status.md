# 기록 구현 추적

수정일: 2026-10-16(W09b·W18 인수 검증 반영). 도메인 구성은 사용자 확인으로 확정했고 담당자·사용자 규모는 ❓입니다. ID와 AC 번호는 이 도메인 안에서만 유일합니다. `[웹]`과 `[iOS]`는 별도 구현 범위입니다. `[iOS·P4]`의 P 번호는 [개발 단계](../../docs/DEVELOPMENT-PHASES.md)의 담당 Phase입니다.

## 범례

- ✅ 반영됨 — 해당 웹 또는 iOS 코드에 구현됨. 네이티브·Simulator 검사와 실제 갤러리·실기기 완료는 구분한다.
- ⬜ 미반영 — 네이티브 구현 또는 실기기 검증 전
- 🚫 폐기 — 사용자 확인 후 범위에서 제거한 항목

## 요구사항 원장

| ID | 요구사항 | AC | 상태 | PR |
|---|---|---|---|---|
| FR-1 | [웹] 완료 기록 | AC-1: 하차 성공에서만 1회 생성하고 진행·포기 여정은 완료로 집계하지 않는다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-2 | [웹] 연결 메모 | AC-2: 여행별 최대 200자 선택 메모를 저장하고 수정한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-3 | [웹] 기록 탐색 | AC-3: 연간 일합계 5단계 잔디, 날짜별 최신순 10개씩, 연도 탐색을 제공한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-4 | [웹] 완료 분석 | AC-4: 주/월 합계·횟수·태그 필터를 제공하고 예시와 실제 기록을 분리한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-5 | [iOS·P4] 완료·메모 저장 | AC-5: 타입 모델과 로컬 저장소에 동일한 완료·메모 계약을 구현한다. | ✅ | [W08 PR #9](https://github.com/rnqhstmd/focus-mate/pull/9) |
| NFR-1 | [iOS·P4] 집계·복원 정확성 | AC-6: 시간대·날짜 경계, 손상·중복, 메모 연결을 실제 저장소에서 검증한다. | ✅ | [W08 PR #9](https://github.com/rnqhstmd/focus-mate/pull/9) |
| FR-6 | [iOS·P4] 요약·기록·분석 화면 | AC-7: 하차 후 요약에서 200자 선택 메모를 남기고 기록에서 수정한다. 연간 일합계 5단계 잔디·날짜별 최신순 10개·연도 탐색·주/월·태그 분석을 제공하며 예시와 실제 기록을 분리한다. 분석에는 태그 누적 막대·마친 시간대·자주 탄 노선 상위 3·여행 길이 분포·최장 연속일·메모 회고를 포함한다. | ✅ | [#25](https://github.com/rnqhstmd/focus-mate/pull/25) (코드·Simulator, PR 리뷰 중) |
| FR-7 | [iOS·P4] 동일 완료 기록·기간·날짜 기준의 앱·위젯 공용 순수 분석 집계(W09b) | W09b AC-1~7: 주·월·태그·비교·인사이트를 동일 완료 기록의 순수 집계로 계산한다. | ✅ | [#25](https://github.com/rnqhstmd/focus-mate/pull/25) (코드·Simulator, PR 리뷰 중) |
| FR-8 | [iOS·후속] 공용 집계에 기반한 소형·중형 분석 홈 위젯과 해당 분석 맥락으로의 진입(W18) | W18 AC-1·3~7: 공용 집계를 small·medium 분석 위젯과 기간·태그 앱 진입에 사용한다. | ✅ | [#25](https://github.com/rnqhstmd/focus-mate/pull/25) (코드·Simulator, PR 리뷰 중) |
| NFR-2 | [iOS·후속] 버전 있는 최소 집계 스냅샷의 저장 성공 후 공유·오류 격리·빈 기록/오래된 값/접근 불가 구분(W18) | W18 AC-2·4·6: 검증·저장 성공 뒤 최소 스냅샷을 원자 게시하며 원본 오류·오래된 값·접근 불가를 분리한다. | ✅ | [#25](https://github.com/rnqhstmd/focus-mate/pull/25) (코드·Simulator, PR 리뷰 중) |

## 근거와 개발 연결

- FR-7: W09b [#25](https://github.com/rnqhstmd/focus-mate/pull/25) 구현·인수 ACCEPT. 앱과 위젯의 동일 완료 기록·날짜·기간 순수 집계로 계산을 공유한다.
- FR-8, NFR-2: W18 [#25](https://github.com/rnqhstmd/focus-mate/pull/25) 구현·인수 ACCEPT. 최소 공유 스냅샷·게시 오류 격리·stale/empty/unavailable·분석 small/medium을 구현했다. 실제 갤러리/탭·서명·실기기는 미확보다.

- FR-1 / AC-1: recordJourney / completeFareTag.
- FR-2 / AC-2: saveSummaryMemo / postMemo.
- FR-3 / AC-3: renderRecords.
- FR-4 / AC-4: renderAnalytics. 2026-10-13 시장 조사 반영: renderAnalyticsInsights(시간대·노선·길이·메모)·longestStreak·태그 누적 막대.
- FR-5 / AC-5: W08 RecordSnapshot·RecordSection 및 AppModel 완료/메모 저장 API. 저장 v2 유지, 실제 하차 outcome 연동은 W09 후속.
- NFR-1 / AC-6: RecordSectionTests·RecordStorageTests 신규 35건. 전체 iOS 98 unit + 11 UI, 웹31+edgeQA 및 빌드 통과. 실제 파일 복원·원본 보존·쓰기 실패와 날짜 경계를 검증했다.
- FR-6 / AC-7: 기존 W09a 요약·기록·메모에 W09b 주/월·태그·비교·시간대·노선·길이·연속일·메모 회고를 더했다. [#25](https://github.com/rnqhstmd/focus-mate/pull/25) 인수 ACCEPT. 실기기 VoiceOver(잔디 조정 포함)는 W14.

[현재 동작](../../docs/CURRENT-STATE.md) · [화면 계약](../../docs/FLOWS.md) · [개발 단계](../../docs/DEVELOPMENT-PHASES.md). W08의 FR-5·NFR-1은 PRD 인수 검증 ACCEPT와 직접 iOS 테스트 결과로 갱신했습니다. 화면 및 실제 기기 검증 완료를 의미하지 않습니다.

<!-- gx-sync
git-head: -
svn-revision: -
pr-merged-at: -
-->

## W17·W09b·W18 통합 검증 (2026-10-16)

최초 전체에서 iOS 단위1,426건/0실패·UI270통과/47실패, Node/Python 테스트·전체 빌드가 통과했다. 확인창 테스트 도우미 한 파일만 수정한 뒤 전체 호출부7클래스83건/0실패로 재검증해 미해결0건을 확인했다. 단일 전체UI317/0 재실행 결과는 아니다. [최종 검증](../../.dev/codex-system-surfaces-w18/reports/verify-final.md)·[19개 기준 인수](../../.dev/codex-system-surfaces-w18/reports/acceptance-final.md). 실제 OS 배치·서명·실기기·VoiceOver는 별도 미확보 게이트로 남긴다.
