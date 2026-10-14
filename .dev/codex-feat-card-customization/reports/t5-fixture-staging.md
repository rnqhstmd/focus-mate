# T5 fixture staging

Status: **READY — fixture 생성·전체 decode·staging 완료**

- Generator: `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.dev/codex-feat-card-customization/ui-photo-fixtures/generate.py`
- Generator SHA-256: `a113fdd193d4e90c4ff0e8b7390e9d1cfaa601227c57778dc9a0e234ae447771`
- 독립 stdlib PNG encoder: zlib 1.2.12; 전체 재읽기: Pillow 12.3.0.
- 생성 과정에 SUT/production processor를 사용하지 않았다. 각 PNG는 전체 픽셀 bytes/치수/mode를 재읽어 확인했다.
- b.png alpha 범위 64...255. 10개 PNG의 입력 SHA-256은 모두 다르며 각 파일은 1MiB 미만이다.
- PNG 출력은 동일 인수로 두 번 계산해 바이트 동일성을 확인했다. 재현 환경의 zlib 버전은 위에 고정 기록했다.
- Pillow 검증은 ImageIO·앱 processor·XCTest 성공 증거가 아니다. 앱 처리 후 출력 SHA/크기 검증은 후속 UI 실행에서 수행한다.

## 정확한 staging

- 조회: `xcrun simctl get_app_container D3BB49D7-3834-4BC9-B910-1CADD9E036E1 app.focusmate.prototype data`
- Container: `/Users/bonseung/Library/Developer/CoreSimulator/Devices/88EC0B32-40D7-4592-A34F-E09C051CECFA/data/Containers/Data/Application/674392C7-B856-49D3-9CF6-2B0E88ED10E3`
- Manifest/입력 디렉터리: `/Users/bonseung/Library/Developer/CoreSimulator/Devices/88EC0B32-40D7-4592-A34F-E09C051CECFA/data/Containers/Data/Application/674392C7-B856-49D3-9CF6-2B0E88ED10E3/Library/Application Support/FocusMate/UITestPhotoFixtures`
- 경로 이탈 검출용 실제 정상 이미지: `/Users/bonseung/Library/Developer/CoreSimulator/Devices/88EC0B32-40D7-4592-A34F-E09C051CECFA/data/Containers/Data/Application/674392C7-B856-49D3-9CF6-2B0E88ED10E3/Library/Application Support/FocusMate/escape.png`
- `missing.png`는 local/staged 양쪽에서 부재 확인. 기존 다른 내용이 있으면 덮어쓰거나 삭제하지 않고 중단한다.
- 복사한 모든 파일은 source/staged 전체 bytes와 SHA-256을 대조했다. 다른 사용자 파일을 수정하지 않았다.
- `ui-photo-fixtures/`는 DEV/.gitignore:19 기존 규칙으로 ignored임을 `git check-ignore -v`로 확인했다.
- 앱 실행/종료·xcodebuild·시험·production/test/Git 변경은 하지 않았다. 재설치로 컨테이너가 바뀌면 재조회 후 재배치한다.

## Manifest

| 이름 | 정확한 배열 순서 |
|---|---|
| valid2.json | a.png, b.png |
| mixed.json | unreadable.bin, a.png |
| seven.json | p1.png, p2.png, p3.png, p4.png, p5.png, p6.png, p7.png |
| invalidPaths.json | ../escape.png, missing.png |
| hold.json | a.png |

실행 인자: `--fm-ui-card-photo-manifest FocusMate/UITestPhotoFixtures/<name>.json`.
hold는 추가 인자 `--fm-ui-card-import-hold manual` 사용. 실제 PhotosPicker/VoiceOver 증거와 구분한다.

## 입력 inventory

| 파일 | 치수/mode | bytes | SHA-256 |
|---|---|---:|---|
| a.png | 120×80 RGB | 240 | `5e96f3c401f5d7381f2c6e232aa357528c58c2767adadeec97192b06937571c1` |
| b.png | 80×120 RGBA | 322 | `209bf9c6215097340e219e2a84e302c98233e6077fb28e1401b3200ddf69760d` |
| p1.png | 101×80 RGB | 214 | `46dfceb9cfb664ad62d3032b993a6eee1d715f4eaf83434ed43c183f9a59ab7b` |
| p2.png | 102×80 RGB | 221 | `b39ee3bb55294004bfb4b0732c2ccfe9c3974ea4e6f4f629bc4d9400a61a632e` |
| p3.png | 103×80 RGB | 223 | `344c917552270dd5cfec30b4b98e5b5845fc39d9fda7e5476636be34c879373c` |
| p4.png | 104×80 RGB | 223 | `d08ccb96bd6cceda2986f78bd193c352bf0e904744a0323d19d71612b819bd2b` |
| p5.png | 105×80 RGB | 224 | `55bf4e79e56522f4e776a70936387df0aa58927e7dcca863296c097602732bd8` |
| p6.png | 106×80 RGB | 225 | `692bd1ab455d2aadb90b6bc22fb3d11c10c6301ea43380486d80520b5493edcd` |
| p7.png | 107×80 RGB | 225 | `87df8b206fa16ffe7941c240ce67456298910bf919df8fddf83f475be2514d1c` |
| escape.png | 48×32 RGB | 128 | `fdd922623d0279e9aebb67a84cf2bfc1ddcab72fa19b2963ef04b356bbf79977` |
| unreadable.bin | — | 56 | `9eecf0a0e389413182a053f6ae2d387be0edeeb3c584d3d362666cba0f55f1cc` |
| valid2.json | — | 46 | `b6604ea3e899146589d8de22fe192a53bb1c2472b0157d041faf9f1306693290` |
| mixed.json | — | 55 | `3133d4fa0d438afe80fa4f45d7d47e9774dd4965910a00c6dab0afc00ef5265b` |
| seven.json | — | 138 | `fa0951a7d43478e139b879dfad683c7cba84dbd397dc9c62646556b665e7625d` |
| invalidPaths.json | — | 60 | `d0bba00143d865432a6d0294d83bee4ff70cec7303063c992e4dbd7b71e5340d` |
| hold.json | — | 29 | `fb8203d385e8f77ab38e1c48580948d2dc61a790557df396a3e59cde1ad8d7fa` |

Machine-readable inventory: `../ui-photo-fixtures/inventory.json`.

재현: 번들 Python으로 `generate.py --stage-container <새로 조회한 container>` 실행. 추가 프로젝트 의존성 설치 없음.
