import SwiftUI

/// 기록·분석 화면 공통 틀(시안 R19·R23·R24): 화면 전체 지도 위에 떠 있는 패널(좌우 12, 바닥 20, 반경 28, 흰 20% 테두리)과
/// 패널 아래쪽 고정 "다음 여행 시작하기". 화면 구조(push·시스템 뒤로 버튼)는 그대로 두고 모양만 시안에 맞춘다.
@MainActor
struct RecordsPanelScreen<Content: View>: View {
    @Bindable var model: AppModel
    /// 내용이 짧으면 패널 높이를 내용에 맞추고 아래에 붙인다(R24). 아니면 패널이 화면을 채우고 안에서 스크롤한다(R19·R23).
    var hugsContent = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack(alignment: .bottom) {
            SceneMapBackdrop(model: model, showsStationAnnotation: false)
                .ignoresSafeArea()
            // 시안: 패널 위끝 y=116(내비 막대 바로 아래).
            panel
                .padding(.top, -2)
                .padding(.horizontal, 12).padding(.bottom, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .background(FMDesign.background.ignoresSafeArea())
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var panel: some View {
        VStack(spacing: 0) {
            if hugsContent {
                ViewThatFits(in: .vertical) {
                    inner
                    ScrollView { inner }.scrollIndicators(.hidden)
                }
            } else {
                ScrollView { inner }.scrollIndicators(.hidden)
            }
            // 시안: 패널 아래 고정 "다음 여행 시작하기"(335x43, 패널 안쪽 22, 아래 15). 진행 여정이 있으면 메인의 확인 창을 거쳐야 하므로 숨긴다.
            if model.activeJourney == nil {
                Button {
                    model.path.removeAll()
                    _ = model.startTripFromMain()
                } label: {
                    Text("다음 여행 시작하기").frame(maxWidth: .infinity)
                }
                .buttonStyle(FMPrimaryButtonStyle(size: .compact))
                .accessibilityIdentifier("records.startNext")
                .padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 15)
            }
        }
        .frame(maxWidth: .infinity)
        .background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 28))
        .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(FMDesign.panelStroke, lineWidth: 1) }
    }

    private var inner: some View {
        content()
            .padding(.top, 23).padding(.horizontal, 23).padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 시안 R19·R23 "잔디 / 분석" 탭 모양: 바깥 #181C19 반경 10·안쪽 3, 선택 칸 #303B34 반경 8, 12pt(선택 흰색·비선택 #BFC6C1).
/// 지금은 두 화면이 push로 나뉘어 있어 선택되지 않은 칸은 다른 화면으로 가는 버튼이다.
struct RecordsTabBar: View {
    struct Tab {
        let title: String
        let selected: Bool
        let identifier: String?
        let action: (() -> Void)?
    }
    let tabs: [Tab]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(tabs, id: \.title) { tab in
                if let action = tab.action {
                    Button(action: action) { label(tab) }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(tab.identifier ?? "")
                } else {
                    label(tab).accessibilityAddTraits(tab.selected ? .isSelected : [])
                }
            }
        }
        .padding(3)
        .background(Color(hex: 0x181C19), in: RoundedRectangle(cornerRadius: 10))
    }

    private func label(_ tab: Tab) -> some View {
        Text(tab.title).font(FontCatalog.text(12, relativeTo: .subheadline))
            .foregroundStyle(tab.selected ? Color.white : FMDesign.secondaryText)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(tab.selected ? Color(hex: 0x303B34) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
    }
}

extension Color {
    /// 저장된 "#RRGGBB" 기록 색. 형식이 틀리면 보조 글자색.
    init(hexString: String) {
        self.init(hex: UInt32(hexString.dropFirst(), radix: 16) ?? 0xBFC6C1)
    }
}
