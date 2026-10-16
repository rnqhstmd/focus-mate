# RecordsAnalytics 메모 편집 진입 실패 분석

2026-10-16. 읽기 전용 조사. 전체 iOS suite가 실행 중이므로 production/test 소스를 수정하지 않았고 빌드·테스트·시뮬레이터도 실행하지 않았다. 전체 종료 후 root 지시 전까지 소스 동결을 유지한다.

## 직접 확인한 실패

- 실패: `RecordsAnalyticsUITests.testAC5_분석메모에서_기존편집기로_돌아가_저장하면_재진입에_최신메모를_읽는다`, line57의 `recordMemo.field` TextField5초 대기. 실행23.116초에 실패했다.
- 정확히 해당 Test Case started부터 해당 Test Case failed까지 원문만 [발췌 로그](records-memo-failure-excerpt.log)에 저장했다. 시작20:18:27.722, 메모 tap16.86초→field 대기17.30초→실패22.50초. 앞뒤 다른 test의 로그는 섞지 않았다.
- 해당 테스트는 분석 진입·메모 reveal·존재/hittable·`회고1` label까지 통과하고 실제 `memo.tap()`을 실행했다. 실패 뒤 편집기 값/입력/저장/재진입 최신 메모 assertion은 실행되지 않았으므로 그 뒤 동작을 성공/실패로 확대하지 않는다.
- 동일 전체 실행의 `RecordsUITests.testAC20_AC26_AC29_AC30_메모_남기기_수정_제한_실패_유지`는54.034초 PASS다. 직접 기록 경로로 동일 `recordMemo.field`를 찾고 수정/200자 제한/저장실패 초안/취소를 검사했으므로 TextField 종류·identifier 소실을 공통 편집기 원인으로 보기 어렵다. 분석 AC1·AC3·큰글자 복귀도 각각 PASS다.
- 수정 전 조사 당시 `ios-full-source-manifest.json`의294개 항목을 파일 SHA-256과 대조해 드리프트0을 직접 확인했다. 보고서 작성만으로 동결된 소스 결과를 바꾸지 않는다.

## 원인 가설과 근거

가장 강한 가설은 **분석의 plain 행 버튼에서 채워진 배경을 제거한 뒤 빈 중앙의 hit 영역을 명시하지 않은 production 표현 회귀**다. 확정 원인은 아직 아니다.

`RecordsAnalyticsView.recordButton`은 `Button { onOpenRecord(record.id) }`의 label을 leading VStack으로 만들고 `frame(maxWidth:.infinity,minHeight:44)` 및 세로13pt padding을 붙인다. 이번 시각 변경은 종전의 전체 행 `background(.white.opacity(0.06), RoundedRectangle...)`를 제거하고 하단1pt overlay만 남겼다. label 안에 `contentShape(Rectangle())`는 없다. 빈 가로 영역의 자동 버튼 중앙을 탭하면 plain 버튼의 실제 그려진 텍스트/하단선과 빗나갈 가능성이 있다. XCUITest의 exists/isHittable은 합성한 단일 탭 좌표가 의도한 action을 발생시켰다는 증거가 아니다.

root가 확인한 Apple 공식 [`contentShape(_:eoFill:)`](https://developer.apple.com/documentation/swiftui/view/contentshape(_:eofill:)) 및 [`ContentShapeKinds.interaction`](https://developer.apple.com/documentation/swiftui/contentshapekinds/interaction)은 hit testing 영역을 명시하는 API다. 이는 최소 수정의 API 근거이며 이 실패의 실제 원인 확정 증거와는 다르다.

반면 기록→분석→메모 callback은 여전히 `pendingAnalyticsRecordID=id; showsAnalytics=false` → destination `.onDisappear` → `openPendingAnalyticsRecord()` → `editing` 설정 → 기존 `.sheet(item:)`이다. 이 navigation/선택/저장 계약에는 이번 변경 diff가 없다. `RecordMemoEditor`는 같은 TextField와 identifier를 유지하고 직접 기록 편집 검사가 같은 실행에서 통과했다. 따라서 먼저 테스트 timeout이나 query를 바꿀 근거가 없다.

다만 현재 로그는 탭 이후 navigation 상태나 callback 실행 여부를 기록하지 않는다. action 자체 미발생과 pop 이후 sheet 표시 시점 문제를 로그만으로 완전히 구분할 수 없다. 전체 종료 후 xcresult 실패 screenshot/AX snapshot에서 analytics가 남아 있는지 또는 records만 보이는지 확인하면 두 가설을 좁힐 수 있다. 캡처33의 메모 행이 보였다는 사실은 그 행을 눌러 편집기로 돌아갔다는 증거가 아니다. 기존 collector는 기록에서 편집기를 열었고 분석 메모는 표시만 캡처했다.

## 전체 종료 후 최소 수정안

우선 실제 full-row 버튼의 빈 영역도 제품에서 누를 수 있도록 label 내부의 frame/padding 다음에 아래1줄을 추가한다. 모양·데이터·콜백·선택·저장과 테스트 assertion은 유지한다.

```swift
.contentShape(Rectangle())
```

공통 `recordButton`을 쓰는 최근 여행/메모 행 양쪽에 같은 원인을 해결한다. 테스트에서 텍스트좌표를 직접 탭하거나 timeout을 늘리거나 callback/모델을 주입하는 우회는 하지 않는다. `recordMemo.field` query와 `회고1`/`새 회고`·저장후복귀·재진입 assertion도 그대로 둔다.

전체 종료 후 root의 단일 큐에서 원래 실패 test(또는 그파일)와 영향 있는 RecordsUITests를 재실행한다. 실제 행 중앙 탭으로 메모 편집→수정 저장→분석 재진입에 최신값이 보이는지 확인한다. 여전히 실패하거나 실패 snapshot이 callback 이후 records 상태를 가리키면, tap영역 가설을 확정했다고 주장하지 말고 destination pop 이후 sheet presentation timing을 별도 재현해 최소 수정한다. 전체 suite를 다시 돌리는 기본 루프로 만들지 않는다.

## 판정

- production 수정 후보: label contentShape 누락. 가능성이 높지만 실행으로 미확정.
- 테스트 수정 근거: 현재 없음. 엄격한 원래 assertion 유지.
- 전체 suite 최종 결과: 이 보고서가 확정하지 않는다.

## 전체 종료 후 승인된 최소 수정

root가 첫 전체 실행 종료(unit1426/0 failures, UI319/2 failures, exit65)를 확인한 뒤 수정 지시했다. `RecordsAnalyticsView.recordButton` label의 `frame(maxWidth:.infinity,minHeight:44,alignment:.leading)` 바로 뒤에 `.contentShape(Rectangle())`1행을 추가했다. 기존 action·identifier·접근성 label·저장·선택·테스트 assertion은 수정하지 않았다.

`git diff --check` 성공. 이 작업자는 빌드·테스트·시뮬레이터를 실행하지 않았다. 원인 확정과 해결 판정은 root의 영향 범위 runtime 결과가 나온 뒤에만 기록한다. 이 수정은 전체 실행 시작 시294개 manifest 이후의 명시적인 후속 변경이다.

## 영향 범위 실행 후 결과

root의 `ios-affected-23.log`에서 RecordsAnalytics5건/0실패와 AC5의35.141초PASS를 직접 확인했다. 원래 AC5의메모행탭→기존편집기→수정저장→재진입최신메모 assertion을 바꾸지 않고production contentShape1행만 추가한 후 재현되던 진입 실패가 해소됐다. 이는 hit영역 회귀 가설을 지지하는 실제 수정후 근거다. 전체 결과는unit1426/0·UI319/2실패/exit65를 그대로 보존하고, 후속 두파일7건/0실패/exit0과 구분한다.

실패 attachment만 내보낸 manifest가 빈 배열이라는root확인을 받았다. 따라서 실패 screenshot/AX snapshot 확보로 원인을 확정했다고 쓰지 않으며, 원래 assertion을 유지한 contentShape수정후AC5 PASS가현재의실행근거다.
