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
                        distance: 1_800, heading: 0, pitch: 50)), interactionModes: []) {
                        if route.count > 1 {
                            MapPolyline(coordinates: route)
                                .stroke(FMDesign.primary.opacity(0.8), lineWidth: 3)
                        }
                        if showsStationAnnotation {
                            Annotation(stop.name, coordinate: coordinate, anchor: .bottom) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 36)).foregroundStyle(FMDesign.primary)
                                    .shadow(color: .black.opacity(0.65), radius: 8, y: 3)
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: false))
                    .mapControls { }
                    // Large text can make the overlay taller than the map. Preserve a visible map region.
                    .safeAreaPadding(.bottom, min(max(0, bottomInset), max(0, geometry.size.height - 160)))
                    .id(stop.id)
                } else {
                    FMDesign.background
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(FMDesign.background)
        .environment(\.colorScheme, .dark)
        .accessibilityHidden(true)
    }
}
