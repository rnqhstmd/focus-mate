## Trust Ledger

### 위험 수용
- [기준선 전체 테스트 생략] 사용자 상시 지시(작업 중 focused만, 전체는 마지막 1회)로 Step 0.5 전체 iOS 테스트를 실행하지 않음. 빌드·경고 기준선(5)만 측정 (implement/Step 0.5)

## 통합 감사 (review)

감사 범위는 W16 1~11단계의 Python 변환 스크립트와 Swift 계산 모듈입니다. 파일을 직접 읽어 확인했고 코드는 실행하지 않았습니다.

설계서는 앞 522줄까지만 읽었습니다. J절 뒤쪽(테스트·AC 표 등)은 미확인입니다. 설계서에 쓰인 `StationOption`·`RouteCandidate`와 코드의 `StopSearchOption`·`RouteCandidate`는 이름이 다르지만 이번 감사 대상이 아니므로 다루지 않았습니다.

### 발견 사항

- [GAP/MEDIUM] xlsx 압축 해제 크기와 XML 크기에 상한이 없음 (zip bomb·거대 XML)
  - 위치: `scripts/route_data/xlsx.py:39-41, 77-81, 105-114`
  - 근거:
    - `ZipInfo.file_size`나 압축비를 검사하지 않습니다.
    - `sharedStrings.xml`은 `archive.read`로 통째로 올린 뒤 `ET.fromstring`에 넘깁니다.
    - 시트는 `iterparse`로 읽지만 `rows`에 전부 쌓습니다. 크기 상한도 행 수 상한도 없습니다.
    - 테스트에도 악성 입력 케이스(DOCTYPE, 고압축 엔트리)가 없습니다. `scripts/tests`에서 DOCTYPE·ENTITY를 검색했을 때 결과는 0건이었습니다.
    - 입력은 사용자가 공식 사이트에서 직접 내려받는 파일이라 위협은 로컬 DoS(메모리·시간 소진)로 제한됩니다.
  - 권고:
    - 엔트리별 `file_size` 상한(예: 시트 500MB, sharedStrings 100MB)과 압축비 상한을 둡니다.
    - 행 수 상한(예: 200만 행)을 둡니다.
    - 초과 시 `InputError`(종료 코드 2)로 끝냅니다.

- [GAP/MEDIUM] XML 엔티티(DOCTYPE/ENTITY) 선언을 차단하지 않음
  - 위치: `xlsx.py:53, 58, 80`
  - 근거:
    - `xml.etree`(expat)는 기본적으로 외부 엔티티를 해석하지 않으므로 XXE 파일 읽기는 확인된 위험이 아닙니다.
    - 그러나 내부 엔티티 중첩 확장(billion laughs)은 expat 버전에 달려 있습니다. 2.4.1 이상은 증폭 방어가 있지만, 사용자 환경의 Python·expat 버전은 미확인입니다.
    - 정상 xlsx에는 DOCTYPE이 없으므로 차단해도 정상 입력에 영향이 없습니다.
  - 권고: 파싱 전에 바이트에서 `<!DOCTYPE`과 `<!ENTITY`를 찾아 거부합니다. `defusedxml`은 표준 라이브러리가 아니므로 이 방식이 맞습니다.

- [GAP/MEDIUM] 지수 표기 정수(`1E999999999`)가 CPU·메모리 DoS가 됨
  - 위치: `scripts/route_data/routes.py:55-62` (`normalize_integer`)
  - 근거:
    - `Decimal("1E999999999")`는 유한하고 정수값이라 검사를 통과합니다.
    - 그 뒤 `int(number)`가 10^999999999를 실제로 만들어 수백 MB와 긴 시간을 쓸 수 있습니다.
    - `ValueError`로 잡히는 지점은 `format` 이후입니다. int 문자열 변환 한도(Python 3.11+)가 막아 주더라도 `int()` 생성 비용은 이미 치른 뒤입니다.
    - 대상은 ROUTE_ID, NODE_ID, 순번, ARS 숫자 셀입니다.
  - 권고: `number.adjusted()`(자릿수)를 검사해서, 예를 들어 15 초과면 `int()` 전에 `ValueError`로 거절합니다.

- [GAP/MEDIUM] 오류 처리가 설계(종료 코드 2)와 다르게 traceback으로 종료됨
  - 위치: `xlsx.py:38-63, 99, 111`, `build_route_data.py:159-167`
  - 근거: `main`은 `InputError`와 `MissingColumnsError`만 잡습니다. 아래 예외는 잡히지 않아 종료 코드 1과 traceback으로 끝납니다.
    - `BadZipFile`
    - `KeyError`(workbook.xml 또는 시트 경로 없음)
    - `ET.ParseError`
    - `ValueError("시트가 없습니다")`
    - `IndexError`(sharedStrings 색인 범위 초과, 99행)
    - `AttributeError`(셀 `r` 속성 없음, 85행)
    - `TypeError`(행 `r` 속성 없음, 112행)
    - 출력 파일은 파싱 단계에서 실패하므로 건드리지 않습니다. AC-49의 기존 산출물 보존은 이 경로에서 성립합니다.
  - 권고: `read_first_sheet`에서 위 예외들을 `InputError`로 변환합니다.

- [RISK/MEDIUM] 출력 교체 이후 단계에서 실패할 수 있고, 임시 파일이 앱 번들에 섞일 위험이 있음
  - 위치: `build_route_data.py:90, 110-112, 134-144`
  - 근거:
    - `_replace_atomically`(90행)가 끝난 뒤에야 입력 xlsx를 다시 `read_bytes`해서 SHA를 계산합니다(110-111행). 여기서 실패하면 종료 코드는 실패인데 산출물은 이미 교체된 상태입니다.
    - 설계는 "어느 단계에서 실패해도 기존 산출물은 그대로"라고 했으므로 이 부분은 설계와 다릅니다. 산출물 자체는 완전한 새 파일이어서 손상은 아닙니다.
    - `mkstemp`가 만든 `.seoul-route-data.json.XXXX` 임시 파일은 SIGKILL이나 정전 때 남습니다. 설계 A절에 따르면 `Resources/RouteData/`는 동기화 폴더라서 그 안의 비소스 파일은 앱에 포함됩니다. `--out`을 번들 위치로 직접 주면 숨김 임시 파일이 번들에 들어갈 수 있습니다.
    - README는 `--out scripts/data/out/`(gitignore 대상)를 안내하므로 기본 절차에서는 발생하지 않습니다.
    - `fsync` 없이 `os.replace`하므로 전원 손실 시 빈 파일이 남을 수 있습니다. 재생성이 가능해서 영향은 작습니다.
    - 권한은 `mkstemp` 때문에 0600입니다. 공개 데이터이고 git이 권한을 추적하지 않으므로 보안 영향은 없습니다.
  - 권고:
    - SHA 계산을 교체 전에 끝냅니다(수치는 메모리에서 계산 가능합니다).
    - `--out`이 `Resources/` 아래이면 경고하거나 거부합니다.
    - 쓰기 직전에 `flush`와 `fsync`를 합니다.

- [GAP/MEDIUM] 원천 xlsx 커밋 방지 장치가 없음 (AC-76)
  - 위치: `/Users/bonseung/projects/focus-mate/next-step-w16/.gitignore`
  - 근거:
    - `.gitignore`에는 `scripts/data/out/`만 있습니다. `*.xlsx`가 없습니다.
    - README는 사용자가 파일을 "내려받아" 쓰게 합니다. 작업 폴더나 저장소 루트에 두면 `git add .`로 올라갈 수 있습니다.
    - 현재 저장소에는 xlsx가 없음을 Glob으로 확인했습니다. 지금은 안전하지만 방지는 사람 주의에만 의존합니다.
  - 권고: `.gitignore`에 `*.xlsx`를 추가하고, README에 "저장소 밖 폴더에 두라"고 명시합니다.

- [GAP/MEDIUM] 로더와 카탈로그가 값의 상한과 범위를 검증하지 않아 정수 오버플로로 크래시할 수 있음
  - 위치: `RouteCatalog.swift:92-94`, `RouteLeg.swift:29, 54-55`, `RouteCatalogLoader.swift:20-25, 29-31`
  - 확인된 방어:
    - 음수·범위 밖 정류장 색인: `allSatisfy(stops.indices.contains)`로 거부됩니다.
    - 배열 길이 불일치, 정류장 2개 미만, 구간 1초 미만: 거부됩니다.
    - 모르는 정류장 id: `unknownStop`으로 거부됩니다.
    - NaN: JSON 문법상 불가능하고 `JSONSerialization`도 거부합니다.
    - 중복 id: `Dictionary(uniquingKeysWith:)`를 써서 trap이 나지 않습니다.
  - 미방어(근거):
    - `seconds`와 `meters`에 상한이 없습니다. `Int.max`에 가까운 값이면 `elapsed +=`(29행)나 `2 * $0 * target`(54행)에서 오버플로 trap이 납니다. `distanceMeters`의 `reduce(0,+)`도 같습니다.
    - 음수 `meters`는 통과합니다. 그러면 `distanceText`가 음수 km 문자열을 만듭니다.
    - 위도·경도 범위를 검사하지 않습니다. `Int.max / 1e6` 같은 값은 유한하지만 지도 단계(W16b)에서 잘못된 좌표로 이어질 수 있습니다.
    - `leg()`는 `minutes`가 매우 크면 `target`에 비례해 반복합니다(저장 여정 재계산 경로, 설계 F절). 입력 범위 가드가 없습니다.
    - 스크립트 쪽 상한도 없습니다. `routes.py:180-185`는 `run_minutes`에 상한이 없습니다. `segments.py:36-37`은 loop 거리 합이 0이면 `uses_run_minutes`가 무조건 참이라, 거대한 운행시간이 그대로 구간 초로 나옵니다.
    - 번들은 코드 서명으로 보호되므로 런타임 변조는 위협이 아닙니다. 실제 경로는 "원천 데이터 이상값 → 스크립트 → 번들 → 크래시"입니다.
  - 권고:
    - 로더에서 `seconds` 1…86400, `meters` 0…상한, 위도 33~39·경도 124~130(스크립트와 동일 범위)을 검사해 `RouteCatalogIssue`로 거부합니다.
    - 스크립트에서도 같은 검사를 하고, `run_minutes` 상한(예: 24시간)과 좌표 동일 노선 처리를 추가합니다.
    - `leg()`에 `minutes` 상한 가드를 둡니다.

- [GAP/MEDIUM] 로더가 설계서에 적힌 무결성 검사 일부를 하지 않음
  - 위치: `RouteCatalogLoader.swift:14-15`, `RouteCatalog.swift:109-110`
  - 근거:
    - 중복 정류장 id와 중복 노선 id를 조용히 첫 항목으로 합칩니다(거부하지 않음). 노선 id가 중복되면 후보 `id`(=노선 id)가 충돌합니다.
    - 스크립트 쪽에서도 같은 위험이 생깁니다. `ROUTE_ID`를 원문 문자열로 그룹핑(`routes.py:83`)한 뒤 정규화하므로, 서로 다른 원문(`"1"`과 `"1.0"`)이 같은 정규화 id가 될 수 있습니다.
  - 권고: 로더에서 중복 id를 `malformed`로 거부합니다. 스크립트에서는 정규화 id로 그룹핑합니다.

- [POLICY/MEDIUM] 공공누리 제1유형 출처 표시 의무의 충족 시점이 이번 범위에서 보장되지 않음
  - 위치: `build_route_data.py:28-36, 81`, `scripts/data/README.md:14`, 설계서 H절
  - 근거:
    - 출처표시 화면(`DataSourceView`)은 W16b 범위입니다. 이번 범위의 산출물(JSON `source`)에는 provider, copyright, license, datasetID, baseDate는 있습니다.
    - 반면 원천 URL, "가공해서 이용했다"는 변경 사실 문구, 원문 파일 형식의 출처 문구는 `source`에 없습니다. 설계서 H절은 "구간 시간은 앱이 계산한 값"이라는 안내를 계획했고, 이번 범위 코드에는 없습니다.
    - 위험은 W16b 이전에 JSON이 `Resources/RouteData/`에 들어가 릴리스 빌드에 포함되는 경우입니다. 현재 `Resources/**/*.json`은 0건이라 아직 포함되지 않았습니다. 이 상태가 유지되는 한 의무 위반은 아닙니다.
  - 권고:
    - W16b가 끝나기 전에는 JSON을 번들에 넣지 않는다는 규칙을 문서화합니다.
    - 출처 문구에 "서울특별시 ○○를 이용하여 가공·계산함"을 포함하고, 원천 URL을 `source`에 추가하는 것을 W16b 설계 항목으로 확정합니다.

- [ASSUMPTION/MEDIUM] 라이선스 문구를 하드코딩하고 있어 원천 라이선스 변경이나 오기재를 감지하지 못함
  - 위치: `build_route_data.py:28-36`
  - 근거:
    - OA-1095와 OA-15066이 공공누리 제1유형이라는 점은 사용자가 준 설계서와 README의 주장입니다. 네트워크 접근이 없어 이번 감사에서 확인하지 못했습니다(미확인).
    - 스크립트는 원천 파일과 무관하게 항상 "공공누리 제1유형"을 JSON에 찍습니다. 데이터셋 라이선스가 바뀌면 거짓 출처 표기가 나갑니다.
  - 권고:
    - 두 데이터셋 페이지에서 저작권 유형을 직접 확인하고 확인일을 기록합니다.
    - README 갱신 절차에 "내려받을 때 라이선스 유형 재확인" 단계를 추가합니다.

- [GAP/MEDIUM] 설계와 구현의 정규화 불일치
  - 위치: `routes.py:169-177` 외
  - 근거:
    - 설계는 숫자 셀 `노선번호`를 `Decimal`로 정규화한 뒤 결합하게 했습니다. 코드는 원문(`_text`)으로 결합합니다. 숫자 셀 `1.0E2` 같은 표기는 결합에 실패합니다. 이 경우 노선이 조용히 "기본정보에 없는 노선"으로 빠집니다. 95% 결합률 게이트가 일부를 막아 주지만 5% 미만의 소실은 통과합니다.
    - 설계는 "(가상)이 들어간" 지점 제거, 코드와 README는 "(가상)으로 끝나는" 지점 제거입니다(`routes.py:128`). 이름 중간에 (가상)이 있으면 가상 지점이 남습니다.
    - 설계가 요구한 ARS 요약 통계(숫자 셀 수, 0 채움 수, 번호 없음 수)는 출력되지 않고 이상 건수만 나옵니다.
  - 권고: 의도를 확정해서 코드나 설계 중 한쪽을 맞춥니다.

### 교차 검증 결과

- [정합] 외부 의존성 없음 — `scripts/route_data/*.py`는 모두 표준 라이브러리만 import합니다(Python 3.10+ 문법 `str | None`은 README에 최소 버전 미명시).
- [정합] 출력 크기 상한 검사가 교체 전에 수행됨 — `build_route_data.py:88-89`
- [정합] 임시 파일 후 `os.replace` — `build_route_data.py:134-144`. 실패 시 임시 파일은 `BaseException`에서 정리됩니다(SIGKILL은 제외).
- [정합] 경로 처리 — xlsx는 파일로 추출하지 않고 `archive.open/read`만 쓰므로 zip slip과 경로 탐색은 해당되지 않습니다(`xlsx.py:62`의 normpath 결과는 아카이브 조회 키로만 사용).
- [정합] 외부 엔티티(XXE 파일 읽기) — `xml.etree` 기본 동작으로 외부 엔티티를 해석하지 않습니다. 위 [XML 엔티티] 항목은 확장 증폭만 다룹니다.
- [정합] 좌표 범위 검사와 노선 제외 — `routes.py:162-164` (BR-11)
- [정합] 민감정보 — 스크립트·테스트·config에서 `/Users/`, `bonseung`, `sqisoft`, key/secret/token 검색 결과 0건. `.claude/config.json`의 `webhookUrl`은 빈 문자열입니다. 데이터는 공개 정류장·노선 정보만 담고 개인정보는 없습니다.
- [정합] 산출물 비커밋 — `.gitignore:22`가 `scripts/data/out/`를 제외합니다(`scripts/data/out/seoul-route-data.json`이 로컬에 존재). 번들 위치에 JSON은 아직 없습니다.
- [불일치] AC-76(원천 xlsx 비커밋) — 위 `.gitignore` 항목 참조. 현재는 xlsx가 없어 충족하지만 방지 장치는 없습니다.
- [불일치] 설계 "정수 오류는 ID 오류로 노선 제외, 필수 열 누락은 종료 코드 2" — 정수 오류는 구현됐지만, 파일 자체가 손상된 경우의 종료 코드는 위 [오류 처리] 항목처럼 설계와 다릅니다.
- [불일치] 설계 "어느 단계에서 실패해도 기존 산출물 유지" — 위 [교체 이후 단계 실패] 항목 참조.
- [불일치] 설계 A절의 로더 오류 조건 — 로더는 id 중복을 검사하지 않고, 구간 1초 미만 검사는 `RouteCatalog.init`에 있습니다(동작은 일치).

### 확인이 필요한 사항

1. 두 데이터셋(OA-1095, OA-15066)의 현재 저작권 유형이 공공누리 제1유형인지 확인한 사람과 시점은 언제입니까?
   - 맥락: 스크립트가 이 문구를 하드코딩해서 JSON에 찍습니다. 이번 감사는 네트워크 없이 진행해 확인하지 못했습니다.
   - 유형: 선택
   - 선택지:
     - (a) 사용자가 직접 확인해 확인일을 README에 기록 (권장)
     - (b) 이미 확인했으므로 근거 링크만 기록
     - (c) 직접 입력 — 위 선택지 외 다른 의견을 직접 입력합니다

2. 로더의 값 범위 검증(구간 초·미터 상한, 좌표 범위, id 중복)과 스크립트의 입력 크기 상한(zip·행 수·DOCTYPE)을 이번 W16 범위에서 보강하겠습니까?
   - 맥락: 현재 코드는 정상 입력에서 동작하지만, 오염된 원천이나 번들에서 크래시·DoS 방어가 부족합니다.
   - 유형: 선택
   - 선택지:
     - (a) 이번 범위에서 보강 (권장) — 앱 화면 연결(W16b) 전에 로더가 안전해야 합니다
     - (b) W16b로 이월하되 이월 사실을 설계서에 기록
     - (c) 직접 입력 — 위 선택지 외 다른 의견을 직접 입력합니다

### 감사 요약
- 총 11건 (CRITICAL: 0, HIGH: 0, MEDIUM: 11)
- 조치 필요. 배포를 막을 수준의 항목은 없습니다. 다만 W16b로 앱에 연결하기 전에 로더 값 검증, 출처 표시, 라이선스 확인은 닫아야 합니다.

```yaml
security_verdict:
  critical: 0
  high: 0
  medium: 11
```

### 관련 파일
- `/Users/bonseung/projects/focus-mate/next-step-w16/scripts/route_data/xlsx.py`
- `/Users/bonseung/projects/focus-mate/next-step-w16/scripts/route_data/routes.py`
- `/Users/bonseung/projects/focus-mate/next-step-w16/scripts/route_data/segments.py`
- `/Users/bonseung/projects/focus-mate/next-step-w16/scripts/build_route_data.py`
- `/Users/bonseung/projects/focus-mate/next-step-w16/ios/FocusMate/RouteCatalogLoader.swift`
- `/Users/bonseung/projects/focus-mate/next-step-w16/ios/FocusMate/RouteCatalog.swift`
- `/Users/bonseung/projects/focus-mate/next-step-w16/ios/FocusMate/RouteLeg.swift`
- `/Users/bonseung/projects/focus-mate/next-step-w16/.gitignore`
- `/Users/bonseung/projects/focus-mate/next-step-w16/scripts/data/README.md`

### 통합 리뷰 (reviewer)
- 1회차: SPEC FAIL(AC-77 부분) · Important 3 [동작결함](요약 집계 누락) → 재현 RED R1 후 수정
- 2회차: SPEC PASS 47/47 · Important 2 [동작불변] → 정리 완료 · Minor 4 유예
- security: CRITICAL 0 · HIGH 0 · MEDIUM 11 (2 정리, 9 유예 — reports/review-deferred.md)
