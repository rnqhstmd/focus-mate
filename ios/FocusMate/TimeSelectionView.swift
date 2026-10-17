import SwiftUI

/// 저장된 현재 정류장에서 출발하는 시간·버스·도착지 선택 화면.
@MainActor
struct TimeSelectionView: View {
    @Bindable var model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var panelHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                SceneMapBackdrop(model: model,
                                 bottomInset: max(panelHeight, geometry.size.height * (dynamicTypeSize.isAccessibilitySize ? 0.85 : 0.73) + 12) + 28,
                                 routeID: model.journeyPlan.selectedRouteID)
                    .ignoresSafeArea()
                LinearGradient(colors: [.clear, FMDesign.background.opacity(0.5), FMDesign.background],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea().allowsHitTesting(false)
                VStack(alignment: .leading, spacing: 12) {
                    if !dynamicTypeSize.isAccessibilitySize {
                        origin.padding(.horizontal, 22).padding(.top, 12)
                    }
                    Spacer(minLength: 16)
                    VStack(spacing: 16) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                if dynamicTypeSize.isAccessibilitySize { origin }
                                Text("시간부터 골라볼까요?")
                                    .font(FontCatalog.text(24, bold: true, relativeTo: .title2))
                                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                                    .accessibilityIdentifier("screen.time")
                                duration.frame(maxWidth: .infinity)
                                MinuteRuler(value: minutes, range: JourneyPlanner.minuteRange)
                                Text("눈금을 좌우로 밀어 1분씩 선택하세요")
                                    .font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
                                    .frame(maxWidth: .infinity)
                                candidates
                            }
                        }
                        .scrollIndicators(.hidden)
                        .accessibilityIdentifier("time.contentScroll")
                        Button(model.journeyProceedState.title) { model.proceedToPreparation() }
                            .buttonStyle(FMPrimaryButtonStyle())
                            .disabled(!model.journeyProceedState.isEnabled)
                            .accessibilityIdentifier("time.proceed")
                    }
                    .fmPanel()
                    .frame(maxHeight: geometry.size.height * (dynamicTypeSize.isAccessibilitySize ? 0.85 : 0.73))
                    .padding(.horizontal, 12).padding(.bottom, 12)
                    .background {
                        GeometryReader { panel in
                            Color.clear.preference(key: TimePanelHeightKey.self, value: panel.size.height)
                        }
                    }
                }
            }
            .foregroundStyle(FMDesign.primary)
            .onPreferenceChange(TimePanelHeightKey.self) { panelHeight = $0 }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var duration: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            if model.journeyPlan.minutes >= 60 {
                Text("\(model.journeyPlan.minutes / 60)").font(.system(size: 40, weight: .semibold, design: .rounded))
                Text("h").font(FontCatalog.text(18, relativeTo: .title3))
            }
            Text("\(model.journeyPlan.minutes >= 60 ? model.journeyPlan.minutes % 60 : model.journeyPlan.minutes)")
                .font(.system(size: 40, weight: .semibold, design: .rounded))
            Text("min").font(FontCatalog.text(18, relativeTo: .title3))
        }
        .monospacedDigit()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("선택한 여행 시간")
        .accessibilityValue("\(model.journeyPlan.minutes)")
        .accessibilityIdentifier("time.minutesLabel")
    }

    @ViewBuilder private var origin: some View {
        if let station = model.snapshot?.currentStation {
            VStack(alignment: .leading, spacing: 4) {
                Label("출발", systemImage: "mappin.circle.fill")
                    .font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
                Text(station.name).font(FontCatalog.text(dynamicTypeSize.isAccessibilitySize ? 20 : 18, bold: true, relativeTo: .title3))
                    .accessibilityValue(station.name).accessibilityIdentifier("time.origin")
                if let bound = model.currentStationBound {
                    Text(bound).font(FontCatalog.text(dynamicTypeSize.isAccessibilitySize ? 15 : 13, relativeTo: .subheadline)).foregroundStyle(FMDesign.secondaryText)
                        .accessibilityIdentifier("time.bound")
                }
            }
            .padding(dynamicTypeSize.isAccessibilitySize ? 12 : 0)
            .background(dynamicTypeSize.isAccessibilitySize ? FMDesign.panel.opacity(0.85) : .clear,
                        in: RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder private var candidates: some View {
        if model.journeyCandidates.isEmpty {
            Text("이 시간에 도착하는 버스가 없어요.\n눈금을 움직여 다른 시간을 골라보세요.")
                .font(FontCatalog.text(15, relativeTo: .subheadline)).foregroundStyle(FMDesign.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(model.journeyCandidates) { candidateButton($0) }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(3)
        } else {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(model.journeyCandidates) { candidateButton($0) }
                }
                .padding(3)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var minutes: Binding<Int> {
        Binding(get: { model.journeyPlan.minutes }, set: { model.journeyPlan.setMinutes($0) })
    }

    private func candidateButton(_ candidate: RouteCandidate) -> some View {
        let isSelected = model.journeyPlan.selectedRouteID == candidate.routeID
        return Button {
            model.chooseJourneyRoute(candidate.routeID)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("\(candidate.busKind) \(candidate.busNumber)", systemImage: "bus.fill")
                        .font(FontCatalog.text(17, bold: true, relativeTo: .headline))
                        .fixedSize(horizontal: false, vertical: true)
                    if isSelected { Image(systemName: "checkmark.circle.fill") }
                }
                Text(candidate.destination).font(FontCatalog.text(17, bold: true, relativeTo: .headline)).fixedSize(horizontal: false, vertical: true)
                Text("\(candidate.minutes)분 · \(candidate.stops)정류장 · \(candidate.distanceText)")
                    .font(FontCatalog.text(12, relativeTo: .caption)).fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 190, alignment: .leading)
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .foregroundStyle(isSelected ? Color.black : FMDesign.primary)
            .background(isSelected ? FMDesign.primary : Color(red: 21 / 255, green: 27 / 255, blue: 23 / 255),
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(FMDesign.primary.opacity(0.18)) }
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
    private let pointsPerMinute: CGFloat = 8

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            HStack(spacing: 12) {
                minuteButton(increasing: false)
                accessibleSlider.frame(maxWidth: .infinity, minHeight: 44)
                minuteButton(increasing: true)
            }
        } else {
            Canvas { context, size in
                let center = size.width / 2
                for minute in range {
                    let x = center + CGFloat(minute - value) * pointsPerMinute
                    guard x >= -20, x <= size.width + 20 else { continue }
                    let major = minute.isMultiple(of: 5)
                    var tick = Path()
                    tick.move(to: CGPoint(x: x, y: 12))
                    tick.addLine(to: CGPoint(x: x, y: major ? 44 : 30))
                    context.stroke(tick, with: .color(FMDesign.primary.opacity(major ? 0.65 : 0.3)), lineWidth: major ? 2 : 1)
                    if major {
                        context.draw(Text("\(minute)").font(.caption2).foregroundColor(FMDesign.secondaryText),
                                     at: CGPoint(x: x, y: 62))
                    }
                }
                var pointer = Path()
                pointer.move(to: CGPoint(x: center - 5, y: 0))
                pointer.addLine(to: CGPoint(x: center + 5, y: 0))
                pointer.addLine(to: CGPoint(x: center, y: 7))
                pointer.closeSubpath()
                context.fill(pointer, with: .color(FMDesign.primary))
                context.fill(Path(CGRect(x: center - 1, y: 10, width: 2, height: 38)), with: .color(FMDesign.primary))
            }
            .frame(height: 78)
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


/// Includes the panel's outer bottom padding so map attribution clears the actual overlay.
private enum TimePanelHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
