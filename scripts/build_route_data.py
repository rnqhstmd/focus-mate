#!/usr/bin/env python3
"""Converts the Seoul Open Data bus xlsx files into the app's bundled route data.

Usage:
  python3 scripts/build_route_data.py --stops "서울시버스노선별정류소정보(YYYYMMDD).xlsx" \
      --routes "서울시버스노선기본정보(YYYYMMDD).xlsx" --out <seoul-route-data.json>
"""
import argparse
from fractions import Fraction
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parent))

from route_data.routes import (REASON_COORDINATE, REASON_KIND, REASON_NO_INFO,  # noqa: E402
                               JoinRateError, build_routes)
from route_data.segments import allocate_seconds, loop_meters, uses_run_minutes  # noqa: E402
from route_data.xlsx import MissingColumnsError, read_first_sheet, require_columns  # noqa: E402

STOP_COLUMNS = ["ROUTE_ID", "노선명", "순번", "NODE_ID", "ARS_ID", "정류소명", "X좌표", "Y좌표"]
INFO_COLUMNS = ["노선번호", "유형", "운행시간"]
DEFAULT_MAX_BYTES = 10_000_000
SOURCE = {
    "copyright": "서울특별시",
    "dataset": "서울시버스노선별정류소정보",
    "datasetID": "OA-1095",
    "license": "공공누리 제1유형",
    "provider": "서울 열린데이터광장",
    "routeInfoDataset": "서울시버스노선기본정보",
    "routeInfoDatasetID": "OA-15066",
}


class InputError(Exception):
    """Bad input files or arguments (exit code 2)."""


class OutputTooLargeError(Exception):
    """The rendered file exceeds the size limit (exit code 4)."""


def build(stops_path, routes_path, out_path, *, base_date=None, min_join_rate=Fraction(95, 100),
          max_bytes=DEFAULT_MAX_BYTES):
    stops_path, routes_path, out_path = Path(stops_path), Path(routes_path), Path(out_path)
    warnings = []
    stops_date = _file_date(stops_path)
    routes_date = _file_date(routes_path)
    if stops_date and routes_date and stops_date != routes_date:
        warnings.append(f"경고: 두 파일의 기준일이 다릅니다 (정류소정보 {stops_date}, 노선기본정보 {routes_date})")
    base_date = base_date or stops_date
    if not base_date:
        raise InputError("기준일을 파일 이름에서 찾을 수 없습니다. --base-date를 지정하세요")

    stops_sheet = read_first_sheet(stops_path)
    info_sheet = read_first_sheet(routes_path)
    require_columns(stops_sheet, STOP_COLUMNS)
    require_columns(info_sheet, INFO_COLUMNS)
    result = build_routes(stops_sheet, info_sheet, min_join_rate=min_join_rate)

    stops = {}
    route_lines = []
    implausible = []
    fallback = 0
    for route in result.routes:
        for stop in route.stops:
            stops.setdefault(stop.node_id, stop)
        meters = loop_meters([(stop.lat_micro, stop.lon_micro) for stop in route.stops])
        if not uses_run_minutes(meters, route.run_minutes):
            fallback += 1
            if route.run_minutes is not None and route.run_minutes > 0:
                implausible.append(route.route_id)
        seconds = allocate_seconds(meters, route.run_minutes, route.kind)
        route_lines.append(_dumps([route.route_id, route.number, route.kind,
                                   [stop.node_id for stop in route.stops], seconds, meters]))

    source = dict(SOURCE, baseDate=base_date, routeInfoFile=routes_path.name, stopsFile=stops_path.name)
    stop_lines = [_dumps([stop.node_id, stop.name, stop.ars or "", stop.lat_micro, stop.lon_micro])
                  for _, stop in sorted(stops.items())]
    text = "\n".join(['{"format":1,"source":' + json.dumps(source, ensure_ascii=False, sort_keys=True,
                                                           separators=(",", ":")) + ',"stops":[',
                      ",\n".join(stop_lines), '],"routes":[', ",\n".join(route_lines), "]}"]) + "\n"
    data = text.encode("utf-8")
    if len(data) > max_bytes:
        raise OutputTooLargeError(f"산출 크기 {len(data)} bytes가 한도 {max_bytes} bytes를 넘습니다")
    _replace_atomically(out_path, data)

    excluded = result.excluded
    summary = warnings + [
        f"입력 행 수: {len(stops_sheet.rows)}",
        f"입력 노선 수: {len({row['ROUTE_ID'].value for row in stops_sheet.rows if 'ROUTE_ID' in row})}",
        f"포함 노선 수: {len(result.routes)}",
        f"정류장 수: {len(stops)}",
        *(f"제외 노선 — {reason}: {_ids(excluded.get(reason, []))}"
          for reason in (REASON_NO_INFO, REASON_KIND, REASON_COORDINATE)),
        *(f"제외 노선 — {reason}: {_ids(ids)}" for reason, ids in excluded.items()
          if reason not in (REASON_NO_INFO, REASON_KIND, REASON_COORDINATE)),
        f"가상 지점 제거: {result.virtual_removed}",
        f"끝 중복 제거: {result.tail_duplicates_removed}",
        f"공동 운행 중복 번호: {result.duplicate_info_numbers}",
        f"ARS 이상: {result.ars_anomalies}",
        f"운행시간 이상 노선: {_ids(implausible)}",
        f"대체 속도 노선 수: {fallback}",
        f"결합률: {float(result.join_rate) * 100:.1f}%",
        f"산출 크기: {len(data)} bytes",
        f"SHA-256 정류소정보: {_sha256(stops_path.read_bytes())}",
        f"SHA-256 노선기본정보: {_sha256(routes_path.read_bytes())}",
        f"SHA-256 산출: {_sha256(data)}",
    ]
    return "\n".join(summary)


def _file_date(path):
    match = re.search(r"\((\d{4})(\d{2})(\d{2})\)", path.name)
    return "-".join(match.groups()) if match else None


def _dumps(value):
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def _ids(ids):
    return ",".join(ids) if ids else "없음"


def _sha256(data):
    return hashlib.sha256(data).hexdigest()


def _replace_atomically(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    handle, temporary = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    try:
        with os.fdopen(handle, "wb") as stream:
            stream.write(data)
        os.replace(temporary, path)
    except BaseException:
        if os.path.exists(temporary):
            os.unlink(temporary)
        raise


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--stops", required=True, help="서울시버스노선별정류소정보(YYYYMMDD).xlsx")
    parser.add_argument("--routes", required=True, help="서울시버스노선기본정보(YYYYMMDD).xlsx")
    parser.add_argument("--out", required=True, help="산출 JSON 경로")
    parser.add_argument("--base-date", help="기준일 YYYY-MM-DD (기본: 정류소정보 파일 이름의 날짜)")
    parser.add_argument("--min-join-rate", type=Fraction, default=Fraction(95, 100))
    parser.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    args = parser.parse_args(argv)
    try:
        summary = build(args.stops, args.routes, args.out, base_date=args.base_date,
                        min_join_rate=args.min_join_rate, max_bytes=args.max_bytes)
    except (InputError, MissingColumnsError) as error:
        print(error, file=sys.stderr)
        return 2
    except JoinRateError as error:
        print(error, file=sys.stderr)
        return 3
    except OutputTooLargeError as error:
        print(error, file=sys.stderr)
        return 4
    print(summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
