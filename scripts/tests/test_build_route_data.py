import hashlib
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from tests.xlsx_fixture import Num, write_xlsx

REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts" / "build_route_data.py"
STOPS_NAME = "서울시버스노선별정류소정보(20260902).xlsx"
INFO_NAME = "서울시버스노선기본정보(20260902).xlsx"
STOP_HEADER = ["ROUTE_ID", "노선명", "순번", "NODE_ID", "ARS_ID", "정류소명", "X좌표", "Y좌표"]
INFO_HEADER = ["노선번호", "유형", "운행시간"]


def stop_row(rid, number, seq, node, ars, name, x, y):
    return [Num(str(rid)), number, Num(str(seq)), Num(str(node)), ars, name, Num(x), Num(y)]


# 노선 100(A,B,C) / 200(C,D,E) / 300(F,G): 8행, 정류장 C 공유 -> 고유 정류장 7개
STOP_ROWS = [
    stop_row(100, "100", 1, 1001, "01001", "가", "127.000", "37.500"),
    stop_row(100, "100", 2, 1002, "01002", "나", "127.010", "37.500"),
    stop_row(100, "100", 3, 1003, "01003", "다", "127.020", "37.500"),
    stop_row(200, "2000", 1, 1003, "01003", "다", "127.020", "37.500"),
    stop_row(200, "2000", 2, 1004, "01004", "라", "127.030", "37.500"),
    stop_row(200, "2000", 3, 1005, "01005", "마", "127.040", "37.500"),
    stop_row(300, "마포01", 1, 1006, "01006", "바", "127.050", "37.510"),
    stop_row(300, "마포01", 2, 1007, "01007", "사", "127.060", "37.510"),
]
INFO_ROWS = [
    ["100", "간선", Num("60")],
    ["2000", "지선", Num("50")],
    ["마포01", "마을", Num("40")],
]


def run_cli(*args):
    return subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True)


class Base(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.dir = Path(self._tmp.name)

    def make(self, stops_name=STOPS_NAME, info_name=INFO_NAME, stop_header=None, stop_rows=None,
             info_header=None, info_rows=None):
        sp = self.dir / stops_name
        ip = self.dir / info_name
        write_xlsx(sp, [stop_header or STOP_HEADER] + (STOP_ROWS if stop_rows is None else stop_rows))
        write_xlsx(ip, [info_header or INFO_HEADER] + (INFO_ROWS if info_rows is None else info_rows))
        return sp, ip

    def cli(self, sp, ip, out, *extra):
        return run_cli("--stops", str(sp), "--routes", str(ip), "--out", str(out), *extra)

    @staticmethod
    def load(out):
        return json.loads(Path(out).read_text(encoding="utf-8"))


class BuildRouteDataTest(Base):
    def test_정상_입력은_노선3개와_중복제거된_정류장을_산출한다(self):
        sp, ip = self.make()
        out = self.dir / "o.json"
        r = self.cli(sp, ip, out)
        self.assertEqual(r.returncode, 0, r.stderr)
        data = self.load(out)
        self.assertEqual(len(data["routes"]), 3)
        self.assertEqual(len(data["stops"]), 7)
        by_id = {x[0]: x for x in data["routes"]}
        for rid, number, kind in (("100", "100", "간선"), ("200", "2000", "지선"), ("300", "마포01", "마을")):
            self.assertEqual(by_id[rid][1], number)
            self.assertIn(kind, by_id[rid][2])

    def test_같은_입력을_두번_실행하면_바이트가_같다(self):
        sp, ip = self.make()
        a, b = self.dir / "a.json", self.dir / "b.json"
        self.assertEqual(self.cli(sp, ip, a).returncode, 0)
        self.assertEqual(self.cli(sp, ip, b).returncode, 0)
        self.assertEqual(a.read_bytes(), b.read_bytes())

    def test_정류소정보에_필수열이_없으면_종료2와_누락열_이름을_알리고_기존_산출을_보존한다(self):
        header = [h for h in STOP_HEADER if h != "X좌표"]
        rows = [r[:6] + r[7:] for r in STOP_ROWS]
        sp, ip = self.make(stop_header=header, stop_rows=rows)
        out = self.dir / "o.json"
        out.write_bytes(b"OLD")
        r = self.cli(sp, ip, out)
        self.assertEqual(r.returncode, 2)
        self.assertIn("X좌표", r.stderr)
        self.assertEqual(out.read_bytes(), b"OLD")

    def test_기본정보에_운행시간_열이_없으면_종료2와_누락열_이름을_알리고_기존_산출을_보존한다(self):
        sp, ip = self.make(info_header=["노선번호", "유형"], info_rows=[r[:2] for r in INFO_ROWS])
        out = self.dir / "o.json"
        out.write_bytes(b"OLD")
        r = self.cli(sp, ip, out)
        self.assertEqual(r.returncode, 2)
        self.assertIn("운행시간", r.stderr)
        self.assertEqual(out.read_bytes(), b"OLD")

    def test_파일이름의_날짜가_기준일과_출처_파일이름이_된다(self):
        sp, ip = self.make()
        out = self.dir / "o.json"
        self.assertEqual(self.cli(sp, ip, out).returncode, 0)
        src = self.load(out)["source"]
        self.assertEqual(src["baseDate"], "2026-09-02")
        self.assertEqual(src["stopsFile"], STOPS_NAME)
        self.assertEqual(src["routeInfoFile"], INFO_NAME)

    def test_두_파일의_날짜가_다르면_경고하고_정류소정보_날짜를_기준일로_쓴다(self):
        sp, ip = self.make(info_name="서울시버스노선기본정보(20260901).xlsx")
        out = self.dir / "o.json"
        r = self.cli(sp, ip, out)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("경고", r.stdout)
        self.assertIn("2026-09-01", r.stdout)
        self.assertEqual(self.load(out)["source"]["baseDate"], "2026-09-02")

    def test_파일이름에_날짜가_없고_기준일_옵션도_없으면_종료2(self):
        sp, ip = self.make(stops_name="stops.xlsx", info_name="info.xlsx")
        out = self.dir / "o.json"
        r = self.cli(sp, ip, out)
        self.assertEqual(r.returncode, 2)
        self.assertIn("기준일", r.stderr)
        self.assertFalse(out.exists())

    def test_기준일_옵션은_파일이름_날짜보다_우선한다(self):
        sp, ip = self.make()
        out = self.dir / "o.json"
        r = self.cli(sp, ip, out, "--base-date", "2026-10-01")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(self.load(out)["source"]["baseDate"], "2026-10-01")

    def test_산출_크기가_한도를_넘으면_종료4이고_기존_산출을_보존한다(self):
        sp, ip = self.make()
        out = self.dir / "o.json"
        out.write_bytes(b"OLD")
        r = self.cli(sp, ip, out, "--max-bytes", "100")
        self.assertEqual(r.returncode, 4)
        self.assertEqual(out.read_bytes(), b"OLD")

    def test_결합률이_기준에_못_미치면_종료3이고_산출을_만들지_않는다(self):
        sp, ip = self.make(info_rows=INFO_ROWS[:1], stop_rows=STOP_ROWS[:6][:3] + STOP_ROWS[3:6])
        out = self.dir / "o.json"
        r = self.cli(sp, ip, out)
        self.assertEqual(r.returncode, 3)
        self.assertFalse(out.exists())

    def test_결합률_0이면_기본정보에_없는_노선을_제외하고_성공한다(self):
        sp, ip = self.make(info_rows=INFO_ROWS[:1], stop_rows=STOP_ROWS[:6])
        out = self.dir / "o.json"
        r = self.cli(sp, ip, out, "--min-join-rate", "0")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("제외 노선 — 기본정보에 없는 노선: 200", r.stdout)
        self.assertEqual([x[0] for x in self.load(out)["routes"]], ["100"])

    def test_산출_파일은_정해진_줄_형식을_따른다(self):
        sp, ip = self.make()
        out = self.dir / "o.json"
        self.assertEqual(self.cli(sp, ip, out).returncode, 0)
        text = out.read_bytes().decode("utf-8")
        self.assertTrue(text.endswith("\n"))
        lines = text.split("\n")[:-1]
        self.assertTrue(lines[0].startswith('{"format":1,"source":{'))
        self.assertTrue(lines[0].endswith('"stops":['))
        self.assertEqual(lines[-1], "]}")
        sep = lines.index('],"routes":[')
        node_ids = []
        for ln in lines[1:sep]:
            node_ids.append(json.loads(ln.rstrip(","))[0])
        self.assertEqual(node_ids, sorted(node_ids))
        self.assertEqual(len(node_ids), 7)
        for ln in lines[sep + 1:-1]:
            route = json.loads(ln.rstrip(","))
            nodes, secs, meters = route[3], route[4], route[5]
            self.assertEqual(len(secs), len(nodes))
            self.assertEqual(len(meters), len(nodes))
            self.assertTrue(all(s >= 30 for s in secs))

    def test_성공_요약은_정해진_줄을_모두_담고_산출_해시가_실제와_같다(self):
        sp, ip = self.make()
        out = self.dir / "o.json"
        r = self.cli(sp, ip, out)
        self.assertEqual(r.returncode, 0, r.stderr)
        prefixes = ["입력 행 수:", "입력 노선 수:", "포함 노선 수:", "정류장 수:",
                    "제외 노선 — 기본정보에 없는 노선:", "제외 노선 — 유형 제외:", "제외 노선 — 좌표 이상:",
                    "가상 지점 제거:", "끝 중복 제거:", "운행시간 이상 노선:", "대체 속도 노선 수:",
                    "결합률:", "산출 크기:", "SHA-256 정류소정보:", "SHA-256 노선기본정보:", "SHA-256 산출:"]
        lines = r.stdout.splitlines()
        for p in prefixes:
            self.assertTrue(any(l.startswith(p) for l in lines), p)
        vals = {l.split(":", 1)[0] + ":": l.split(":", 1)[1].strip() for l in lines if ":" in l}
        self.assertEqual(vals["입력 행 수:"], "8")
        self.assertEqual(vals["포함 노선 수:"], "3")
        self.assertEqual(vals["정류장 수:"], "7")
        self.assertEqual(vals["결합률:"], "100.0%")
        self.assertEqual(vals["SHA-256 산출:"], hashlib.sha256(out.read_bytes()).hexdigest())
        self.assertEqual(vals["SHA-256 정류소정보:"], hashlib.sha256(sp.read_bytes()).hexdigest())
        self.assertEqual(vals["산출 크기:"], "%d bytes" % out.stat().st_size)

    def test_운행시간이_비정상이면_대체_속도로_구간_시간을_계산하고_요약에_알린다(self):
        stop_rows = [
            stop_row(700, "700", 1, 7001, "07001", "가", "127.000", "37.500"),
            stop_row(700, "700", 2, 7002, "07002", "나", "127.000", "37.509"),
        ]
        sp, ip = self.make(stop_rows=stop_rows, info_rows=[["700", "간선", Num("1190")]])
        out = self.dir / "o.json"
        r = self.cli(sp, ip, out)
        self.assertEqual(r.returncode, 0, r.stderr)
        line = [l for l in r.stdout.splitlines() if l.startswith("운행시간 이상 노선:")][0]
        self.assertIn("700", line)
        self.assertEqual(self.load(out)["routes"][0][4], [269, 269])


    @staticmethod
    def summary(stdout):
        return {l.split(":", 1)[0]: l.split(":", 1)[1].strip() for l in stdout.splitlines() if ":" in l}

    def test_R1_기본_입력의_입력_정류장_수는_7이고_최소_보정_초과는_0이다(self):
        sp, ip = self.make()
        r = self.cli(sp, ip, self.dir / "o.json")
        self.assertEqual(r.returncode, 0, r.stderr)
        v = self.summary(r.stdout)
        self.assertEqual(v["입력 정류장 수"], "7")
        self.assertEqual(v["최소 보정 초과 노선 수"], "0")

    def test_R1_제외된_노선의_정류장도_입력_정류장_수에_센다(self):
        extra = [stop_row(900, "900", 1, 2001, "02001", "아", "127.100", "37.500"),
                 stop_row(900, "900", 2, 2002, "02002", "자", "127.110", "37.500")]
        sp, ip = self.make(stop_rows=STOP_ROWS + extra)
        r = self.cli(sp, ip, self.dir / "o.json", "--min-join-rate", "0")
        self.assertEqual(r.returncode, 0, r.stderr)
        v = self.summary(r.stdout)
        self.assertEqual(v["입력 정류장 수"], "9")
        self.assertEqual(v["정류장 수"], "7")

    def test_R1_운행시간이_30초_하한보다_짧으면_모든_구간이_30초가_되고_최소_보정_초과로_센다(self):
        stop_rows = [
            stop_row(800, "800", 1, 8001, "08001", "가", "127.000", "37.500"),
            stop_row(800, "800", 2, 8002, "08002", "나", "127.000", "37.509"),
            stop_row(800, "800", 3, 8003, "08003", "다", "127.000", "37.518"),
        ]
        sp, ip = self.make(stop_rows=stop_rows, info_rows=[["800", "간선", Num("1")]])
        out = self.dir / "o.json"
        r = self.cli(sp, ip, out)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(self.load(out)["routes"][0][4], [30, 30, 30])
        self.assertEqual(self.summary(r.stdout)["최소 보정 초과 노선 수"], "1")

    def test_R1_ARS_보정과_이상은_정류장_기준으로_센다(self):
        stop_rows = [
            stop_row(100, "100", 1, 1001, Num("1234"), "가", "127.000", "37.500"),
            stop_row(100, "100", 2, 1002, "7832", "나", "127.010", "37.500"),
            stop_row(100, "100", 3, 1003, "~", "다", "127.020", "37.500"),
            stop_row(200, "2000", 1, 1002, "7832", "나", "127.010", "37.500"),
            stop_row(200, "2000", 2, 1004, "01004", "라", "127.030", "37.500"),
        ]
        sp, ip = self.make(stop_rows=stop_rows, info_rows=INFO_ROWS[:2])
        out = self.dir / "o.json"
        r = self.cli(sp, ip, out)
        self.assertEqual(r.returncode, 0, r.stderr)
        v = self.summary(r.stdout)
        self.assertEqual(v["ARS 0 채움"], "1")
        self.assertEqual(v["ARS 5자리 아님"], "1")
        self.assertEqual(v["ARS 번호 없음"], "1")
        stops = {x[0]: x for x in self.load(out)["stops"]}
        self.assertEqual(stops["1001"][2], "01234")


class InputGuardCliTest(Base):
    def assert_clean_exit2(self, r, out):
        self.assertEqual(r.returncode, 2, r.stderr)
        self.assertNotIn("Traceback", r.stderr)
        self.assertTrue(r.stderr.strip())
        self.assertEqual(out.read_bytes(), b"OLD")

    def test_성공_산출의_source에_출처_URL_두_개가_있다(self):
        sp, ip = self.make()
        out = self.dir / "o.json"
        self.assertEqual(self.cli(sp, ip, out).returncode, 0)
        src = self.load(out)["source"]
        self.assertEqual(src["sourceURL"], "https://data.seoul.go.kr/dataList/OA-1095/F/1/datasetView.do")
        self.assertEqual(src["routeInfoSourceURL"], "https://data.seoul.go.kr/dataList/OA-15066/F/1/datasetView.do")

    def test_zip이_아닌_입력은_종료2이고_traceback_없이_기존_산출을_보존한다(self):
        sp, ip = self.make()
        sp.write_bytes(b"not a zip")
        out = self.dir / "o.json"
        out.write_bytes(b"OLD")
        self.assert_clean_exit2(self.cli(sp, ip, out), out)

    def test_존재하지_않는_입력_경로는_종료2이고_기존_산출을_보존한다(self):
        _, ip = self.make()
        out = self.dir / "o.json"
        out.write_bytes(b"OLD")
        r = self.cli(self.dir / "없음.xlsx", ip, out)
        self.assert_clean_exit2(r, out)

    def test_시트에_DOCTYPE이_든_입력은_종료2이고_기존_산출을_보존한다(self):
        from tests.xlsx_fixture import write_xlsx_with_doctype
        sp, ip = self.make()
        write_xlsx_with_doctype(sp, [STOP_HEADER] + STOP_ROWS)
        out = self.dir / "o.json"
        out.write_bytes(b"OLD")
        self.assert_clean_exit2(self.cli(sp, ip, out), out)

    def test_압축_데이터가_손상된_입력은_종료2이고_traceback_없이_기존_산출을_보존한다(self):
        from tests.xlsx_fixture import write_xlsx_corrupt_deflate
        sp, ip = self.make()
        write_xlsx_corrupt_deflate(sp, [STOP_HEADER] + STOP_ROWS)
        out = self.dir / "o.json"
        out.write_bytes(b"OLD")
        self.assert_clean_exit2(self.cli(sp, ip, out), out)

    def test_크기_초과_종료4_뒤_out_폴더에_임시_파일이_남지_않는다(self):
        sp, ip = self.make()
        outdir = self.dir / "outdir"
        outdir.mkdir()
        out = outdir / "o.json"
        out.write_bytes(b"OLD")
        before = sorted(os.listdir(outdir))
        r = self.cli(sp, ip, out, "--max-bytes", "100")
        self.assertEqual(r.returncode, 4)
        self.assertEqual(sorted(os.listdir(outdir)), before)
        self.assertEqual(out.read_bytes(), b"OLD")


class LargeXlsxGuardTest(unittest.TestCase):
    def test_저장소에_1MB_이상_xlsx가_추적되거나_남아있지_않다(self):
        r = subprocess.run(["git", "ls-files", "-co", "--exclude-standard"], cwd=REPO,
                           capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        big = []
        for rel in r.stdout.splitlines():
            p = REPO / rel
            if p.suffix.lower() == ".xlsx" and p.is_file() and p.stat().st_size >= 1_000_000:
                big.append(rel)
        self.assertEqual(big, [])


if __name__ == "__main__":
    unittest.main()
