# w16b-t1 RED
테스트: scripts/tests/test_build_route_data.py(InputGuardCliTest), test_xlsx.py(XlsxGuardTest), test_routes.py(NormalizeIntegerDigitLimitTest), 헬퍼 추가 xlsx_fixture.py(_rewrite_entry, write_xlsx_with_doctype, write_xlsx_with_bad_shared_index)
실행: cd scripts && python3 -m unittest discover -s tests -t . -k <클래스들> (1E999999999 케이스 제외)
결과: 47건 중 FAIL 3 / ERROR 8 (XlsxError ImportError, source URL KeyError, 16자리 미거부 등). 기존 케이스 통과.
우려: 1E999999999 케이스는 현 구현에서 int 변환이 사실상 멈춤(120초 초과 hang) -> RED 확인은 hang. 존재하지 않는 경로 종료2, 종료4 임시파일 케이스, 15자리 케이스는 현 구현에서 이미 통과(회귀 가드).

## 재현 RED R1
추가: test_xlsx.py XlsxHardeningTest 8건, test_build_route_data.py InputGuardCliTest 손상 deflate 1건, 헬퍼 추가(write_xlsx_with_comment_then_doctype, write_xlsx_utf16_sheet, write_xlsx_corrupt_deflate, write_xlsx_without_entry, write_xlsx_broken_sheet_xml, write_xlsx_cell_without_r, _rewrite_entry_bytes).
실행: cd scripts && python3 -m unittest discover -s tests -t . -k XlsxHardening -k InputGuard
- 실패(RED, 6건): 긴 주석 뒤 DOCTYPE, workbook.xml DOCTYPE, workbook.xml.rels DOCTYPE, UTF-16 시트(FAIL, XlsxError 아님), 손상 deflate xlsx.py 쪽(ERROR, zlib/BadZipFile 누출), 손상 deflate CLI(종료 2 아님/Traceback).
- 이미 통과(회귀 가드, 3건): workbook.xml 엔트리 없음, 시트 XML 문법 오류, 셀 r 속성 없음 -> 모두 현재 XlsxError.
