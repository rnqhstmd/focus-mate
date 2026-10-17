# Largest-text recovery search failure: read-only analysis

판정: 이번 실패는 검증 helper의 오래된 화면 조작 경로로 설명된다. 현재 증거는 검색 production 결함을 입증하지 않는다. 테스트/production 수정, 빌드, 테스트, 시뮬레이터 조작은 실행하지 않았다.

## 정확한 실패 구간

- 원본: `reports/ios-full.log:29141–29764`, 624줄, test started부터 failed까지.
- 동일한 내용을 변경 없이 `reports/large-search-failure-excerpt.log`에 추출했다.
- `SimulatorLargeTextRecoveryTests.testAC32_XXXL에서_60분_2014를_선택하면_선택값을_유지하고_준비로_진입한다`는 13.123초 후 `SimulatorLargeTextRecoveryTests.swift:70`의 `search.result.seongsu.isHittable` assertion에서 실패했다. 시간 화면에 아직 진입하지 않았으므로 시간 선택/후보 선택/준비 화면의 회귀라는 판정은 할 수 없다.

## 직접 읽은 실행 증거

| 원본 로그 위치 | 관찰 |
|---|---|
| 29191 | 키보드 전 search.scroll frame은 `(46,162,310,512.7)`이다. |
| 29297–29303 | 검색어 입력 뒤 scroll 높이가 211.7로 줄고, 입력창은 Keyboard Focused다. 성수역 결과는 존재하지만 y399.2–558.9로 scroll의 하단 y373.7 밖에 있다. |
| 29393 | 실제 키보드에 `Search`/`검색` 버튼이 노출된다. |
| 29460–29466 | reach 진입 전에도 같은 viewport/결과 frame과 키보드 포커스가 유지된다. |
| 29576,29583,29590 | helper는 앱 전체 `Swipe up Target Application`을 세 번 실행한다. search.scroll에 좌표를 제한한 조작이나 Search 제출은 없다. |
| 29645–29651 | 세 번 뒤에도 scroll `(46,162,310,211.7)`, 결과 `(45.5,399.2,311,159.7)`, Keyboard Focused가 그대로다. |
| 29741,29762–29764 | 키보드 Search가 여전히 존재하며 결과 도달 assertion이 실패한다. |

손가락 이벤트가 정확히 어느 하위 뷰에서 소비됐는지는 로그만으로 확정하지 않는다. 다만 전역 세 번 swipe가 실제 검색 viewport나 포커스를 바꾸지 않았다는 결과는 명확하다.

## 같은 전체 실행에서 통과한 경로와 비교

- `LargeTextUITests.swift:85–87`은 search.*가 안 닿고 키보드가 있으면 `app.typeText("\n")`로 실제 Search 제출을 보낸다.
- `InitialStationSearchView.swift:33–35`의 `.focused`, `.submitLabel(.search)`, `.onSubmit { searchFocused = false }`가 이 사용자 조작을 처리한다. `:40–41`에 실제 scroll ID `search.scroll`과 키보드 dismiss 동작이 있다.
- 그래도 안 닿으면 `LargeTextUITests.swift:101–108`은 실제 search.scroll viewport와 target 중간점의 차이를 최대 viewport 60%로 제한해 양방향 좌표 드래그한다. 마지막 hittable assertion은 유지된다.
- 같은 전체 로그의 `20451–20518`에서 이 검색 전용 테스트가 12.816초에 통과했다. 그 구간에는 t7.50의 newline 입력, t8.11 결과 탭, 확인 탭, time 진입과 정류장 저장 검증이 실제로 기록돼 있다.
- `20519–21106`의 가장 큰 글자 60분 전체 흐름도 80.749초에 통과했다.
- 실패한 별도 recovery 테스트의 `SimulatorLargeTextRecoveryTests.swift:61–70`은 여전히 전역 swipe만 사용한다. “LargeTextUITests와 같은 경로”라는 주석은 현재 코드와 일치하지 않는다.

## root 승인 후 적용할 최소 수정안

`SimulatorLargeTextRecoveryTests`의 지역 reach helper에서 search.*만 이미 통과한 LargeText 경로로 정렬한다.

1. 현재 `record(stage reach 전)`을 유지한다.
2. search.*가 안 닿고 키보드가 있으면 실제 newline/Search 제출을 보낸다.
3. 최대 3회라는 현재 검색 시도 제한을 유지하되 search.scroll 실제 viewport에 한정한 방향성 좌표 드래그를 사용한다.
4. 기존 `record(stage reach 후)`, 최종 isHittable assertion, 결과 직접 탭, 확인의 즉시 도달 assertion, 정류장/60분/2014/도착지 저장 검증을 모두 유지한다.
5. production 변경, 허용 오차 확대, 모델 주입, 숨겨진 테스트 경로를 추가하지 않는다.

추가 관찰: 같은 지역 reach helper는 뒤의 time.candidate.2014에도 사용된다. 이 실행은 검색에서 중단되어 그 뒤의 성공 여부는 미확인이다. 이미 다른 가장 큰 글자 테스트가 쓰는 `revealTimeContent`의 실제 패널 경로와도 다르므로, 검색 수정 후 재실행에서 이 지점을 따로 관찰해야 한다. 현재 보고서 단계에서는 이를 추가 실패로 단정하거나 코드를 수정하지 않았다.

검증 제안: root가 전체 큐 종료 후 변경을 승인하면 해당 AC32 한 개만 focused 재실행해 Search 제출→결과 탭→시간→후보→준비의 원래 assertion이 모두 실행되는지 확인한다. 이미 통과한 전체 suite를 다시 반복할 필요는 이 분석만으로 발생하지 않는다.
