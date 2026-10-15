# T1 IMPLEMENT — xlsx 읽기

## 구현 내용
- scripts/route_data/__init__.py (빈 패키지)
- scripts/route_data/xlsx.py: Cell, Sheet, MissingColumnsError, require_columns, read_first_sheet. workbook 첫 sheet → rels 경로, sharedStrings(<si> 직속 <t> + <r> 안 <t>, rPh 제외), inlineStr, r 속성 열 위치, iterparse.

## GREEN 증거
- `python3 -m unittest discover -s scripts/tests -t scripts` → Ran 14 tests, OK (14 pass / 0 fail)
- 실데이터 확인: 서울시버스노선별정류소정보(20260902).xlsx 41,688행·헤더 8열·ARS '11486' 문자열, 1.0초. 노선기본정보 822행.

## REFACTOR 내역
- 정리 없음 (최소 구현 그대로)

## self-review 결과
- 완전성: 인터페이스 5개 모두 구현. 품질: 표준 라이브러리만. 규율: 테스트 미수정(hash 동일). 테스트: 14/14.

## 우려사항
없음
