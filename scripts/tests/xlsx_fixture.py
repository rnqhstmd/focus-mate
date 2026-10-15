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
