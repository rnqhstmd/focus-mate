import XCTest
@testable import FocusMate

/// W16b AC-49 데이터 출처 화면 문구 모델. 기댓값은 손으로 쓴 리터럴이다.
final class DataSourceContentTests: XCTestCase {
    private func metadata(baseDate: String = "2026-09-02") -> RouteDataMetadata {
        RouteDataMetadata(
            baseDate: baseDate,
            dataset: "서울시버스노선별정류소정보",
            datasetID: "OA-1095",
            provider: "서울 열린데이터광장",
            copyright: "서울특별시",
            license: "공공누리 제1유형",
            routeInfoDataset: "서울시버스노선기본정보",
            routeInfoDatasetID: "OA-15066",
            stopsFile: "stops.csv",
            routeInfoFile: "routes.csv",
            sourceURL: "https://data.seoul.go.kr/dataList/OA-1095/F/1/datasetView.do",
            routeInfoSourceURL: "https://data.seoul.go.kr/dataList/OA-15066/F/1/datasetView.do"
        )
    }

    // 깨짐 명명: 저작권자·제공처·라이선스를 서로 바꾸거나 빠뜨리면 실패.
    func testAC49_저작권자_제공처_라이선스를_메타데이터에서_그대로_보인다() {
        let content = DataSourceContent(metadata: metadata())

        XCTAssertEqual(content.copyrightText, "서울특별시")
        XCTAssertEqual(content.providerText, "서울 열린데이터광장")
        XCTAssertEqual(content.licenseText, "공공누리 제1유형")
    }

    // 깨짐 명명: 데이터셋 순서가 바뀌거나 ID 괄호 형식이 달라지면 실패.
    func testAC49_데이터셋_둘은_이름과_ID를_괄호로_묶어_순서대로_보인다() {
        let content = DataSourceContent(metadata: metadata())

        XCTAssertEqual(content.datasetTexts, [
            "서울시버스노선별정류소정보 (OA-1095)",
            "서울시버스노선기본정보 (OA-15066)",
        ])
    }

    // 깨짐 명명: 기준일 점 표기 변환이 빠지거나 접두 문구가 달라지면 실패.
    func testAC49_기준일은_점_구분으로_보인다() {
        XCTAssertEqual(DataSourceContent(metadata: metadata()).baseDateText, "데이터 기준일 2026.09.02")
    }

    // 깨짐 명명: 형식 검증 없이 '-'를 치환하면(예: "09/02/2026" 또는 "2026-9-2") 실패.
    func testAC49_기준일이_yyyyMMdd_형식이_아니면_원문을_그대로_보인다() {
        XCTAssertEqual(DataSourceContent(metadata: metadata(baseDate: "2026-9-2")).baseDateText, "데이터 기준일 2026-9-2")
        XCTAssertEqual(DataSourceContent(metadata: metadata(baseDate: "20260902")).baseDateText, "데이터 기준일 20260902")
        XCTAssertEqual(DataSourceContent(metadata: metadata(baseDate: "")).baseDateText, "데이터 기준일 ")
    }

    // 깨짐 명명: 원천 주소 순서가 바뀌거나 하나만 보이면 실패.
    func testAC49_원천_페이지_주소_둘을_순서대로_보인다() {
        XCTAssertEqual(DataSourceContent(metadata: metadata()).sourceURLs, [
            "https://data.seoul.go.kr/dataList/OA-1095/F/1/datasetView.do",
            "https://data.seoul.go.kr/dataList/OA-15066/F/1/datasetView.do",
        ])
    }

    // 깨짐 명명: 가공 고지 문구가 빠지거나 달라지면 실패.
    func testAC49_가공_고지_문구가_고정이다() {
        XCTAssertEqual(
            DataSourceContent(metadata: metadata()).processingNotice,
            "구간 시간과 거리는 원천 데이터를 가공·계산한 값이에요"
        )
    }

    // 깨짐 명명: 번들 픽스처 메타데이터와 다른 값을 하드코딩하면 실패.
    func testAC49_번들_픽스처_메타데이터로도_같은_문구가_나온다() {
        let content = DataSourceContent(metadata: RouteCatalog.fixtureMetadata)

        XCTAssertEqual(content.baseDateText, "데이터 기준일 2026.09.02")
        XCTAssertEqual(content.datasetTexts.first, "서울시버스노선별정류소정보 (OA-1095)")
    }

    // MARK: BR-17 unavailable

    // 깨짐: 메타데이터를 읽을 수 없을 때 쓰는 고정 문구(출처·라이선스·데이터셋·주소·가공 고지)가 명세와 다르면 실패한다.
    func testBR17_unavailable은_고정_문구와_기준일_확인불가를_보인다() {
        let content = DataSourceContent.unavailable

        XCTAssertEqual(content.copyrightText, "서울특별시")
        XCTAssertEqual(content.providerText, "서울 열린데이터광장")
        XCTAssertEqual(content.datasetTexts, [
            "서울시버스노선별정류소정보 (OA-1095)",
            "서울시버스노선기본정보 (OA-15066)",
        ])
        XCTAssertEqual(content.licenseText, "공공누리 제1유형")
        XCTAssertEqual(content.baseDateText, "데이터 기준일 확인할 수 없어요")
        XCTAssertEqual(content.sourceURLs, [
            "https://data.seoul.go.kr/dataList/OA-1095/F/1/datasetView.do",
            "https://data.seoul.go.kr/dataList/OA-15066/F/1/datasetView.do",
        ])
        XCTAssertEqual(content.processingNotice, "구간 시간과 거리는 원천 데이터를 가공·계산한 값이에요")
    }
}
