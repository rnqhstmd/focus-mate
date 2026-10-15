# t1-red 보고

## 실패 확인 명령
`python3 -m unittest discover -s scripts/tests -t scripts -v` → 14 tests, errors=14 (전부 ModuleNotFoundError: route_data)

## 케이스 (14)
- test_header_and_row_values_by_column_name
- test_header_cells_are_trimmed
- test_ars_id_string_keeps_leading_zero_and_is_text
- test_numeric_cell_is_not_text_and_keeps_raw_value
- test_numeric_scientific_notation_preserved_verbatim
- test_boolean_cell_is_zero_or_one_and_not_text
- test_rich_text_shared_string_runs_are_concatenated
- test_phonetic_rph_text_is_excluded
- test_omitted_cell_does_not_shift_following_columns
- test_inline_string_cell_is_text
- test_first_sheet_is_resolved_via_workbook_rels
- test_missing_column_raises_with_name_listed
- test_multiple_missing_columns_are_all_reported_in_names_order
- test_all_columns_present_does_not_raise

## 참조한 파일
없음 (프로덕션 코드 미참조, 신규 작성만)

## 테스트 코드 전문: scripts/tests/test_xlsx.py
```python
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
```

## 헬퍼: scripts/tests/xlsx_fixture.py (write_xlsx, Inline, Num, Bool, Rich)
```python
"""테스트용 최소 xlsx 생성 헬퍼 (zipfile만 사용)."""
import zipfile
from xml.sax.saxutils import escape


class Inline:
    def __init__(self, text):
        self.text = text


class Num:
    def __init__(self, raw):
        self.raw = raw


class Bool:
    def __init__(self, flag):
        self.flag = flag


class Rich:
    """리치 텍스트 공유 문자열. parts는 <r><t> 조각, phonetic은 <rPh><t> 읽기 기호."""

    def __init__(self, parts, phonetic=None):
        self.parts = parts
        self.phonetic = phonetic


def _col(i):
    s = ""
    i += 1
    while i:
        i, r = divmod(i - 1, 26)
        s = chr(65 + r) + s
    return s


def _t(text):
    return '<t xml:space="preserve">%s</t>' % escape(text)


def write_xlsx(path, rows, *, sheet_file="sheet1.xml"):
    """rows: 행 목록, 행은 셀 목록. str=공유 문자열, None=생략 칸,
    Inline/Num/Bool/Rich=해당 셀. sheet_file이 sheet1.xml이 아니면
    워크북 첫 시트를 그 파일로 매핑하고 sheet1.xml은 미끼 둘째 시트로 둔다."""
    shared = []
    sheet_rows = []
    for rn, row in enumerate(rows, start=1):
        cells = []
        for ci, c in enumerate(row):
            ref = "%s%d" % (_col(ci), rn)
            if c is None:
                continue
            if isinstance(c, str):
                shared.append("<si>%s</si>" % _t(c))
                cells.append('<c r="%s" t="s"><v>%d</v></c>' % (ref, len(shared) - 1))
            elif isinstance(c, Rich):
                body = "".join("<r>%s</r>" % _t(p) for p in c.parts)
                if c.phonetic is not None:
                    body += '<rPh sb="0" eb="1">%s</rPh>' % _t(c.phonetic)
                shared.append("<si>%s</si>" % body)
                cells.append('<c r="%s" t="s"><v>%d</v></c>' % (ref, len(shared) - 1))
            elif isinstance(c, Inline):
                cells.append('<c r="%s" t="inlineStr"><is>%s</is></c>' % (ref, _t(c.text)))
            elif isinstance(c, Num):
                cells.append('<c r="%s"><v>%s</v></c>' % (ref, c.raw))
            elif isinstance(c, Bool):
                cells.append('<c r="%s" t="b"><v>%d</v></c>' % (ref, 1 if c.flag else 0))
            else:
                raise TypeError(c)
        sheet_rows.append('<row r="%d">%s</row>' % (rn, "".join(cells)))
    ns = 'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
    sheet_xml = '<?xml version="1.0" encoding="UTF-8"?><worksheet %s><sheetData>%s</sheetData></worksheet>' % (
        ns, "".join(sheet_rows))
    decoy_xml = ('<?xml version="1.0" encoding="UTF-8"?><worksheet %s><sheetData>'
                 '<row r="1"><c r="A1" t="inlineStr"><is><t>DECOY</t></is></c></row>'
                 '</sheetData></worksheet>' % ns)
    sst = '<?xml version="1.0" encoding="UTF-8"?><sst %s count="%d" uniqueCount="%d">%s</sst>' % (
        ns, len(shared), len(shared), "".join(shared))
    rel = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    pkg = "http://schemas.openxmlformats.org/package/2006/relationships"
    decoy = sheet_file != "sheet1.xml"
    sheets = '<sheet name="Main" sheetId="1" r:id="rId2"/>' if decoy else '<sheet name="Main" sheetId="1" r:id="rId1"/>'
    rels = ""
    if decoy:
        sheets += '<sheet name="Decoy" sheetId="2" r:id="rId1"/>'
        rels += '<Relationship Id="rId1" Type="%s/worksheet" Target="worksheets/sheet1.xml"/>' % rel
        rels += '<Relationship Id="rId2" Type="%s/worksheet" Target="worksheets/%s"/>' % (rel, sheet_file)
    else:
        rels += '<Relationship Id="rId1" Type="%s/worksheet" Target="worksheets/sheet1.xml"/>' % rel
    rels += '<Relationship Id="rId9" Type="%s/sharedStrings" Target="sharedStrings.xml"/>' % rel
    workbook = ('<?xml version="1.0" encoding="UTF-8"?><workbook %s xmlns:r="%s"><sheets>%s</sheets></workbook>'
                % (ns, rel, sheets))
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml",
                   '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"/>')
        z.writestr("_rels/.rels",
                   '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="%s"><Relationship Id="rId1" Type="%s/officeDocument" Target="xl/workbook.xml"/></Relationships>' % (pkg, rel))
        z.writestr("xl/workbook.xml", workbook)
        z.writestr("xl/_rels/workbook.xml.rels",
                   '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="%s">%s</Relationships>' % (pkg, rels))
        z.writestr("xl/worksheets/" + sheet_file, sheet_xml)
        if decoy:
            z.writestr("xl/worksheets/sheet1.xml", decoy_xml)
        z.writestr("xl/sharedStrings.xml", sst)
```
