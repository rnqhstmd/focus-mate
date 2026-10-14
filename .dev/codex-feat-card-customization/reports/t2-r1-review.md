# W10 T2 재리뷰 R1

태스크 범위: design.md:204의 T2 계층과 AC-W10-05/12/24/25/27/28/29만 심사했다. 실제 `reports/t2-r1-diff.txt`, 최신 PRD/설계 부록, 이전 `t2-review.md`, `t2-impl.md` fix1 부록, `t2-memory-red.md`, 관련 생산/시험 소스와 부모 실행 로그를 읽었다. 구현자의 의도 설명 대신 실제 코드와 로그로 판단했다. 테스트·빌드·에이전트·Git 작업을 실행하지 않았고 이 보고서만 작성했다.

## Part 1: AC 충족 매트릭스

아래 ✅는 **배정된 T2 책임의 충족**이다. PhotosPicker, Controller clamp/초안/안내, AppModel 연결, 실제 보관함 삭제와 공통 UI는 후속 태스크의 pending이며 T2 실패 항목이 아니다.

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-W10-05 | ✅ | `ios/FocusMate/CardPhotoProcessor.swift:33`의 8MiB 선행 검사, :34~37의 실제 source/orientation 반영 비율, :88~100의 완전 source와 무결성 검증, :121~140의 제한 thumbnail/draw, :44~57의 출력 byte·치수·orientation 재검증. `ios/FocusMateTests/CardPhotoProcessorTests.swift:25/48/71/230/254`의 실제 JPG/PNG/HEIC/WebP/정확한 8MiB 정상 입력과 :127~177의 비율·손상·초과 거절이 유지된다. 신규 `CardPhotoIntegrityTests.swift:7/19/27/40/48`은 손상과 정상 multi-IDAT/Adam7 입력을 구별한다. |
| AC-W10-12 | ✅ | `ios/FocusMate/CardStyle.swift:84~92`의 저장 치수/비율과 유한 중심 -1...2, 너비 0.15...2.5 검증. `ios/FocusMateTests/CardStyleTests.swift:120~220`은 양축/너비 경계·범위 밖·NaN/Infinity를 검증한다. 저장값을 clamp하지 않으며 편집 요청 clamp는 T3 책임이다. |
| AC-W10-24 | ✅ | `ios/FocusMate/CardSection.swift:7/15/33/40`의 style과 ID/발급 시각 유지, `SnapshotCodec.swift:38/64`의 공동 v3 JSON, `LocalSnapshotStore.swift:104~114`의 검증 후 atomic write. `ios/FocusMateTests/CardStyleStorageTests.swift:36~67`은 실제 파일/새 Store에서 6장의 내용·alpha·배치·순서·색·정체성 복원을 확인한다. 완료 안내는 후속 범위다. |
| AC-W10-25 | ✅ | `ios/FocusMate/CardStyle.swift:27~45`의 소유 Data를 같은 snapshot에 저장하며 원본 경로에 의존하지 않는다. `ios/FocusMateTests/CardStyleStorageTests.swift:72~82`는 입력 원본 파일 삭제 후 새 Store 복원을 확인한다. 실제 Photos 보관함 삭제 검증은 pending이다. |
| AC-W10-27 | ✅ | `ios/FocusMate/CardStyle.swift:74~83`에서 전체 6,291,456바이트를 overflow 없이 검사한 뒤 장당 1,048,576바이트를 검사한다. `ios/FocusMateTests/CardStyleStorageTests.swift:234/258/283/307`은 정확한 네 경계에서 저장/복원 또는 쓰기·디렉토리 생성 0회와 기존 원본 보존을 확인한다. 구조 byte 시험의 허용된 no-op 이미지 validator를 실제 정상 이미지 검증 증거로 확대하지 않는다. |
| AC-W10-28 | ✅ | `ios/FocusMate/LocalSnapshotStore.swift:59~68/93~101/105~109`에서 backup/load/save가 실제 사진 검증을 공유한다. 후보 실패와 원본 writeBlocked를 분리하고 :72~84의 byte 동일 백업 재읽기→원본 재확인→삭제→없음 확인을 유지한다. `ios/FocusMateTests/CardStyleStorageTests.swift:169/184/199/217/331/344`의 손상·선행검증·백업 실패·치수 불일치·원본 보존 시험이 유지된다. 앱 오류/재시도 UI는 후속 범위다. |
| AC-W10-29 | ✅ | `ios/FocusMate/SnapshotCodec.swift:11~34/51~61/70~83`은 독립 v2 DTO와 v1/v2 읽기·변환, 기존 영역 보존 및 v3 저장을 구현한다. `CardSection.swift:33`은 v3 style 필수다. `ios/FocusMateTests/CardStyleStorageTests.swift:87/99/109/140`과 `CardSupplementTests.swift:25/45/87/110`의 누락 거절·unknown style 무시·읽기 무쓰기·이용 상태/정체성·보충 회귀가 유지된다. |

[Must] 7건 중 7건 충족, [Should] 0건 중 0건 충족.

## 설계 범위 이탈

이탈 없음. 누적 T2 diff는 생산 6파일과 관련 시험 12파일이며 R1 생산 수정은 `CardPhotoProcessor.swift`에 집중되어 있다. 최신 design.md:226~231의 원본 index/provider 추가 할당 제거, PNG 고정 버퍼 검증, WebP 필수 prefix 검증 범위에 부합한다. 새로운 원본 픽셀 상한이나 정상 형식 배제는 없다.

## Part 1 판정

**SPEC PASS** — T2 계층의 지정 AC 7개 모두 충족한다. 이 판정을 먼저 확정한다. 전체 W10/실제 picker/화면 완료 승인은 아니다.

## 재리뷰 판정

| 이전 항목 | 판정 | 근거 |
|-----------|------|------|
| I-1 원본 decode/cache/provider 전체 Data 추가 할당 | ADDRESSED — CLOSED | `ios/FocusMate/CardPhotoProcessor.swift:121~140`은 thumbnail과 제한된 context만 사용한다. :88~100/:157~307의 PNG 검증은 원본 raster를 만들지 않는다. 부모 fresh 메모리 로그 :197~212의 고정 예산 PASS와 실제 출력 assertion 성공으로 종결한다. |
| M-1 축소되는 극단 비율의 반올림 관찰 | NOT ADDRESSED — DEFER | `ios/FocusMate/CardPhotoProcessor.swift:50`, `ios/FocusMateTests/CardPhotoProcessorTests.swift:127~141/182~186`. 관련 신규 재현 증거 없음; 이전 Minor 유지. |
| M-2 균일 색 orientation fixture의 검증력 | NOT ADDRESSED — DEFER | `ios/FocusMateTests/CardPhotoProcessorTests.swift:111~123`, `CardPhotoTestFixtures.swift:18~21`. 비대칭 방향 assertion으로 변경되지 않았으며 회전 동작 결함 증거 없음. |
| M-3 성공 byte 경계 시험의 미사용 관측값 | NOT ADDRESSED — DEFER | `ios/FocusMateTests/CardStyleStorageTests.swift:243~246/292~295`. `original`/`directories`의 미사용 관측값 유지. 비차단 Minor 유지. |

## Part 2: 코드 품질 리뷰

### Critical (0건) — [동작결함]

없음.

### Important (0건)

없음. 이전 I-1은 ADDRESSED/CLOSED이며 신규 차단 결함은 확인하지 않았다.

### Minor (3건) — [동작불변], 비차단

- **M-1 — DEFER — `ios/FocusMate/CardPhotoProcessor.swift:50`; `ios/FocusMateTests/CardPhotoProcessorTests.swift:127~141/182~186` — [동작불변] [검증 필요]**. 축소되는 0.1/10 경계·근접 비율의 정수 치수 반올림은 이전 관찰 그대로다. 이번 수정에서 새 동작 결함을 재현한 근거가 없으므로 승격하지 않는다. 후속 focused 확인 대상은 1000×10000/10000×1000 및 경계 근처 정상 입력이다.
- **M-2 — DEFER — `ios/FocusMateTests/CardPhotoProcessorTests.swift:111~123`; `CardPhotoTestFixtures.swift:18~21` — [동작불변]**. 균일 색 입력은 같은 치수를 만드는 반대 회전/거울 변환을 구별하지 못한다. 현재 WithTransform 구현의 오류를 주장하지 않는다. 비대칭 영역과 독립 좌표별 색 assertion 보강 권고는 이전과 같다.
- **M-3 — DEFER — `ios/FocusMateTests/CardStyleStorageTests.swift:243~246/292~295` — [동작불변]**. 성공 byte 경계 시험에서 사용하지 않는 원본 읽기/디렉토리 카운터가 남아 있다. 핵심 저장·재로드 equality는 유지된다. 미사용 관측값 정리 권고는 이전과 같다.

### 수정 경계 검토

- **원본 자원 소유권:** 생산 코드에서 `CGImageSourceCreateImageAtIndex`, 원본 `dataProvider.data`, subsample fallback이 제거됐다. `completeSource`는 cache=false이고 입력 무결성 확인은 축소 반복 밖이다(:34/40). 실제 썸네일/draw는 최대 2048 치수 확인 뒤 실행된다(:125~134). zlib 상태는 지역 소유이며 초기화 성공 직후 `defer inflateEnd`를 등록한다(:167~172). 입력 pointer는 `withUnsafeBytes` 밖으로 나오지 않는다.
- **PNG bounds/성능:** :181~195는 chunk 길이·CRC 접근 전에 범위를 확인하고 :214~218은 표준 치수/depth/interlace 조합을 확인한다. :219~227은 palette와 IDAT 순서를 검사한다. :230~250은 동일 inflate 상태와 64KiB 출력 버퍼를 사용하며 진행 없는 반복을 종료/거절한다. :273~306은 일반/Adam7 행 크기를 UInt64로 도출하고 합/곱 overflow와 정확한 raster 총량·filter 0...4를 검사한다. 빈 Adam7 pass를 건너뛰고 행/버퍼 경계 상태를 유지한다. 원본 픽셀 수에 비례하는 배열을 만들지 않는다. 처리 시간은 압축 해제량에 비례하며 전체 decoder CPU/메모리의 전역 상한을 보장하지 않는다.
- **정상 PNG 호환:** grayscale 1/2/4/8/16, truecolor 8/16, palette 1/2/4/8, grayscale-alpha/RGBA 8/16 및 interlace 0/1을 허용한다(:206~218). multi-IDAT에 걸친 단일 zlib, Adler/종료, 정확한 scanline 종료를 요구한다. zlib 종료 뒤 미사용 압축 tail 허용(:243)은 과도한 inflate 출력 허용과 다르다(:292). 정상 multi-IDAT/Adam7와 기존 정상 PNG/alpha/8MiB 시험은 유지된다.
- **WebP guard:** :315~342의 RIFF/chunk/padding 경계 안에서만 VP8L signature/version과 첫 transform 필수 비트를 읽는다. 실제 5-byte header+0xff 한 바이트 손상 입력은 presence/type 뒤 필요한 palette 8bit 중 5bit만 남아 :352에서 거절된다. 일반 VP8/extended 형식을 일괄 거절하지 않고 새로운 input pixel cap도 없다. 보조이미지/Huffman 전체 strict decoder가 아니며 모든 손상 본문 탐지를 주장하지 않는다. 이 제한 자체를 재현 없는 신규 결함으로 승격하거나 full codec 구현을 요구하지 않는다.
- **시험 독립성:** 신규 integrity 입력은 시험 측 직접 byte/CRC/Adler builder와 리터럴 색 assertion을 사용하고 생산 encoder로 기대값을 생성하지 않는다. memory 시험 :46~56은 첫 processor 호출·고정 예산·출력 검증을 유지한다. sampler의 종료/취소 join 뒤 결과를 읽고 출력 색 판독은 측정 종료 후 수행한다. production 시험 전용 API/새 cache/provider 할당은 추가되지 않았다. 이전 시험 규약 지적 외 신규 Important는 확인하지 않았다.

### 직접 읽은 실행 증거와 한계

| 증거 | 직접 확인한 결과 |
|------|------------------|
| `t2-memory-platform-control.log:224~231` | 독립 thumbnail-only 1/1 PASS, sampled RSS 증가 **300,236,800 bytes**, 744 samples, errors=[] |
| `t2-memory-actual-red.log:158~166` | 수정 전 실제 assertion FAIL: **530,186,240 > 402,653,184 bytes**, 1072 samples, errors=[] |
| `t2-fix1-memory.log` 및 `t2-impl.md:87~91` | 구현자 fresh 측정 **365,592,576 ≤ 402,653,184 bytes**; 부모 별도 측정과 구분 |
| `t2-parent-fix1-memory.log:197~212` | 부모 fresh 1/1 PASS: **363,495,424 ≤ 402,653,184 bytes**, 541 samples, errors=[], TEST SUCCEEDED |
| `t2-parent-fix1-cumulative.log:90/103/157/481/5660/5672` | integrity 5/5, memory 3/3, processor 25/25 포함 unit **182/182**, 기존 T1 UI **2/2**, 합계 **184/184**, 실패 0, TEST SUCCEEDED |

384MiB는 actual RED 전에 고정한 특정 8192 WebP/환경의 회귀 예산이다. 독립 ImageIO 비용 약300MB는 플랫폼 관측값이며 전역 메모리 상한이 아니다. sampled peak는 관측 하한, kernel lifetime peak는 interval-reset 불가다. 누적 실행 memory 결과를 fresh 결과로 대체하지 않는다. 기존 process/stored 손상 시험 및 신규 손상 회귀 성공을 확인했지만 모든 형식의 모든 손상 탐지·실기기 메모리 안전·실제 PhotosPicker 완료로 확대하지 않는다.

## Part 2 판정

**QUALITY PASS** — Critical 0, Important 0, Minor 3(DEFER). I-1 CLOSED. 신규 재현 가능한 동작 결함은 확인하지 않았다. 재리뷰는 T2 R1의 승인이고 전체 기능 회고/완료 승인이 아니다.

```yaml
spec-review:
  verdict: PASS
  ac_total: 7
  ac_met: 7
  ac_partial: 0
  ac_unmet: 0
  unmet_ids: []
```

```yaml
quality-review:
  verdict: PASS
  critical: 0
  important: 0
  important_behavior: 0
  minor: 3
  closed_findings: [I-1]
  deferred_findings: [M-1, M-2, M-3]
```
