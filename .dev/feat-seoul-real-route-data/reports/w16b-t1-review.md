# W16b T1 태스크 리뷰 R0

## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 |
|----|-------|------|
| 1) source에 sourceURL·routeInfoSourceURL | ✅ | build_route_data.py SOURCE 두 키 추가. 테스트 `test_성공_산출의_source에_출처_URL_두_개가_있다`가 값까지 검증 |
| 2) XlsxError 변환 (zip 아님·파트 누락·XML 파싱 실패·r 누락·색인 범위 밖·한도 초과) | ✅ (테스트 공백 있음) | xlsx.py:55에서 BadZipFile, KeyError, ParseError, TypeError, AttributeError, IndexError를 변환한다. `r` 누락은 `_column_index(None)`이 TypeError를 내서 잡힌다. 테스트는 zip 아님·색인 범위 밖·한도 초과만 있고, 파트 누락·XML 파싱 실패·`r` 누락 테스트는 없다 |
| 3) 엔트리 크기 사전 거부, 행 한도, DOCTYPE/ENTITY 거부 | ⚠️ | 크기와 행 한도는 xlsx.py:48, 139에서 충족한다. DOCTYPE/ENTITY 거부는 우회할 수 있다(Important 1·2 참조) |
| 4) normalize_integer 15자리 초과 거부 | ✅ | routes.py:62에서 `adjusted() >= 15`를 int 변환 전에 검사한다. 15자리 통과, 16자리 거부, `1E999999999` 테스트가 있다 |
| 5) CLI: XlsxError·없는 파일 → 종료 2, Traceback 없음, out 미변경 | ⚠️ | XlsxError는 종료 2로 처리한다(build_route_data.py:185). 없는 파일은 OSError가 XlsxError로 바뀌어 통과한다. 하지만 손상된 압축 데이터는 `zlib.error`/`EOFError`가 잡히지 않아 Traceback이 난다(Important 3 참조) |
| 6) 실패 시 임시 파일 미잔존 (+SHA 선계산, fsync, 0644) | ✅ | `_replace_atomically`의 BaseException 정리 경로, input_hashes 선계산, fsync, chmod 0o644가 diff에 있다 |

[Must] 6건 중 4건 충족, 2건 부분. [Should]는 해당 없음.

## 설계 범위 이탈
diff에는 scripts 하위 파일만 있어 이탈이 없다. impl.md는 `ios/.../seoul-route-data.json` 재생성(1,693,124 bytes)을 보고했지만 diff에는 이 파일이 없다. 바이너리나 대용량이라 제외된 것으로 보이며, 검증하지 못했다(Minor 1).

## Part 1 판정
SPEC FAIL. AC-3과 AC-5가 부분 충족이다. 재구현 라운드에서 Important 1~3을 함께 처리해야 한다.

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (4건)
1. xlsx.py:129-131 — 시트 DOCTYPE 검사가 앞 4096바이트만 본다. 선언 앞에 4KB가 넘는 주석이나 공백 prolog를 두면 검사를 우회한다. 또 `b"<!DOCTYPE"` 바이트 매칭이라 UTF-16으로 인코딩된 XML도 통과한다. expat은 UTF-16을 처리하므로 AC-3 "DOCTYPE/ENTITY 거부"가 깨진다. → [동작결함] (재구현 대상 — AC-3)
   - 권고: 스트림 전체를 청크 단위로 검사한다. 또는 `XMLParser`의 `DefaultHandler`/`start_doctype_decl` 계열 훅이나 `iterparse(events=("start",))` 이전에 doctype 이벤트를 거부한다. 최소한 UTF-8/ASCII 이외 인코딩 선언은 거부한다.
2. xlsx.py:68, 73 — `xl/workbook.xml`과 `xl/_rels/workbook.xml.rels`는 `_safe_xml` 없이 `ET.fromstring`으로 파싱한다. 이 파트들은 DOCTYPE/ENTITY 거부 대상에서 빠져 있다. → [동작결함] (재구현 대상 — AC-3)
   - 권고: 읽는 모든 XML 파트를 한 헬퍼(read+검사)로 통일한다.
3. xlsx.py:55 — 예외 목록에 `zlib.error`(손상된 deflate 스트림), `EOFError`(잘린 스트림), `RuntimeError`(암호화 엔트리), `NotImplementedError`(미지원 압축), `zipfile.LargeZipFile`이 없다. 이런 입력이면 Traceback과 종료 코드 1이 되어 AC-5 "Traceback 없음"을 어긴다. → [동작결함] (재구현 대상 — AC-5)
   - 권고: 예외 목록에 추가하고, 손상 압축 데이터 케이스 테스트를 넣는다.
4. test_xlsx.py, test_build_route_data.py — AC-2가 명시한 파트 누락(workbook/rels 없음), XML 파싱 실패, `r` 속성 누락 테스트가 없다. 해당 변환 경로는 회귀 가드가 없다. → [동작불변]
   - 권고: 이 세 케이스와, 가능하면 workbook.xml DOCTYPE 케이스와 4KB 초과 prolog 케이스를 추가한다.

### Minor (6건)
1. impl.md가 보고한 번들 JSON 재생성은 diff에 없어 검증하지 못했다. 필요하면 오케스트레이터가 SHA와 크기를 확인한다.
2. xlsx.py:55 — `ValueError`, `TypeError`, `AttributeError`, `IndexError`를 넓게 잡아서 `_cell`이나 `_sheet_rows`의 프로그래밍 버그도 "xlsx를 읽을 수 없음"으로 가려질 수 있다. `r` 누락 검사를 명시적으로 하고 예외를 좁히는 편이 낫다. `RecursionError`와 `MemoryError`는 잡히지 않는다.
3. test_routes.py — `time.monotonic() < 1.0` 단언은 느린 CI에서 불안정할 수 있다. `1E999999999`에 ValueError가 나는 것만 확인해도 충분하다. [검증 필요] 이 테스트가 부하 상황에서 안정적인지.
4. 테스트 함수 안에서 import를 반복한다(test_routes, test_xlsx). 모듈 상단으로 올리는 편이 낫다. test_routes.py:255 앞에 빈 줄이 3개다.
5. build_route_data.py:95 — 입력 SHA를 파싱과 별도로 `read_bytes()` 한다. 두 읽기 사이에 파일이 바뀌면 SHA와 파싱 내용이 어긋난다. 파싱한 바이트 기준으로 계산하거나 한 번만 읽는 것이 안전하다. 또 `os.replace` 후 디렉터리 fsync는 없다.
6. routes.py:62 — `MAX_INTEGER_DIGITS`와 `adjusted() >= 15` 조합이 "15자리까지 허용"이라는 의미를 바로 드러내지 않는다. `adjusted() > MAX_INTEGER_DIGITS - 1`처럼 쓰거나 주석을 추가하면 읽기 쉽다.

## Part 2 판정
QUALITY FAIL. Important이 4건이고, 그중 3건이 동작결함이다.

```yaml
spec_verdict:
  verdict: FAIL
  ac_total: 6
  ac_met: 4
  ac_partial: 2
  ac_unmet: 0
  unmet_ids: [AC-3, AC-5]
```

```yaml
quality_verdict:
  verdict: FAIL
  critical: 0
  important: 4
  important_behavior: 3
  minor: 6
```