import MapKit
import SwiftUI

/// 여행 화면 배경 지도(FR-1~4·8·11·14). 판단은 컨트롤러가 하고 이 뷰는 그리기와 제스처 전달만 한다.
@MainActor
struct JourneyMapView: View {
    let map: JourneyMapController
    /// 하단 정보 높이. 지도 안전 영역 아래쪽에 더해 Apple 지도 표기를 하단 정보 위로 올린다.
    let bottomInset: CGFloat
    @State private var position: MapCameraPosition
    /// 버스 아이콘을 화면 기준 진행 방향으로 돌리기 위한 현재 지도 방위. 조작이 끝날 때만 갱신한다.
    @State private var renderedHeading: Double = 0
    /// 지도를 처음 만들 때 함께 넘긴 표식·덮개 다각형은 MapKit이 그리지 않는 일이 있어(정류장 점이 안 보이던 원인),
    /// 지도가 자리를 잡은 뒤에 더한다. 선은 처음부터 그린다.
    @State private var showsMarks = false

    init(map: JourneyMapController, bottomInset: CGFloat) {
        self.map = map
        self.bottomInset = bottomInset
        _position = State(initialValue: .camera(Self.camera(for: map.cameraTarget)))
    }

    var body: some View {
        // 앱이 옮길 때는 @State에 직접 대입하므로 setter는 MapKit(사용자 제스처)에서만 호출된다.
        Map(position: Binding(get: { position }, set: { new in
            position = new
            if new.positionedByUser { map.userMovedCamera() }
        }), interactionModes: [.pan, .zoom, .rotate]) {
            // 덮개(검정 33%)를 지도 안 다각형으로 깔아 노선선·표식이 그 위에 선명하게 그려지게 한다(R06과 같은 방식).
            if showsMarks {
                MapPolygon(coordinates: Self.scrimBox(around: map.destinationStop.point.coordinate))
                    .foregroundStyle(FMDesign.mapScrim)
            }
            // 시안 R13: 버스부터 도착까지(앞으로 갈 구간)는 노선 종류 색 3pt, 지나온 구간은 흰 선 2.5pt.
            MapPolyline(coordinates: map.travelledPoints.map(\.coordinate))
                .stroke(FMDesign.routePassed, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            MapPolyline(coordinates: map.remainingPoints.map(\.coordinate))
                .stroke(FMDesign.routeColor(kind: map.journey.routeKind),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
            ForEach(showsMarks ? Array(map.visibleStops.dropLast()) : [], id: \.id) { stop in
                Annotation("", coordinate: stop.point.coordinate, anchor: .center) {
                    Circle().fill(map.isPassed(stop) ? FMDesign.stopPassed : .white).frame(width: 7, height: 7)
                        .overlay(Circle().strokeBorder(FMDesign.stopStroke, lineWidth: 1))
                }
                .annotationTitles(.hidden)
            }
            // 도착: 검은 원에 노선색 테두리, 가운데 흰 점.
            if showsMarks {
            Annotation("", coordinate: map.destinationStop.point.coordinate, anchor: .center) {
                Circle().fill(FMDesign.stopStroke).frame(width: 16, height: 16)
                    .overlay(Circle().strokeBorder(FMDesign.routeColor(kind: map.journey.routeKind), lineWidth: 2.5))
                    .overlay(Circle().fill(.white).frame(width: 6, height: 6))
            }
            .annotationTitles(.hidden)
            }
            Annotation("", coordinate: map.bus.point.coordinate, anchor: .center) {
                BusTopMarker(color: FMDesign.busBodyColor(kind: map.journey.routeKind), width: 30)
                    .rotationEffect(.degrees(map.bus.headingDegrees - renderedHeading))
            }
            .annotationTitles(.hidden)
        }
        .mapStyle(mapStyle)
        .environment(\.colorScheme, .dark)
        .mapControls {
            MapCompass().mapControlVisibility(.hidden)
            MapPitchToggle().mapControlVisibility(.hidden)
            MapScaleView().mapControlVisibility(.hidden)
        }
        .background(FMDesign.mapBase)
        .safeAreaPadding(.bottom, bottomInset)
        .task {
            try? await Task.sleep(for: .milliseconds(600))
            showsMarks = true
        }
        .onMapCameraChange(frequency: .onEnd) { context in renderedHeading = context.camera.heading }
        .onChange(of: map.cameraTarget) { _, target in
            withAnimation(target.animated ? .linear(duration: 1) : nil) { position = .camera(Self.camera(for: target)) }
        }
        // MapKit 내부 요소(실제 지명·법적 표기 등)는 children: .ignore로도 접근성 트리에 남는다(T0).
        // 지도는 VoiceOver에서 하나의 요소로 읽혀야 하므로(FR-12) 내부를 숨기고 같은 자리에 대표 요소를 둔다.
        .accessibilityHidden(true)
        .overlay {
            Color.clear
                .allowsHitTesting(false)
                .accessibilityElement()
                .accessibilityLabel(JourneyMapDisplay.mapLabel)
                .accessibilityValue(JourneyMapDisplay.mapValue(next: map.nextStop.name,
                                                               destination: map.destinationStop.name))
                .accessibilityIdentifier("journey.map")
        }
    }

    /// 실제 장소(POI)는 가상 코스와 헷갈리지 않게 숨긴다(BR-1). 위성은 라벨 없는 3D 항공 사진(시안 기본)이다.
    private var mapStyle: MapStyle {
        switch map.state.theme {
        case .dark: .standard(elevation: .realistic, pointsOfInterest: .excludingAll)
        case .satellite: .imagery(elevation: .realistic)
        }
    }

    private static func scrimBox(around center: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        let d = 0.6
        return [
            CLLocationCoordinate2D(latitude: center.latitude - d, longitude: center.longitude - d),
            CLLocationCoordinate2D(latitude: center.latitude - d, longitude: center.longitude + d),
            CLLocationCoordinate2D(latitude: center.latitude + d, longitude: center.longitude + d),
            CLLocationCoordinate2D(latitude: center.latitude + d, longitude: center.longitude - d),
        ]
    }

    private static func camera(for target: JourneyCameraTarget) -> MapCamera {
        MapCamera(centerCoordinate: target.center.coordinate, distance: target.distanceMeters,
                  heading: target.headingDegrees, pitch: target.pitchDegrees)
    }
}

private extension CoursePoint {
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}
