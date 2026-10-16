# W18 T1 구현

Shared 최소 DTO/전체유효성검사 codec, version 우선 분류, AppGroup 전용 atomic store, 30분/날짜/시간대 freshness, 엄격한 URLComponents 링크/24hTTL, 상태별 순수표시와 자정갱신 구현.

RED: t1-red-run.log 실제28건 실행,35assertfailure(예외5포함). GREEN: t1-green-w09b-regression.log 단위 Widget28건 + RecordsRow2건 실행30/0fail. 전체테스트 아님. 원문개인정보 필드 없이 최소7일/합계/태그/저장여정만 공유. 위젯에서 집계/진행외삽하지 않음.

테스트body수정없음. 해시 t1-test-hashes.json. 정적리뷰진행중. fullverify pending.
