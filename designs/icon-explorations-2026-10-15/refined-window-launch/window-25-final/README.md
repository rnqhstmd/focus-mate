# Focus Mate — Window 25

원본 `../icon-25.svg`를 보존하고 선 두께를 약 50% 키운 최종 아이콘과 스플래시 모션 시안입니다. 실제 iOS 앱 코드나 화면 구현이 아닌 독립 영상 파일입니다.

- `icon-25-bold.svg` / `icon-25-bold.png`: 1024×1024, 검정 배경·흰 선. 외곽 60, 중앙선 36, 손잡이 48 (원본 40 / 24 / 32). 외곽 프레임은 균일한 60 스트로크이며 모서리 반경은 64입니다.
- `focus-mate-window-25-splash.mp4`: 720×1560 (6:13), H.264, 60fps, 96 프레임, 1.600초, 무음.
- `focus-mate-window-25-splash.gif`: 360×780, 25fps로 원본 모션 샘플링, 총 1.600초, 무한 반복. 정지 화면 병합으로 실제 저장 프레임은 28개입니다. GIF의 해상도와 색상 수는 MP4보다 낮습니다.
- 심볼은 화면 중앙에 높이 약 202px로 배치했습니다. 확대 구간에 최대 1.34배까지 커집니다.
- 타이밍: 0–0.20초 정지 → 0.20–0.80초 중앙선·손잡이 동시 170px 오른쪽 이동(아이콘 좌표) → 0.80–1.25초 확대·페이드 → 1.25–1.60초 Focus Mate 브랜드 화면 유지. 화면에서의 이동량은 약 83px입니다.
- 바깥 프레임은 여는 동안 고정됩니다. 밝은 배경·들판·해 또는 가상의 앱 UI는 없습니다.

`keyframe-*.png` 3장은 완성 MP4를 디코드해 확인한 이미지입니다. `validation.json`에 실제 MP4/GIF 검사 결과를 기록했습니다. 중간 96개 PNG 프레임과 실행 바이너리는 생성 후 정리했습니다.

## 재생성

`zsh regenerate.sh`로 전체 파일을 다시 만들 수 있습니다. 이 환경의 bundled Node + sharp로 `render.cjs`를 실행한 뒤, macOS의 Swift + AVFoundation으로 `encode.swift`를 컴파일·실행합니다. 마지막으로 bundled Python + Pillow로 `make-gif.py`를 실행합니다. `verify.swift`는 MP4 샘플 수를 세고 실제 영상에서 PNG 3장을 추출합니다. 스크립트는 이 폴더를 출력 위치로 사용합니다.

Swift 컴파일 시 현재 Xcode SDK와 `-target arm64-apple-macosx15.0`을 명시했습니다. 별도 도구 설치·API 키·시뮬레이터는 사용하지 않았습니다.
