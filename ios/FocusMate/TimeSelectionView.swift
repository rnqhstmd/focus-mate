import SwiftUI

/// 저장된 현재 정류장에서 출발하는 시간·버스·도착지 선택 화면(시안 R04·R05·R26·R06).
@MainActor
struct TimeSelectionView: View {
    @Bindable var model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var panelHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0

    private var selectedCandidate: RouteCandidate? {
        model.journeyCandidates.first { $0.routeID == model.journeyPlan.selectedRouteID }
    }

    var body: some View {
        GeometryReader { geometry in
            let maxPanel = geometry.size.height * (dynamicTypeSize.isAccessibilitySize ? 0.85 : 0.78)
            ZStack(alignment: .bottom) {
                SceneMapBackdrop(model: model,
                                 bottomInset: max(panelHeight, 120) + 8,
                                 routeID: model.journeyPlan.selectedRouteID,
                                 labelsOrigin: true,
                                 leg: selectedCandidate?.leg.stopIndices)
                    .ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    if !dynamicTypeSize.isAccessibilitySize {
                        ZStack(alignment: .topLeading) {
                            originSummary
                            if let selectedCandidate { routeChip(selectedCandidate) }
                        }
                        .padding(.leading, 16).padding(.top, -2)
                    }
                    Spacer(minLength: 16)
                    panel(maxHeight: maxPanel)
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
            .foregroundStyle(FMDesign.primary)
            .onPreferenceChange(TimePanelHeightKey.self) { panelHeight = $0 }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func panel(maxHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                content
                    .background {
                        GeometryReader { proxy in
                            Color.clear.preference(key: TimeContentHeightKey.self, value: proxy.size.height)
                        }
                    }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .frame(height: contentHeight > 0 ? min(contentHeight, max(120, maxHeight - 110)) : nil)
            .onPreferenceChange(TimeContentHeightKey.self) { contentHeight = $0 }
            .accessibilityIdentifier("time.contentScroll")
            Button(model.journeyProceedState.title) { model.proceedToPreparation() }
                .buttonStyle(FMPrimaryButtonStyle(size: .compact))
                .disabled(!model.journeyProceedState.isEnabled)
                .accessibilityIdentifier("time.proceed")
                .padding(.horizontal, 20).padding(.top, 20)
        }
        .padding(.top, 13).padding(.bottom, 15)
        .frame(maxWidth: .infinity)
        .background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 28))
        .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(FMDesign.panelStroke, lineWidth: 1) }
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal, 12)
        .background {
            GeometryReader { panel in
                Color.clear.preference(key: TimePanelHeightKey.self, value: panel.size.height)
            }
        }
        .padding(.bottom, 20)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Button { model.goBack() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 15, weight: .regular))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로")
                .accessibilityIdentifier("time.back")
                Text("시간부터 골라볼까요?")
                    .font(FontCatalog.text(18, weight: .bold, relativeTo: .title3))
                    .padding(.leading, 12)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("screen.time")
                Spacer(minLength: 0)
            }
            .padding(.leading, 19).padding(.trailing, 20)
            if dynamicTypeSize.isAccessibilitySize { origin.padding(.horizontal, 20).padding(.top, 8) }
            duration.frame(maxWidth: .infinity).padding(.top, 7)
            MinuteRuler(value: minutes, range: JourneyPlanner.minuteRange)
                .padding(.horizontal, 19).padding(.top, 8)
            Text("눈금을 좌우로 밀어 1분씩 선택하세요")
                .font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(FMDesign.hintText)
                .frame(maxWidth: .infinity).padding(.top, 1)
            candidates.padding(.top, 11)
        }
    }

    private var duration: some View {
        Text("\(model.journeyPlan.minutes) min")
            .font(FontCatalog.text(32, weight: .bold, relativeTo: .largeTitle))
            .monospacedDigit()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("선택한 여행 시간")
            .accessibilityValue("\(model.journeyPlan.minutes)")
            .accessibilityIdentifier("time.minutesLabel")
    }

    /// 출발 정류장은 지도 표식(시각)으로 보인다. 지도는 낭독에서 빠지므로 같은 정보를 보이지 않는 요소로 둔다.
    @ViewBuilder private var originSummary: some View {
        if let station = model.snapshot?.currentStation {
            Color.clear.frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityLabel(["출발 정류장", model.currentStationBound].compactMap { $0 }.joined(separator: ", "))
                .accessibilityValue(station.name)
                .accessibilityIdentifier("time.origin")
        }
    }

    /// R06 왼쪽 위 노선 칩: 반투명 검정 판 위 노선 배지(높이 38).
    private func routeChip(_ candidate: RouteCandidate) -> some View {
        RouteBadge(kind: candidate.busKind, number: candidate.busNumber, height: 38)
            .padding(6)
            .background(Color(hex: 0x080808).opacity(0.79), in: RoundedRectangle(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.145), lineWidth: 1) }
            .accessibilityHidden(true)
            .accessibilityIdentifier("time.routeChip")
    }

    @ViewBuilder private var origin: some View {
        if let station = model.snapshot?.currentStation {
            VStack(alignment: .leading, spacing: 4) {
                Text("출발 정류장").font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
                Text(station.name).font(FontCatalog.text(20, weight: .bold, relativeTo: .title3))
                    .accessibilityValue(station.name).accessibilityIdentifier("time.origin")
                if let bound = model.currentStationBound {
                    Text(bound).font(FontCatalog.text(15, relativeTo: .subheadline)).foregroundStyle(FMDesign.secondaryText)
                        .accessibilityIdentifier("time.bound")
                }
            }
            .padding(12)
            .background(FMDesign.panel.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder private var candidates: some View {
        if model.journeyCandidates.isEmpty {
            Text("이 시간에 도착하는 버스가 없어요.\n눈금을 움직여 다른 시간을 골라보세요.")
                .font(FontCatalog.text(13, relativeTo: .subheadline)).foregroundStyle(Color(hex: 0xC5D0C8))
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 83)
                .background(Color(hex: 0x151B17), in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 21).padding(.top, 15)
        } else if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(model.journeyCandidates) { candidateButton($0) }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
        } else {
            ScrollViewReader { reader in
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(model.journeyCandidates) { candidateButton($0).id($0.routeID) }
                    }
                }
                .contentMargins(.horizontal, 21, for: .scrollContent)
                .scrollIndicators(.hidden)
                .onChange(of: model.journeyPlan.selectedRouteID) { _, routeID in
                    guard let routeID else { return }
                    if reduceMotion { reader.scrollTo(routeID, anchor: .trailing) }
                    else { withAnimation(.easeInOut(duration: 0.3)) { reader.scrollTo(routeID, anchor: .trailing) } }
                }
            }
        }
    }

    private var minutes: Binding<Int> {
        Binding(get: { model.journeyPlan.minutes }, set: { model.journeyPlan.setMinutes($0) })
    }

    private func candidateButton(_ candidate: RouteCandidate) -> some View {
        let isSelected = model.journeyPlan.selectedRouteID == candidate.routeID
        let large = dynamicTypeSize.isAccessibilitySize
        return Button {
            model.chooseJourneyRoute(candidate.routeID)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                RouteBadge(kind: candidate.busKind, number: candidate.busNumber)
                Text(candidate.destination)
                    .font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
                    .foregroundStyle(isSelected ? Color(hex: 0x111A13) : FMDesign.primary)
                    .lineLimit(large ? nil : 1)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 9)
                Text("\(candidate.minutes) min · \(candidate.stops)정류장")
                    .font(FontCatalog.text(11, relativeTo: .caption))
                    .foregroundStyle(isSelected ? Color(hex: 0x405147) : Color(hex: 0xC2CCC5))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }
            .padding(.leading, 13).padding(.trailing, 13).padding(.top, 15).padding(.bottom, 15)
            .frame(width: large ? nil : 178, alignment: .topLeading)
            .frame(maxWidth: large ? .infinity : nil, minHeight: large ? nil : 140, alignment: .topLeading)
            .background(isSelected ? Color(hex: 0xF4F6F2) : Color(hex: 0x151B17), in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isSelected ? Color(hex: 0xF4F6F2) : Color.white.opacity(0.17), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(candidate.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("time.candidate.\(candidate.routeID)")
    }
}

/// A fixed pointer over minute ticks. Drag translation is measured from the gesture's starting value.
private struct MinuteRuler: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var value: Int
    let range: ClosedRange<Int>
    @State private var dragStart: Int?
    private let pointsPerMinute: CGFloat = 12

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            HStack(spacing: 12) {
                minuteButton(increasing: false)
                accessibleSlider.frame(maxWidth: .infinity, minHeight: 44)
                minuteButton(increasing: true)
            }
        } else {
            // R04 눈금자: 검정 상자, 1분 = 12pt, 5분 눈금 20pt(흰 73%)·1분 눈금 10pt(흰 33%), 10분마다 "N min" 라벨.
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
                let center = size.width / 2
                for minute in range {
                    let x = (center + CGFloat(minute - value) * pointsPerMinute).rounded() + 0.5
                    guard x >= -40, x <= size.width + 40 else { continue }
                    let major = minute.isMultiple(of: 5)
                    if minute != value {
                        var tick = Path()
                        tick.move(to: CGPoint(x: x, y: 24))
                        tick.addLine(to: CGPoint(x: x, y: major ? 44 : 34))
                        context.stroke(tick, with: .color(.white.opacity(major ? 0.73 : 0.33)), lineWidth: 1)
                    }
                    if minute.isMultiple(of: 10) || minute == range.lowerBound {
                        context.draw(Text("\(minute) min")
                            .font(FontCatalog.fixed(12, weight: minute == value ? .bold : .regular))
                            .foregroundColor(FMDesign.secondaryText),
                                     at: CGPoint(x: x, y: 60))
                    }
                }
                var pointer = Path()
                pointer.move(to: CGPoint(x: center - 5, y: 4))
                pointer.addLine(to: CGPoint(x: center + 5, y: 4))
                pointer.addLine(to: CGPoint(x: center, y: 11))
                pointer.closeSubpath()
                context.fill(pointer, with: .color(.white))
                context.fill(Path(CGRect(x: center - 1, y: 22, width: 2, height: 23)), with: .color(.white))
            }
            .frame(height: 81)
            .contentShape(Rectangle())
            .simultaneousGesture(DragGesture(minimumDistance: 3)
                .onChanged { drag in
                    guard abs(drag.translation.width) > abs(drag.translation.height) else { return }
                    if dragStart == nil { dragStart = value }
                    let next = (dragStart ?? value) - Int((drag.translation.width / pointsPerMinute).rounded())
                    value = min(range.upperBound, max(range.lowerBound, next))
                }
                .onEnded { _ in dragStart = nil })
            // No inertia or implicit animation: this direct manipulation also respects Reduce Motion.
            .accessibilityRepresentation { accessibleSlider }
        }
    }

    private func minuteButton(increasing: Bool) -> some View {
        Button {
            value = min(range.upperBound, max(range.lowerBound, value + (increasing ? 1 : -1)))
        } label: {
            Image(systemName: increasing ? "plus" : "minus")
                .font(.title3.weight(.semibold))
                .frame(minWidth: 44, minHeight: 44)
                .background(FMDesign.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(increasing ? value >= range.upperBound : value <= range.lowerBound)
        .accessibilityLabel(increasing ? "여행 시간 1분 늘리기" : "여행 시간 1분 줄이기")
        .accessibilityIdentifier(increasing ? "time.minute.increase" : "time.minute.decrease")
    }

    private var accessibleSlider: some View {
        Slider(value: Binding(get: { Double(value) }, set: { value = Int($0.rounded()) }),
               in: Double(range.lowerBound)...Double(range.upperBound), step: 1) {
            Text("여행 시간")
        }
        .accessibilityValue("\(value)분")
        .accessibilityIdentifier("time.ruler")
    }
}


private enum TimeContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Includes the panel's outer bottom padding so map attribution clears the actual overlay.
private enum TimePanelHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
