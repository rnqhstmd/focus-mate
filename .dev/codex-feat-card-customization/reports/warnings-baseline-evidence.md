# 경고 기준선 증거 정정
state warnings-baseline:0은 최초 incremental 측정값이며 cold compile 무경고 증거가 아니다. 숫자를 사후상향해 신규경고를 숨기지 않는다. gx-verify 경고 측정규약3항대로 실제신규 여부를 원문 비교한다.

Immutable HEAD5b7af0f VO archive coldbuild voiceover-native-test.log: 기존 CardIssuanceView14:52 failedAnnouncement actor reference, JourneyStartModelTests128 choose unused, SDK AppIntents Metadata extraction skipped. 이 경고들은 W10신규가 아님. 일부 source-line 재인쇄/architecture 반복은 원문 중복.

W10신규 CardStyleStorageTests243/292 unused original 2경고는 기존baseline으로 간주할수없다. RED author mechanical 수리 및focused후 hash갱신 예정이며 아직닫히지않음. 다른 신규경고도 실제 coldbuild/finalverify 로그로 판정한다.

T5-parent-red incremental은 SDK metadata warning1, XCTest12/12actualRED 성공(제품부재에대한실패), 경고없다고주장하지않음.
