# ProfileUITests AC20 실패 조사 (researcher, 2026-10-15)

- 실패: ProfileUITests.swift:281, :305 둘 다 `XCTAssertTrue(entry.isHittable, "메인에서 마이페이지 진입 불가(메인 스크롤 없음)")`에서 실패. 마이페이지 진입 전 단계.
- 원인: 테스트 결함. 메인은 RootView.swift:176 `ScrollView`로 바뀌었고(가장 큰 글자 도달용), accessibility5에서 open.profile은 첫 화면 밖이라 스크롤 전 isHittable=false가 정상. 같은 파일 testW10AC35는 `reachVisible(entry, h)`(367행)로 스크롤 후 탭해 통과.
- 수정안(권장): 280~281, 304~305의 isHittable 단언을 `try reachVisible(entry, h)`로 교체, 305행 테스트에 `throws` 추가. 진입 후 검증 강도 유지.
- 주의: 진입 수정 후 처음 실행되는 후속 단계(내비바 겹침, 최대 3회 swipe)에서 화면 결함이 추가로 드러날 수 있음 → 수정 후 재실행 확인 필요.
- 증거: scratchpad/profile.log, scratchpad/r1.xcresult
