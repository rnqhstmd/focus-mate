import unittest
from decimal import Decimal
from fractions import Fraction

from route_data.xlsx import Cell, Sheet

STOP_HEADER = ["ROUTE_ID", "노선명", "순번", "NODE_ID", "ARS_ID", "정류소명", "X좌표", "Y좌표"]
INFO_HEADER = ["노선번호", "유형", "운행시간"]


def srow(rid, number, seq, node, name, ars=None, x="127.0", y="37.5"):
    """정류소정보 한 행. x/y가 None이면 칸 생략(빈 좌표)."""
    row = {
        "ROUTE_ID": Cell(str(rid), False),
        "노선명": Cell(number, True),
        "순번": Cell(str(seq), False),
        "NODE_ID": Cell(str(node), False),
        "정류소명": Cell(name, True),
    }
    if ars is not None:
        row["ARS_ID"] = ars
    if x is not None:
        row["X좌표"] = Cell(x, False)
    if y is not None:
        row["Y좌표"] = Cell(y, False)
    return row


def irow(number, kind, run=None):
    row = {"노선번호": Cell(number, True)}
    if kind is not None:
        row["유형"] = Cell(kind, True)
    if run is not None:
        row["운행시간"] = Cell(run, False)
    return row


def stops_sheet(rows):
    return Sheet(header=list(STOP_HEADER), rows=rows)


def info_sheet(rows):
    return Sheet(header=list(INFO_HEADER), rows=rows)


def simple_route(rid, number, nodes=("1", "2")):
    return [srow(rid, number, i + 1, n, "정류장" + str(n)) for i, n in enumerate(nodes)]


class NormalizeIntegerTest(unittest.TestCase):
    def test_정수_문자열은_그대로_반환한다(self):
        from route_data.routes import normalize_integer
        self.assertEqual(normalize_integer("100100026"), "100100026")

    def test_지수_표기는_정수_문자열로_바꾼다(self):
        from route_data.routes import normalize_integer
        self.assertEqual(normalize_integer("1.0E8"), "100000000")

    def test_소수부가_0인_값은_정수_문자열로_바꾼다(self):
        from route_data.routes import normalize_integer
        self.assertEqual(normalize_integer("12.0"), "12")

    def test_정수가_아니면_ValueError를_낸다(self):
        from route_data.routes import normalize_integer
        for bad in ("12.5", "", "abc"):
            with self.subTest(bad=bad):
                with self.assertRaises(ValueError):
                    normalize_integer(bad)


class NormalizeArsTest(unittest.TestCase):
    def test_문자열_셀의_앞자리_0을_보존한다(self):
        from route_data.routes import normalize_ars
        self.assertEqual(normalize_ars(Cell("00123", True)), "00123")

    def test_문자열_셀은_5자리가_아니어도_그대로_둔다(self):
        from route_data.routes import normalize_ars
        self.assertEqual(normalize_ars(Cell(" 7832 ", True)), "7832")

    def test_숫자_셀은_5자리로_앞을_0으로_채운다(self):
        from route_data.routes import normalize_ars
        self.assertEqual(normalize_ars(Cell("1234", False)), "01234")

    def test_빈_값_물결_전부_0_None은_None이다(self):
        from route_data.routes import normalize_ars
        for cell in (Cell("", True), Cell("~", True), Cell("00000", True),
                     Cell("0", False), None):
            with self.subTest(cell=cell):
                self.assertIsNone(normalize_ars(cell))


class BuildRoutesTest(unittest.TestCase):
    def build(self, stops, info, **kw):
        from route_data.routes import build_routes
        return build_routes(stops_sheet(stops), info_sheet(info), **kw)

    def test_AC58_기본정보_중복_번호는_첫_행을_쓰고_개수를_센다(self):
        result = self.build(simple_route(1, "A100"),
                            [irow("A100", "간선"), irow("A100", "지선")])
        self.assertEqual([r.number for r in result.routes], ["A100"])
        self.assertEqual(result.routes[0].kind, "간선")
        self.assertEqual(result.duplicate_info_numbers, 1)

    def test_AC59_기본정보에_없는_노선은_제외한다(self):
        rows = simple_route(1, "A1") + simple_route(2, "B200")
        result = self.build(rows, [irow("A1", "간선")], min_join_rate=0)
        self.assertEqual([r.number for r in result.routes], ["A1"])
        self.assertEqual(result.excluded.get("기본정보에 없는 노선", []), ["2"])

    def test_AC60_한강_관광은_제외하고_빈_유형은_심야로_둔다(self):
        rows = (simple_route(1, "H") + simple_route(2, "T")
                + simple_route(3, "N") + simple_route(4, "J"))
        info = [irow("H", "한강"), irow("T", "관광"), irow("N", None), irow("J", "지선")]
        result = self.build(rows, info, min_join_rate=0)
        self.assertEqual([(r.number, r.kind) for r in result.routes],
                         [("N", "심야"), ("J", "지선")])
        self.assertEqual(result.excluded.get("유형 제외", []), ["1", "2"])

    def test_운행시간은_Decimal로_읽고_숫자가_아니면_None이다(self):
        rows = simple_route(1, "R1") + simple_route(2, "R2") + simple_route(3, "R3")
        info = [irow("R1", "간선", "35.5"), irow("R2", "간선", "0"), irow("R3", "간선", "abc")]
        result = self.build(rows, info)
        self.assertEqual([r.run_minutes for r in result.routes],
                         [Decimal("35.5"), Decimal("0"), None])

    def test_AC61_끝이_가상인_정류장만_제거하고_개수를_센다(self):
        rows = [srow(7, "G", 1, 1, "g1"), srow(7, "G", 2, 2, "중간(가상)"),
                srow(7, "G", 3, 3, "g3")]
        result = self.build(rows, [irow("G", "간선")])
        self.assertEqual([s.name for s in result.routes[0].stops], ["g1", "g3"])
        self.assertEqual(result.virtual_removed, 1)

    def test_AC61_이름_중간의_가상은_제거하지_않는다(self):
        rows = [srow(7, "G", 1, 1, "(가상)공원앞"), srow(7, "G", 2, 2, "g2")]
        result = self.build(rows, [irow("G", "간선")])
        self.assertEqual([s.name for s in result.routes[0].stops], ["(가상)공원앞", "g2"])
        self.assertEqual(result.virtual_removed, 0)

    def test_첫_정류장이_가상이어도_제거한다(self):
        rows = [srow(7, "G", 1, 1, "시점(가상) "), srow(7, "G", 2, 2, "g2"),
                srow(7, "G", 3, 3, "g3")]
        result = self.build(rows, [irow("G", "간선")])
        self.assertEqual([s.name for s in result.routes[0].stops], ["g2", "g3"])
        self.assertEqual(result.virtual_removed, 1)

    def test_가상_제거_후_연속된_같은_NODE_ID는_하나로_합친다(self):
        rows = [srow(7, "G", 1, 1, "g1"), srow(7, "G", 2, 2, "a"),
                srow(7, "G", 3, 2, "b(가상)"), srow(7, "G", 4, 2, "c"),
                srow(7, "G", 5, 3, "g5")]
        result = self.build(rows, [irow("G", "간선")])
        self.assertEqual([s.node_id for s in result.routes[0].stops], ["1", "2", "3"])

    def test_AC62_마지막이_첫_NODE_ID와_같으면_끝_행을_지운다(self):
        rows = [srow(8, "H", 1, 10, "h1"), srow(8, "H", 2, 20, "h2"),
                srow(8, "H", 3, 30, "h3"), srow(8, "H", 4, 10, "h1'")]
        result = self.build(rows, [irow("H", "간선")])
        self.assertEqual([s.name for s in result.routes[0].stops], ["h1", "h2", "h3"])
        self.assertEqual(result.tail_duplicates_removed, 1)

    def test_AC63_순번_오름차순으로_정렬한다(self):
        rows = [srow(9, "J", 9, 3, "s9"), srow(9, "J", 1, 1, "s1"),
                srow(9, "J", 5, 2, "s5")]
        result = self.build(rows, [irow("J", "간선")])
        self.assertEqual([s.name for s in result.routes[0].stops], ["s1", "s5", "s9"])

    def test_순번은_문자열이_아니라_정수로_비교한다(self):
        rows = [srow(9, "J", 10, 2, "s10"), srow(9, "J", 2, 1, "s2")]
        result = self.build(rows, [irow("J", "간선")])
        self.assertEqual([s.name for s in result.routes[0].stops], ["s2", "s10"])

    def test_AC71_좌표가_비었거나_범위_밖인_노선은_제외한다(self):
        rows = (simple_route(1, "OK1") + simple_route(2, "OK2")
                + [srow(3, "NOX", 1, 1, "a", x=None), srow(3, "NOX", 2, 2, "b")]
                + [srow(4, "LAT", 1, 1, "a", y="40.0"), srow(4, "LAT", 2, 2, "b")])
        info = [irow(n, "간선") for n in ("OK1", "OK2", "NOX", "LAT")]
        result = self.build(rows, info, min_join_rate=0)
        self.assertEqual([r.number for r in result.routes], ["OK1", "OK2"])
        self.assertEqual(result.excluded.get("좌표 이상", []), ["3", "4"])

    def test_NaN_또는_Infinity_좌표_노선은_예외_없이_좌표_이상으로_제외한다(self):
        cases = (("Y NaN", "127.0", "NaN"), ("X NaN", "NaN", "37.5"),
                 ("Y Infinity", "127.0", "Infinity"))
        for label, x, y in cases:
            with self.subTest(label=label):
                rows = (simple_route(1, "OK")
                        + [srow(2, "BAD", 1, 1, "a", x=x, y=y), srow(2, "BAD", 2, 2, "b")])
                info = [irow("OK", "간선"), irow("BAD", "간선")]
                result = self.build(rows, info, min_join_rate=0)
                self.assertEqual([r.number for r in result.routes], ["OK"])
                self.assertEqual(result.excluded.get("좌표 이상", []), ["2"])

    def test_가상_제거_후_정류장이_1개면_정류장_부족으로_제외한다(self):
        rows = [srow(5, "S", 1, 1, "s1"), srow(5, "S", 2, 2, "s2(가상)")]
        result = self.build(rows, [irow("S", "간선")], min_join_rate=0)
        self.assertEqual(result.routes, [])
        self.assertEqual(result.excluded.get("정류장 부족", []), ["5"])

    def test_순번이_정수가_아닌_노선은_ID_오류로_제외한다(self):
        rows = [srow(6, "E", "1.5", 1, "a"), srow(6, "E", 2, 2, "b")]
        result = self.build(rows, [irow("E", "간선")], min_join_rate=0)
        self.assertEqual(result.routes, [])
        self.assertEqual(result.excluded.get("ID 오류", []), ["6"])

    def test_ROUTE_ID는_정수_오름차순으로_정렬한다(self):
        rows = simple_route(10, "T10") + simple_route(9, "T9")
        info = [irow("T10", "간선"), irow("T9", "간선")]
        result = self.build(rows, info)
        self.assertEqual([r.route_id for r in result.routes], ["9", "10"])

    def test_좌표를_마이크로도_정수로_반올림_변환한다(self):
        rows = [srow(1, "C", 1, 1, "a", x="127.06447", y="37.5000005"),
                srow(1, "C", 2, 2, "b")]
        result = self.build(rows, [irow("C", "간선")])
        stop = result.routes[0].stops[0]
        self.assertEqual(stop.lat_micro, 37500001)
        self.assertEqual(stop.lon_micro, 127064470)

    def test_ARS_5자리가_아닌_정류장_행을_이상으로_센다(self):
        rows = [srow(1, "A", 1, 1, "a", ars=Cell("7832", True)),
                srow(1, "A", 2, 2, "b", ars=Cell("00123", True)),
                srow(1, "A", 3, 3, "c", ars=Cell("~", True))]
        result = self.build(rows, [irow("A", "간선")])
        self.assertEqual(result.ars_anomalies, 1)
        self.assertEqual([s.ars for s in result.routes[0].stops], ["7832", "00123", None])

    def test_AC73_정류소명이_달라도_NODE_ID가_같으면_같은_node_id를_낸다(self):
        month1 = [srow(1, "A", 1, 111, "옛이름"), srow(1, "A", 2, 222, "x")]
        month2 = [srow(1, "A", 1, 111, "새이름"), srow(1, "A", 2, 222, "x")]
        info = [irow("A", "간선")]
        r1 = self.build(month1, info)
        r2 = self.build(month2, info)
        self.assertEqual(r1.routes[0].stops[0].node_id, "111")
        self.assertEqual(r1.routes[0].stops[0].node_id, r2.routes[0].stops[0].node_id)

    def test_결합률이_기준_미만이면_JoinRateError를_낸다(self):
        from route_data.routes import JoinRateError
        rows = simple_route(1, "A") + simple_route(2, "B") + simple_route(3, "C")
        with self.assertRaises(JoinRateError) as ctx:
            self.build(rows, [irow("A", "간선")])
        self.assertEqual(ctx.exception.rate, Fraction(1, 3))
        self.assertEqual(sorted(ctx.exception.unmatched), ["2", "3"])

    def test_결합률은_정류소정보_전체_노선_대비_비율이다(self):
        rows = simple_route(1, "A") + simple_route(2, "B")
        result = self.build(rows, [irow("A", "간선")], min_join_rate=0)
        self.assertEqual(result.join_rate, Fraction(1, 2))


if __name__ == "__main__":
    unittest.main()
