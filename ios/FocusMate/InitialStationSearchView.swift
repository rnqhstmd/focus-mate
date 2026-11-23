import SwiftUI

/// 정류장을 검색한 뒤 지도와 노선 정보를 보고 출발지를 확정한다.
@MainActor
struct InitialStationSearchView: View {
    @Bindable var model: AppModel
    private let onConfirm: ((StopSearchOption) -> Void)?

    private enum AccessibilityTarget: Hashable {
        case query
        case preview
        case result(String)
        case saveFailure
    }

    @State private var search = StationSearchState()
    @FocusState private var searchFocused: Bool
    @AccessibilityFocusState private var accessibilityTarget: AccessibilityTarget?
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var contentHeight: CGFloat = 0
    @State private var panelHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    @State private var footerHeight: CGFloat = 0
    @State private var attemptedConfirmation = false

    init(model: AppModel, onConfirm: ((StopSearchOption) -> Void)? = nil) {
        self.model = model
        self.onConfirm = onConfirm
    }

    var body: some View {
        let catalog = model.routeCatalog
        let result = catalog.map(search.result(in:))
        let selected = result.flatMap(search.selectedOption(from:))
        let bottomPadding: CGFloat = searchFocused ? 8 : 20

        GeometryReader { geometry in
            ZStack(alignment: selected == nil ? .top : .bottom) {
                SceneMapBackdrop(model: model, stationID: selected?.id,
                                 bottomInset: panelHeight + bottomPadding, isStationSearchPreview: true)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 12) {
                    searchHeader
                        .background {
                            GeometryReader { header in
                                Color.clear.preference(key: SearchHeaderHeightKey.self, value: header.size.height)
                            }
                        }
                    searchContent(result, selected: selected, catalog: catalog,
                                  heightLimit: selected.map { _ in previewHeightLimit(in: geometry.size.height) })
                    if let selected {
                        footer(selected: selected)
                            .background {
                                GeometryReader { footer in
                                    Color.clear.preference(key: SearchFooterHeightKey.self, value: footer.size.height)
                                }
                            }
                    }
                }
                .padding(.vertical, 16)
                .foregroundStyle(FMDesign.primary)
                .frame(maxWidth: .infinity, maxHeight: selected == nil ? .infinity : nil, alignment: .topLeading)
                .background {
                    if selected != nil {
                        RoundedRectangle(cornerRadius: 28).fill(FMDesign.panel)
                            .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(FMDesign.panelStroke, lineWidth: 1) }
                    }
                }
                .padding(.horizontal, 12)
                .background {
                    GeometryReader { panel in
                        Color.clear.preference(key: SearchPanelHeightKey.self, value: panel.size.height)
                    }
                }
                .padding(.bottom, bottomPadding)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .onPreferenceChange(SearchPanelHeightKey.self) { panelHeight = $0 }
            .onPreferenceChange(SearchHeaderHeightKey.self) { headerHeight = $0 }
            .onPreferenceChange(SearchFooterHeightKey.self) { footerHeight = $0 }
        }
        .background(FMDesign.background.ignoresSafeArea())
    }

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(onConfirm == nil ? "출발 정류장" : "출발 정류장 변경")
                .font(FontCatalog.text(20, weight: .bold, relativeTo: .title2))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("screen.initialStationEntry")
            if let notice = model.stationResetNotice, onConfirm == nil {
                Text(notice.text)
                    .font(FontCatalog.style(.subheadline)).foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("search.resetNotice")
            }
            searchField
        }
        .padding(.horizontal, 18)
    }

    private func searchContent(_ result: StationSearchResult?, selected: StopSearchOption?,
                               catalog: RouteCatalog?, heightLimit: CGFloat?) -> some View {
        ScrollViewReader { scroll in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let selected, let catalog {
                        preview(selected, catalog: catalog).id(AccessibilityTarget.preview)
                    } else {
                        results(result)
                    }
                }
                .padding(.horizontal, 18).padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    GeometryReader { content in
                        Color.clear.preference(key: SearchContentHeightKey.self, value: content.size.height)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.immediately)
            .frame(height: heightLimit.map { contentHeight > 0 ? min(contentHeight, $0) : $0 })
            .onPreferenceChange(SearchContentHeightKey.self) { contentHeight = $0 }
            .accessibilityIdentifier("search.scroll")
            .onChange(of: search.query) { _, _ in
                if case let .results(options, _)? = result, let first = options.first {
                    scroll.scrollTo(AccessibilityTarget.result(first.id), anchor: .top)
                }
            }
            .onChange(of: search.selectedID) { previous, current in
                attemptedConfirmation = false
                if current != nil {
                    scroll.scrollTo(AccessibilityTarget.preview, anchor: .top)
                } else if let previous, !searchFocused {
                    if case let .results(options, _)? = result, options.contains(where: { $0.id == previous }) {
                        let target = AccessibilityTarget.result(previous)
                        scroll.scrollTo(target, anchor: .center)
                        accessibilityTarget = target
                    } else {
                        accessibilityTarget = .query
                    }
                }
            }
        }
    }

    private func previewHeightLimit(in height: CGFloat) -> CGFloat {
        let fraction: CGFloat = typeSize.isAccessibilitySize || searchFocused ? 1 : 0.73
        return max(56, height * fraction - max(80, headerHeight) - max(56, footerHeight) - 56)
    }

    private var searchField: some View {
        let active = searchFocused || !search.query.isEmpty
        return HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(FMDesign.hintText).accessibilityHidden(true)
            TextField("정류장 이름 또는 번호", text: $search.query)
                .textFieldStyle(.plain)
                .font(FontCatalog.text(15, relativeTo: .body))
                .autocorrectionDisabled()
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { searchFocused = false }
                .accessibilityLabel("정류장 검색")
                .accessibilityIdentifier("search.query")
                .accessibilityFocused($accessibilityTarget, equals: .query)
            if !search.query.isEmpty {
                Button { search.query = "" } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(FMDesign.secondaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, -10)
                .accessibilityLabel("검색어 지우기")
                .accessibilityIdentifier("search.clear")
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 48)
        .background(FMDesign.rowFill, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(active ? Color(hex: 0xD7B378) : FMDesign.ctaStroke, lineWidth: active ? 1.5 : 1)
        }
    }

    @ViewBuilder private func results(_ result: StationSearchResult?) -> some View {
        switch (model.routeAvailability, result) {
        case (.loading, _):
            status(ProceedState.routeDataLoading.title, id: "search.loading")
        case (.failed, _), (_, nil):
            status("정류장 정보를 불러오지 못했어요", id: "search.loadFailed")
            Button { model.startRouteData(retryFailed: true) } label: {
                Text("정류장 정보 다시 불러오기").frame(minHeight: 44).contentShape(Rectangle())
            }
            .accessibilityIdentifier("search.retry")
        case let (.ready, result?):
            switch result {
            case .prompt:
                status("정류장 이름이나 번호를 입력하세요", id: "search.prompt")
            case .empty:
                status("결과가 없어요", id: "search.empty")
            case let .results(options, overflow):
                ForEach(options) { option in
                    resultButton(option, from: result).id(AccessibilityTarget.result(option.id))
                }
                if overflow {
                    status("결과가 많아요. 더 자세히 입력해 주세요", id: "search.overflow")
                }
            }
        }
    }

    private func status(_ message: String, id: String) -> some View {
        Text(message).font(FontCatalog.style(.subheadline)).foregroundStyle(FMDesign.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier(id)
    }

    private func resultButton(_ option: StopSearchOption, from result: StationSearchResult) -> some View {
        Button {
            guard search.select(option.id, from: result) else { return }
            searchFocused = false
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.name).font(FontCatalog.text(16, weight: .bold, relativeTo: .headline))
                    if let bound = option.boundLabel {
                        Text(bound).font(FontCatalog.style(.subheadline)).foregroundStyle(FMDesign.secondaryText)
                    }
                    if let ars = option.ars {
                        Text("정류장 번호 \(ars)").font(FontCatalog.style(.caption)).foregroundStyle(FMDesign.secondaryText)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FMDesign.hintText)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(FMDesign.rowFill, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(FMDesign.ctaStroke, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(option.accessibilityLabel)
        .accessibilityHint("정류장 미리보기를 열어요.")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("search.result.\(option.id)")
        .accessibilityFocused($accessibilityTarget, equals: .result(option.id))
    }

    private func preview(_ option: StopSearchOption, catalog: RouteCatalog) -> some View {
        let numbers = option.servingBusNumbers(in: catalog)
        let displayLimit = 4
        let displayedNumbers = numbers.prefix(displayLimit).joined(separator: ", ")
        let extra = numbers.count - displayLimit
        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("선택한 출발 정류장").font(FontCatalog.style(.caption, weight: .semibold))
                    .foregroundStyle(FMDesign.secondaryText)
                Text(option.name).font(FontCatalog.text(23, weight: .bold, relativeTo: .title2))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("search.confirmation")
                    .accessibilityFocused($accessibilityTarget, equals: .preview)
                    .onAppear { accessibilityTarget = .preview }
                if let bound = option.boundLabel {
                    Text(bound).font(FontCatalog.style(.subheadline))
                        .accessibilityIdentifier("search.previewDirection")
                }
                if let ars = option.ars {
                    Text("정류장 번호 \(ars)").font(FontCatalog.style(.caption)).foregroundStyle(FMDesign.secondaryText)
                        .accessibilityIdentifier("search.previewARS")
                }
            }
            if !numbers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("정차 노선").font(FontCatalog.style(.caption, weight: .semibold))
                        .foregroundStyle(FMDesign.secondaryText)
                    Text(extra > 0 ? "\(displayedNumbers) 외 \(extra)개" : displayedNumbers)
                        .font(FontCatalog.style(.subheadline))
                        .accessibilityIdentifier("search.previewRoutes")
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FMDesign.rowFill, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(FMDesign.ctaStroke, lineWidth: 1))
    }

    private func footer(selected: StopSearchOption) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 10))
        return VStack(alignment: .leading, spacing: 8) {
            if attemptedConfirmation, model.saveFailure != nil {
                Text("출발 정류장 저장에 실패했어요. 확인을 다시 눌러 주세요.")
                    .font(FontCatalog.style(.subheadline)).foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("search.saveFailure")
                    .accessibilityFocused($accessibilityTarget, equals: .saveFailure)
                    .onAppear { accessibilityTarget = .saveFailure }
            }
            layout {
                Button("다시 선택") { search.clearSelection() }
                    .buttonStyle(FMSecondaryButtonStyle())
                    .accessibilityIdentifier("search.reselect")
                Button(confirmationTitle) {
                    attemptedConfirmation = true
                    if let onConfirm { onConfirm(selected) }
                    else { model.confirmInitialStation(selected) }
                }
                .buttonStyle(FMPrimaryButtonStyle(size: .compact))
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("search.confirm")
            }
        }
        .padding(.horizontal, 16)
    }

    private var confirmationTitle: String {
        onConfirm == nil ? "출발지로 선택" : "출발지 변경"
    }
}

private enum SearchContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private enum SearchPanelHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private enum SearchHeaderHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private enum SearchFooterHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
