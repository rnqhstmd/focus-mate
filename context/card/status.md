# 카드 구현 추적

수정일: 2026-10-13. 도메인 구성은 사용자 확인으로 확정했고 담당자·사용자 규모는 ❓입니다. ID와 AC 번호는 이 도메인 안에서만 유일합니다. `[웹]`과 `[iOS]`는 별도 구현 범위입니다. `[iOS·P2]`의 P 번호는 [개발 단계](../../docs/DEVELOPMENT-PHASES.md)의 담당 Phase입니다.

## 범례

- ✅ 반영됨 — 현재 웹 코드에 구현됨. VM 검사 표시는 모형 검증이며 실제 브라우저·iPhone 완료를 의미하지 않음
- ⬜ 미반영 — 네이티브 구현 또는 실기기 검증 전
- 🚫 폐기 — 사용자 확인 후 범위에서 제거한 항목

## 요구사항 원장

| ID | 요구사항 | AC | 상태 | PR |
|---|---|---|---|---|
| FR-1 | [웹] 1회 카드 발급 | AC-1: 카드 ID를 저장하고 기존 사용자를 보존하며 승하차에 같은 ID를 표시한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-2 | [웹] 카드 꾸미기 | AC-2: 사진 최대 6장·파일당 8MB, 색·배치·겹침·삭제·되돌리기·고정 IC 칩을 지원한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| NFR-1 | [웹] 편집·저장 안전 | AC-3: 취소 확인·시연 분리·저장 실패 안내를 유지한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-3 | [iOS·P2] 카드 발급·접촉 카드 | AC-4: 공통 SwiftUI 카드 뷰로 1회 발급하고 카드 ID를 저장하며 기존 사용자를 보존한다. 승하차 카드와 LCD에 같은 이름/ID를 표시하고 지원 기기에서만 발급 햅틱을 낸다. 사진 입력은 FR-4로 분리했다. | ⬜ | - |
| NFR-2 | [iOS·P5] 카드·사진 보존 | AC-5: 로컬 카드·사진 저장과 복원·용량 제한을 실제 저장소에서 검증한다. | ⬜ | - |
| FR-4 | [iOS·P5] 카드 꾸미기 | AC-6: 배경색과 플랫폼 사진 입력으로 최대 6장을 넣고 위치·크기·겹침·삭제·되돌리기를 제공한다. IC 칩은 고정이고 사진은 카드 경계에서 잘린다. 편집 취소는 확인한다. | ⬜ | - |
| FR-5 | [iOS·P5] 마이페이지 | AC-7: 같은 카드와 records가 집계한 완료 여정 수·시간을 표시한다. card는 집계를 계산하지 않고 읽기만 한다. | ⬜ | - |

## 근거와 개발 연결

- FR-1 / AC-1: createTransitPass / loadTransitPass.
- FR-2 / AC-2: cardStudio / saveCardStyle.
- NFR-1 / AC-3: saveCardStyle / cardStyleStorageOK.
- FR-3 / AC-4: 네이티브 구현 전.
- NFR-2 / AC-5: 네이티브 구현 전.
- FR-4·FR-5 / AC-6·AC-7: 네이티브 구현 전. Phase 1은 발급 여부만 저장하며 카드 ID·외형은 아직 없다.

[현재 동작](../../docs/CURRENT-STATE.md) · [화면 계약](../../docs/FLOWS.md) · [개발 단계](../../docs/DEVELOPMENT-PHASES.md). 현재 요구사항 원장은 코드와 마지막 직접 VM 검사로 작성했으며 자동 git 동기화는 아직 실행하지 않았습니다.

<!-- gx-sync
git-head: -
svn-revision: -
pr-merged-at: -
-->
