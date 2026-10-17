import SwiftUI

/// 출발 뒤 타이머 화면. 지도(W06) 위에 남은 시간·정류장·거리와 일시정지·지도 도구를 얹는다.
/// 지도를 만들 수 없는 여정(저장 도착지 불일치 등)은 W05 배치로 보인다. 도착 안내(W09)는 이 위에 붙는다.
@MainActor
struct JourneyTimerView: View {
    let controller: JourneyTimerController
    let map: JourneyMapController?
    let reduceMotion: Bool
    /// 도착 안내가 덮을 때는 내용을 그리지 않는다 — 숨김 수식어만으로는 아래 "남은 시간 0분"이 낭독에 남는다(BR-7).
    /// 등장 처리(진도·앱 밖 표시 동기화)와 진단은 그대로 둔다.
    var concealed = false
    #if DEBUG
    var path: [Destination] = []
    #endif
    @AccessibilityFocusState private var remainingFocused: Bool
    /// 일시정지↔재개 버튼이 같은 자리에서 바뀌므로, 연타의 두 번째 탭이 반대 전환으로 들어가지 않게 잠깐 무시한다.
    @State private var lastControlTap: ContinuousClock.Instant?
    @State private var bottomHeight: CGFloat = 0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// 하단 지표 글자(웹 기준 라벨 12·단위 15·숫자 30)를 글자 크기 설정에 맞춰 키운다.
    @ScaledMetric(relativeTo: .caption) private var labelSize: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var unitSize: CGFloat = 15
    @ScaledMetric(relativeTo: .title) private var valueSize: CGFloat = 30
    private static let tapGuard: Duration = .milliseconds(500)

    private var minutesText: String { JourneyTimerDisplay.text(minutes: controller.remainingMinutes) }

    var body: some View {
        Group {
            if concealed { Color.clear }
            else if let map { mapBody(map) } else { legacyBody }
        }
        .onAppear {
            controller.appear()
            remainingFocused = true
        }
        #if DEBUG
        .overlay(alignment: .bottomLeading) { diagnostics }
        #endif
    }

    // MARK: 지도 배치

    private func mapBody(_ map: JourneyMapController) -> some View {
        ZStack {
            JourneyMapView(map: map, bottomInset: max(190, bottomHeight + 60))
            if controller.status == .paused {
                PausedJourneyShade(bottomInset: max(190, bottomHeight + 60))
                    .ignoresSafeArea(.container, edges: .all)
            }
            VStack {
                Spacer(minLength: 0)
                LinearGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.73), location: 0.65),
                    .init(color: .black.opacity(0.88), location: 1)
                ], startPoint: .top, endPoint: .bottom)
                .frame(height: max(190, bottomHeight + 60))
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .allowsHitTesting(false).accessibilityHidden(true)
            VStack(spacing: 0) {
                topBar(map)
                Spacer(minLength: 0)
                VStack(spacing: 24) {
                    if controller.status == .paused {
                        Text("일시정지됨")
                            .font(.system(.title3, weight: .medium))
                            .foregroundStyle(.white.opacity(0.73))
                            .padding(.top, 16)
                    }
                    bottomInfo(map)
                }
                    .background(GeometryReader { proxy in
                        Color.clear.preference(key: BottomInfoHeightKey.self, value: proxy.size.height)
                    })
            }
        }
        .foregroundStyle(.white)
        .background(Color.black.ignoresSafeArea())
        .onPreferenceChange(BottomInfoHeightKey.self) { bottomHeight = $0 }
        .onChange(of: MapSync(status: controller.status, elapsed: controller.elapsedSeconds)) { _, sync in
            withAnimation(reduceMotion ? nil : .linear(duration: 1)) { map.sync(status: sync.status, elapsedSeconds: sync.elapsed) }
        }
        .onChange(of: reduceMotion) { _, on in map.setReduceMotion(on) }
        .sheet(isPresented: Binding(get: { map.state.isThemeSheetPresented },
                                    set: { if !$0 { map.dismissThemeSheet() } })) {
            JourneyMapThemeSheet(map: map)
        }
        #if DEBUG
        .overlay(alignment: .bottomTrailing) { mapDiagnostics(map) }
        #endif
    }

    private func topBar(_ map: JourneyMapController) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                roundControl
                Spacer(minLength: 16)
                VStack(spacing: 12) {
                    toolButton(systemImage: "location.fill", label: JourneyMapDisplay.followLabel,
                               value: JourneyMapDisplay.followValue(map.state.camera), id: "journey.map.follow",
                               enabled: map.state.toolsEnabled) { map.followTapped() }
                    toolButton(systemImage: "map", label: JourneyMapDisplay.themeLabel, value: nil,
                               id: "journey.map.theme", enabled: map.state.toolsEnabled) { map.openThemeSheet() }
                }
            }
            notices.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    @ViewBuilder private var roundControl: some View {
        switch controller.status {
        case .running:
            roundButton(JourneyTimerDisplay.pauseLabel, systemImage: "pause.fill", id: "journey.timer.pause") { controller.pause() }
        case .paused:
            roundButton(JourneyTimerDisplay.resumeLabel, systemImage: "play.fill", id: "journey.timer.resume") { controller.resume() }
        case .arrived:
            // 도착 안내가 위를 덮는다(W09).
            EmptyView()
        }
    }

    private func roundButton(_ title: String, systemImage: String, id: String, action: @escaping () -> Void) -> some View {
        Button { guardedTap(action) } label: {
            Image(systemName: systemImage).font(.system(size: 20, weight: .bold))
                .frame(width: 48, height: 48)
                .background(.black.opacity(0.6), in: Circle())
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .accessibilityLabel(title)
        .accessibilityIdentifier(id)
    }

    private func toolButton(systemImage: String, label: String, value: String?, id: String, enabled: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage).font(.system(size: 18, weight: .semibold))
                .frame(width: 48, height: 48)
                .background(.black.opacity(0.6), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .accessibilityLabel(label)
        .accessibilityValue(value ?? "")
        .accessibilityIdentifier(id)
    }

    private func bottomInfo(_ map: JourneyMapController) -> some View {
        // 큰 글자에서는 세 지표를 세로로 쌓는다. ViewThatFits는 두 배치를 모두 만들어 남은 시간의 초기 포커스가 풀리므로 쓰지 않는다.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(alignment: .top, spacing: 0))
        let stacked = dynamicTypeSize.isAccessibilitySize
        return layout {
            remainingColumn.frame(maxWidth: stacked ? nil : .infinity, alignment: .leading)
            stopsColumn(map).frame(maxWidth: stacked ? nil : .infinity, alignment: stacked ? .leading : .center)
            distanceColumn(map).frame(maxWidth: stacked ? nil : .infinity, alignment: stacked ? .leading : .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.vertical, 14)
        .environment(\.colorScheme, .dark)
    }

    private var remainingColumn: some View {
        infoColumn(label: "남은 시간", value: Text(minutesText))
            .contentTransition(reduceMotion ? .identity : .numericText())
            .animation(reduceMotion ? nil : .default, value: controller.remainingMinutes)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(JourneyTimerDisplay.accessibilityLabel)
            .accessibilityValue(JourneyTimerDisplay.accessibilityValue(minutes: controller.remainingMinutes))
            .accessibilityIdentifier("journey.timer.remaining")
            .accessibilityFocused($remainingFocused)
    }

    private func stopsColumn(_ map: JourneyMapController) -> some View {
        infoColumn(label: JourneyMapDisplay.remainingStopsLabel,
                   value: Text(JourneyMapDisplay.stopsText(map.remainingStops)) + Text(" 개").font(.system(size: unitSize)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(JourneyMapDisplay.remainingStopsLabel)
            .accessibilityValue(JourneyMapDisplay.stopsAccessibilityValue(map.remainingStops))
            .accessibilityIdentifier("journey.timer.stops")
    }

    private func distanceColumn(_ map: JourneyMapController) -> some View {
        infoColumn(label: JourneyMapDisplay.remainingDistanceLabel,
                   value: Text(JourneyMapDisplay.distanceText(tenthsKm: map.remainingDistanceTenthsKm))
                       + Text(" km").font(.system(size: unitSize)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(JourneyMapDisplay.remainingDistanceLabel)
            .accessibilityValue(JourneyMapDisplay.distanceAccessibilityValue(tenthsKm: map.remainingDistanceTenthsKm))
            .accessibilityIdentifier("journey.timer.distance")
    }

    private func infoColumn(label: String, value: Text) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: labelSize)).foregroundStyle(.white.opacity(0.64))
            value.font(.system(size: valueSize, weight: .bold)).lineLimit(1).minimumScaleFactor(0.6)
        }
    }

    // MARK: W05 배치 (지도 없음)

    private var legacyBody: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 0)
            Text(minutesText)
                .font(.system(size: 64, weight: .bold))
                .lineLimit(1).minimumScaleFactor(0.5)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .animation(reduceMotion ? nil : .default, value: controller.remainingMinutes)
                .accessibilityLabel(JourneyTimerDisplay.accessibilityLabel)
                .accessibilityValue(JourneyTimerDisplay.accessibilityValue(minutes: controller.remainingMinutes))
                .accessibilityIdentifier("journey.timer.remaining")
                .accessibilityFocused($remainingFocused)
            legacyControl
            notices
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.white)
        .background(Color.black.ignoresSafeArea())
    }

    @ViewBuilder private var legacyControl: some View {
        switch controller.status {
        case .running:
            controlButton(JourneyTimerDisplay.pauseLabel, systemImage: "pause.fill", id: "journey.timer.pause") { controller.pause() }
        case .paused:
            controlButton(JourneyTimerDisplay.resumeLabel, systemImage: "play.fill", id: "journey.timer.resume") { controller.resume() }
        case .arrived:
            // 도착 안내가 위를 덮는다(W09).
            EmptyView()
        }
    }

    private func controlButton(_ title: String, systemImage: String, id: String, action: @escaping () -> Void) -> some View {
        Button { guardedTap(action) } label: {
            Label(title, systemImage: systemImage)
                .font(.headline).foregroundStyle(.black)
                .frame(minWidth: 160, minHeight: 44).padding(.vertical, 8).padding(.horizontal, 24)
                .background(Color(white: 0.95), in: Capsule())
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .accessibilityLabel(title)
        .accessibilityIdentifier(id)
    }

    private func guardedTap(_ action: () -> Void) {
        let now = ContinuousClock.now
        if let last = lastControlTap, last.duration(to: now) < Self.tapGuard { return }
        lastControlTap = now
        action()
    }

    @ViewBuilder private var notices: some View {
        if controller.showsTransitionFailure {
            Text(JourneyTimerDisplay.transitionFailureText).font(.subheadline).foregroundStyle(.orange)
                .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("journey.timer.saveFailure")
        }
        if controller.showsSaveWarning {
            Text(controller.status == .arrived ? JourneyTimerDisplay.arrivalWarningText : JourneyTimerDisplay.checkpointWarningText)
                .font(.subheadline).foregroundStyle(.orange)
                .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("journey.timer.saveWarning")
        }
    }

    #if DEBUG
    private var diagnostics: some View {
        let status = switch controller.status { case .running: "running"; case .paused: "paused"; case .arrived: "arrived" }
        let object: [String: Any] = [
            "status": status, "elapsed": controller.elapsedSeconds, "remainingMinutes": controller.remainingMinutes,
            "text": minutesText, "showsSaveWarning": controller.showsSaveWarning,
            "showsSaveFailure": controller.showsTransitionFailure, "focus": remainingFocused ? "remaining" : "none",
            "path": path.map { "\($0)" },
        ]
        let json = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
            .map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return Text("타이머 진단").font(.system(size: 1)).foregroundStyle(.clear)
            .accessibilityValue(json).accessibilityIdentifier("test.timer").allowsHitTesting(false)
    }

    /// 화면에 보이지 않는 지도 값(렌더 개수·카메라 목표·좌표)만 담는다.
    private func mapDiagnostics(_ map: JourneyMapController) -> some View {
        let bus = map.bus, target = map.cameraTarget, destination = map.destinationStop
        let object: [String: Any] = [
            "bus": ["lat": bus.point.latitude, "lon": bus.point.longitude, "from": bus.segmentFrom, "to": bus.segmentTo,
                    "fraction": bus.fraction, "arrived": bus.isArrived],
            "destination": ["index": destination.index, "lat": destination.point.latitude, "lon": destination.point.longitude],
            "course": map.journey.stops.map { [$0.point.latitude, $0.point.longitude] },
            "render": ["route": map.routePoints.count, "stopMarkers": map.visibleStops.count, "bus": true, "destination": true],
            "camera": ["lat": target.center.latitude, "lon": target.center.longitude, "heading": target.headingDegrees,
                       "pitch": target.pitchDegrees, "animated": target.animated, "revision": target.revision],
        ]
        let json = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
            .map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return Text("지도 진단").font(.system(size: 1)).foregroundStyle(.clear)
            .accessibilityValue(json).accessibilityIdentifier("test.map").allowsHitTesting(false)
    }
    #endif
}

private struct MapSync: Equatable {
    let status: JourneyTimerController.Status
    let elapsed: Int
}

private struct BottomInfoHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// A strong pause dim with a smooth, lighter band around MapKit's native attribution.
private struct PausedJourneyShade: View {
    let bottomInset: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let legal = min(0.9, max(0.15, (proxy.size.height - bottomInset - 20) / max(1, proxy.size.height)))
            LinearGradient(stops: [
                .init(color: .black.opacity(0.55), location: 0),
                .init(color: .black.opacity(0.68), location: 0.6),
                .init(color: .black.opacity(0.94), location: 1)
            ], startPoint: .top, endPoint: .bottom)
            .mask {
                LinearGradient(stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: max(0, legal - 0.08)),
                    .init(color: .black.opacity(0.3), location: legal),
                    .init(color: .black, location: min(1, legal + 0.08)),
                    .init(color: .black, location: 1)
                ], startPoint: .top, endPoint: .bottom)
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}
