# T2 구현 보고

Status: NEEDS_CONTEXT — 테스트 결함 의심. 전체 GREEN 미확보.

## actual RED와 원인 수리
- 부모 `t2-red-test-recheck.log`: 컴파일 성공 후 unit 174 tests / 98 failures (11 unexpected), exit 65. 이전 recordJSON delimiter 컴파일 오류와 분리한 실제 assertion RED다.
- GREEN 후보 실행 1~5: unit 174 tests / 17 failures (1 unexpected), exit 65. 선언 stub는 해소했으나 ImageIO가 손상 PNG를 투명 thumbnail로 부분 복구하면서 사진/Store assertion이 실패했다. 색 기대값 5건도 실패했다. attempt1~attempt5 로그를 보존했다.
- source/index `.statusComplete`, thumbnail 성공, bitmap draw, thumbnail provider 접근만으로는 손상을 검출하지 못했다. 두 초기 bitmap 비교도 투명 fallback을 판별하지 못해 제거했다.
- 최종 수리: 원본 ImageIO index 이미지를 subsample factor 8로 요청하고 실제 pixel provider 데이터가 nil이면 unreadable. thumbnail은 원본 source에서 매번 always/max/transform 옵션으로 생성한다. 이 검사를 load/save/backup의 actual 사진 검증에서도 공유한다. 원본 UIImage 전체 디코딩과 새 cache 계층은 없다.
- 진단 중 원본 색 공간/RGBA 로그를 추가한 뒤 제거했다. 최종 source에는 임시 print/DEBUG 진단이 없다.

## 구현 내용
- `ios/FocusMate/CardStyle.swift`: 보관 생성자를 유지하며 표준 RGB 18/255,20/255,22/255와 실제 isStandard 판정. RGB→수량→중복 ID→전체 byte→각 사진 empty/장당 byte/양수 치수·ratio/finite 배치 순서로 검증. 총량은 남은 허용량과 비교한 뒤 더해 overflow를 피한다.
- `ios/FocusMate/CardSection.swift`: style 보관 및 updating(style:)에서 ID/발급 시각 유지. v3 CodingKeys에 필수 style 추가. 기존 ISO8601 날짜 encode/decode 유지.
- `ios/FocusMate/AppSnapshot.swift`: 카드 style 모델 오류를 invalidCardStyle로 포장한다. 기존 단계·정류장·카드·기록 검증 유지.
- `ios/FocusMate/SnapshotCodec.swift`: currentVersion=3. 독립 LegacySnapshotV2/LegacyCardV2DTO가 v2의 style을 모르는 키로 무시하고 기존 stage/station/card/journey/records 계약을 보존한다. v1 변환 유지, 다른 version은 unsupportedVersion. decode 후 기존 records 정렬 유지.
- `ios/FocusMate/CardPhotoProcessor.swift`: 8MiB 선행 검사, orientation 적용 metadata ratio 판정, complete source/index와 실제 픽셀 decode, 긴 변<=2048 thumbnail·bitmap draw. alpha 입력은 PNG, 나머지는 JPEG 0.85/0.7/0.55/0.4. 매 축소는 원본 source에서 다시 thumbnail 생성, long side*0.75/min64의 유한 축소. finalize/실제 byte<=1MiB 검사 후 출력 재디코딩 actual 치수/ratio/orientation 검증. 저장 사진은 declared/actual 치수 일치·긴 변·ratio·본문 검사 실패를 invalidCardPhoto로 분류. 사진 0장의 stored style은 통과.
- `ios/FocusMate/LocalSnapshotStore.swift`: load/save/backup 세 경로에 actual 사진 검증 공유. closure의 모든 throw를 invalidState(invalidCardPhoto)로 포장. save 후보 모델·사진 검증은 원본 load/encode/create/write보다 먼저. 원본 실패는 writeBlocked, atomic write는 기존 1회. 이미지 손상도 복구 대상이며 byte-for-byte backup 확인→원본 re-read→delete→missing 확인 순서는 그대로다. 마지막 named initializer 인자 호환 유지.

## focused 실행 증거
실행한 집합은 지정 9개 unit 파일과 SimulatorLargeTextRecoveryTests뿐이다. 전체 스위트·다른 빌드/검증 명령은 실행하지 않았다. 각 실행의 시뮬레이터 종료를 기다려 직렬로 재실행했다.

```sh
FOCUSMATE_SIMULATOR_ID=D3BB49D7-3834-4BC9-B910-1CADD9E036E1 python3 scripts/check-ios.py test ios/FocusMateTests/CardStyleTests.swift ios/FocusMateTests/CardPhotoProcessorTests.swift ios/FocusMateTests/CardStyleStorageTests.swift ios/FocusMateTests/SnapshotCodecTests.swift ios/FocusMateTests/CardStorageTests.swift ios/FocusMateTests/CardSupplementTests.swift ios/FocusMateTests/RecordStorageTests.swift ios/FocusMateTests/StorageRecoveryTests.swift ios/FocusMateTests/StorageV2Tests.swift ios/FocusMateUITests/SimulatorLargeTextRecoveryTests.swift > .dev/codex-feat-card-customization/t2-impl-test.log 2>&1
```

최종 실행 결과는 UI 종료 후 아래에 append한다. 현재 unit 결과: 174 tests / 5 failures (0 unexpected), 169 test cases pass. CardStyleStorageTests 17/17와 손상 processor 검사는 통과했다.

진단 실행 5에서 RecordStorageTests selector를 실수로 2번 전달했다. 다른 시험을 추가하지 않았고 실제 실행 count는 unit 174로 동일했다. 최종 실행 6은 지정 명령과 정확히 동일한 인자 목록이다.

## 테스트 결함 의심 — 부모 test-author 확인 요청
`CardPhotoTestFixtures.image()`의 CGContext는 DeviceRGB이고 `CGColor(red:green:blue:alpha:)`로 채운다. processor 변환 전 원본 source를 CGImageSourceCreateImageAtIndex로 디코딩한 실제 raw pixels부터 기대 순수 빨강과 다르다. 원본 Data는 변경하지 않았다.

진단 로그 `t2-impl-test-attempt5.log`의 원본/thumbnail 비교:
- PNG 및 exact8MiB PNG: 원본 sRGB premultipliedLast `[255,38,0,255]`, thumbnail/출력도 green 38. 시험은 green<15를 기대한다.
- JPEG: 원본 sRGB noneSkipLast `[255,39,0,255]`, 출력 green39. 시험은 green<15를 기대한다.
- HEIC: 원본 sRGB noneSkipLast `[255,38,1,255]`, 출력 green38. 시험은 green<15를 기대한다.
- alpha PNG: 원본 sRGB premultipliedLast `[128,19,0,128]`, 출력 green19, alpha128. 시험은 green<5를 기대한다.
- WebP는 원본/출력 `[220,40,80,255]`로 허용 오차 시험이 통과한다.

부모 test-author가 원본 fixture 픽셀을 독립 확인하고 fixture의 context/색 공간 또는 기대값을 수리한 뒤 새 hash와 RED 증거를 제공해야 한다. context의 색 공간에 직접 RGB component를 지정하는 채우기 방식 등을 확인할 수 있다. 입력의 실제 색을 바꿔 assertion만 통과시키는 production 보정은 하지 않았다. 테스트 파일 작성·수정·삭제와 해시 파일 수정은 0회다.

## REFACTOR 내역
전체 focused GREEN이 아니므로 독립 REFACTOR 단계에 진입하지 않았으며 GREEN 유지 성공을 주장하지 않는다. 구현에 필요한 private source/metadata/thumbnail/encode helper 및 Store validatePhotos(in:)로 중복 경로를 공유했다. declaration marker, 실패한 두 bitmap 비교, 임시 진단 출력은 제거했다. frozen legacy 날짜 decoder와 현재 v3 날짜 decoder는 버전 계약 독립성을 위해 합치지 않았다. 추가 기능·외부 공개 API·format allowlist·cache 계층은 추가하지 않았다.

## self-review 결과
6개 허용 생산 파일 전체와 tracked diff를 직접 대조했다. 최신 snapshot의 카드 외 여정/기록을 초기화하지 않고 v2 DTO에서 기존 필수 records/journey 구조를 유지한다. 잘못된 style과 actual 사진 오류를 구분하고, 원본 보존 복구 순서는 바꾸지 않았다. 저장 후보의 실패에 read/create/write가 발생하지 않는 시험이 최종 후보에서 통과했다. TimeSelection 등 다른 생산 파일·테스트는 수정하지 않았다. commit/push/agent/다른 worktree 작업은 없다.

## 우려사항
- 위 5개 색상 assertion 때문에 완료/GREEN을 선언할 수 없다. 부모 test-author 확인이 필요하다.
- 범위 밖 기존 actor-isolation/unused 테스트 변수 경고와 SDK AppIntents metadata/시뮬레이터 진단 출력은 변경하지 않았다. 손상 입력의 ImageIO 진단은 플랫폼 출력이며 자체 로그를 추가하지 않았다.
- 설치 SDK CGImageSource/CGContext 선언과 reports/api-notes.md의 공식 근거를 사용했다. source/index 실제 decode를 검사하며 subsample 지원이 없는 형식은 ImageIO가 더 큰 index 이미지를 반환할 수 있다. 최종 저장/thumbnail의 2048 한도와 별개인 decode 자원 특성이다.

## 최종 focused 실행 종료 결과
- 지정 명령 정확히 재실행(실행 6), 실제 프로세스 종료 코드 65. `** TEST FAILED **`.
- Unit: 174 tests / 5 failures (0 unexpected), 169개 case pass.
- SimulatorLargeTextRecoveryTests: 2 tests / 0 failures (0 unexpected), 2개 pass.
- 합계: 실제 176개 case / 171 pass / 5 fail. 5개는 원본 RGB와 다른 색상 기대 assertion이며, GREEN 미확보.
- CardPhotoProcessorTests 25개 중 20개 pass, CardStyleTests 59/59, CardStyleStorageTests 17/17. 기존 저장·마이그레이션·복구 시험 및 UI 회귀 모두 pass.
- 최종 소스에는 declaration marker/임시 진단 출력 없음. tracked 허용 생산 diff 공백 검사 exit0, 신규 두 파일은 전문 self-review로 확인.
- 테스트 해시 최종 확인: t2-test-hashes.json: 13개 전부 일치; t1-test-hashes.json: 3개 전부 일치. 해시 파일 자체를 수정하지 않았다.
- 다음 단계: 부모 test-author가 fixture 실제 픽셀과 기대값의 불일치를 확인·수리하고 새 hash를 인계하면 같은 focused 명령으로 GREEN 검증 후 독립 REFACTOR 재개.

## 부모 fixture 수리 후 직접 GREEN
테스트 작성자가 fixture 생성/독립 판독을 명시적 sRGB로 통일하고 처리 전 원본 sanity검사를 추가했다. 기존 RGB/alpha기대값과모든케이스유지. 생산소스추가변경없음. 부모지정focused실행 actual176/176PASS,0fail,exit0. unit174/0fail,UI2/0fail. t2-parent-color-test.log. 해시 기준은author의허용2파일만갱신하고13파일전체무결성확인. 새소스수정없는상태에서추가 REFACTOR대상없음(기존helper공유완료). 태스크6개생산파일로 scopedreview진입. 이미지sourceDecode자원계약은후속리뷰에서확인해야한다.


## fix 라운드 1

### 구현 내용 — scoped-review I-1
- `ios/FocusMate/CardPhotoProcessor.swift`만 수정했다. 다른 생산 파일·시험 파일을 수정하지 않았고, 에이전트·commit/push를 사용하지 않았다.
- thumbnail의 `CGImageSourceCreateImageAtIndex` + `dataProvider.data` 원본 읽기와 subsample 우회 경로를 제거했다. 기존 ThumbnailAlways/MaxPixelSize/WithTransform, 최대 2048 thumbnail, 제한된 bitmap draw, source/index status 확인을 유지했다. 입력 byte/비율·alpha·인코딩 quality·유한 축소·출력 byte 재디코딩/치수/ratio/orientation 계약을 유지했다. 정상 WebP 제외나 새 원본 픽셀 한도를 넣지 않았다.
- 동일 파일의 private `CardPhotoIntegrity`가 PNG 실제 source type일 때 `completeSource`에서 한 번 검증한다. 최초 입력 검증은 축소 반복 밖에 있고 저장 사진·최종 출력 재검증도 같은 경계를 사용한다. 원본 raster Data/CGContext를 만들지 않는다.
- PNG signature, chunk 길이/경계/type/CRC(type+data), 첫 IHDR 13바이트/양수 31-bit 치수/표준 color type별 depth/압축0/filter0/interlace0 또는1, PLTE 제한과 indexed 필수·grayscale 금지, 하나 이상의 연속 IDAT, 마지막 IEND 길이0을 검증한다.
- 하나의 SDK zlib inflate 상태를 IDAT들에 걸쳐 유지한다. 고정 65,536바이트 output buffer로 Z_STREAM_END/Adler 검증을 요구하고 부분 복구를 사용하지 않는다. IHDR의 일반/Adam7 일곱 pass에서 빈 pass를 제외하고 안전한 UInt64 길이 산술로 정확한 행 수/바이트 수와 각 행 filter0...4를 검사한다. zlib 끝 뒤의 압축 tail만으로 거절하지 않는다.
- 실제 RIFF/WEBP chunk 경계와 VP8L signature/version 및 첫 transform의 필수 고정 prefix 비트 존재를 검사한다. 구체적인 6-byte VP8L payload의 0xff는 transform present/type3 뒤 color_table_size 8비트 중 5비트만 남아 `.unreadable`로 거절된다. JPEG/HEIC/PNG 및 일반 lossy/extended WebP decoder 경로를 제거하지 않았다.

### GREEN 증거
부모가 제공한 실제 RED는 `t2-memory-actual-red.log`의 RSS 증가530,186,240 > 고정402,653,184와 `t2-integrity-before-fix-actual.log`의 5실행/4PASS/1FAIL이다. 플랫폼 control 300,236,800/744samples/errors0은 부모 인계 값이며 이번 라운드에서 다시 실행하지 않았다.

1. **먼저 fresh 단일 memory 회귀** — exit0, 실제 고유 test 1개 시작/1개 PASS/0 FAIL, compiler error0, `** TEST SUCCEEDED **`.
```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate -destination 'platform=iOS Simulator,id=D3BB49D7-3834-4BC9-B910-1CADD9E036E1' -derivedDataPath .build/ios -parallel-testing-enabled NO -collect-test-diagnostics never -only-testing:FocusMateTests/CardPhotoMemoryTests/testI1_FirstProduction8192_preservesImageWithoutRedundantOriginalDecodeWithin384MiB test CODE_SIGNING_ALLOWED=NO > .dev/codex-feat-card-customization/t2-fix1-memory.log 2>&1
```
실제 출력:
```text
MEMORY_PROBE production-first-8192-384MiB baselineRSS=289718272 maxSampleRSS=655310848 sampledRSSGrowth=365592576 afterRSS=304037888 physFootprintBefore=31672504 physFootprintAfter=35080520 kernelLifetimePeakRSSBefore=314671104 kernelLifetimePeakRSSAfter=656343040 timerSampleCount=839 errors=[] sampledPeakIsLowerBound=true kernelPeakIsNotResettable=true
Executed 1 test, with 0 failures (0 unexpected) in 0.908 (0.913) seconds
** TEST SUCCEEDED **
```
입력/기대/384MiB 한도를 그대로 유지했다. 365,592,576 <= 402,653,184이며 정상 출력 치수·byte·독립 색 assertion도 같은 test 안에서 PASS했다.

2. **그 후 지정 focused 회귀** — exit0, 실제 고유 test 179개 시작/179개 PASS/0 FAIL, compiler error0. suite 중복 요약을 더하지 않고 Test Case started/passed를 직접 세었다. `CardPhotoIntegrityTests` 5개 모두 실제 PASS(잘린 IDAT, 짧은 raster, 정상 multi-IDAT, 정상 Adam7, malformed VP8L). 기존 process/stored damaged-body 시험도 포함된다.
```sh
FOCUSMATE_SIMULATOR_ID=D3BB49D7-3834-4BC9-B910-1CADD9E036E1 python3 scripts/check-ios.py test ios/FocusMateTests/CardStyleTests.swift ios/FocusMateTests/CardPhotoProcessorTests.swift ios/FocusMateTests/CardStyleStorageTests.swift ios/FocusMateTests/CardPhotoIntegrityTests.swift ios/FocusMateTests/SnapshotCodecTests.swift ios/FocusMateTests/CardStorageTests.swift ios/FocusMateTests/CardSupplementTests.swift ios/FocusMateTests/RecordStorageTests.swift ios/FocusMateTests/StorageRecoveryTests.swift ios/FocusMateTests/StorageV2Tests.swift > .dev/codex-feat-card-customization/t2-fix1-focused.log 2>&1
```
실제 마지막 결과:
```text
Executed 179 tests, with 0 failures (0 unexpected) in 8.427 (8.484) seconds
** TEST SUCCEEDED **
```
전체 suite/다른 device/UI를 실행하지 않았다. 부모의 별도 누적 UI·fresh memory 검증은 이 보고의 실행 범위 밖이다.

### REFACTOR 내역
1. source 무결성 검증을 private helper와 scanline 상태로 분리하고 기존 thumbnail helper를 제한된 decode/draw 책임으로 정리했다 → 위 focused179 PASS로 확인. 이후 추가 정리나 동작 변경 없음.

### self-review 결과
- 실제 byte buffer 경계 검사를 pointer 접근 전에 수행하고, chunk CRC에 type와 data를 함께 포함했다. IDAT boundary에서 inflate 상태를 리셋하지 않으며 행 filter가 buffer boundary를 넘어도 상태를 유지한다. scanline 총 길이는 overflow를 검사한다. 64KiB 외 원본 크기에 비례하는 raster 저장 없음.
- `completeSource`의 공통 진입점이 process/stored validation 양쪽에 적용됨을 확인했다. 최종 encoded bytes 재디코딩·치수/비율/orientation 검사 유지.
- 테스트 잠금 JSON은 일반 파일 SHA-1이 아닌 Git blob SHA-1이다. 해당 방식으로 15개 전부 확인했고 불일치0이다. 테스트 수정 없음.
- 자기 검토에서 추가 수정이 필요한 발견 없음. M1/M2/M3 추측 수정 없음. 기존 보고 및 `## 과잉 구현 정리` 절을 포함한 앞선 내용은 append로 보존했다.

### 우려사항·검증 한계
- ImageIO WebP thumbnail 자체가 큰 일시 할당을 할 수 있다. 이 수정은 중복 원본 decode/cache를 제거하며 모든 decoder 내부 할당을 2048 raster 크기로 제한한다는 보장이 아니다. sampled RSS는 관측 하한이며 384MiB 실제 회귀 PASS가 모든 입력/실기기 메모리 보장을 뜻하지 않는다.
- WebP guard는 필수 framing/첫 transform prefix만 검사한다. 전체 entropy/transform/pixel bitstream의 strict 무결성 decoder가 아니다. ImageIO status·제한된 decode/draw를 계속 사용한다.
- 첫 memory build에는 기존 CardIssuanceView actor 경고, 기존 시험 unused 값 경고, AppIntents metadata extraction 안내가 있었다. 범위 밖 경고를 수정하지 않았으며 경고 없는 출력이라고 주장하지 않는다.

### 직접 확인한 공식 근거
- [W3C PNG 3 규격](https://www.w3.org/TR/png-3/), sections5/7/8/9/10/11: chunk/type/CRC/order, scanline/Adam7/filter, 단일 zlib IDAT stream, IHDR/PLTE/IEND 및 IDAT 뒤 unused trailing bytes 허용.
- [Google WebP lossless 규격](https://developers.google.com/speed/webp/docs/webp_lossless_bitstream_specification), sections2/3/4/4.1/4.2/4.4: LSB-first와 signature/version, transform presence/type, 고정 size bits, color_table_size=ReadBits(8)+1. 요청 URL의 실제 문서는 `_specification` 경로다.
- 설치 iPhoneSimulator27.0 SDK `usr/include/zlib.h`: inflateInit_/inflate/avail_in/avail_out/Z_STREAM_END/Z_BUF_ERROR/crc32 계약. 새 의존 패키지 없음; `import zlib` SDK 모듈 사용.

**Status: DONE** — I-1 FIX R1의 지정 source 수정·focused 검증 완료. 위 검증 한계는 유지하며 전체 W10 완료를 주장하지 않는다.

## 부모 fixR1 직접 검증
별도 fresh memory1/1PASS, sampledRSSGrowth363495424<=고정402653184,541samples/errors0. 이어누적focused184/184PASS(unit182+T1UI2),exit0. t2-parent-fix1-memory.log /t2-parent-fix1-cumulative.log. 새5 integrity/3 memory도모두실행. 테스트15hash일치, source변경없이parent직접검증. scopedre-review진입.
