"""Minimal standard-library xlsx reader for the Seoul bus source files."""
from dataclasses import dataclass
import posixpath
import re
import xml.etree.ElementTree as ET
import zipfile

_MAIN = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
_REL = "{http://schemas.openxmlformats.org/package/2006/relationships}"
_DOC_REL = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"
_TEXT_TYPES = {"s", "inlineStr", "str"}


@dataclass(frozen=True)
class Cell:
    value: str
    is_text: bool


@dataclass(frozen=True)
class Sheet:
    header: list
    rows: list


class MissingColumnsError(Exception):
    def __init__(self, missing):
        self.missing = list(missing)
        super().__init__("필수 열이 없습니다: " + ", ".join(self.missing))


def require_columns(sheet, names):
    missing = [name for name in names if name not in sheet.header]
    if missing:
        raise MissingColumnsError(missing)


def read_first_sheet(path):
    with zipfile.ZipFile(path) as archive:
        shared = _shared_strings(archive)
        grid = _sheet_rows(archive, _first_sheet_path(archive), shared)
    if not grid:
        return Sheet(header=[], rows=[])
    header_row = grid[0][1]
    columns = sorted(header_row)
    header = [header_row[col].value.strip() for col in columns]
    names = {col: header_row[col].value.strip() for col in columns}
    rows = [{names[col]: cell for col, cell in cells.items() if col in names} for _, cells in grid[1:]]
    return Sheet(header=header, rows=rows)


def _first_sheet_path(archive):
    workbook = ET.fromstring(archive.read("xl/workbook.xml"))
    sheet = workbook.find(f"{_MAIN}sheets/{_MAIN}sheet")
    if sheet is None:
        raise ValueError("시트가 없습니다")
    rel_id = sheet.get(f"{_DOC_REL}id")
    rels = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
    for rel in rels.iter(f"{_REL}Relationship"):
        if rel.get("Id") == rel_id:
            target = rel.get("Target")
            return target.lstrip("/") if target.startswith("/") else posixpath.normpath(posixpath.join("xl", target))
    raise ValueError("첫 시트 경로를 찾을 수 없습니다")


def _text(node):
    """Joins every <t> under the node except phonetic runs (<rPh>)."""
    parts = []
    for child in node:
        if child.tag == f"{_MAIN}t":
            parts.append(child.text or "")
        elif child.tag == f"{_MAIN}r":
            parts.extend(t.text or "" for t in child.iter(f"{_MAIN}t"))
    return "".join(parts)


def _shared_strings(archive):
    if "xl/sharedStrings.xml" not in archive.namelist():
        return []
    root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
    return [_text(si) for si in root.iter(f"{_MAIN}si")]


def _column_index(reference):
    letters = re.match(r"[A-Z]+", reference).group()
    index = 0
    for letter in letters:
        index = index * 26 + ord(letter) - ord("A") + 1
    return index


def _cell(element, shared):
    kind = element.get("t", "n")
    value = element.find(f"{_MAIN}v")
    if kind == "inlineStr":
        inline = element.find(f"{_MAIN}is")
        text = _text(inline) if inline is not None else ""
    elif kind == "s":
        text = shared[int(value.text)] if value is not None else ""
    else:
        text = value.text or "" if value is not None else ""
    return Cell(value=text, is_text=kind in _TEXT_TYPES)


def _sheet_rows(archive, sheet_path, shared):
    rows = []
    with archive.open(sheet_path) as stream:
        for _, element in ET.iterparse(stream):
            if element.tag != f"{_MAIN}row":
                continue
            cells = {_column_index(c.get("r")): _cell(c, shared) for c in element.iter(f"{_MAIN}c")}
            rows.append((int(element.get("r")), cells))
            element.clear()
    return rows
