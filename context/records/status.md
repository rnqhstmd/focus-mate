# 기록 구현 추적

수정일: 2026-10-16(공용 집계·위젯 계획 추가). 도메인 구성은 사용자 확인으로 확정했고 담당자·사용자 규모는 ❓입니다. ID와 AC 번호는 이 도메인 안에서만 유일합니다. `[웹]`과 `[iOS]`는 별도 구현 범위입니다. `[iOS·P4]`의 P 번호는 [개발 단계](../../docs/DEVELOPMENT-PHASES.md)의 담당 Phase입니다.

## 범례

- ✅ 반영됨 — 현재 웹 코드에 구현됨. VM 검사 표시는 모형 검증이며 실제 브라우저·iPhone 완료를 의미하지 않음
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
| FR-6 | [iOS·P4] 요약·기록·분석 화면 | AC-7: 하차 후 요약에서 200자 선택 메모를 남기고 기록에서 수정한다. 연간 일합계 5단계 잔디·날짜별 최신순 10개·연도 탐색·주/월·태그 분석을 제공하며 예시와 실제 기록을 분리한다. 분석에는 태그 누적 막대·마친 시간대·자주 탄 노선 상위 3·여행 길이 분포·최장 연속일·메모 회고를 포함한다. | ⬜ | - |
| FR-7 | [iOS·P4] 동일 완료 기록·기간·날짜 기준의 앱·위젯 공용 순수 분석 집계(W09b) | - | ⬜ | - |
| FR-8 | [iOS·후속] 공용 집계에 기반한 소형·중형 분석 홈 위젯과 해당 분석 맥락으로의 진입(W18) | - | ⬜ | - |
| NFR-2 | [iOS·후속] 버전 있는 최소 집계 스냅샷의 저장 성공 후 공유·오류 격리·빈 기록/오래된 값/접근 불가 구분(W18) | - | ⬜ | - |

## 근거와 개발 연결

- FR-7: 기존 대기 W09b에 공용 순수 집계 범위를 보강한다. 분석 화면과 위젯에서 계산을 중복하지 않으며 새 집계 전용 작업을 만들지 않는다.
- FR-8, NFR-2: W18 대기. W09b 집계 결과를 공유·갱신·표시하며 집중 유도 위젯과 한 브랜치/PR로 구현한다. [승인 계획](../../.dev/system-surfaces-plan/plan.md)의 작업별 AC를 사용하며 원장의 AC는 착수 PRD에서 연결한다. 아직 구현·검증 완료가 아니다.

- FR-1 / AC-1: recordJourney / completeFareTag.
- FR-2 / AC-2: saveSummaryMemo / postMemo.
- FR-3 / AC-3: renderRecords.
- FR-4 / AC-4: renderAnalytics. 2026-10-13 시장 조사 반영: renderAnalyticsInsights(시간대·노선·길이·메모)·longestStreak·태그 누적 막대.
- FR-5 / AC-5: W08 RecordSnapshot·RecordSection 및 AppModel 완료/메모 저장 API. 저장 v2 유지, 실제 하차 outcome 연동은 W09 후속.
- NFR-1 / AC-6: RecordSectionTests·RecordStorageTests 신규 35건. 전체 iOS 98 unit + 11 UI, 웹31+edgeQA 및 빌드 통과. 실제 파일 복원·원본 보존·쓰기 실패와 날짜 경계를 검증했다.
- FR-6 / AC-7: W09a로 요약(200자 선택 메모)·기록(연 단위 잔디 5단계, 선택 날짜 최신순 10개 더 보기, 연도 이동, 메모 남기기/수정)이 일부 반영됐다. 주/월·태그 분석과 인사이트는 W09b라 상태는 ⬜ 유지한다. 실기기 VoiceOver(잔디 조정)는 W14.

[현재 동작](../../docs/CURRENT-STATE.md) · [화면 계약](../../docs/FLOWS.md) · [개발 단계](../../docs/DEVELOPMENT-PHASES.md). W08의 FR-5·NFR-1은 PRD 인수 검증 ACCEPT와 직접 iOS 테스트 결과로 갱신했습니다. 화면 및 실제 기기 검증 완료를 의미하지 않습니다.

<!-- gx-sync
git-head: -
svn-revision: -
pr-merged-at: -
-->
