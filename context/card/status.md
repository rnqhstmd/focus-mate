# 카드 구현 추적

수정일: 2026-10-13. 도메인 구성은 사용자 확인으로 확정했고 담당자·사용자 규모는 ❓입니다. ID와 AC 번호는 이 도메인 안에서만 유일합니다. `[웹]`과 `[iOS]`는 별도 구현 범위입니다. `[iOS·P2]`의 P 번호는 [개발 단계](../../docs/DEVELOPMENT-PHASES.md)의 담당 Phase입니다.

## 범례

- ✅ 반영됨 — 현재 웹 코드에 구현됨. VM 검사 표시는 모형 검증이며 실제 브라우저·iPhone 완료를 의미하지 않음
- ⬜ 미반영 — 네이티브 구현 또는 실기기 검증 전
- 🟡 부분 반영 — iOS에서 일부 범위만 구현됨. 남은 범위는 아래 근거에 적는다
- 🚫 폐기 — 사용자 확인 후 범위에서 제거한 항목

## 요구사항 원장

| ID | 요구사항 | AC | 상태 | PR |
|---|---|---|---|---|
| FR-1 | [웹] 1회 카드 발급 | AC-1: 카드 ID를 저장하고 기존 사용자를 보존하며 승하차에 같은 ID를 표시한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-2 | [웹] 카드 꾸미기 | AC-2: 사진 최대 6장·파일당 8MB, 색·배치·겹침·삭제·되돌리기·고정 IC 칩을 지원한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| NFR-1 | [웹] 편집·저장 안전 | AC-3: 취소 확인·시연 분리·저장 실패 안내를 유지한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-3 | [iOS·P2] 카드 발급·접촉 카드 | AC-4: 공통 SwiftUI 카드 뷰로 1회 발급하고 카드 ID를 저장하며 기존 사용자를 보존한다. 승하차 카드와 LCD에 같은 이름을 표시하고(카드 번호는 어떤 화면에도 표시하지 않음) 지원 기기에서만 발급 햅틱을 낸다. 사진 입력은 FR-4로 분리했다. | 🟡 | W01 `feat/card-issuance-contact-card` |
| NFR-2 | [iOS·P5] 카드·사진 보존 | AC-5: 로컬 카드·사진 저장과 복원·용량 제한을 실제 저장소에서 검증한다. | ⬜ | - |
| FR-4 | [iOS·P5] 카드 꾸미기 | AC-6: 배경색과 플랫폼 사진 입력으로 최대 6장을 넣고 위치·크기·겹침·삭제·되돌리기를 제공한다. IC 칩과 비접촉 표시만 고정이고(브랜드·이름·문구는 꾸미면 사라짐) 사진은 카드 경계에서 잘린다. 기본 카드는 서울 점묘 배경이며 카드 번호를 카드에 표시하지 않는다. 편집 취소는 확인한다. | ⬜ | - |
| FR-5 | [iOS·P5] 마이페이지 | AC-7: 같은 카드와 records가 집계한 완료 여정 수·시간을 표시한다. card는 집계를 계산하지 않고 읽기만 한다. | ⬜ | - |

## 근거와 개발 연결

- FR-1 / AC-1: createTransitPass / loadTransitPass.
- FR-2 / AC-2: cardStudio / saveCardStyle.
- NFR-1 / AC-3: saveCardStyle / cardStyleStorageOK.
- FR-3 / AC-4: W01에서 발급 화면(CardIssuanceView)·1회 발급과 카드 저장(CardSnapshot `FM-`+8자리·발급 시각)·기존 사용자 보충(AppModel.start)·공통 카드 뷰(PassFace)·이름/번호 단일 출처(PassIdentity)·발급 그라데이션 햅틱을 구현했다(PRD AC-1~21). 승하차 카드 배치와 LCD 이름·체크 표시는 W04에서 구현한다. VoiceOver 장식 비노출·완료 후 포커스·실기기 진동 체감은 수동 확인 전.
- NFR-2 / AC-5: 네이티브 구현 전.
- FR-4·FR-5 / AC-6·AC-7: 네이티브 구현 전. W01부터 카드 ID·발급 시각을 저장하고 기본 외형 카드(PassFace)를 쓴다. 꾸민 외형은 아직 없다.

[현재 동작](../../docs/CURRENT-STATE.md) · [화면 계약](../../docs/FLOWS.md) · [개발 단계](../../docs/DEVELOPMENT-PHASES.md). 현재 요구사항 원장은 코드와 마지막 직접 VM 검사로 작성했으며 자동 git 동기화는 아직 실행하지 않았습니다.

<!-- gx-sync
git-head: -
svn-revision: -
pr-merged-at: -
-->
