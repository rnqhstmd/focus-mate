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
            // 남은 구간은 흐린 흰색, 지나온 구간은 노선 종류 색(지선 초록·간선 파랑).
            MapPolyline(coordinates: map.remainingPoints.map(\.coordinate))
                .stroke(FMDesign.routeRemaining, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            MapPolyline(coordinates: map.travelledPoints.map(\.coordinate))
                .stroke(FMDesign.routeColor(kind: map.journey.routeKind),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            ForEach(map.visibleStops, id: \.id) { stop in
                Annotation("", coordinate: stop.point.coordinate) {
                    Circle().fill(map.isPassed(stop) ? FMDesign.stopPassed : .white).frame(width: 10, height: 10)
                        .overlay(Circle().stroke(FMDesign.stopStroke, lineWidth: 1.5))
                }
                .annotationTitles(.hidden)
            }
            Annotation("", coordinate: map.destinationStop.point.coordinate) {
                Image(systemName: "flag.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(.orange)
            }
            .annotationTitles(.hidden)
            Annotation("", coordinate: map.bus.point.coordinate) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                    .padding(6).background(Circle().fill(FMDesign.routeColor(kind: map.journey.routeKind)))
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
        .overlay { FMMapScrim() }
        .background(FMDesign.mapBase)
        .safeAreaPadding(.bottom, bottomInset)
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

    private static func camera(for target: JourneyCameraTarget) -> MapCamera {
        MapCamera(centerCoordinate: target.center.coordinate, distance: target.distanceMeters,
                  heading: target.headingDegrees, pitch: target.pitchDegrees)
    }
}

private extension CoursePoint {
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}
