# W10 UI 테스트 기준선 실패 수정 보고

## 근본 원인 (하네스/픽스처 배치 문제, 앱 동작 결함 아님)
- 테스트가 쓰는 `--fm-ui-card-photo-manifest FocusMate/UITestPhotoFixtures/<name>.json` (CardCustomizationFlowTests.swift:459)은 앱 Application Support 기준 상대경로로 해석된다 (UITestBootstrap.swift:27-32).
- 그 픽스처(valid2/mixed/seven/invalidPaths/hold.json, a/b/p1-7.png, unreadable.bin, escape.png)는 저장소에 없고, W10 때 특정 시뮬레이터(88EC0B32...) 컨테이너에 수동 배치됐다 (.dev/codex-feat-card-customization/reports/t5-fixture-staging.md:17,35 "재설치/컨테이너 변경 시 재배치").
- 새 시뮬레이터 031BC52B...에는 UITestPhotoFixtures 디렉터리가 없다(find로 확인). 매니페스트 읽기 실패 -> UITestBootstrap.swift:42 의 unreadable 입력만 반환 -> 사진이 draft에 안 들어가 waitState(:614)가 timeout(.timedOut=2).
- 테스트 중 사진 import 경로를 안 타는 test01-03, 10(경로 이탈은 실패가 기대값)만 통과한 것과 일치.

## 수정
- ios/FocusMate/UITestBootstrap.swift (DEBUG 전용): 매니페스트 인자가 있으면 `stagePhotoFixtures(support:)`가 필요한 PNG/매니페스트/escape.png/unreadable.bin을 앱 컨테이너에 생성(이미 있으면 덮어쓰지 않음). `import UIKit` 추가. 치수는 기존 단언과 동일(a 120x80, b 80x120 알파, p1-7 = 101..107x80, escape 48x32). 테스트 파일·단언은 변경 없음.

## 검증
- 지정 명령 실행: exit 0, `Executed 13 tests, with 0 failures`, `** TEST SUCCEEDED **` (통과 13 / 실패 0). 로그 /tmp/w10-ui.log.

## 남는 위험
- test05가 316초 걸림(다른 테스트 16~71초). 통과는 했으나 느린 원인은 미조사 -> CI 타임아웃/불안정 후보.
- 픽스처는 생성 PNG라 W10 원본(Pillow 생성)과 바이트가 다르다. 테스트는 치수/ID/해시 상이성만 단언하므로 영향 없음.
- red-staging, ios/FocusMateTests는 건드리지 않음. 변경은 커밋하지 않음.
