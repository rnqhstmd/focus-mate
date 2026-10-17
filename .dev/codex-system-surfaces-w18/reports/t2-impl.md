# W18 T2 구현

원본 검증→W09b 단일공용집계→최소7일/상위태그/저장여정 투영. Publisher는 실제공유읽기로동일자료/신선도비교, 원자쓰기성공후reload만. AppModel 저장/보충/복원/정리성공만게시, 마이그레이션저장실패후foreground차단,원본오류격리. 기본 publisher nil, production만실제AppGroup주입.

링크정책: rawURL보류/consume시TTL재검증/원문UTF16 ID/열린흐름유지/진행정지카드확인만,새여정기존확인,분석week/day/유효tag일회전달. Root URL/ready/foreground 연결. Records 분석목적지identity로초기week/tag상태갱신.

RED: t2-red-t1-fix-green.log T2 32건실행50assertfailure(예외4). GREEN t2-green-run.log Shared36+T2 32=68건/0fail. UI RED5중2실패관측. 첫UIgreen에초기week stateidentity 및alertbuttonquery추가문제확인,수리후재실행필요.

테스트미수정해시t2-test-hashes.json. 전체검증아님. 실제OS URL 전달/서명/위젯탭미검증.
