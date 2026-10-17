import MapKit
import SwiftUI

/// A decorative map of the selected catalog stop. It never requests device location.
@MainActor
struct SceneMapBackdrop: View {
    var model: AppModel
    var stationID: String? = nil
    var bottomInset: CGFloat = 0
    var routeID: String? = nil
    var showsStationAnnotation = true
    /// Time selection (R04~R06): the origin pin carries "출발 정류장" + stop name labels.
    var labelsOrigin = false
    /// Time selection (R06): stop indices of the chosen leg. When set, the camera frames the whole leg and the
    /// map shows a thin route line, stop dots and a bus marker at the origin instead of the pin.
    var leg: [Int]? = nil
    /// Shown when no stop is selected yet (first station search): Seoul Forest area.
    var fallbackCoordinate: CLLocationCoordinate2D? = nil

    @State private var position: MapCameraPosition = .automatic

    private var stop: RouteCatalog.Stop? {
        guard let catalog = model.routeCatalog,
              let id = stationID ?? model.snapshot?.currentStation?.id,
              let index = catalog.stopIndex(id: id) else { return nil }
        return catalog.stops[index]
    }

    /// Pen main camera: a wide oblique aerial view (G-global 4-3, A C2).
    static let cameraDistance: Double = 3_000
    static let cameraPitch: Double = 55
    /// Seoul Forest, used behind the first station search before any stop exists.
    static let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.5444, longitude: 127.0374)

    private var routeColor: Color {
        guard let routeID, let catalog = model.routeCatalog, let index = catalog.routeIndex(id: routeID) else {
            return FMDesign.routeBranch
        }
        return FMDesign.routeColor(kind: catalog.routes[index].kind)
    }

    private var routeCoordinates: [CLLocationCoordinate2D] {
        guard let catalog = model.routeCatalog else { return [] }
        let indices: [Int]
        if let leg {
            indices = leg
        } else if let routeID, let index = catalog.routeIndex(id: routeID) {
            indices = catalog.routes[index].stops
        } else {
            return []
        }
        return indices.compactMap { stopIndex in
            guard catalog.stops.indices.contains(stopIndex) else { return nil }
            let point = catalog.stops[stopIndex].point
            return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        }
    }

    private static func camera(at coordinate: CLLocationCoordinate2D) -> MapCameraPosition {
        .camera(MapCamera(centerCoordinate: coordinate, distance: cameraDistance, heading: 0, pitch: cameraPitch))
    }

    /// Frames every point of the leg with a margin so the line clears the top chip and the panel.
    private static func framing(_ points: [CLLocationCoordinate2D]) -> MapCameraPosition? {
        guard points.count > 1 else { return nil }
        var rect = MKMapRect.null
        for point in points {
            let mapPoint = MKMapPoint(point)
            rect = rect.union(MKMapRect(x: mapPoint.x, y: mapPoint.y, width: 0, height: 0))
        }
        let margin = max(rect.width, rect.height) * 0.25 + 200
        return .rect(rect.insetBy(dx: -margin, dy: -margin))
    }

    private func targetPosition(for coordinate: CLLocationCoordinate2D) -> MapCameraPosition {
        if leg != nil, let framed = Self.framing(routeCoordinates) { return framed }
        return Self.camera(at: coordinate)
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let stop {
                    let coordinate = CLLocationCoordinate2D(latitude: stop.point.latitude, longitude: stop.point.longitude)
                    let route = routeCoordinates
                    let detailed = leg != nil && route.count > 1
                    let decorated = labelsOrigin || detailed
                    Map(position: $position, interactionModes: []) {
                        if decorated {
                            // 시안(R04·R06)의 표식·노선선은 덮개 위에 선명하다. 덮개를 지도 안 다각형으로 깔아
                            // 노선선·표식이 그 위에 그려지게 한다(Apple 로고·Legal은 지도 위 UI라 가려지지 않는다).
                            MapPolygon(coordinates: Self.scrimBox(around: coordinate))
                                .foregroundStyle(FMDesign.mapScrim)
                        }
                        if route.count > 1 {
                            if detailed {
                                MapPolyline(coordinates: route)
                                    .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                                MapPolyline(coordinates: route)
                                    .stroke(routeColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            } else {
                                MapPolyline(coordinates: route)
                                    .stroke(routeColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                            }
                        }
                        if detailed {
                            ForEach(Array(route.enumerated().dropFirst()), id: \.offset) { item in
                                Annotation("", coordinate: item.element, anchor: .center) {
                                    stopDot(isLast: item.offset == route.count - 1)
                                }
                                .annotationTitles(.hidden)
                            }
                            Annotation("", coordinate: route[0], anchor: .center) { busMarker }
                                .annotationTitles(.hidden)
                        } else if showsStationAnnotation {
                            Annotation(stop.name, coordinate: coordinate, anchor: .bottom) {
                                if labelsOrigin { originMarker(name: stop.name) } else {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 36)).foregroundStyle(FMDesign.primary)
                                        .shadow(color: .black.opacity(0.65), radius: 8, y: 3)
                                }
                            }
                            .annotationTitles(labelsOrigin ? .hidden : .automatic)
                        }
                    }
                    .mapStyle(.imagery(elevation: .realistic))
                    .mapControls { }
                    .overlay { if !decorated { FMMapScrim() } }
                    // Large text can make the overlay taller than the map. Preserve a visible map region.
                    .safeAreaPadding(.bottom, min(max(0, bottomInset), max(0, geometry.size.height - 160)))
                    .safeAreaPadding(.top, detailed ? 70 : 0)
                    .onAppear { position = targetPosition(for: coordinate) }
                    .onChange(of: leg) { _, _ in
                        withAnimation(.easeInOut(duration: 0.6)) { position = targetPosition(for: coordinate) }
                    }
                    .id(stop.id)
                } else if let fallbackCoordinate {
                    Map(initialPosition: Self.camera(at: fallbackCoordinate), interactionModes: [])
                        .mapStyle(.imagery(elevation: .realistic))
                        .mapControls { }
                        .overlay { FMMapScrim() }
                        .safeAreaPadding(.bottom, min(max(0, bottomInset), max(0, geometry.size.height - 160)))
                } else {
                    FMDesign.mapBase.overlay { FMMapScrim() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(FMDesign.mapBase)
        .environment(\.colorScheme, .dark)
        .accessibilityHidden(true)
    }

    /// A box well beyond the visible area around the stop, used as the in-map scrim.
    private static func scrimBox(around center: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        let d = 0.6
        return [
            CLLocationCoordinate2D(latitude: center.latitude - d, longitude: center.longitude - d),
            CLLocationCoordinate2D(latitude: center.latitude - d, longitude: center.longitude + d),
            CLLocationCoordinate2D(latitude: center.latitude + d, longitude: center.longitude + d),
            CLLocationCoordinate2D(latitude: center.latitude + d, longitude: center.longitude - d),
        ]
    }

    /// R04 origin marker: white drop pin (30x39, #151A1D hole) over two black label boxes. The pin tip sits on
    /// the stop; the labels hang below it.
    private func originMarker(name: String) -> some View {
        VStack(spacing: 3) {
            OriginPin().frame(width: 30, height: 39)
            VStack(spacing: -4) {
                Text("출발 정류장").font(FontCatalog.fixed(11)).foregroundStyle(Color(hex: 0xE5EAE7))
                    .padding(.horizontal, 9).padding(.vertical, 5).background(.black)
                Text(name).font(FontCatalog.fixed(16, weight: .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4).background(.black)
            }
        }
        .fixedSize()
        // Anchored at the bottom of the stack; move it down so the pin tip (y = 39) lands on the stop.
        .modifier(PinTipOffset())
    }

    private func stopDot(isLast: Bool) -> some View {
        Circle()
            .fill(isLast ? FMDesign.stopStroke : Color.white)
            .frame(width: isLast ? 8 : 5, height: isLast ? 8 : 5)
            .overlay { Circle().strokeBorder(isLast ? routeColor : FMDesign.stopStroke, lineWidth: isLast ? 1.5 : 1) }
    }

    /// R06 bus marker at the origin: a kind-coloured bus body seen from above.
    private var busMarker: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(routeColor)
            .frame(width: 22, height: 32)
            .overlay {
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.black.opacity(0.45)).frame(width: 14, height: 6)
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 2).fill(Color.black.opacity(0.45)).frame(width: 14, height: 4)
                }
                .padding(.vertical, 4)
            }
            .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.85), lineWidth: 1) }
            .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
    }
}

/// Moves a view centred on a point so that its top + 39pt (the pin tip) sits on that point.
private struct PinTipOffset: ViewModifier {
    @State private var height: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .background { GeometryReader { proxy in Color.clear.onAppear { height = proxy.size.height }
                .onChange(of: proxy.size.height) { _, value in height = value } } }
            .offset(y: max(0, height - 39))
    }
}

/// White drop pin with a dark hole (R04).
private struct OriginPin: View {
    var body: some View {
        ZStack(alignment: .top) {
            PinShape().fill(Color.white).shadow(color: .black.opacity(0.4), radius: 3, y: 1)
            Circle().fill(Color(hex: 0x151A1D)).frame(width: 11, height: 11).padding(.top, 9.5)
        }
    }
}

private struct PinShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r = rect.width / 2
        let center = CGPoint(x: rect.midX, y: r)
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.minX, y: r),
                      control1: CGPoint(x: rect.midX - r * 0.35, y: rect.maxY - r * 0.55),
                      control2: CGPoint(x: rect.minX, y: r + r * 0.75))
        path.addArc(center: center, radius: r, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                      control1: CGPoint(x: rect.maxX, y: r + r * 0.75),
                      control2: CGPoint(x: rect.midX + r * 0.35, y: rect.maxY - r * 0.55))
        path.closeSubpath()
        return path
    }
}

/// Uniform black 33% over a map. The Apple Maps logo and "Legal" link (bottom-leading, just above the
/// map's bottom safe area) are left uncovered so the required attribution keeps full contrast.
struct FMMapScrim: View {
    var body: some View {
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let width = proxy.size.width + insets.leading + insets.trailing
            let height = proxy.size.height + insets.top + insets.bottom
            FMDesign.mapScrim
                .mask {
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                        RoundedRectangle(cornerRadius: 14)
                            .frame(width: 150, height: 40)
                            .blur(radius: 6)
                            .position(x: insets.leading + 70, y: insets.top + proxy.size.height - 18)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                }
                .frame(width: width, height: height)
                .offset(x: -insets.leading, y: -insets.top)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
