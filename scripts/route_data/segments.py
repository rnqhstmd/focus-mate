"""Segment distances and per-segment seconds for one bus loop."""
from decimal import Decimal
from fractions import Fraction
import math

EARTH_RADIUS_M = 6371008.8
MIN_SEGMENT_SECONDS = 30
FALLBACK_SPEED_KMH = {
    "간선": Decimal("13.4"), "지선": Decimal("11.6"), "마을": Decimal("8.8"), "광역": Decimal("19.6"),
    "공항": Decimal("34.8"), "심야": Decimal("17.3"), "순환": Decimal("9.4"),
}
OTHER_SPEED_KMH = Decimal("11.6")
# 운행시간이 뜻하는 직선 평균 속도가 이보다 느리면 원천 입력 오류로 보고 대체 속도를 쓴다(예: 541번 1190분).
MIN_PLAUSIBLE_SPEED_KMH = Decimal("3")


def distance_meters(a_lat_micro, a_lon_micro, b_lat_micro, b_lon_micro):
    lat1, lon1, lat2, lon2 = (math.radians(value / 1_000_000)
                              for value in (a_lat_micro, a_lon_micro, b_lat_micro, b_lon_micro))
    h = math.sin((lat2 - lat1) / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin((lon2 - lon1) / 2) ** 2
    return math.floor(2 * EARTH_RADIUS_M * math.asin(math.sqrt(h)) + 0.5)


def loop_meters(points):
    count = len(points)
    return [distance_meters(*points[i], *points[(i + 1) % count]) for i in range(count)]


def uses_run_minutes(meters, run_minutes):
    if run_minutes is None or run_minutes <= 0:
        return False
    total_seconds = _round_half_up(Fraction(run_minutes) * 60)
    if total_seconds <= 0:
        return False
    total_meters = sum(meters)
    if total_meters == 0:
        return True
    speed = Fraction(total_meters) * Fraction(36, 10) / total_seconds
    return speed >= Fraction(MIN_PLAUSIBLE_SPEED_KMH)


def allocate_seconds(meters, run_minutes, kind):
    if not uses_run_minutes(meters, run_minutes):
        speed = Fraction(FALLBACK_SPEED_KMH.get(kind, OTHER_SPEED_KMH))
        return [max(MIN_SEGMENT_SECONDS, _round_half_up(Fraction(m) * Fraction(36, 10) / speed)) for m in meters]
    total = _round_half_up(Fraction(run_minutes) * 60)
    count = len(meters)
    if total < MIN_SEGMENT_SECONDS * count:
        return [MIN_SEGMENT_SECONDS] * count

    fixed = set()
    while True:
        free = [i for i in range(count) if i not in fixed]
        budget = total - MIN_SEGMENT_SECONDS * len(fixed)
        free_meters = sum(meters[i] for i in free)
        ideal = {i: (Fraction(budget * meters[i], free_meters) if free_meters else Fraction(budget, len(free)))
                 for i in free}
        short = {i for i, value in ideal.items() if value < MIN_SEGMENT_SECONDS}
        if not short:
            break
        fixed |= short

    seconds = [MIN_SEGMENT_SECONDS] * count
    for i, value in ideal.items():
        seconds[i] = math.floor(value)
    remainder = budget - sum(seconds[i] for i in free)
    by_fraction = sorted(free, key=lambda i: (-(ideal[i] - math.floor(ideal[i])), i))
    for i in by_fraction[:remainder]:
        seconds[i] += 1
    return seconds


def _round_half_up(value):
    """Rounds a non-negative Fraction to the nearest integer, halves up."""
    return math.floor(value + Fraction(1, 2))
