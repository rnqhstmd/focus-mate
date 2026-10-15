import os
import tempfile
import unittest

from tests.xlsx_fixture import Bool, Inline, Num, Rich, write_xlsx

HEADER = ["ROUTE_ID", "노선명", "순번", "NODE_ID", "ARS_ID", "정류소명", "X좌표", "Y좌표"]


class XlsxReadTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.path = os.path.join(self._tmp.name, "t.xlsx")

    def read(self, rows, **kw):
        from route_data.xlsx import read_first_sheet
        write_xlsx(self.path, rows, **kw)
        return read_first_sheet(self.path)

    def test_header_and_row_values_by_column_name(self):
        """AC-57: 8개 열 헤더를 읽고 행 값을 열 이름으로 꺼낸다."""
        sheet = self.read([HEADER, [Num("100100001"), "1호선", Num("1"), Num("101000001"),
                                    "01234", "서울역", Num("126.97"), Num("37.55")]])
        self.assertEqual(sheet.header, HEADER)
        row = sheet.rows[0]
        self.assertEqual(row["노선명"].value, "1호선")
        self.assertEqual(row["정류소명"].value, "서울역")
        self.assertEqual(row["ROUTE_ID"].value, "100100001")

    def test_header_cells_are_trimmed(self):
        """헤더 앞뒤 공백은 제거된다."""
        sheet = self.read([[" ARS_ID ", "정류소명  "], ["1", "a"]])
        self.assertEqual(sheet.header, ["ARS_ID", "정류소명"])
        self.assertEqual(sheet.rows[0]["ARS_ID"].value, "1")

    def test_ars_id_string_keeps_leading_zero_and_is_text(self):
        """AC-64: 문자열 ARS_ID '00123','7832'는 그대로이고 is_text True."""
        sheet = self.read([["ARS_ID"], ["00123"], ["7832"]])
        self.assertEqual([r["ARS_ID"].value for r in sheet.rows], ["00123", "7832"])
        self.assertTrue(all(r["ARS_ID"].is_text for r in sheet.rows))

    def test_numeric_cell_is_not_text_and_keeps_raw_value(self):
        """숫자 셀은 is_text False, 값은 XML 원문."""
        sheet = self.read([["X좌표"], [Num("127.06447")]])
        cell = sheet.rows[0]["X좌표"]
        self.assertEqual(cell.value, "127.06447")
        self.assertFalse(cell.is_text)

    def test_numeric_scientific_notation_preserved_verbatim(self):
        """숫자 셀 '1.0E8'은 변환 없이 원문 보존."""
        sheet = self.read([["NODE_ID"], [Num("1.0E8")]])
        self.assertEqual(sheet.rows[0]["NODE_ID"].value, "1.0E8")

    def test_boolean_cell_is_zero_or_one_and_not_text(self):
        """불리언 셀은 '1'/'0', is_text False."""
        sheet = self.read([["flag"], [Bool(True)], [Bool(False)]])
        self.assertEqual([r["flag"].value for r in sheet.rows], ["1", "0"])
        self.assertFalse(any(r["flag"].is_text for r in sheet.rows))

    def test_rich_text_shared_string_runs_are_concatenated(self):
        """리치 텍스트 공유 문자열의 <r><t> 조각을 이어붙인다."""
        sheet = self.read([["정류소명"], [Rich(["서울", "역", " 앞"])]])
        cell = sheet.rows[0]["정류소명"]
        self.assertEqual(cell.value, "서울역 앞")
        self.assertTrue(cell.is_text)

    def test_phonetic_rph_text_is_excluded(self):
        """rPh(읽기 기호) 안의 t는 값에서 제외한다."""
        sheet = self.read([["정류소명"], [Rich(["서울", "역"], phonetic="ソウル")]])
        self.assertEqual(sheet.rows[0]["정류소명"].value, "서울역")

    def test_omitted_cell_does_not_shift_following_columns(self):
        """생략된 칸이 있어도 r 위치 기준으로 열이 정해지고 키가 없다."""
        sheet = self.read([["A", "B", "C"], ["a", None, "c"]])
        row = sheet.rows[0]
        self.assertNotIn("B", row)
        self.assertEqual(row["A"].value, "a")
        self.assertEqual(row["C"].value, "c")

    def test_inline_string_cell_is_text(self):
        """inlineStr 셀은 is_text True, <is><t> 값."""
        sheet = self.read([["노선명"], [Inline("종로01")]])
        cell = sheet.rows[0]["노선명"]
        self.assertEqual(cell.value, "종로01")
        self.assertTrue(cell.is_text)

    def test_first_sheet_is_resolved_via_workbook_rels(self):
        """첫 시트가 sheet2.xml로 매핑돼도 rels를 따라 그 시트를 읽는다."""
        sheet = self.read([["노선명"], ["진짜"]], sheet_file="sheet2.xml")
        self.assertEqual(sheet.header, ["노선명"])
        self.assertEqual(sheet.rows[0]["노선명"].value, "진짜")


class XlsxGuardTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.path = os.path.join(self._tmp.name, "t.xlsx")

    def test_압축_해제_크기가_한도를_넘으면_XlsxError(self):
        from route_data.xlsx import XlsxError, read_first_sheet
        write_xlsx(self.path, [["A"], ["x"]])
        with self.assertRaises(XlsxError):
            read_first_sheet(self.path, max_entry_bytes=10)

    def test_데이터_행이_max_rows를_넘으면_XlsxError(self):
        from route_data.xlsx import XlsxError, read_first_sheet
        write_xlsx(self.path, [["A"], ["x"], ["y"]])
        with self.assertRaises(XlsxError):
            read_first_sheet(self.path, max_rows=1)

    def test_데이터_행이_max_rows와_같으면_정상(self):
        from route_data.xlsx import read_first_sheet
        write_xlsx(self.path, [["A"], ["x"], ["y"]])
        sheet = read_first_sheet(self.path, max_rows=2)
        self.assertEqual([r["A"].value for r in sheet.rows], ["x", "y"])

    def test_시트_XML에_DOCTYPE이_있으면_XlsxError(self):
        from route_data.xlsx import XlsxError, read_first_sheet
        from tests.xlsx_fixture import write_xlsx_with_doctype
        write_xlsx_with_doctype(self.path, [["A"], ["x"]])
        with self.assertRaises(XlsxError):
            read_first_sheet(self.path)

    def test_공유_문자열_XML에_ENTITY가_있으면_XlsxError(self):
        from route_data.xlsx import XlsxError, read_first_sheet
        from tests.xlsx_fixture import write_xlsx_with_doctype
        write_xlsx_with_doctype(self.path, [["A"], ["x"]], entry="xl/sharedStrings.xml")
        with self.assertRaises(XlsxError):
            read_first_sheet(self.path)

    def test_공유_문자열_색인이_범위_밖이면_XlsxError(self):
        from route_data.xlsx import XlsxError, read_first_sheet
        from tests.xlsx_fixture import write_xlsx_with_bad_shared_index
        write_xlsx_with_bad_shared_index(self.path, ["A"])
        with self.assertRaises(XlsxError):
            read_first_sheet(self.path)

    def test_zip이_아닌_파일은_XlsxError(self):
        from route_data.xlsx import XlsxError, read_first_sheet
        with open(self.path, "wb") as f:
            f.write(b"not a zip")
        with self.assertRaises(XlsxError):
            read_first_sheet(self.path)


class XlsxHardeningTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.path = os.path.join(self._tmp.name, "t.xlsx")

    def assert_xlsx_error(self):
        from route_data.xlsx import XlsxError, read_first_sheet
        with self.assertRaises(XlsxError):
            read_first_sheet(self.path)

    def test_긴_주석_뒤의_DOCTYPE도_XlsxError(self):
        from tests.xlsx_fixture import write_xlsx_with_comment_then_doctype
        write_xlsx_with_comment_then_doctype(self.path, [["A"], ["x"]])
        self.assert_xlsx_error()

    def test_workbook_XML에_DOCTYPE이_있으면_XlsxError(self):
        from tests.xlsx_fixture import write_xlsx_with_doctype
        write_xlsx_with_doctype(self.path, [["A"], ["x"]], entry="xl/workbook.xml")
        self.assert_xlsx_error()

    def test_workbook_rels에_DOCTYPE이_있으면_XlsxError(self):
        from tests.xlsx_fixture import write_xlsx_with_doctype
        write_xlsx_with_doctype(self.path, [["A"], ["x"]], entry="xl/_rels/workbook.xml.rels")
        self.assert_xlsx_error()

    def test_UTF16_시트_XML은_XlsxError(self):
        from tests.xlsx_fixture import write_xlsx_utf16_sheet
        write_xlsx_utf16_sheet(self.path, [["A"], ["x"]])
        self.assert_xlsx_error()

    def test_손상된_deflate_데이터는_XlsxError(self):
        from tests.xlsx_fixture import write_xlsx_corrupt_deflate
        write_xlsx_corrupt_deflate(self.path, [["A"], ["x"]])
        self.assert_xlsx_error()

    def test_workbook_엔트리가_없으면_XlsxError(self):
        from tests.xlsx_fixture import write_xlsx_without_entry
        write_xlsx_without_entry(self.path, [["A"], ["x"]], "xl/workbook.xml")
        self.assert_xlsx_error()

    def test_시트_XML_문법_오류는_XlsxError(self):
        from tests.xlsx_fixture import write_xlsx_broken_sheet_xml
        write_xlsx_broken_sheet_xml(self.path, [["A"], ["x"]])
        self.assert_xlsx_error()

    def test_셀에_r_속성이_없으면_XlsxError(self):
        from tests.xlsx_fixture import write_xlsx_cell_without_r
        write_xlsx_cell_without_r(self.path, ["A"])
        self.assert_xlsx_error()


class RequireColumnsTest(unittest.TestCase):
    def sheet(self, header):
        from route_data.xlsx import Sheet
        return Sheet(header=header, rows=[])

    def test_missing_column_raises_with_name_listed(self):
        """AC-74: 'X좌표'가 빠지면 MissingColumnsError, missing 및 메시지에 포함."""
        from route_data.xlsx import MissingColumnsError, require_columns
        s = self.sheet([h for h in HEADER if h != "X좌표"])
        with self.assertRaises(MissingColumnsError) as cm:
            require_columns(s, HEADER)
        self.assertEqual(cm.exception.missing, ["X좌표"])
        self.assertIn("X좌표", str(cm.exception))

    def test_multiple_missing_columns_are_all_reported_in_names_order(self):
        """둘 이상 빠지면 names 순서대로 모두 담긴다."""
        from route_data.xlsx import MissingColumnsError, require_columns
        s = self.sheet(["ROUTE_ID", "순번"])
        with self.assertRaises(MissingColumnsError) as cm:
            require_columns(s, ["Y좌표", "ROUTE_ID", "ARS_ID", "순번"])
        self.assertEqual(cm.exception.missing, ["Y좌표", "ARS_ID"])
        self.assertIn("Y좌표", str(cm.exception))
        self.assertIn("ARS_ID", str(cm.exception))

    def test_all_columns_present_does_not_raise(self):
        """모두 있으면 예외 없이 None."""
        from route_data.xlsx import require_columns
        self.assertIsNone(require_columns(self.sheet(HEADER), HEADER))


if __name__ == "__main__":
    unittest.main()
