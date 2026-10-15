# W04 승차권·승차 태그 — PR 배경

## 배경
준비 허브(W03)에서 태그·할 일·소리를 확정하면 '승차권 보기' 버튼이 켜졌지만 확정만 하고 어느 화면으로도 이동하지 않았다. 승차권·승차 태그·여행 화면이 없었고, 진행 여정 저장 형식(`journey.active`)도 정의되지 않아 값이 들어 있으면 손상으로 처리됐다. journey FR-11(승차권·승차 태그)이 미반영 상태였다.

사용자 결정:
- Phase 0 '최신 승차 단말기' 브라우저 확인은 보류하고 시안(Pen TUNX2·kxUUR·JmXmQ·Vts6F·DO8HO)과 docs/FLOWS.md 계약으로 구현한다.
- 출발 안내는 FLOWS 2차 계약(세 문장 → '시작')을 채택한다(최신 시안 DO8HO와 일치).
- 재실행 시 메인에 '진행 중인 여정' 안내만 띄우고, 메인 '여행 시작하기'(라벨 변경)는 진행 여정을 기록 없이 정리하고 새로 시작한다(W07 전 임시). 새 승차는 진행 여정을 교체한다(최대 1건).
- 승차 태그 뒤로가기 → 승차권, 저장 실패 → 멈추고 다시 태그, '시작' 뒤 임시 '여행' 화면 + 뒤로가기로 메인.
- 진행 여정만 손상되면 여정만 버리고 카드·기록은 유지한다(보안 감사 HIGH 대응).

## 요구사항
- FR-1~16, BR-1~9, AC-1~28(Given-When-Then) — `.dev/feat-boarding-pass-tag/prd.md`.
- 핵심: 미완성 준비 차단, 30% 겹침 시 놓기 전 인식·진동, 인식 0.3초 뒤 진행 여정 정확히 1회 저장, 1400ms+450ms 뒤 여행, 이탈·숨김은 전환만 취소(저장 유지), 낭독기·키보드 활성화 대체 경로, 동작 줄이기, 가장 큰 글자 도달성.

## 설계 요점 (design.md 2회차)
- 저장: 버전 3 유지, `JourneySnapshot`(선택 입력·태그 정의·소리·승차 시각·phase·진도)만 저장, 구조 검증(카탈로그 대조 없음), v2는 null만.
- 순수 규칙 `BoardingGeometry/Timing/Clock`, 승차권 값 `BoardingPassContent`.
- `BoardingTagController`(저장 recognitionID·전환 transitionToken 분리, pendingSave/pendingTransition 노출), `DepartureBriefingController`.
- 화면 `BoardingPassView`·`BoardingTagView`·`JourneyView`, 주입 묶음 `JourneyServices`.
- 기준선에서 발견한 W10 사진 UI 9건 실패(픽스처가 저장소에 없음)를 UITestBootstrap이 픽스처를 생성하도록 고침.

## Audit Summary
- 1회차: CRITICAL 0, HIGH 1(진행 여정 손상이 파일 전체 차단), MEDIUM 5 → HIGH·MEDIUM 2건(저장 시점 값, `.journey` 가드) 재현 RED 후 수정.
- 2회차: CRITICAL 0, HIGH 0, MEDIUM 6 — 배포 차단 사유 없음. W05 착수 전 처리 권고: 버린 여정 원본 사본·안내, 승차 후 확정값 잔존 재승차, minutes/elapsed 상한·카탈로그.
- 통합 리뷰 2회차: SPEC PASS 28/28, QUALITY PASS(Critical 0, Important 0).
- 자세한 내용: `.dev/feat-boarding-pass-tag/trust-ledger.md`
