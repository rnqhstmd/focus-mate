# 카드 구현 추적

수정일: 2026-10-15. 도메인 구성은 사용자 확인으로 확정했고 담당자·사용자 규모는 ❓입니다. ID와 AC 번호는 이 도메인 안에서만 유일합니다. `[웹]`과 `[iOS]`는 별도 구현 범위입니다. `[iOS·P2]`의 P 번호는 [개발 단계](../../docs/DEVELOPMENT-PHASES.md)의 담당 Phase입니다.

## 범례

- ✅ 반영됨 — 해당 [웹]/[iOS] 범위에 구현되고 아래 명시한 검증을 통과함. VM은 모형, Simulator는 시뮬레이터 증거이며 실제 iPhone 완료를 의미하지 않음
- ⬜ 미반영 — 해당 요구사항 구현 전. 구현 후 남은 실기기 QA는 근거에 별도로 기록함
- 🟡 부분 반영 — iOS에서 일부 범위만 구현됨. 남은 범위는 아래 근거에 적는다
- 🚫 폐기 — 사용자 확인 후 범위에서 제거한 항목

## 요구사항 원장

| ID | 요구사항 | AC | 상태 | PR |
|---|---|---|---|---|
| FR-1 | [웹] 1회 카드 발급 | AC-1: 카드 ID를 저장하고 기존 사용자를 보존하며 승하차에 같은 ID를 표시한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-2 | [웹] 카드 꾸미기 | AC-2: 사진 최대 6장·파일당 8MB, 색·배치·겹침·삭제·되돌리기·고정 IC 칩을 지원한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| NFR-1 | [웹] 편집·저장 안전 | AC-3: 취소 확인·시연 분리·저장 실패 안내를 유지한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-3 | [iOS·P2] 카드 발급·접촉 카드 | AC-4: 공통 SwiftUI 카드 뷰로 1회 발급하고 카드 ID를 저장하며 기존 사용자를 보존한다. 승하차 카드와 LCD에 같은 이름을 표시하고(카드 번호는 어떤 화면에도 표시하지 않음) 지원 기기에서만 발급 햅틱을 낸다. 사진 입력은 FR-4로 분리했다. | 🟡 | W01 [#12](https://github.com/rnqhstmd/focus-mate/pull/12) |
| NFR-2 | [iOS·P5] 카드·사진 보존 | AC-5: 로컬 카드·사진 저장과 복원·용량 제한을 실제 저장소에서 검증한다. | ✅ | W10 [#15](https://github.com/rnqhstmd/focus-mate/pull/15) |
| FR-4 | [iOS·P5] 카드 꾸미기 | AC-6: 배경색과 플랫폼 사진 입력으로 최대 6장을 넣고 위치·크기·겹침·삭제·되돌리기를 제공한다. IC 칩과 비접촉 표시만 고정이고(브랜드·이름·문구는 꾸미면 사라짐) 사진은 카드 경계에서 잘린다. 기본 카드는 서울 점묘 배경이며 카드 번호를 카드에 표시하지 않는다. 편집 취소는 확인한다. | ✅ | W10 [#15](https://github.com/rnqhstmd/focus-mate/pull/15) |
| FR-5 | [iOS·P5] 마이페이지 | AC-7: 같은 카드와 records가 집계한 완료 여정 수·시간을 표시한다. card는 집계를 계산하지 않고 읽기만 한다. | ✅ | W11 [#13](https://github.com/rnqhstmd/focus-mate/pull/13), W10 [#15](https://github.com/rnqhstmd/focus-mate/pull/15) |

## 근거와 개발 연결

- FR-1 / AC-1: createTransitPass / loadTransitPass.
- FR-2 / AC-2: cardStudio / saveCardStyle.
- NFR-1 / AC-3: saveCardStyle / cardStyleStorageOK.
- FR-3 / AC-4: W01에서 발급 화면(CardIssuanceView)·1회 발급과 카드 저장(CardSnapshot `FM-`+8자리·발급 시각)·기존 사용자 보충(AppModel.start)·공통 카드 뷰(PassFace)·이름/번호 단일 출처(PassIdentity)·발급 그라데이션 햅틱을 구현했다(PRD AC-1~21). 승하차 카드 배치와 LCD 이름·체크 표시는 W04에서 구현한다. VoiceOver 장식 비노출·완료 후 포커스·실기기 진동 체감은 수동 확인 전.
- NFR-2 / AC-5: W10은 CardSnapshot.style과 처리 사진 Data를 단일 버전 3 app-state.json에 함께 보존하고 LocalSnapshotStore의 원자적 쓰기를 사용한다. 입력 장당 8MiB·최대 6장, 처리 후 보존 장당 1MiB·전체 6MiB로 제한한다. 버전 1·2는 기본 외형으로 읽고 읽기만으로 재저장하지 않는다. 저장 사진의 디코딩·치수와 외형 구조를 검증한다. 실패 시 이전 파일·저장 외형을 유지하며 명시적 복구는 W13의 원본 백업 검증 뒤 정리 순서를 따른다. 소유 Photos 원본 2장을 삭제한 뒤 같은 저장 상태를 재실행하여 사진 ID·이미지 hash·치수·배치·색 유지를 확인했다. 전체 파일 bytes 비교는 삭제 후 두 cold launch 사이만 수행했다. 원본 파일 자체를 별도로 보관하는 기능과 처리 사진 보존은 구별한다. 실제 iPhone 보존·성능 QA는 W14 대기다.
- FR-4 / AC-6: W10은 독립 초안에서 준비색·사용자 색·PhotosPicker 입력, 사진 선택·위치·비율 유지 크기·앞뒤 이동·삭제·최근 20회 되돌리기·기본 복원을 제공한다. 변경 또는 입력 중 종료는 계속 편집/버리기를 확인하며 버린 뒤 늦게 도착한 입력은 반영하지 않는다. 실패 저장은 초안을 유지하여 재시도한다. PassFace는 기본 서울 점묘·고정 IC 칩/비접촉 표시를 공유하고 꾸민 카드의 브랜드·이름·문구를 숨기며 사진을 경계에서 자른다. 카드 번호는 표시하지 않는다. 서울알림 폰트와 승인 R39/R40 시안을 대조했다. 장식 카드 내부만 고정 글자 크기를 유지하고 화면 본문·도구는 Dynamic Type을 따른다. 실제 iPhone·햅틱 체감은 W14 대기다.
- FR-5 / AC-7: W11에서 마이페이지(ProfileView, 시안 EPnQQ 구성)를 구현했다. 통계는 records의 RecordSection.lifetimeSummary를 ProfileStats로 읽기만 하고(card 모델에 집계 없음), 화면은 "3"·"1 h 5 min", VoiceOver는 "완료한 여정, 3회"·"함께한 시간, 1시간 5분". 유효하지 않은 기록이면 "-"와 안내. W10 합류로 카드 꾸미기 행은 실제 편집 세션을 열고 저장/닫기 후 같은 마이페이지로 돌아온다. 저장 성공 안내는 복귀 화면에 표시하며 PassFace(style: model.currentCardStyle)가 같은 저장 외형을 읽는다. 자리표시 cardStudio/customize 매핑은 제거했다. 카드 정체성·기록·집계 불변 및 XXXL 메인→마이페이지→편집→복귀를 Simulator에서 검증했다. 카드 내부 시안 근거는 W10 화면 보고서에 있다. VoiceOver 실제 낭독·동작 줄이기는 실기기 미검증(W14).
- FR-5 / AC-7 보충: 마이페이지 큰 글자 UI 테스트 2건 실패는 테스트 결함(스크롤 없이 진입점 isHittable 단언)이라 W09a에서 테스트만 고쳤고 화면 변경은 없다.

W10은 최종 단위 547건·Release 빌드, 웹 31건과 edge QA·빌드를 통과했고 제품 인수 Must34/34·Should1/1, 리뷰 차단 결함 0건이다. 안내 수정 전 완료 UI7건과 통합 focused UI6건은 별도 시점 근거다. 전체 UI115건 중 나머지108건은 사용자 요청으로 중단하여 미완료다. 실제 VoiceOver 선택·상태·현재값 및 X/Y 조작은 확인했고 width swipe 추가 경로와 가져오기 안내의 지속 시각 초점은 미확정이다. [W10 최종 검증](../../.dev/codex-feat-card-customization/reports/final-verification.md)과 [제품 인수](../../.dev/codex-feat-card-customization/reports/acceptance.md)를 참조한다.

[현재 동작](../../docs/CURRENT-STATE.md) · [화면 계약](../../docs/FLOWS.md) · [개발 단계](../../docs/DEVELOPMENT-PHASES.md). 현재 원장은 웹 VM 검사와 위 항목별 iOS 실행 근거를 구분하여 작성했습니다. 자동 git 동기화는 실행하지 않았습니다.

<!-- gx-sync
git-head: -
svn-revision: -
pr-merged-at: -
-->
