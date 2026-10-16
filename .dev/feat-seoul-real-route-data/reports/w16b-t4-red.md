# W16b T4 RED (AC-49 데이터 출처)
- 신규: ios/FocusMateTests/DataSourceContentTests.swift (7건), ios/FocusMateUITests/DataSourceUITests.swift (4건)
- 갱신: ios/FocusMateTests/ProfileModelTests.swift (openFromProfile(.dataSource) 3건 + 메뉴 매핑/제목 1건 추가)
- AppFoundationTests의 Destination.allCases 순회는 open() 호출만 하므로 수정 불필요 (case 추가가 자동 반영).
- 실행 안 함(지시). 예상 실패: DataSourceContent/Destination.dataSource/ProfileMenuItem.dataSource 미정의 컴파일 오류(정상 RED).
- Destination.title 프로퍼티 존재를 가정함(계약의 "title"). 이름이 다르면 오케스트레이터가 알려주세요.
- 프로덕션 코드 미열람.
