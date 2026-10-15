"""Cleans OA-1095 route stop rows and joins them with OA-15066 route info."""
from collections import defaultdict
from dataclasses import dataclass
from decimal import ROUND_HALF_UP, Decimal, InvalidOperation
from fractions import Fraction

EXCLUDED_KINDS = {"한강", "관광"}
NIGHT_KIND = "심야"
REASON_NO_INFO = "기본정보에 없는 노선"
REASON_KIND = "유형 제외"
REASON_COORDINATE = "좌표 이상"
REASON_TOO_FEW = "정류장 부족"
REASON_ID = "ID 오류"
VIRTUAL_SUFFIX = "(가상)"
LATITUDE_RANGE = (Decimal(33), Decimal(39))
LONGITUDE_RANGE = (Decimal(124), Decimal(130))


@dataclass(frozen=True)
class StopPoint:
    node_id: str
    name: str
    ars: str | None
    lat_micro: int
    lon_micro: int


@dataclass(frozen=True)
class CleanRoute:
    route_id: str
    number: str
    kind: str
    run_minutes: Decimal | None
    stops: list


@dataclass(frozen=True)
class RouteBuildResult:
    routes: list
    excluded: dict
    virtual_removed: int
    tail_duplicates_removed: int
    duplicate_info_numbers: int
    ars_anomalies: int
    join_rate: Fraction
    ars_zero_filled: int


class JoinRateError(Exception):
    def __init__(self, rate, unmatched):
        self.rate = rate
        self.unmatched = list(unmatched)
        super().__init__(f"노선 기본정보 결합률 {float(rate):.1%}이 기준보다 낮습니다. 결합 실패: {', '.join(self.unmatched)}")


def normalize_integer(text):
    try:
        number = Decimal(text.strip())
    except (InvalidOperation, AttributeError):
        raise ValueError(f"정수가 아닙니다: {text!r}") from None
    if not number.is_finite() or number != number.to_integral_value():
        raise ValueError(f"정수가 아닙니다: {text!r}")
    return format(int(number), "d")


def normalize_ars(cell):
    if cell is None:
        return None
    text = cell.value.strip()
    if not cell.is_text and text:
        try:
            text = normalize_integer(text).zfill(5)
        except ValueError:
            pass
    if not text or text == "~" or set(text) == {"0"}:
        return None
    return text


def is_ars_anomaly(ars):
    """True when a stop number exists but is not five digits (e.g. "7832")."""
    return ars is not None and not (len(ars) == 5 and ars.isdigit())


def build_routes(stops, info, *, min_join_rate=Fraction(95, 100)):
    infos, duplicates = _route_infos(info)
    groups = defaultdict(list)
    for row in stops.rows:
        groups[_text(row, "ROUTE_ID")].append(row)

    excluded = defaultdict(list)
    routes = []
    unmatched = []
    counters = {"virtual": 0, "tail": 0, "zero_filled": set()}
    for raw_id, rows in groups.items():
        number = _text(rows[0], "노선명")
        route_info = infos.get(number)
        if route_info is None:
            unmatched.append(raw_id)
        route = _clean_route(raw_id, rows, route_info, excluded, counters)
        if route is not None:
            routes.append(route)
            counters["zero_filled"] |= {stop.node_id for stop in route.stops} & _zero_filled_nodes(rows)

    join_rate = Fraction(len(groups) - len(unmatched), len(groups)) if groups else Fraction(0)
    if join_rate < min_join_rate:
        raise JoinRateError(join_rate, sorted(unmatched, key=_id_order))
    routes.sort(key=lambda route: int(route.route_id))
    first_stops = {}
    for route in routes:
        for stop in route.stops:
            first_stops.setdefault(stop.node_id, stop)
    anomalies = sum(1 for stop in first_stops.values() if is_ars_anomaly(stop.ars))
    return RouteBuildResult(
        routes=routes,
        excluded={reason: sorted(ids, key=_id_order) for reason, ids in excluded.items()},
        virtual_removed=counters["virtual"],
        tail_duplicates_removed=counters["tail"],
        duplicate_info_numbers=duplicates,
        ars_anomalies=anomalies,
        join_rate=join_rate,
        ars_zero_filled=len(counters["zero_filled"]),
    )


def _clean_route(raw_id, rows, route_info, excluded, counters):
    try:
        route_id = normalize_integer(raw_id)
        ordered = sorted(((int(normalize_integer(_text(row, "순번"))), index, row)
                          for index, row in enumerate(rows)), key=lambda item: item[:2])
        points = [_stop_point(row) for _, _, row in ordered]
    except ValueError:
        excluded[REASON_ID].append(raw_id)
        return None
    if any(point is None for point in points):
        excluded[REASON_COORDINATE].append(route_id)
        return None

    kept = [point for point in points if not point.name.endswith(VIRTUAL_SUFFIX)]
    counters["virtual"] += len(points) - len(kept)
    merged = []
    for point in kept:
        if not merged or merged[-1].node_id != point.node_id:
            merged.append(point)
    if len(merged) > 1 and merged[-1].node_id == merged[0].node_id:
        merged.pop()
        counters["tail"] += 1
    if len(merged) < 2:
        excluded[REASON_TOO_FEW].append(route_id)
        return None

    if route_info is None:
        excluded[REASON_NO_INFO].append(route_id)
        return None
    kind, run_minutes = route_info
    if kind in EXCLUDED_KINDS:
        excluded[REASON_KIND].append(route_id)
        return None
    return CleanRoute(route_id=route_id, number=_text(rows[0], "노선명"), kind=kind or NIGHT_KIND,
                      run_minutes=run_minutes, stops=merged)


def _stop_point(row):
    """Returns None when a coordinate is missing or outside the plausible Korean range."""
    node_id = normalize_integer(_text(row, "NODE_ID"))
    try:
        latitude = Decimal(_text(row, "Y좌표"))
        longitude = Decimal(_text(row, "X좌표"))
    except InvalidOperation:
        return None
    if not (latitude.is_finite() and longitude.is_finite()):
        return None
    if not (LATITUDE_RANGE[0] <= latitude <= LATITUDE_RANGE[1]
            and LONGITUDE_RANGE[0] <= longitude <= LONGITUDE_RANGE[1]):
        return None
    return StopPoint(node_id=node_id, name=_text(row, "정류소명"), ars=normalize_ars(row.get("ARS_ID")),
                     lat_micro=_micro(latitude), lon_micro=_micro(longitude))


def _zero_filled_nodes(rows):
    """NODE_IDs whose ARS came from a numeric cell shorter than five digits (and was zero-padded)."""
    nodes = set()
    for row in rows:
        cell = row.get("ARS_ID")
        if cell is None or cell.is_text or not cell.value.strip():
            continue
        try:
            digits = normalize_integer(cell.value)
            node_id = normalize_integer(_text(row, "NODE_ID"))
        except ValueError:
            continue
        if len(digits) < 5 and normalize_ars(cell) is not None:
            nodes.add(node_id)
    return nodes


def _route_infos(info):
    infos = {}
    counts = defaultdict(int)
    for row in info.rows:
        number = _text(row, "노선번호")
        counts[number] += 1
        if number not in infos:
            infos[number] = (_text(row, "유형"), _minutes(_text(row, "운행시간")))
    return infos, sum(1 for count in counts.values() if count > 1)


def _minutes(text):
    try:
        value = Decimal(text)
    except InvalidOperation:
        return None
    return value if value.is_finite() else None


def _micro(value):
    return int((value * 1_000_000).quantize(Decimal(1), rounding=ROUND_HALF_UP))


def _text(row, column):
    cell = row.get(column)
    return cell.value.strip() if cell is not None else ""


def _id_order(route_id):
    try:
        return (0, int(normalize_integer(route_id)), route_id)
    except ValueError:
        return (1, 0, route_id)
