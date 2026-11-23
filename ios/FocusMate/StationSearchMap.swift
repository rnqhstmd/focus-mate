import MapKit
import SwiftUI
import UIKit

/// The caller gives each selected stop its own map identity so old tile loads cannot cover a later selection.
@MainActor
struct StationSearchMap: UIViewRepresentable {
    let target: StationSearchMapTarget

    func makeUIView(context: Context) -> HostView { HostView(point: target.point) }

    func updateUIView(_ uiView: HostView, context: Context) {}

    final class HostView: UIView, MKMapViewDelegate {
        private let map = MKMapView()
        private let fallback = UIView()
        private let fallbackLabel = UILabel()
        private let camera: MKMapCamera
        private var hasRenderedMap = false

        init(point: CoursePoint) {
            let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: 1_100, pitch: 0, heading: 0)
            super.init(frame: .zero)
            overrideUserInterfaceStyle = .dark

            let configuration = MKStandardMapConfiguration(elevationStyle: .flat)
            configuration.pointOfInterestFilter = .excludingAll
            map.preferredConfiguration = configuration
            map.showsCompass = false
            map.showsScale = false
            map.isScrollEnabled = false
            map.isZoomEnabled = false
            map.isRotateEnabled = false
            map.isPitchEnabled = false
            map.setCamera(camera, animated: false)

            fallback.backgroundColor = UIColor(FMDesign.mapBase)
            fallbackLabel.text = "지도를 불러오는 중이에요."
            fallbackLabel.font = .preferredFont(forTextStyle: .footnote)
            fallbackLabel.adjustsFontForContentSizeCategory = true
            fallbackLabel.textColor = .secondaryLabel
            fallbackLabel.textAlignment = .center
            fallbackLabel.numberOfLines = 0
            fallbackLabel.translatesAutoresizingMaskIntoConstraints = false
            fallback.addSubview(fallbackLabel)
            NSLayoutConstraint.activate([
                fallbackLabel.centerXAnchor.constraint(equalTo: fallback.centerXAnchor),
                fallbackLabel.centerYAnchor.constraint(equalTo: fallback.centerYAnchor),
                fallbackLabel.leadingAnchor.constraint(greaterThanOrEqualTo: fallback.leadingAnchor, constant: 18),
                fallbackLabel.trailingAnchor.constraint(lessThanOrEqualTo: fallback.trailingAnchor, constant: -18),
            ])
            map.delegate = self
            let station = MKPointAnnotation()
            station.coordinate = coordinate
            map.addAnnotation(station)
            addSubview(map)
            addSubview(fallback)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layoutSubviews() {
            super.layoutSubviews()
            guard map.frame != bounds, !bounds.isEmpty else { return }
            map.frame = bounds
            fallback.frame = bounds
            map.setCamera(camera, animated: false)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
            marker.markerTintColor = .white
            marker.glyphTintColor = UIColor(FMDesign.mapBase)
            marker.glyphImage = UIImage(systemName: "bus")
            marker.displayPriority = .required
            marker.isEnabled = false
            marker.titleVisibility = .hidden
            marker.subtitleVisibility = .hidden
            return marker
        }

        func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
            if fullyRendered {
                hasRenderedMap = true
                fallback.isHidden = true
            } else {
                showUnavailableMap()
            }
        }

        func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: any Error) {
            showUnavailableMap()
        }

        private func showUnavailableMap() {
            if !hasRenderedMap { fallbackLabel.text = "지도를 불러오지 못했어요." }
        }
    }
}
