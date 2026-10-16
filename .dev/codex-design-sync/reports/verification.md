# 디자인 동기화 최종 검증

2026-10-16. 첫 전체 검사는 2실패로 종료됐고, 두 수정 뒤 영향 범위 7건과 별도 빌드가 통과했다. 서로 다른 실행을 전체 1745건 통과로 합산하지 않는다.

| 검사 | 결과 | 직접 확인한 출처 |
|---|---|---|
| 전체 iOS 1회 | Unit 1426/0실패, UI 319/2실패, exit 65, 5931.415초 | [전체 로그](ios-full.log), [exit](ios-full-exit.json) |
| 수정 후 영향 범위 | RecordsAnalytics 5 + SimulatorLargeTextRecovery 2, 7/7 PASS, exit 0, 245.476초 | [후속 로그](ios-affected-23.log), [exit](ios-affected-23-exit.json) |
| 별도 Debug Simulator 빌드 | BUILD SUCCEEDED, exit 0, 4.065초 | [빌드 로그](ios-build-final.log), [exit](ios-build-final-exit.json) |
| 실제 이미지 시각 대조 | main/time 92, card 90, journey 90, records 91 PASS | [비교표](visual-comparison.md), 각 visual-*-final.json |

전체 실패 1은 분석 메모 행을 눌러도 편집 입력이 나타나지 않은 문제였다. 채워진 배경을 없앤 plain 행 버튼의 label에 `.contentShape(Rectangle())` 한 줄을 추가했다. 원래 AC5의 실제 탭→메모 수정/저장→분석 재진입 최신값 검사가 35.141초에 PASS했다. [실패 분석](records-memo-failure-analysis.md)에 가설과 후속 근거를 구분했다. root가 확인한 실패 attachment 전용 export manifest는 빈 배열이므로 자동 실패 화면을 확보했다고 주장하지 않는다.

전체 실패 2는 SimulatorLargeTextRecovery AC32의 최대 글자 검색 결과 도달이었다. 해당 test의 실제 도달 보조를 보완하고 기존 선택값/준비 진입 assertion을 유지했다. 같은 AC32는 102.723초, AC33은 12.966초에 PASS했다. 두 실행의 source manifest를 직접 비교해 전체 이후 변경 파일이 `RecordsAnalyticsView.swift`와 `SimulatorLargeTextRecoveryTests.swift` 두 개뿐임을 확인했다. 전체를 다시 실행하지 않았다.

화면 33개는 after22의 05–16/12개와 after17의 나머지 21개를 유지한 composite다. 각 bundle/hash는 [수집 메타데이터](after-capture-observations.json)에 보존한다. 정확 상태 기준이 없는 14/18/분석 스크롤/출처·설정은 구조 또는 현행 보존 범위다. 후속 23은 hit 영역과 테스트 조작 경로 변경에 대한 실행이며 최신 23 재캡처로 부르지 않는다.

별도 MinuteRulerValue/unit seam은 통제된 계획 변경으로 추가하지 않았다. 실제 drag 15/360/60/61·후보 해제·native Slider 노출/값과 접근성 44pt ±1분 버튼 입력을 확인했다. 실기기 VoiceOver 증가/감소 통과로 해석하지 않는다. 기존 Node/Python 테스트 결과는 해당 로그에 보존한다. Python 문법 빌드만 별도 재확인한 [exit 메타데이터](python-build-final-exit.json)에서 exit 0/0.055초를 직접 확인했다. 이는 전체 테스트 재실행이 아니다.

[정리 메타데이터](resource-cleanup.json)에서 소유 Pro 종료, 전용 SE 삭제, 미상 기기 미접촉, 빌드 근거·워크트리 보존을 확인했다. 삭제 디렉터리 할당량은 2,253,922,304B이고 관측 여유 증가량은 299,343,872B다. 서로 다른 수치를 같은 실제 회수량이라고 보고하지 않는다.

물리 햅틱 질감·강도/동기, 실기기 VoiceOver, OS Widget/Island 실제 표시·갱신은 미검증이다. static preview와 Simulator/자동검사로 대체하지 않는다. 상세 증거는 [AC 원장](ac-evidence-final.md)을 따른다. 이 문서 갱신에서는 로그/메타데이터만 읽었고 추가 소스 수정·빌드·테스트·시뮬레이터 실행을 하지 않았다.
