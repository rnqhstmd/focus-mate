# W10 설계 비판 검토

MUST-ADDRESS 0 / CONSIDER 7. 설계작성자와 별도의 w10_design_critic(gpt-6-astra/low) 검토.

1. 사진clip과hit범위를같다고가정하지말것. 카드밖사진이주변색·목록·저장을가로채지않고목록으로재선택·복귀할수있어야한다.
2. 저장사진actualdecode완료·선언치수·2048pixel상한을명확히한다. 헤더만정상/본문손상·작은압축/큰pixel을분리하고load/save/W13정상판정동일경계.
3. generation보호는성공뿐아니라오류알림·isImporting해제에도적용한다. 취소무시loader성공/실패·확인중완료뒤계속/버리기검증.
4. 실제PhotosPicker/VO실행경로는CUA timeout으로미확정. fixture/식별자/캡처를실제낭독완료로올리지않는다.
5. model/photo+schema/store태스크병합후Controller배치로의존을해소한다. 불필요한임시형식·어댑터추가금지.
6. undo20이상이미지byte6MiB의세션전체메모리한도는아니다. 교체/삭제이력·디코딩·base64buffer메모리/저장시간관찰. 근거없이파일저장/cache계층추가금지.
7. 기존XXXL선택실패원인과본문가독성/끝도달검증을분리한다. wheel20초기준완화금지.

총평: 단일v3원자적저장/v2DTO와latestSnapshot카드만갱신방향적절. 태스크의존정정후설계에근본문제없음.
