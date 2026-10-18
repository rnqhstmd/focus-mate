import SwiftUI

/// 데이터 출처 화면 문구(FR-10, AC-49). 공공누리 제1유형은 출처 표시가 조건이다.
struct DataSourceContent: Equatable {
    static let processingNoticeText = "구간 시간과 거리는 원천 데이터를 가공·계산한 값이에요"

    let copyrightText: String
    let providerText: String
    let datasetTexts: [String]
    let licenseText: String
    let baseDateText: String
    /// 원천 페이지 주소. 오프라인 앱이라 링크 동작 없이 글자로만 보인다(FR-12).
    let sourceURLs: [String]
    let processingNotice: String

    init(metadata: RouteDataMetadata) {
        copyrightText = metadata.copyright
        providerText = metadata.provider
        datasetTexts = ["\(metadata.dataset) (\(metadata.datasetID))",
                        "\(metadata.routeInfoDataset) (\(metadata.routeInfoDatasetID))"]
        licenseText = metadata.license
        baseDateText = "데이터 기준일 \(Self.dottedDate(metadata.baseDate))"
        sourceURLs = [metadata.sourceURL, metadata.routeInfoSourceURL]
        processingNotice = Self.processingNoticeText
    }

    private init(baseDateText: String) {
        copyrightText = "서울특별시"
        providerText = "서울 열린데이터광장"
        datasetTexts = ["서울시버스노선별정류소정보 (OA-1095)", "서울시버스노선기본정보 (OA-15066)"]
        licenseText = "공공누리 제1유형"
        self.baseDateText = baseDateText
        sourceURLs = ["https://data.seoul.go.kr/dataList/OA-1095/F/1/datasetView.do",
                      "https://data.seoul.go.kr/dataList/OA-15066/F/1/datasetView.do"]
        processingNotice = Self.processingNoticeText
    }

    /// 정류장 데이터를 읽지 못했을 때도 출처는 보이고 기준일만 알 수 없다고 한다(BR-17). 실데이터 회귀 테스트가 번들 값과 맞는지 본다.
    static let unavailable = DataSourceContent(baseDateText: "데이터 기준일 확인할 수 없어요")

    /// "2026-09-02" → "2026.09.02". 형식이 다르면 원문 그대로 둔다.
    private static func dottedDate(_ text: String) -> String {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        let lengths = parts.map(\.count)
        guard lengths == [4, 2, 2], parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }) else { return text }
        return parts.joined(separator: ".")
    }
}

/// 마이페이지 → 데이터 출처. 큰 글자에서도 전체를 스크롤로 읽을 수 있고 줄 수 제한이 없다.
@MainActor
struct DataSourceView: View {
    @Bindable var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(Destination.dataSource.title).font(FontCatalog.text(23, weight: .bold, relativeTo: .title2)).accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("screen.dataSource")
                switch model.routeAvailability {
                case .loading:
                    Text(ProceedState.routeDataLoading.title).foregroundStyle(FMDesign.secondaryText)
                        .accessibilityIdentifier("dataSource.loading")
                case .failed:
                    Text(ProceedState.routeDataFailed.title).foregroundStyle(FMDesign.secondaryText)
                        .accessibilityIdentifier("dataSource.failed")
                    content(.unavailable)
                case let .ready(catalog):
                    content(DataSourceContent(metadata: catalog.metadata))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fmPanel()
            .padding(.horizontal, 12).padding(.vertical, 20)
        }
        .background(FMDesign.background.ignoresSafeArea())
        .foregroundStyle(FMDesign.primary).tint(FMDesign.primary)
        .font(FontCatalog.text(15))
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func content(_ content: DataSourceContent) -> some View {
        line(content.copyrightText, id: "dataSource.copyright")
        line(content.providerText, id: "dataSource.provider")
        ForEach(Array(content.datasetTexts.enumerated()), id: \.offset) { index, text in
            line(text, id: "dataSource.dataset.\(index)")
        }
        line(content.licenseText, id: "dataSource.license")
        line(content.baseDateText, id: "dataSource.baseDate")
        ForEach(Array(content.sourceURLs.enumerated()), id: \.offset) { index, url in
            Text(url).font(FontCatalog.text(12, relativeTo: .footnote)).foregroundStyle(FMDesign.secondaryText).textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("dataSource.url.\(index)")
        }
        line(content.processingNotice, id: "dataSource.processing")
    }

    private func line(_ text: String, id: String) -> some View {
        Text(text).fixedSize(horizontal: false, vertical: true).accessibilityIdentifier(id)
    }
}
