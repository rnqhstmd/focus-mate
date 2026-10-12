# 여정 구현 추적

수정일: 2026-10-12. 도메인 구성은 사용자 확인으로 확정했고 담당자·사용자 규모는 ❓입니다. ID와 AC 번호는 이 도메인 안에서만 유일합니다. `[웹]`과 `[iOS]`는 별도 구현 범위입니다.

## 범례

- ✅ 반영됨 — 현재 웹 코드에 구현됨. VM 검사 표시는 모형 검증이며 실제 브라우저·iPhone 완료를 의미하지 않음
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
| FR-5 | [iOS] 실제 분 타이머 | AC-6: 선택한 실제 분을 진행하며 pause/resume 및 로컬 체크포인트를 구현한다. | ⬜ | - |
| FR-6 | [iOS] MapKit 가상 코스 | AC-7: 기본 지도와 승인된 앱 내 가상 코스를 표시한다. 실제 GPS·버스 API는 범위 밖이다. | ⬜ | - |
| NFR-2 | [iOS] 생명주기 안전 | AC-8: 잠금·종료·복귀에서 저장 손실·중복·앱 밖 진도 증가가 없는지 실기기로 검증한다. | ⬜ | - |

## 근거와 개발 연결

- FR-1 / AC-1: selectTime / currentTimeJourney.
- FR-2 / AC-2: syncPreparation / completePreparation.
- FR-3 / AC-3: completeFareTag / 신규 VM hold 회귀.
- FR-4 / AC-4: tick / checkpointJourney / resumePreviousJourney.
- NFR-1 / AC-5: prototype-edge-qa.cjs 직접 실행 결과.
- FR-5 / AC-6: 네이티브 구현 전.
- FR-6 / AC-7: 네이티브 구현 전.
- NFR-2 / AC-8: 실기기 검사 전.

[현재 동작](../../docs/CURRENT-STATE.md) · [화면 계약](../../docs/FLOWS.md) · [개발 단계](../../docs/DEVELOPMENT-PHASES.md). 현재 요구사항 원장은 코드와 마지막 직접 VM 검사로 작성했으며 자동 git 동기화는 아직 실행하지 않았습니다.

<!-- gx-sync
git-head: -
svn-revision: -
pr-merged-at: -
-->
