import SwiftUI

/// 최초 1회 출발 정류장을 검색해 고르는 화면. 확인 버튼은 아래에 고정해 키보드·큰 글자에서도 닿게 한다.
@MainActor
struct InitialStationSearchView: View {
    @Bindable var model: AppModel
    @State private var search = StationSearchState()
    @FocusState private var searchFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // 검색은 그릴 때 한 번만 한다. 결과·선택·확인 버튼이 같은 결과를 쓴다.
        let result = model.routeCatalog.map(search.result(in:))
        let selected = result.flatMap(search.selectedOption(from:))
        GeometryReader { geometry in
          VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("출발 정류장").font(FontCatalog.style(.title2, weight: .bold)).accessibilityIdentifier("screen.initialStationEntry")
                    Text("출발 정류장을 골라주세요.").font(FontCatalog.style(.subheadline)).foregroundStyle(FMDesign.secondaryText)
                    if let notice = model.stationResetNotice {
                        Text(notice.text).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("search.resetNotice")
                    }
                    Text("정류장 검색").font(FontCatalog.style(.caption)).foregroundStyle(FMDesign.secondaryText)
                    TextField("정류장 이름 또는 번호", text: $search.query)
                        .textFieldStyle(.plain).padding(14)
                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.16)))
                        .autocorrectionDisabled()
                        .focused($searchFocused)
                        .submitLabel(.search)
                        .onSubmit { searchFocused = false }
                        .accessibilityLabel("정류장 검색").accessibilityIdentifier("search.query")
                    results(result, selected: selected)
                }.padding(.bottom, 8)
            }
            .accessibilityIdentifier("search.scroll")
            .scrollDismissesKeyboard(.immediately)
            if model.saveFailure != nil {
                Text("출발 정류장 저장에 실패했어요. 확인을 다시 눌러 주세요.")
                    .foregroundStyle(.secondary).accessibilityIdentifier("search.saveFailure")
            }
            Button("확인") {
                if let selected { model.confirmInitialStation(selected) }
            }
            .buttonStyle(FMPrimaryButtonStyle(size: .compact)).frame(maxWidth: .infinity)
            .disabled(selected == nil)
            .accessibilityHint("고른 정류장에서 출발해요").accessibilityIdentifier("search.confirm")
        }
            .foregroundStyle(FMDesign.primary)
            .frame(maxHeight: typeSize.isAccessibilitySize || searchFocused
                ? max(0, geometry.size.height - 44) : max(0, geometry.size.height * 0.68 - 44))
            .fmPanel(padding: 22)
          }
        }
    }

    @ViewBuilder private func results(_ result: StationSearchResult?, selected: StopSearchOption?) -> some View {
        switch (model.routeAvailability, result) {
        case (.loading, _):
            Text(ProceedState.routeDataLoading.title).foregroundStyle(.secondary).accessibilityIdentifier("search.loading")
        case (.failed, _), (_, nil):
            Text(ProceedState.routeDataFailed.title).foregroundStyle(.secondary).accessibilityIdentifier("search.loadFailed")
        case let (.ready(catalog), result?):
            switch result {
            case .prompt:
                Text("정류장 이름이나 번호를 입력하세요").foregroundStyle(.secondary).accessibilityIdentifier("search.prompt")
            case .empty:
                Text("결과가 없어요").foregroundStyle(.secondary).accessibilityIdentifier("search.empty")
            case let .results(options, overflow):
                ForEach(options) { option in resultButton(option, selected: selected, catalog: catalog) }
                if overflow {
                    Text("결과가 많아요. 더 자세히 입력해 주세요").foregroundStyle(.secondary)
                        .accessibilityIdentifier("search.overflow")
                }
                if let selected {
                    Text(StationSearchState.confirmationText(for: selected)).accessibilityIdentifier("search.confirmation")
                }
            }
        }
    }

    private func resultButton(_ option: StopSearchOption, selected: StopSearchOption?, catalog: RouteCatalog) -> some View {
        let isSelected = selected?.id == option.id
        return Button {
            _ = search.select(option.id, in: catalog)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.name).font(FontCatalog.style(.headline, weight: .semibold))
                    if let ars = option.ars { Text(ars).foregroundStyle(.secondary) }
                    if let bound = option.boundLabel { Text(bound).foregroundStyle(.secondary) }
                }
                Spacer(minLength: 0)
                if isSelected { Image(systemName: "checkmark.circle.fill") }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(FMDesign.primary)
            .background(Color(white: 0.067), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(isSelected ? 1 : 0.14)))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(option.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("search.result.\(option.id)")
    }
}
