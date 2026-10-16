# 최종 소스 검토

## Part 1 — 설계 충족 정적 판정: PASS, 전체 실행 결과 대기

승인 PRD/design 및 현재 전체 변경 파일 목록과 diff를 재검토했다. 이전 검토 이후 추가된 접근성 시간 조절, 실제 지도 법적 표기 위치, 검색·준비 키보드와 요약 시트, 기록·프로필 표시 및 테스트 입력 변경을 현재 소스에서 확인했다. 새 공통 뷰 FMDesign/MainHomeView/SceneMapBackdrop와 신규 ruler UI 테스트도 포함했다.

현재 변경 목록에 AppModel, 여정 계산·저장·타이머·승하차 controller, 마이그레이션, Shared/Widget 변경은 없다. 표시값과 action 연결은 기존 데이터/메서드를 사용한다. 준비 .bus 기본값과 기존 햅틱/Reduce Motion 정책을 바꾸는 diff는 없다.

## Part 2 — actionable findings: 없음

이번 최종 정적 검토에서 수정이 필요한 새 기능 계약 회귀나 접근성 결함은 확인하지 못했다. 핵심 경계는 다음과 같다.

- 시간: 일반 크기는 실제 Canvas 수평 드래그와 native Slider 접근성 표현을 사용한다. 접근성 크기는 보이는 native Slider와 ±1분 버튼을 사용하며 버튼은 범위를 clamp하고 양 끝에서 비활성화된다. 두 입력 모두 기존 Binding → journeyPlan.setMinutes를 사용하므로 선택 해제 정책을 우회하지 않는다. 접근성 후보는 본문 세로 흐름에 놓여 기존 가로 ScrollView 높이 충돌 원인을 제거한다.
- 테스트 입력: 일반 크기의 고정 목표 15/360/60/61, 실제 분 표시, Slider 값, 후보 선택 해제·진행 잠금 assertion을 유지한다. 접근성 helper는 보이는 ± 버튼을 실제 탭하고 매번 정확히 1분 변경과 Slider 값을 확인한다. 현재 값에서 ±1 기대값을 계산하는 것은 요구사항 자체이며 구현의 드래그/clamp 계산을 복제하지 않는다. 시간 도달 시도 증가와 프로필 양방향·저속 드래그는 실제 입력 보조만 바꾸고 hittable·정확한 경계 assertion을 유지한다. 모델 주입이나 가짜 Slider로 성공을 만드는 경로는 없다.
- 지도: 새 공통 지도는 실제 catalog 좌표·노선을 사용하고 safeAreaPadding으로 실제 네이티브 법적 표기 영역을 옮긴다. 시간은 측정값과 실제 패널 높이 fallback을 사용한다. 지도 전체 blur/brightness를 제거했고, 준비 편집·키보드 상태는 지도를 숨긴다. 가짜 Apple 로고나 복제 법적 문구를 추가하지 않았다. 이전 actual capture-22 시각 검토에서 06/07/08 출처 가독성을 직접 확인한 것과 정적 판정을 구분한다.
- 검색·요약: 검색 제목·결과는 같은 유연한 스크롤 안에 있고 확인 버튼은 별도 영역이며 검색 submit으로 키보드를 닫는다. 요약은 ScrollView.fixedSize를 제거하고 CTA를 safeAreaInset에 예약한다. 본문·action 높이로 시트 크기를 결정하되 viewport 상한을 적용하며 기존 draft/update·실패 표시·finish 저장 호출과 navigation pop 차단은 보존한다.
- navigation·기록: root bar 숨김은 빈 path 조건 안에서만 적용되어 destination back 경로를 일괄 숨기지 않는다. 기록의 집계·선택 날짜·메모 action과 분석 browser/adapter 계산은 바뀌지 않았다. PassFace opacity는 표시 인자이며 카드 저장 모델에 새 상태를 만들지 않는다.

## 증거 범위와 남은 게이트

- 이 검토에서는 빌드·테스트·시뮬레이터·캡처를 실행하지 않았다. root의 진행 중인 전체 suite 완료·테스트 수·실패 수·exit를 이 보고서가 확정하지 않는다.
- 일반 크기 물리 드래그 테스트와 접근성 ± 버튼 테스트는 실제 VoiceOver Slider 증가/감소를 실행한 증거가 아니다. AC2 보고에서 실제 드래그/버튼 입력, native AX 노출·값, 미검증 VoiceOver 조절을 구분해야 한다. 현재 보이는 native Slider의 조절 체감도 별도 OS 검증 범위다.
- 지도 출처 시각 pass는 검토한 capture-22 일반 크기 상태에 한한다. 모든 최대 글자·가로 화면·스크롤/키보드 조합을 확인했다고 확대하지 않는다.
- 물리 햅틱 체감, 실제 Widget/Island 표시와 VoiceOver 체감은 별도 미검증이며 자동 테스트로 대체하지 않는다.
- 이전에 본 검토자가 프로필 테스트의 입력 보조를 수정한 이력이 있다. 이번 최종 검토에서는 production/test 소스를 수정하지 않았고 보고서와 시각 판정 번역만 작성했다.

visual-card-final.json은 의미·점수(90)·verdict(pass)를 유지한 채 한국어로 번역했다. 이전 capture-17의 88점 결론을 capture-22가 대체한다는 출처 구분도 보존했다.

## 첫 전체 실행 이후 최소 수정 독립 재검토

상태: **두 후속 변경의 정적 검토 PASS, actionable finding 없음; 영향 범위23은 최종7건/0실패·exit0으로 해소 확인**. 이 절은 위의 첫 전체 실행 대기 상태를 갱신한다. 첫 전체 실행은 unit1426건/0실패, UI319건/2실패, exit65로 종료됐으며 전체 성공이 아니다. 실제 종료 메타데이터는 `ios-full-exit.json`, 두 실패 분석은 `records-memo-failure-analysis.md`와 `large-search-failure-analysis.md`를 읽었다.

`ios-full-source-manifest.json`과 `ios-affected-23-source-manifest.json`을 비교해 변경 항목이 아래 두 파일뿐임을 확인했다. RecordsAnalyticsView의 현재 내용에서 새 contentShape 한 줄을 제거한 SHA-256은 첫 전체 시작 manifest와 일치한다. source/test 실행 없이 파일·메타데이터만 읽었다.

1. **RecordsAnalyticsView.recordButton:** label의 전체 폭·최소44pt frame 뒤에 `.contentShape(Rectangle())` 한 줄을 추가했다. 배경 제거 뒤 빈 행 중앙이 plain 버튼의 텍스트 hit 영역과 어긋날 수 있다는 실패 가설에 부합하며, 최근 여행/메모 공통 행의 실제 제품 탭 영역을 확보하는 최소 수정이다. action/onOpenRecord, ID·AX label, 기록 선택·navigation·저장·편집기는 그대로다. 테스트를 텍스트 좌표 탭이나 긴 timeout으로 우회하지 않는다. 다만 이 정적 적합성만으로 원인이 확정되거나 편집기 재진입 문제가 해결됐다고 판정하지 않는다.
2. **SimulatorLargeTextRecoveryTests의 local reach:** 도달하지 못하는 검색 요소에 키보드가 있으면 실제 Search submit을 보내고, 검색 scroll frame과 target 위치로 제한된 실제 드래그를 계산한다. 시간 요소는 기존 `revealTimeContent`를 최대3회 사용한다. 검색·시간 외 경로는 종전 최대3회 앱 swipe를 유지한다. 모델 값·callback을 주입하는 경로는 없으며, query/최종 hittable assertion과 검색 확인·진입 직후 진행 버튼 도달, 정확한60분, 실제 후보 탭, 준비 화면 및 저장된 busID/destination/minutes assertion은 유지한다. 입력 동작만 현행 UI에 맞춘 수정이며 timeout·정확도·기댓값을 완화하지 않는다. 별도 AC33 발급/저장 검사는 변경하지 않았다.

후속 verifier에서 `ios-affected-23.log`와 exit 메타데이터를 직접 읽어 RecordsAnalyticsUITests5건 + SimulatorLargeTextRecoveryTests2건 **최종7건/0실패·exit0**을 확인했다. 원래 실패한 분석 메모 재진입·저장 test와 최대 글자 검색→60분→준비 선택 test가 원래 assertion을 유지한 채 각각 pass했다. 재검토 당시 PENDING은 이 직접 증거로 해소됐다. 기존 전체 실행2실패를 지우거나 후속 성공과 합쳐 새 전체 성공 수치를 만들지 않는다. 검증 상세는 `verifier-final.md`를 따른다.

사용자 지시인 전체1회 후 영향 범위 검증을 따른다. 전체 재실행을 요청하지 않으며, 이 재검토에서도 production/test 수정·빌드·테스트·시뮬레이터를 실행하지 않았다.
