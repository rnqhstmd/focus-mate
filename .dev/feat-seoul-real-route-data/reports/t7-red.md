# t7 RED
- 테스트 파일: ios/FocusMateTests/RouteLegTests.swift (16 케이스, AC-13~16·18~21, 경계 61초, 노선 외 출발지, 마지막 구간 0초 nil)
- 실패 확인: check-ios.py test ... -> 컴파일 실패. cannot find type 'RouteLeg' / 'RouteLegFinder' in scope (나머지 "dictionary of type 'T'" 오류는 미정의 타입의 연쇄)
- 마지막 구간 nil 손계산: 노선 [A,B,A,C] 초 [59,119,1,1000], A, 2분. B 59 차이 61 밖, A 178 출발지 제외, C 179 차이 59 후보. round(59*120/179=39.55)=40, round(119*120/179=79.78)=80, 마지막 120-120=0 -> nil
- 참조: RouteCatalogTestFixtures.swift, RouteCatalogTests.swift(앞 60줄)

## 테스트 결함 수정 R1
- testAC18·testAC19의 출발 정류장 id "X"를 "S6"으로 수정(X는 이름, id는 S6). 다른 내용 변경 없음.
