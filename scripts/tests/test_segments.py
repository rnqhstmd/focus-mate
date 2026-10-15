"""route_data.segments 구간 거리·시간 계산 테스트 (RED)."""
import unittest
from decimal import Decimal


class DistanceTest(unittest.TestCase):
    def test_위도_0_009도_차이는_1001m이다(self):
        from route_data.segments import distance_meters
        # 하버사인: 0.009도 * R * pi/180 = 1000.7557m -> 반올림 1001
        self.assertEqual(
            distance_meters(37500000, 127000000, 37509000, 127000000), 1001)

    def test_같은_점의_거리는_0이다(self):
        from route_data.segments import distance_meters
        self.assertEqual(
            distance_meters(37500000, 127000000, 37500000, 127000000), 0)

    def test_한바퀴_구간은_마지막이_회차구간이다(self):
        from route_data.segments import loop_meters
        pts = [(37500000, 127000000), (37509000, 127000000),
               (37518000, 127000000)]
        # 1->2: 1000.756 -> 1001, 2->3: 1001, 3->1(회차): 0.018도 = 2001.511 -> 2002
        self.assertEqual(loop_meters(pts), [1001, 1001, 2002])


class AllocateWithRunMinutesTest(unittest.TestCase):
    def alloc(self, meters, minutes, kind="간선"):
        from route_data.segments import allocate_seconds
        return allocate_seconds(meters, minutes, kind)

    def test_AC61_동일_거리는_균등_배분한다(self):
        self.assertEqual(self.alloc([1001, 1001], Decimal("2")), [60, 60])

    def test_AC62_거리에_비례해_배분한다(self):
        self.assertEqual(
            self.alloc([1001, 1001, 2002], Decimal("4")), [60, 60, 120])

    def test_AC65_남는_1초는_소수부가_큰_구간에_준다(self):
        self.assertEqual(
            self.alloc([1001, 1001, 1001, 3002], Decimal("10")),
            [100, 100, 100, 300])

    def test_AC66_남는_1초는_소수부_동률이_아니면_큰_쪽이다(self):
        # 이상값 128.565, 171.435, 300.000 -> 내림 128,171,300, 1초는 첫째(.565)
        self.assertEqual(
            self.alloc([3002, 4003, 7005], Decimal("10")), [129, 171, 300])

    def test_AC67_30초_미만_구간은_30초로_고정하고_재배분한다(self):
        self.assertEqual(
            self.alloc([11, 1001, 1012], Decimal("10")), [30, 283, 287])

    def test_AC70_거리가_모두_0이면_균등_배분한다(self):
        self.assertEqual(self.alloc([0, 0, 0], Decimal("10")), [200, 200, 200])

    def test_운행시간이_부족하면_모두_30초이다(self):
        self.assertEqual(
            self.alloc([1001, 1001, 1001], Decimal("1")), [30, 30, 30])

    def test_운행시간_소수는_초로_반올림한다(self):
        self.assertEqual(self.alloc([1001, 1001], Decimal("2.5")), [75, 75])

    def test_정확히_나누어떨어지면_잔여가_없다(self):
        self.assertEqual(
            self.alloc([1000, 1000, 1000], Decimal("10")), [200, 200, 200])

    def test_S_603초는_3등분_201초이다(self):
        self.assertEqual(
            self.alloc([1000, 1000, 1000], Decimal("10.05")), [201, 201, 201])

    def test_최대_잔여_동률은_색인_작은_구간이_먼저_받는다(self):
        # S=602, 이상값 200.667 x3 -> 내림 600, 남는 2초는 첫째·둘째
        self.assertEqual(
            self.alloc([1000, 1000, 1000], Decimal("10.0333")), [201, 201, 200])

    def test_배분_합은_항상_운행초와_같다(self):
        cases = [
            ([1001, 1001], Decimal("2"), 120),
            ([1001, 1001, 2002], Decimal("4"), 240),
            ([1001, 1001, 1001, 3002], Decimal("10"), 600),
            ([3002, 4003, 7005], Decimal("10"), 600),
            ([11, 1001, 1012], Decimal("10"), 600),
            ([0, 0, 0], Decimal("10"), 600),
            ([1001, 1001], Decimal("2.5"), 150),
            ([1000, 1000, 1000], Decimal("10.05"), 603),
            ([1000, 1000, 1000], Decimal("10.0333"), 602),
        ]
        for meters, minutes, total in cases:
            with self.subTest(meters=meters, minutes=minutes):
                result = self.alloc(meters, minutes)
                self.assertEqual(sum(result), total)
                self.assertTrue(all(s >= 30 for s in result))


class AllocateFallbackSpeedTest(unittest.TestCase):
    def alloc(self, meters, minutes, kind):
        from route_data.segments import allocate_seconds
        return allocate_seconds(meters, minutes, kind)

    def test_AC68_지선_대체속도로_계산한다(self):
        # 1001*3.6/11.6 = 310.655 -> 311
        self.assertEqual(self.alloc([1001, 1001], None, "지선"), [311, 311])

    def test_운행시간_0도_대체속도로_계산한다(self):
        self.assertEqual(
            self.alloc([1001, 1001], Decimal("0"), "지선"), [311, 311])

    def test_AC69_심야_대체속도로_계산한다(self):
        # 1001*3.6/17.3 = 208.300 -> 208
        self.assertEqual(self.alloc([1001, 1001], None, "심야"), [208, 208])

    def test_대체속도에서도_구간_최소는_30초이다(self):
        # 50*3.6/13.4 = 13.43 -> 30 ; 1001*3.6/13.4 = 268.925 -> 269
        self.assertEqual(self.alloc([50, 1001], None, "간선"), [30, 269])

    def test_알수없는_유형은_11_6_속도를_쓴다(self):
        self.assertEqual(self.alloc([1001], None, "알수없음"), [311])


class ImplausibleRunMinutesTest(unittest.TestCase):
    def alloc(self, meters, minutes, kind):
        from route_data.segments import allocate_seconds
        return allocate_seconds(meters, minutes, kind)

    def uses(self, meters, minutes):
        from route_data.segments import uses_run_minutes
        return uses_run_minutes(meters, minutes)

    def test_최소_허용_속도_상수는_3이다(self):
        from route_data.segments import MIN_PLAUSIBLE_SPEED_KMH
        self.assertEqual(MIN_PLAUSIBLE_SPEED_KMH, Decimal("3"))

    def test_너무_느린_운행시간은_대체_속도로_계산한다(self):
        # 2002*3.6/6000 = 1.2012 km/h < 3 -> 간선 13.4: 1001*3.6/13.4 = 268.925 -> 269
        self.assertEqual(
            self.alloc([1001, 1001], Decimal("100"), "간선"), [269, 269])

    def test_너무_느린_운행시간은_비례_배분을_쓰지_않는다(self):
        self.assertFalse(self.uses([1001, 1001], Decimal("100")))

    def test_빠른_운행시간도_신뢰한다(self):
        # 100 km/h 이어도 상한 검사 없음 -> S=3600 균등 1800
        self.assertTrue(self.uses([50000, 50000], Decimal("60")))
        self.assertEqual(
            self.alloc([50000, 50000], Decimal("60"), "공항"), [1800, 1800])

    def test_경계_속도_3은_운행시간을_신뢰한다(self):
        # 5000*3.6/6000 = 3.0 km/h (포함) -> S=6000 균등
        self.assertEqual(
            self.alloc([2500, 2500], Decimal("100"), "간선"), [3000, 3000])
        self.assertTrue(self.uses([2500, 2500], Decimal("100")))

    def test_거리_합이_0이면_속도_검사_없이_운행시간을_쓴다(self):
        self.assertTrue(self.uses([0, 0, 0], Decimal("10")))

    def test_운행시간_None은_운행시간을_쓰지_않는다(self):
        self.assertFalse(self.uses([1001], None))

    def test_운행시간_0은_운행시간을_쓰지_않는다(self):
        self.assertFalse(self.uses([1001], Decimal("0")))


    def test_반올림_초가_0인_극소_운행시간은_비례_배분을_쓰지_않는다(self):
        # 0.001분 -> S=0, 예외 없이 False
        self.assertFalse(self.uses([1001], Decimal("0.001")))

    def test_반올림_초가_0인_극소_운행시간은_대체_속도로_계산한다(self):
        # 1001*3.6/13.4 = 268.925 -> 269
        self.assertEqual(self.alloc([1001], Decimal("0.001"), "간선"), [269])


if __name__ == "__main__":
    unittest.main()
