import SwiftUI

/// 메인 위에 쌓이는 목적지 화면.
@MainActor
struct DestinationScreen: View {
    let destination: Destination
    @Bindable var model: AppModel
    let onCardCustomization: () -> Void
    let services: JourneyServices

    var body: some View {
        // 마이페이지는 시안대로 자체 여백·좌측 제목을 쓰므로 공통 자리표시 체인 밖에서 그린다.
        if destination == .profile {
            ProfileView(model: model, onCustomize: onCardCustomization)
        } else if destination == .board {
            BoardingPassView(model: model)
        } else if destination == .boarding {
            BoardingTagView(model: model, services: services)
        } else if destination == .journey {
            JourneyView(model: model, services: services)
        } else if destination == .alighting {
            AlightingTagView(model: model, services: services)
        } else if destination == .alightingSummary {
            AlightingSummaryView(model: model, services: services)
        } else if destination == .records {
            RecordsView(model: model, services: services)
        } else if destination == .dataSource {
            DataSourceView(model: model)
        } else if destination == .settings {
            SettingsPlaceholderView(model: model)
        } else {
            placeholderOrTime
        }
    }

    private var placeholderOrTime: some View {
        Group {
            if destination == .time {
                TimeSelectionView(model: model)
            } else if destination == .preparation {
                PreparationView(model: model)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text(destination.title).font(FontCatalog.style(.largeTitle, weight: .bold))
                        .accessibilityIdentifier("screen.\(destination.rawValue)")
                    Spacer()
                }
            }
        }
        .padding(destination == .preparation || destination == .time ? 0 : 24).frame(maxWidth: .infinity, alignment: .leading)
        .navigationTitle(destination == .preparation || destination == .time ? "" : destination.title).navigationBarTitleDisplayMode(.inline)
        #if DEBUG
        .overlay(alignment: .bottomLeading) {
            if destination == .preparation {
                Text("여정 선택 진단").accessibilityValue(journeySelectionJSON).accessibilityIdentifier("test.journeySelection")
                    .font(.system(size: 1)).foregroundStyle(.clear)
            }
        }
        #endif
    }

    #if DEBUG
    /// 준비 화면이 받은 여정 선택(W03 전까지 화면에 쓰지 않는 값)을 UI 테스트가 확인하도록 내보낸다.
    private var journeySelectionJSON: String {
        guard let selection = model.preparedJourney else { return "null" }
        let object: [String: Any] = ["busID": selection.busID, "busNumber": selection.busNumber,
                                     "destination": selection.destination, "minutes": selection.minutes,
                                     "stops": selection.stops]
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else { return "null" }
        return json
    }
    #endif
}

/// 설정 자리표시(시안 R20 패널 모양만). 설정 기능(동작 줄이기 등)은 아직 없다.
/// 공공데이터 출처 표기 의무 때문에 '데이터 출처' 진입은 여기에 둔다(마이페이지 줄은 F단계에서 뺀다).
@MainActor
struct SettingsPlaceholderView: View {
    @Bindable var model: AppModel

    var body: some View {
        ZStack(alignment: .bottom) {
            SceneMapBackdrop(model: model, showsStationAnnotation: false)
                .ignoresSafeArea()
            // 시안 R20: 아래 시트(좌우 12, 바닥 25, 반경 28, 흰 20% 테두리), 안쪽 23, 제목 위 33.
            VStack(alignment: .leading, spacing: 0) {
                Text(Destination.settings.title).font(FontCatalog.text(22, weight: .bold, relativeTo: .title2))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("screen.settings")
                Text("Focus Mate").font(FontCatalog.text(15, relativeTo: .body)).foregroundStyle(FMDesign.hintText)
                    .padding(.top, 25)
                Button { model.open(.dataSource) } label: {
                    HStack(spacing: 6) {
                        Text(Destination.dataSource.title).underline()
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .regular)).accessibilityHidden(true)
                    }
                    .font(FontCatalog.text(11, relativeTo: .footnote))
                    .foregroundStyle(Color(hex: 0xDDDDDD))
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Destination.dataSource.title)
                .accessibilityIdentifier("settings.dataSource")
                .padding(.top, 14)
            }
            .padding(.top, 28).padding(.horizontal, 23).padding(.bottom, 26)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 28))
            .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(FMDesign.panelStroke, lineWidth: 1) }
            .padding(.horizontal, 12).padding(.bottom, 25)
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .background(FMDesign.background.ignoresSafeArea())
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
