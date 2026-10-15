# T7 RED 보고
Status: DONE_WITH_CONCERNS

## 케이스 (총 9건)
- ios/FocusMateTests/LifecycleSeedTests.swift (신규 6건): recordsMemo 존재·12건·진행여정없음·인코딩, 메모 분포(집중 잘됨 1/빈 11), 전부 오늘 날짜(item.date), completedAt 12개 모두 다름, recordsTwoYears 존재·3건·진행여정없음, 날짜 집합(오늘, 작년 3/10, 6/20)
- ios/FocusMateUITests/RecordsUITests.swift (3건): testAC24_AC31 빈 상태, testAC20_AC26_AC29_AC30 메모, testAC27 연도

## 가정
- recordID = "records-memo-0"~"records-memo-11" (0 최신, 1 = "집중 잘됨")
- 기록 항목에 date("YYYY-MM-DD"), completedAt, memo 필드 사용(기존 테스트 AlightingSnapshotTests 근거)
- 시드는 UITestBootstrap.lifecycleSnapshot(name)로 조회된다고 가정
- 마이페이지 진입은 open.profile (기록 화면에서 뒤로 후 메인), 잔디는 adjust(toNormalizedSliderPosition:1/0)로 increment/decrement 대체
- 저장 파일 메모 불변 검증은 persistedText에서 `"memo":""` 정확히 11건(공백 없는 JSON 인코딩 가정)

## 명령
cd /Users/bonseung/Documents/ChatGPT/new-w09 && FOCUSMATE_SIMULATOR_ID=7D81AFEE-FC29-4E6F-8E2C-195C022C52A6 python3 scripts/check-ios.py test ios/FocusMateTests/LifecycleSeedTests.swift ios/FocusMateUITests/RecordsUITests.swift  (exit 65, 로그 scratchpad/t7-red.log)

## 실패 메시지
- 단위 6건: XCTUnwrap failed ... 시드 없음: recordsMemo / recordsTwoYears
- UI: open.records 없음 (메모·연도), records.empty 없음 (빈 상태)

## 참조 파일
ios/FocusMateUITests/UITestLaunchSupport.swift, ProfileUITests.swift, ios/FocusMateTests/LifecycleSeedTests.swift, AlightingSnapshotTests.swift(grep), AlightingModelTests.swift(grep). 프로덕션 코드 미열람.

## 수정 R1
testAC27: heatmap.adjust(toNormalizedSliderPosition:) 호출 2건을 DEBUG 버튼 test.records.nextDay(선택일이 오늘 그대로) / test.records.previousDay(어제, waitUntil로 대기)로 교체. records.heatmap 존재 단언 유지. 다른 케이스 무수정, 실행 안 함.
