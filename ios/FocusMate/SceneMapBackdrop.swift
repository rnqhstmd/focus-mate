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

    private var stop: RouteCatalog.Stop? {
        guard let catalog = model.routeCatalog,
              let id = stationID ?? model.snapshot?.currentStation?.id,
              let index = catalog.stopIndex(id: id) else { return nil }
        return catalog.stops[index]
    }

    /// Pen main camera: a wide oblique aerial view (G-global 4-3, A C2).
    static let cameraDistance: Double = 3_000
    static let cameraPitch: Double = 55

    private var routeColor: Color {
        guard let routeID, let catalog = model.routeCatalog, let index = catalog.routeIndex(id: routeID) else {
            return FMDesign.routeBranch
        }
        return FMDesign.routeColor(kind: catalog.routes[index].kind)
    }

    private var routeCoordinates: [CLLocationCoordinate2D] {
        guard let routeID, let catalog = model.routeCatalog,
              let index = catalog.routeIndex(id: routeID) else { return [] }
        return catalog.routes[index].stops.compactMap { stopIndex in
            guard catalog.stops.indices.contains(stopIndex) else { return nil }
            let point = catalog.stops[stopIndex].point
            return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let stop {
                    let coordinate = CLLocationCoordinate2D(latitude: stop.point.latitude, longitude: stop.point.longitude)
                    let route = routeCoordinates
                    Map(initialPosition: .camera(MapCamera(centerCoordinate: coordinate,
                        distance: Self.cameraDistance, heading: 0, pitch: Self.cameraPitch)), interactionModes: []) {
                        if route.count > 1 {
                            MapPolyline(coordinates: route)
                                .stroke(routeColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        }
                        if showsStationAnnotation {
                            Annotation(stop.name, coordinate: coordinate, anchor: .bottom) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 36)).foregroundStyle(FMDesign.primary)
                                    .shadow(color: .black.opacity(0.65), radius: 8, y: 3)
                            }
                        }
                    }
                    .mapStyle(.imagery(elevation: .realistic))
                    .mapControls { }
                    .overlay { FMMapScrim() }
                    // Large text can make the overlay taller than the map. Preserve a visible map region.
                    .safeAreaPadding(.bottom, min(max(0, bottomInset), max(0, geometry.size.height - 160)))
                    .id(stop.id)
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
