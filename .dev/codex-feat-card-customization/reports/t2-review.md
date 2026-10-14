# W10 T2 통합 리뷰 — 태스크 범위 모드

현재 worktree의 T2 diff와 실제 생산 6파일·관련 시험 10파일(시험 클래스 9개와 fixture helper)을 읽었다. PRD와 design.md 최종 계약, codemap.md, t2-red.md/t2-impl.md, 지정 testing-anti-patterns.md를 기준으로 검토했다. 구현 보고의 정당화는 판정 근거로 사용하지 않았다. 테스트·빌드를 실행하지 않았으며 source/test 수정, commit/push, 다른 worktree 작업, 에이전트 호출을 하지 않았다. 이 보고서만 작성했다.

기존 실행 사실: `.dev/codex-feat-card-customization/t2-parent-color-test.log:708`의 unit 174개/실패 0, `:5887`의 UI 2개/실패 0, `:5899`의 TEST SUCCEEDED를 직접 읽었다. 합계 실제 176개/실패 0이며 중복 suite 요약을 더하지 않았다. UI 2개는 기존 큰 글자 회귀로 T2 이미지 자원 상한이나 PhotosPicker 실사용의 증거가 아니다. t2-impl.md 앞부분의 과거 실패 기록과 최신 실행 사실을 구분했다.

## Part 1: AC 충족 매트릭스

판정 대상은 design.md:204에 배정된 7개 AC의 **T2 계층만**이다. Controller의 clamp/초안·안내, AppModel 저장 연결, 공통 UI, 실제 PhotosPicker·사진 보관함 삭제는 T3/T4/T5 후속 범위다.

| AC | 충족도 | 근거 (파일:라인 또는 PRD 인용) |
|----|-------|------|
| AC-W10-05 | ✅ | CardPhotoProcessor.swift:31의 8,388,608바이트 이하 검사, :33의 실제 source, :35의 orientation 반영 비율 0.1...10 검사, :87의 source/index complete, :116의 실제 픽셀 검증·thumbnail, :143의 재인코딩. CardPhotoProcessorTests.swift:25/48/71/230에 실제 JPEG/PNG/HEIC/WebP, :127~177에 비율·손상·초과, :254에 정확히 8MiB 성공 시험. :28/51/74/98/260의 독립 sRGB 입력 sanity와 출력 내용 assertion을 확인했다. 자원 문제는 Part 2 I-1로 별도 판정한다. |
| AC-W10-12 | ✅ | CardStyle.swift:84~92는 저장 치수·비율·유한 배치와 중심 -1...2/너비 0.15...2.5를 검증하고 저장값을 clamp하지 않는다. CardStyleTests.swift:120~221은 각 축/너비 경계·범위 밖·NaN/±Infinity를 분리 검증한다. 편집 요청 clamp는 T3 범위다. |
| AC-W10-24 | ✅ | CardSection.swift:7/15/33/40에 외형과 정체성 유지, SnapshotCodec.swift:38/64에 v3 공동 JSON 저장, LocalSnapshotStore.swift:104~114에 후보 검증 후 atomic write. CardStyleStorageTests.swift:36~67은 실제 파일과 새 Store에서 6장 바이트·alpha·색·순서·배치·ID·발급시각 복원. 완료 안내와 앱 화면 연결은 후속 범위다. |
| AC-W10-25 | ✅ | CardPhoto.swift에 해당하는 CardStyle.swift:27~45의 Data 값 보관과 단일 snapshot base64 저장은 입력 경로를 보관하지 않는다. CardStyleStorageTests.swift:72~82는 입력 원본 **파일** 삭제 뒤 새 Store에서 내용/외형 복원을 검증한다. 실제 사진 보관함 원본 삭제 성공으로 확대하지 않는다. |
| AC-W10-27 | ✅ | CardStyle.swift:74~83은 overflow 없이 전체 6,291,456바이트를 장당 1,048,576바이트보다 먼저 검사한다. CardStyleStorageTests.swift:234/258/283/307에서 정확한 네 경계의 저장·복원 또는 쓰기/디렉토리 생성 0회·원본 보존을 검증한다. 여기의 no-op 실제이미지 validator는 design.md:164가 허용한 **구조 byte 시험**이며 실제 이미지 성공 증거는 AC24의 별도 실제 PNG 시험이다. |
| AC-W10-28 | ✅ | LocalSnapshotStore.swift:93~101(load), :105~109(save), :59~68(backup 정상판정)에 같은 실제이미지 검증 경계를 사용한다. 후보 실패는 invalidState, 기존 원본 실패는 writeBlocked로 분리한다. :72~84는 byte 동일 백업 재읽기→원본 재읽기/비교→삭제→없음 확인을 유지한다. CardStyleStorageTests.swift:169/184/199/217/331/344는 검증 선행·손상·백업 실패·치수 불일치·원본 보존을 검증하며 StorageRecoveryTests.swift:80/106/278/324/344에서 기존 재읽기·삭제 확인 회귀가 유지된다. 오류 UI/재시도 연결은 후속 범위다. |
| AC-W10-29 | ✅ | SnapshotCodec.swift:11~34에 현재 CardSnapshot과 분리된 v2 DTO, :51~60에 헤더→지원 버전→구조→내용 순서, :70~83에 v1/v2 변환 및 기존 영역 유지. CardSection.swift:33은 v3 style 필수다. CardStyleStorageTests.swift:87/99/109/140은 v3 누락 거절·v2 unknown style 무시·v1/v2 읽기 무쓰기·v3 저장 후 이용 상태 보존. CardSupplementTests.swift:25/45/87/110은 기존 보충·재발급 방지·읽기 무쓰기 회귀를 유지한다. |

[Must] 7건 중 7건 충족, [Should] 0건 중 0건 충족. 이는 T2 계층 판정이며 전체 W10 완료 판정이 아니다.

### 최종 계약 대조

- CardStyle.swift:66~94의 순서는 RGB→수량→중복 ID→전체 byte→사진별 빈 Data→장당 byte→치수/비율→배치이며 생성자는 값만 보관한다. 기본 RGB는 #121416 그대로다. 준비색 UI 목록은 심사하지 않았다.
- SnapshotCodec.swift:45~61은 unsupportedVersion을 구조 오류보다 먼저 분류하며 currentVersion=3이다. v2 id/issuedAt 해석은 별도 DTO로 고정되고 v2 unknown style은 현재 v3 필수 style decoder에 들어가지 않는다. 기존 정류장·journey·records 계약을 이번 변경에서 바꾸지 않았다.
- CardPhotoProcessor.swift:38~60은 최초 긴 변 2048, alpha PNG/불투명 JPEG, 정해진 quality와 유한 0.75 축소를 사용한다. 결과 바이트를 다시 읽어 치수/비율/단일 orientation을 확인한다. 저장사진은 :64~80에서 선언/실제 치수·긴 변·비율을 검사한다. **최종 크기 상한과 원본 디코딩 자원 상한은 다르다**. 후자는 Part 2 I-1에 보고한다.

## 설계 범위 이탈

파일 범위 이탈 없음. 제공된 diff stat은 생산 6파일·시험 10파일, 총 16파일/1,451 insertions/32 deletions다. 기존 시험 변경은 v3 출력·미지원 v4 기대값 및 새 필수 style 확인이며 v1/v2 입력·보존 계약을 유지한다. TimeSelection과 새 UI 소스는 T2 diff에 없고 심사하지 않았다.

구현 방식의 차이는 있다: design.md:61의 원본 전체 디코딩을 피하는 처리 목적에 대해 CardPhotoProcessor.swift:121의 원본 index decode는 제한된 thumbnail 경계 밖에서 실행된다. 이는 파일 범위 이탈이 아니라 Part 2 I-1의 자원 처리 결함이다.

## Part 1 판정

**SPEC PASS** — 배정된 T2 AC 7개 모두 ✅. UI·Controller·실제 보관함 작업을 미구현이라는 이유로 T2 실패로 처리하지 않는다. 이 판정을 먼저 확정한 후 아래 품질 판정을 수행한다.

## Part 2: 코드 품질 리뷰

### Critical (0건) — 전부 [동작결함]

없음. 아래 I-1은 자원 상한 부재가 코드·SDK 계약으로 확인되지만 실제 앱 종료를 재현한 증거는 없어 Important로 분류했다.

### Important (1건) — 항목마다 [동작결함|동작불변] 표기 필수

- **I-1 — ios/FocusMate/CardPhotoProcessor.swift:121~124 — 원본 픽셀 디코딩이 thumbnail 2048 제한을 우회한다. → [동작결함]**
  - `thumbnail`은 `CGImageSourceCreateImageAtIndex`에 cache=true, cacheImmediately=true, subsampleFactor=8을 전달하고 `dataProvider.data`까지 읽은 **후** 별도의 thumbnail을 만든다. :126의 `max(image.width, image.height) <= maximum` 검사는 thumbnail에만 적용되며 sourceImage에는 적용되지 않는다. sourceImage 치수 확인을 이 호출 뒤에 추가하는 것만으로도 이미 발생한 즉시 디코딩 비용을 막지 못한다.
  - 설치 공식 SDK `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/ImageIO.framework/Headers/CGImageSource.h:260~275`는 subsample을 가능한 경우의 축소 요청으로 정의하고 미지원 배율이면 larger/full-size 반환을 허용한다. 지원 형식은 JPEG/HEIF/TIFF/PNG뿐이며 **현재 실제 처리 시험이 통과한 WebP는 이 보장 대상에 없다**. 같은 헤더 :131~142는 cacheImmediately의 생성 시점 decode/cache를 명시한다.
  - 입력 검사는 압축 Data 8MiB와 비율뿐(:32~37)이므로 원본 픽셀 수에는 앱이 정한 상한이 없다. 지원 형식이어도 1/8 축소는 고정 픽셀 상한이 아니며, 미지원 형식/배율은 원본 전체가 디코딩될 수 있다. 따라서 이후 최대 2048 thumbnail이나 1MiB 출력 검사가 원본 decode 메모리를 제한하지 못한다. 이는 design.md:61의 메모리 목적에 부합하지 않고, 정상 고압축 대형 사진 입력에서도 메모리 압박/앱 종료로 이어질 수 있다. 실제 종료 재현을 주장하는 것은 아니다.
  - 이 helper는 process의 매 축소(:40)와 출력 재검증(:52)·저장사진 검증(:76)에 재사용된다. 저장사진 경로는 호출 전 실제 치수 <=2048을 검사하므로 동일한 무제한 원본 위험은 **외부 입력 process 경로**에 집중된다. 저장 경로까지 무제한이라고 확대하지 않는다.
  - 권고: 손상 본문 거절을 유지하면서 원본 픽셀 자원 상한이 보장되는 decode 경계로 교체한다. subsample 옵션을 하드 상한으로 사용하지 말고, 미지원 형식·fallback·큰 원본에서도 bounded decode가 성립하는지 증거를 확보한다. 임의로 정상 WebP를 제거하거나 PRD에 없는 원본 치수 제한을 조용히 추가하지 않는다. 부모는 동작 결함 RGR로 처리한다.
  - [검증 필요] 기존 `testAC05_DamagedBody_거절`, `testStoredDamagedBody`, `testAC05_WebP_실제이미지는_보존가능한_내용으로_처리된다`, `testLongSideAbove2048_비율을_유지하여_축소한다`를 유지하며 고압축 대형 WebP/PNG의 decode peak를 부모가 focused 확인한다. 기존 176 PASS는 이 자원 경계를 검증하지 않는다.

### Minor (3건) — 전부 [동작불변], 비차단

- **M-1 — ios/FocusMate/CardPhotoProcessor.swift:49; ios/FocusMateTests/CardPhotoProcessorTests.swift:127~141/182~186 — 축소되는 극단 비율의 반올림은 미확인이다.** 입력 0.1/10 경계 시험은 10×100/100×10으로 축소가 없고, 큰 이미지 시험은 비율 2다. 원본에서는 유효한 0.1/10 또는 경계 근처 비율이 정수 thumbnail 치수 반올림으로 범위를 벗어나면 :49에서 encodingFailed가 된다. 실제 ImageIO가 이 입력에서 어느 치수를 반환하는지는 이번 읽기 리뷰로 확정하지 않았으므로 결함으로 단정하지 않는다.
  - [검증 필요] 부모가 1000×10000/10000×1000 및 경계 근처 정상 이미지의 focused 처리 결과를 확인한다. 경계 허용/비율 보존이라는 기존 계약을 확인하는 작업이며 새 기능 제안은 아니다.
- **M-2 — ios/FocusMateTests/CardPhotoProcessorTests.swift:111~123; ios/FocusMateTests/CardPhotoTestFixtures.swift:18~21 — orientation 시험의 균일 단색 입력은 회전 방향 오류를 구별하지 못한다.** 현재 치수 swap과 orientation 제거·저장 검증은 확인하지만 +90°와 -90° 또는 거울 변환이 같은 치수를 만드는 경우 순수 빨강 전체는 구분되지 않는다. 실제 구현은 WithTransform을 사용하므로 현재 회전 오류를 발견했다는 주장은 아니다.
  - 권고: 부모 test-author가 비대칭 모서리/영역을 가진 입력과 독립 좌표별 픽셀 기댓값으로 이 시험의 검증력을 보강할 수 있다. 이 리뷰에서 테스트를 추가하거나 실행하지 않았다.
- **M-3 — ios/FocusMateTests/CardStyleStorageTests.swift:243~246/292~295 — 성공 byte 경계 시험의 미사용 관측값이 남아 있다.** PerPhotoLimit/TotalLimit의 `original`은 읽고 사용하지 않으며 `directories`는 증가시키지만 assertion이 없다. 실패 시험과 복사된 설정이 성공 시험의 검증 대상처럼 보인다.
  - 권고: 불필요한 원본 읽기·카운터를 제거하거나 성공 시 검증하려는 부작용을 assertion으로 명확히 한다. 후보 equality/실제 파일 재로드라는 핵심 검증은 이미 유지된다.

### 테스트 품질 규약 대조

지정 testing-anti-patterns.md의 깨짐 명명·미러 assertion·모의 경계·시험 전용 생산 메서드 기준으로 읽었다. 실제 ImageIO fixture/독립 sRGB 판독, 손수 쓴 legacy JSON, 실제 temp file 재로드를 사용한다. Store의 I/O closure 카운트는 실제 Store의 선행 검증/부작용을 관측하며 모의 자체 성공을 검사하지 않는다. AC27 no-op validator는 허용된 구조 byte 경계에 한정된다. 생산 코드에 시험 전용 API는 추가되지 않았다. 직렬화 golden은 규약이 허용하는 데이터 계약 시험이다. 추가 차단 수준의 테스트 품질 결함은 확인하지 않았다. M-1/M-2는 근거가 제한된 검증 관찰로만 남겼으며 AC 충족을 여기서 재판정하지 않았다.

## Part 2 판정

**QUALITY FAIL** — Critical 0, Important 1(동작결함 1), Minor 3. I-1을 수정하고 부모가 해당 자원 경계를 검증한 뒤 재리뷰가 필요하다. 이번 리뷰는 권고만 제공하며 구현을 수행하지 않았다.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 7
  ac_met: 7
  ac_partial: 0
  ac_unmet: 0
  unmet_ids: []
```

```yaml
quality_verdict:
  verdict: FAIL
  critical: 0
  important: 1
  important_behavior: 1
  minor: 3
```
