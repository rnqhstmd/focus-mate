# 최종 독립 verifier

판정: **요청된 전체1회 + 두 실패 최소 수정 + 영향 범위 후속검증 및 최종 빌드의 증거를 확인했다. 현재 actionable finding 없음.** 최초 전체 실행은 실패였으며 수정 후 전체 재실행은 하지 않았다. 이 보고서를 “최신 소스로 전체 suite를 다시 실행해 모두 통과”라고 요약하면 안 된다.

검증자는 기존 파일·로그·JSON·SHA만 읽었으며 source 수정, 추가 빌드·테스트·시뮬레이터 실행은 하지 않았다. `git diff --check`는 exit0/출력 없음으로 확인했다.

## 현재 소스 일치

`ios-affected-23-source-manifest.json`의 `files`294개 각각을 현재 파일 SHA-256과 직접 비교했다. **294개 일치, 누락/불일치0**. manifest 시작 시각은2026-10-16T20:34:04.866788+09:00이다. 따라서 아래 후속 실행이 검증한 소스는 현재 내용과 일치한다.

별도 앞선 재검토에서 첫 전체 시작 manifest와 영향 실행 manifest의 차이는 RecordsAnalyticsView.swift와 SimulatorLargeTextRecoveryTests.swift 두 파일뿐임을 확인했다. 전자는 `.contentShape(Rectangle())`1행, 후자는 기존 정확도·도달 assertion을 유지한 실제 검색 제출/스크롤 입력 보조 수정이다. source 검토 근거는 `review-final.md` 후속 절에 있다.

## 직접 확인한 실행 결과

| 실행 | 직접 읽은 근거 | 확인 결과 |
|---|---|---|
| 첫 전체 iOS suite, 단1회 | `ios-full.log:3815,32587,32601`, `ios-full-exit.json` | unit1426/0실패, UI319/2실패, TEST FAILED, exit65. 종료20:32:49.696413+09:00 |
| 수정 후 영향 범위23 | `ios-affected-23.log:695,787,3488` 및 최종 footer, `ios-affected-23-exit.json` | RecordsAnalytics5 + SimulatorLargeTextRecovery2 =7/0실패, TEST SUCCEEDED, exit0. 종료20:38:10.344723+09:00 |
| 별도 최종 iOS build | `ios-build-final.log` 최종 BUILD SUCCEEDED, `ios-build-final-exit.json` | exit0,4.065초, 종료20:38:27.885210+09:00 |
| Node 기준 검사·edge QA·prototype build | `node-final.log:40–47` 및 후반 PASS/build 출력 | Node31/0실패, edge QA PASS 출력, 현재 prototype 패키징 완료 출력 확인 |
| Python 최종 unit | `python-final.log` |117건,2.384초,OK |
| Python compileall | `python-build-final-exit.json` | `python3 -m compileall -q scripts/route_data scripts/build_route_data.py`, exit0,0.055초, 종료20:41:39.934139+09:00 |

compileall은 quiet 명령이므로 출력 대신 별도로 제공된 `python-build-final-exit.json`의 정확한 command·exit0·종료 시각을 직접 읽어 성공을 확인했다. 이전의 root 보고만 있는 한계는 이 직접 exit 근거로 해소됐다. 이는 테스트 재실행이 아닌 Python 소스 컴파일 확인이다. Node/Python unit 개별 프로세스의 별도 exit JSON은 없으므로 해당 항목은 저장 로그의 결과를 직접 확인한 범위로 기록한다. 이 verifier가 추가 실행한 명령은 없다.

## 원래 두 실패의 해소

1. `RecordsAnalyticsUITests.testAC5_분석메모에서_기존편집기로_돌아가_저장하면_재진입에_최신메모를_읽는다`: 후속 로그695행에서35.141초 pass. 기존 메모 행 탭→기존 편집기·값 확인→수정·저장→분석 재진입의 원래 assertion을 바꾸지 않았다. contentShape는 실제 제품 행 hit 영역을 복구하며 테스트 좌표 우회가 아니다.
2. `SimulatorLargeTextRecoveryTests.testAC32_XXXL에서_60분_2014를_선택하면_선택값을_유지하고_준비로_진입한다`: 후속 로그3488행에서102.723초 pass. 기존 검색결과/확인/진행 도달, 정확한60분, 실제 후보 선택, 준비 진입 및 저장 선택의 minutes60/busID2014/destination assertion을 유지한다. helper는 실제 Search submit·해당 scroll 드래그를 사용한다.

두 원래 실패가 같은 최소 수정 후 영향 실행에서 통과했음을 확인했다. 수정되지 않은 나머지 영역은 최초 전체 실행의 결과이고, 최신 수정 후 검증은 영향7건이다. 최초 실패 이력을 지우거나 두 실행을 합쳐 가상의 전체 성공 건수를 만들지 않는다. 사용자 지시대로 전체 suite 재실행을 요구하거나 수행하지 않았다.

## 실제 시각·갤러리 증거

- 최종 JSON을 직접 읽어 main/time92 pass, card90 pass, journey90 pass, records91 pass를 확인했다. 점수는 각 보고서의 승인 예외·정적 구조·직접 대조 범위이며 기능 테스트 결과에서 만든 점수가 아니다.
- `after-capture-observations.json`은 expected33/collected33/missing0이다. `mergeProvenance`는 after22의05–16/12개와 after17에서 유지한나머지21개를 명시한다. 단일 실행의33개라 부르지 않는다. sourceBundles는17/22 xcresult 두 개다.
- `gallery-browser-qa.json`을 직접 읽었다.33개 화면과 모든 참조 이미지 로딩, 집중 카테고리5개 필터, 시간 검색1개,15→16 이동, 확대·닫기, 전체 선택/이미지 로딩을 기록한다. 검증 시각18:59:40.547437+09:00이며 QAJSON의 “전체 suite 진행 중”은 당시 상태다. 갤러리 조작은 이 verifier가 새로 재실행한 것이 아니라 저장된 QA 결과다.
- 실제 native 지도 법적 표기06/07/08 가독성은 앞선 capture-22 직접 이미지 검토에서 확인했다.14/18 안내와24/32/33 분석 scroll 상태는 정확한 원본 JPEG가 없으므로 구조 검토이며,27/28/31은 현행 내용·가독성 보존 범위다. 누락 기준 이미지를 다른 화면의 exact reference로 가장하지 않는다.

## 남은 물리·OS 게이트

실기기 VoiceOver Slider 조절·포커스 체감, 물리 햅틱 강도·질감·동기와 오디오 체감, 실제 OS Widget/Island 표시·갱신은 미검증이다. 일반 drag·접근성 ±1분 버튼·AX 노출/값 성공을 실제 VoiceOver Slider 조절 성공으로 대체하지 않는다. 캡처된 일반 크기 지도 출처 수용도 모든 최대 글자/가로/스크롤 조합을 포괄하지 않는다.

최종 source 및 영향 범위 runtime의 미해결 소프트웨어 finding은 확인하지 못했다. compileall exit 근거는 확보됐으며, 위 물리·OS 게이트는 별도 미검증으로 남는다.
