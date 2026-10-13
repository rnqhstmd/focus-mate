import SwiftUI

/// 최초 1회 출발 정류장을 검색해 고르는 화면. 확인 버튼은 아래에 고정해 키보드·큰 글자에서도 닿게 한다.
@MainActor
struct InitialStationSearchView: View {
    @Bindable var model: AppModel
    @State private var search = StationSearchState()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최초 정류장 설정").font(.largeTitle.bold()).accessibilityIdentifier("screen.initialStationEntry")
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("정류장 검색", text: $search.query)
                        .textFieldStyle(.roundedBorder).autocorrectionDisabled()
                        .accessibilityLabel("정류장 검색").accessibilityIdentifier("search.query")
                    if search.results.isEmpty {
                        Text("결과가 없어요").foregroundStyle(.secondary).accessibilityIdentifier("search.empty")
                    }
                    ForEach(search.results) { option in
                        resultButton(option)
                    }
                    if let confirmation = search.confirmationText {
                        Text(confirmation).accessibilityIdentifier("search.confirmation")
                    }
                }
            }
            if model.saveFailure != nil {
                Text("출발 정류장 저장에 실패했어요. 확인을 다시 눌러 주세요.")
                    .foregroundStyle(.secondary).accessibilityIdentifier("search.saveFailure")
            }
            Button("확인") {
                if let option = search.selectedOption { model.confirmInitialStation(option) }
            }
            .buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
            .disabled(!search.canConfirm)
            .accessibilityHint("고른 정류장에서 출발해요").accessibilityIdentifier("search.confirm")
        }
    }

    private func resultButton(_ option: StationOption) -> some View {
        let isSelected = search.selectedOption == option
        return Button {
            _ = search.select(option.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.name).font(.headline)
                    Text(option.boundLabel).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if isSelected { Image(systemName: "checkmark.circle.fill") }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(option.name), \(option.boundLabel)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("search.result.\(option.id)")
    }
}
