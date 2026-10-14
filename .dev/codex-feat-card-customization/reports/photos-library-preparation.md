# Photos 보관함 준비 관찰

Status: **READY — 기존 6개 보존 + 소유 fixture 2개 추가, 실제 8개 확인**.

초기에는 `6 Photos`와 실제 6개 썸네일을 확인하고 추가를 보류했다. 부모가 기존 6개 보존 및 소유 fixture 2개 추가를 명시 승인한 뒤 `addmedia`를 1회 실행했다. 현재 **8 Photos/실제 AX 자산 8개**이며, 기존 6개를 소유 자산으로 간주하거나 삭제하지 않았다. 아래 최초 관찰 기록과 마지막 추가 완료 기록을 함께 보존한다.

## 대상과 실제 결과

- Simulator: `F226C28A-81D5-4708-B939-81B605AC748E` / FocusMate W10 VoiceOver / iOS 27.0.
- `simctl listapps`에서 설치된 Photos `com.apple.mobileslideshow`, CFBundleVersion `912.0.235`를 확인했다.
- 독립 probe 프로젝트: `.dev/codex-feat-card-customization/voiceover-probe`.
- 추가한 probe 파일: `ios/FocusMateUITests/PhotosLibraryPreparationProbeTests.swift`(위 archive 내부).
- 현재 W10 production/source/UI test target, 다른 기기, iOS 26.5, Git은 변경하지 않았다.
- 이번 작업은 Settings를 열거나 동작 줄이기를 변경하지 않았다. 앞선 실제 ON 증거는 `reduce-motion-setting.md`에 있다. 현재 W10의 `test.reduceMotion`은 여기서 검증하지 않았다.
- 초기 관찰의 최종 실행 `initial02`: **1 test / 0 failures**, 16.321초, xcodebuild exit 0. 이것은 Photos 앱 관찰 실행 성공이며 빈 보관함/fixture 추가 성공이 아니다.

## 실제 AX에서 관찰한 항목

| 역할 | identifier/label | 증거 |
|---|---|---|
| Application | bundle `com.apple.mobileslideshow`, label `사진` | Photos 실제 앱 |
| NavigationBar | `PXCuratedLibraryUIView` | 보관함 화면 |
| StaticText | `6 Photos` | 보관함 수량 표시, export tree 15행 |
| Button | label `선택` | export tree 17행; 탭하지 않음 |
| Button | `sortFilterButton`, label `정렬 및 필터` | 초기 트리 |
| ScrollView | `content_scroll_view` | 초기 트리 |
| Button | `LibraryTab`, label `보관함`, Selected | export tree 47행 |
| Button | `CollectionsTab`, label `모음` | 초기 트리 |
| Button | `SearchTab`, label `검색` | 초기 트리 |

개별 자산 selector는 최초 트리에 노출되지 않았다. 최초 화면에는 2×3의 실제 사진 썸네일 6개가 보이며 이번에 생성한 색상 fixture가 아니다. 기존 자산의 소유권이나 기본 제공 여부는 판정하지 않는다. 추가 후 자산/삭제 컨트롤 관찰은 아래에 기록한다.

## 원본 증거

- [초기 Photos 화면](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/attachments02/31F80784-602D-4594-89D4-DE1362C8B897.png): 직접 열어 `6 Photos` 및 6개 썸네일 확인.
- [초기 AX 트리](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/attachments02/C772E6B3-4715-4DF0-B081-D8480AEE4620.txt)
- [관찰 실행 로그](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/initial02.log)
- [xcresult](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/initial02.xcresult)
- [설치된 addmedia 도움말](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/addmedia-help.log)
- 원본과 export manifest는 기존 ignored `.build/photos-probe/` 아래에 보존했다.

실제 CLI help에서 `simctl addmedia <device> <path> [... <path>]`를 확인했다. 최초 관찰 단계에서는 호출하지 않았다. 이후 추가한 소유 원본은 `ui-photo-fixtures/a.png`(120×80 RGB), `b.png`(80×120 RGBA)이며 아래 SHA를 재확인했다.

| 입력 | SHA-256 |
|---|---|
| a.png | `5e96f3c401f5d7381f2c6e232aa357528c58c2767adadeec97192b06937571c1` |
| b.png | `209bf9c6215097340e219e2a84e302c98233e6077fb28e1401b3200ddf69760d` |

## 실행·환경 경계

전용 DerivedData는 `.build/photos-probe/derived`. `-destination platform=iOS Simulator,id=F226C28A-81D5-4708-B939-81B605AC748E`, `-parallel-testing-enabled NO`, `-only-testing:FocusMateUITests/PhotosLibraryPreparationProbeTests/testObserveOwnedPhotosLibrary`로 제한했다. 정확한 전체 명령은 `initial02.log` 처음에 있다.

첫 `initial01`은 실행 전 dSYM 생성에서 `No space left on device`로 실패했다. 해당 로그/xcresult를 보존했다. 이 에이전트가 앞 단계에 생성한 완료된 `.build/reduce-motion-probe/derived` 248MiB 캐시만 제거해 재시도했고, Reduce Motion 원본 로그/xcresult/스크린샷은 모두 보존했다. 다른 빌드 캐시나 사용자 파일은 정리하지 않았다.

## 기존 자산 보존 후 추가 완료

부모의 추가 승인 후 원본을 아래 고유 이름으로 복사했다. 경로는 DEV의 ignored `ui-photo-fixtures/photos-library/`이며 원본과 SHA가 같다.

- `W10-Owned-A-79A4547A-E6AA-4D10-9AE6-978F5A3A4E38.png`: a.png, 240 bytes, 빨강 체크 패턴.
- `W10-Owned-B-79A4547A-E6AA-4D10-9AE6-978F5A3A4E38.png`: b.png, 322 bytes, 파랑 체크/alpha 띠 패턴.
- 절대 입력경로·원본경로·SHA: `.build/photos-probe/owned-inputs.json`.
- 실행: `xcrun simctl addmedia F226C28A-81D5-4708-B939-81B605AC748E <위 A 절대경로> <위 B 절대경로>`, 정확히 한 번, exit 0. stdout/stderr는 `addmedia-owned.log`에 보존했다(내용 없음).

`afterAdd03/04` 관찰에서 초기 안내가 늦게 나타났다. 이미 실제 관찰한 `사진의 새로운 기능` / `계속`을 근거로 `afterAdd05`에서 버튼 존재를 기다리고 탭한 뒤 부재를 확인했다. 이어 실제 `선택` 버튼으로 선택 모드에 진입했다. **개별 사진은 선택하지 않았고 삭제는 전혀 하지 않았다.**

최종 `afterAdd05`: **1 test / 0 failures**, 32.181초, xcodebuild exit 0. `ACTUAL_PHOTOS_ASSET_COUNT=8` assertion과 실제 screenshot을 확인했다.

| 관찰 대상 | 실제 상태/접근성 |
|---|---|
| 전체 수량 | `보관함, 8 Photos`; `photos.images.matching(identifier: "PXGGridLayout-Info").count == 8` |
| 기존6개 | 첫2행의 기존6개 자연 사진 유지. 최초/이후 화면을 직접 대조 |
| 소유 A | 3행1열, 빨강 체크. AX frame `{{0.0,405.3},{132.9,133.0}}` |
| 소유 B | 3행2열, 파랑 alpha 체크. AX frame `{{134.6,405.3},{132.9,133.0}}` |
| 소유 두 자산 label | 둘 다 `사진, 10월 14일, 오전 11:52`; 공통 identifier `PXGGridLayout-Info` |
| 선택 모드 종료 | Button label `취소` |
| 선택모드 하단 | Button label `항목 선택`; `삭제` Button은 선택0개여서 Disabled |

관찰된 현재 그리드 순서에서 owned A/B는 0-based image index 6/7이다. 이 순서를 모든 향후 화면/PhotosPicker에 일반화하지 않는다. 두 자산의 날짜 label이 같으므로 label만으로 A/B를 구분할 수 없다. 고유 원본명은 입력 provenance이며 현재 보관함 AX가 파일명을 노출한다는 뜻이 아니다. 부모는 실제 picker 화면을 별도 관찰하고 색상·치수·선택 후 결과를 대조해야 한다.

- [8개와 소유 색상 썸네일·선택 도구 화면](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/attachments05/08B946F6-0FFE-42A9-A316-5A3A51D430B2.png)
- [최종 선택 모드 AX 트리](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/attachments05/4FD006DE-DA56-4C25-9C98-7A4267699F14.txt)
- [최종 실행 로그](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/afterAdd05.log): 283행 count8, 330행8Photos, 356/357행소유자산, 388행삭제Disabled, 411행1/0.
- [최종 xcresult](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/afterAdd05.xcresult)

부수 관찰: 최종 실행 중 Photos 알림 권한 dialog가 나타났고, XCTest 기본 interruption handler가 `허용`을 자동 탭했다(로그 291~316행). 직접 작성한 설정 우회/키 변경은 없었으나 Photos 알림 허용이 발생했음을 기록한다. 최종 Photos는 아무 자산도 고르지 않은 선택 모드로 남아 있다.

현재 증거는 기존 6개를 보존한 실제 보관함에 소유 자산2개가 추가되었다는 범위다. actual W10 PhotosPicker 선택·취소·재선택, 카드 저장, 소유 원본 삭제 후 재실행은 부모의 후속 검증이며 여기서는 PASS로 주장하지 않는다.
