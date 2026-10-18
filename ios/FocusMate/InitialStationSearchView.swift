import SwiftUI

/// 최초 1회 출발 정류장을 검색해 고르는 화면. 확인 버튼은 아래에 고정해 키보드·큰 글자에서도 닿게 한다.
@MainActor
struct InitialStationSearchView: View {
    @Bindable var model: AppModel
    @State private var search = StationSearchState()
    @FocusState private var searchFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var contentHeight: CGFloat = 0
    @State private var panelHeight: CGFloat = 0

    var body: some View {
        // 검색은 그릴 때 한 번만 한다. 결과·선택·확인 버튼이 같은 결과를 쓴다.
        let result = model.routeCatalog.map(search.result(in:))
        let selected = result.flatMap(search.selectedOption(from:))
        GeometryReader { geometry in
          ZStack(alignment: .bottom) {
            SceneMapBackdrop(model: model, bottomInset: panelHeight + 20,
                             fallbackCoordinate: SceneMapBackdrop.defaultCoordinate)
                .ignoresSafeArea()
            VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("출발 정류장").font(FontCatalog.text(20, weight: .bold, relativeTo: .title2))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("screen.initialStationEntry")
                        .padding(.leading, -3)
                    Text("출발 정류장을 골라주세요.").font(FontCatalog.text(12.5, relativeTo: .subheadline))
                        .foregroundStyle(FMDesign.tertiaryText)
                        .padding(.top, 16)
                    if let notice = model.stationResetNotice {
                        Text(notice.text).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)
                            .accessibilityIdentifier("search.resetNotice")
                    }
                    Text("정류장 검색").font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(FMDesign.hintText)
                        .padding(.top, 9)
                    searchField.padding(.top, 6)
                    VStack(alignment: .leading, spacing: 11) {
                        results(result, selected: selected)
                    }
                    .padding(.top, 11)
                }
                .padding(.horizontal, 18).padding(.vertical, 2)
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(key: SearchContentHeightKey.self, value: proxy.size.height)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(height: contentHeight > 0 ? min(contentHeight, max(160, scrollLimit(in: geometry))) : nil)
            .onPreferenceChange(SearchContentHeightKey.self) { contentHeight = $0 }
            .accessibilityIdentifier("search.scroll")
            .scrollDismissesKeyboard(.immediately)
            if model.saveFailure != nil {
                Text("출발 정류장 저장에 실패했어요. 확인을 다시 눌러 주세요.")
                    .foregroundStyle(.secondary).padding(.horizontal, 18).padding(.top, 8)
                    .accessibilityIdentifier("search.saveFailure")
            }
            Button(selected.map(StationSearchState.confirmationText(for:)) ?? "출발 정류장을 골라주세요") {
                if let selected { model.confirmInitialStation(selected) }
            }
            .buttonStyle(FMPrimaryButtonStyle(size: .compact)).frame(maxWidth: .infinity)
            .disabled(selected == nil)
            .accessibilityHint("고른 정류장에서 출발해요").accessibilityIdentifier("search.confirm")
            .padding(.horizontal, 16).padding(.top, 20)
            // 선택 확인 문장은 버튼 라벨로 보인다. 기존 확인 요소는 낭독·검증용으로만 남긴다.
            .overlay(alignment: .topLeading) {
                if let selected {
                    Color.clear.frame(width: 1, height: 1)
                        .accessibilityElement()
                        .accessibilityLabel(StationSearchState.confirmationText(for: selected))
                        .accessibilityHidden(false)
                        .accessibilityIdentifier("search.confirmation")
                }
            }
        }
            .padding(.top, 21).padding(.bottom, 15)
            .foregroundStyle(FMDesign.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 28))
            .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(FMDesign.panelStroke, lineWidth: 1) }
            .padding(.horizontal, 12)
            .background {
                GeometryReader { proxy in
                    Color.clear.onAppear { panelHeight = proxy.size.height }
                        .onChange(of: proxy.size.height) { _, value in panelHeight = value }
                }
            }
            .padding(.bottom, searchFocused ? 8 : 20)
            }
            .ignoresSafeArea(.container, edges: .bottom)
          }
        }
    }

    /// 패널 안 스크롤 영역의 최대 높이. 큰 글자·키보드에서는 화면을 거의 다 쓴다.
    private func scrollLimit(in geometry: GeometryProxy) -> CGFloat {
        let fraction: CGFloat = typeSize.isAccessibilitySize || searchFocused ? 1 : 0.72
        return geometry.size.height * fraction - 140
    }

    private var searchField: some View {
        let active = searchFocused || !search.query.isEmpty
        return HStack(spacing: 8) {
            TextField("정류장 이름 또는 번호", text: $search.query)
                .textFieldStyle(.plain)
                .font(FontCatalog.text(15, relativeTo: .body))
                .autocorrectionDisabled()
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { searchFocused = false }
                .accessibilityLabel("정류장 검색").accessibilityIdentifier("search.query")
            if !search.query.isEmpty {
                Button { search.query = "" } label: {
                    Image(systemName: "xmark").font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: 0x3B6FD8))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, -12)
                .accessibilityLabel("검색어 지우기")
                .accessibilityIdentifier("search.clear")
            }
        }
        .padding(.leading, 12).padding(.trailing, 18)
        .frame(minHeight: 47)
        .background(FMDesign.rowFill, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(active ? Color(hex: 0xD7B378) : FMDesign.ctaStroke, lineWidth: active ? 1.5 : 1)
        }
    }

    @ViewBuilder private func results(_ result: StationSearchResult?, selected: StopSearchOption?) -> some View {
        switch (model.routeAvailability, result) {
        case (.loading, _):
            Text(ProceedState.routeDataLoading.title).font(FontCatalog.text(12.5, relativeTo: .subheadline)).foregroundStyle(FMDesign.hintText).accessibilityIdentifier("search.loading")
        case (.failed, _), (_, nil):
            Text(ProceedState.routeDataFailed.title).font(FontCatalog.text(12.5, relativeTo: .subheadline)).foregroundStyle(FMDesign.hintText).accessibilityIdentifier("search.loadFailed")
        case let (.ready(catalog), result?):
            switch result {
            case .prompt:
                Text("정류장 이름이나 번호를 입력하세요").font(FontCatalog.text(12.5, relativeTo: .subheadline)).foregroundStyle(FMDesign.hintText).accessibilityIdentifier("search.prompt")
            case .empty:
                Text("결과가 없어요").font(FontCatalog.text(12.5, relativeTo: .subheadline)).foregroundStyle(FMDesign.hintText).accessibilityIdentifier("search.empty")
            case let .results(options, overflow):
                ForEach(options) { option in resultButton(option, selected: selected, catalog: catalog) }
                if overflow {
                    Text("결과가 많아요. 더 자세히 입력해 주세요").font(FontCatalog.text(12.5, relativeTo: .subheadline)).foregroundStyle(FMDesign.hintText)
                        .accessibilityIdentifier("search.overflow")
                }
            }
        }
    }

    private func resultButton(_ option: StopSearchOption, selected: StopSearchOption?, catalog: RouteCatalog) -> some View {
        let isSelected = selected?.id == option.id
        return Button {
            _ = search.select(option.id, in: catalog)
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(option.name).font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
                    Text(Self.detail(for: option)).font(FontCatalog.text(10, relativeTo: .caption))
                        .foregroundStyle(FMDesign.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "scope").font(.system(size: 12, weight: .light))
                    .accessibilityHidden(true)
            }
            .padding(.leading, 13).padding(.trailing, 14).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 67, alignment: .leading)
            .foregroundStyle(FMDesign.primary)
            .background(FMDesign.rowFill, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(isSelected ? Color.white : FMDesign.ctaStroke, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(option.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("search.result.\(option.id)")
    }

    /// 시안 "서울 성동구 · 성수동 방면 승차장" 한 줄. 자치구 정보가 없어 정류장 번호(ARS)를 앞에 둔다.
    static func detail(for option: StopSearchOption) -> String {
        [option.ars, option.boundLabel.map { "\($0) 승차장" }].compactMap { $0 }.joined(separator: " · ")
    }
}

private enum SearchContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
