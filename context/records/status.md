# 기록 구현 추적

수정일: 2026-10-13. 도메인 구성은 사용자 확인으로 확정했고 담당자·사용자 규모는 ❓입니다. ID와 AC 번호는 이 도메인 안에서만 유일합니다. `[웹]`과 `[iOS]`는 별도 구현 범위입니다. `[iOS·P4]`의 P 번호는 [개발 단계](../../docs/DEVELOPMENT-PHASES.md)의 담당 Phase입니다.

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
| FR-5 | [iOS·P4] 완료·메모 저장 | AC-5: 타입 모델과 로컬 저장소에 동일한 완료·메모 계약을 구현한다. | ⬜ | - |
| NFR-1 | [iOS·P4] 집계·복원 정확성 | AC-6: 시간대·날짜 경계, 손상·중복, 메모 연결을 실제 저장소에서 검증한다. | ⬜ | - |
| FR-6 | [iOS·P4] 요약·기록·분석 화면 | AC-7: 하차 후 요약에서 200자 선택 메모를 남기고 기록에서 수정한다. 연간 일합계 5단계 잔디·날짜별 최신순 10개·연도 탐색·주/월·태그 분석을 제공하며 예시와 실제 기록을 분리한다. 분석에는 태그 누적 막대·마친 시간대·자주 탄 노선 상위 3·여행 길이 분포·최장 연속일·메모 회고를 포함한다. | ⬜ | - |

## 근거와 개발 연결

- FR-1 / AC-1: recordJourney / completeFareTag.
- FR-2 / AC-2: saveSummaryMemo / postMemo.
- FR-3 / AC-3: renderRecords.
- FR-4 / AC-4: renderAnalytics. 2026-10-13 시장 조사 반영: renderAnalyticsInsights(시간대·노선·길이·메모)·longestStreak·태그 누적 막대.
- FR-5 / AC-5: 네이티브 구현 전.
- NFR-1 / AC-6: 네이티브 구현 전.
- FR-6 / AC-7: 네이티브 구현 전. Phase 1의 기록 화면은 뒤로가기만 있는 빈 목적지다.

[현재 동작](../../docs/CURRENT-STATE.md) · [화면 계약](../../docs/FLOWS.md) · [개발 단계](../../docs/DEVELOPMENT-PHASES.md). 현재 요구사항 원장은 코드와 마지막 직접 VM 검사로 작성했으며 자동 git 동기화는 아직 실행하지 않았습니다.

<!-- gx-sync
git-head: -
svn-revision: -
pr-merged-at: -
-->
