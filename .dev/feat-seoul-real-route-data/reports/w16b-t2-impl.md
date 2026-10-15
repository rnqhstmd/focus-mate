# W16b T2 IMPLEMENT — 카탈로그 기반
## 구현 내용
- RouteCatalog: Equatable, duplicateID(정류장·노선), outOfRange(구간 초 >21600, m 0~200000 밖, 정류장 >1000), metadata sourceURL·routeInfoSourceURL.
- RouteCatalogLoader: bundledURL/bundled, 좌표 마이크로도 범위(33e6~39e6, 124e6~130e6) → outOfRange, 불리언 숫자 거부(CFBoolean), URL 키 필수.
- RouteLeg: minutes 1…360 밖 nil.
- RouteCatalogStore(신규): RouteDataAvailability(loading/ready/failed), startLoading() Task 1회, loaded().
- RouteCatalog+Fixture(신규, DEBUG): acceptanceFixture(PRD 표), uiTestFixture(예시 9정류장 정·역방향 + 2014·2014-r·302·421).
## GREEN 증거
- Store·Catalog·Leg·Search·Candidates focused → Executed 87 tests, 0 failures
## REFACTOR 내역
- 정리 없음
## 우려사항
없음
