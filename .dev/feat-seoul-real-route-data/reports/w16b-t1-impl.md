# W16b T1 IMPLEMENT — 스크립트 보안 보강·출처 URL·번들 배치

## 구현 내용
- xlsx.py: XlsxError, read_first_sheet(max_entry_bytes, max_rows), 엔트리 압축 해제 크기 사전 검사, DOCTYPE/ENTITY 거부(sharedStrings 전체·시트 앞 4KB), 손상·누락·색인 오류를 XlsxError로 변환(OSError 포함).
- routes.py: normalize_integer 15자리 초과(adjusted ≥ 15) 거부 → 지수 표기 거대 정수 DoS 차단.
- build_route_data.py: source에 sourceURL·routeInfoSourceURL, XlsxError → 종료 2, 입력 SHA를 출력 교체 전에 계산, 임시 파일 flush+fsync+0644.
- ios/FocusMate/Resources/RouteData/seoul-route-data.json: 실데이터 재생성(1,693,124 bytes, SHA c5c88056…).

## GREEN 증거
- `python3 -m unittest discover -s scripts/tests -t scripts` → Ran 108, OK

## REFACTOR 내역
- 정리 없음

## 우려사항
없음

## Fix R1 (리뷰 Important 동작결함 3)
- xlsx._read_xml: 모든 XML 파트(workbook, rels, sharedStrings, 시트)를 전체 읽어 UTF-8 검사 + DOCTYPE/ENTITY 거부. 시트는 BytesIO로 iterparse.
- 예외 변환에 zlib.error, EOFError, RuntimeError, NotImplementedError, LargeZipFile 추가.
- GREEN: python 전체 OK. 실데이터 41,688행 1.0초.
