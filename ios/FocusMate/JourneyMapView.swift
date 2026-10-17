import MapKit
import SwiftUI

/// 여행 화면 배경 지도(FR-1~4·8·11·14). 판단은 컨트롤러가 하고 이 뷰는 그리기와 제스처 전달만 한다.
@MainActor
struct JourneyMapView: View {
    let map: JourneyMapController
    /// 하단 정보 높이. 지도 안전 영역 아래쪽에 더해 Apple 지도 표기를 하단 정보 위로 올린다.
    let bottomInset: CGFloat
    @State private var position: MapCameraPosition
    /// 투영 각도를 아직 못 구했을 때 쓰는 현재 지도 방위. 조작이 끝날 때만 갱신한다.
    @State private var renderedHeading: Double = 0
    /// 지도를 처음 만들 때 함께 넘긴 표식·덮개 다각형은 MapKit이 그리지 않는 일이 있어(정류장 점이 안 보이던 원인),
    /// 지도가 자리를 잡은 뒤에 더한다. 선은 처음부터 그린다.
    @State private var showsMarks = false
    /// 버스 그림의 화면 회전 각도(투영으로 구함). 아직 못 구했으면 방위 - 카메라 방위로 대신한다.
    @State private var busScreenAngle: Double?
    private var shapes: RouteShapeStore { RouteShapeStore.shared }

    init(map: JourneyMapController, bottomInset: CGFloat) {
        self.map = map
        self.bottomInset = bottomInset
        _position = State(initialValue: .camera(Self.camera(for: map.cameraTarget)))
    }

    var body: some View {
        MapReader { proxy in
            mapContent
                .onMapCameraChange(frequency: .onEnd) { context in
                    renderedHeading = context.camera.heading
                    updateBusAngle(proxy)
                }
                .onChange(of: map.bus) { _, _ in updateBusAngle(proxy) }
        }
        .task(id: map.segmentRequests.first?.key) {
            map.apply(shape: shapes.shape(for: map.segmentRequests))
            await shapes.load(map.segmentRequests)
        }
        .onChange(of: shapes.revision) { _, _ in
            withAnimation(nil) { map.apply(shape: shapes.shape(for: map.segmentRequests)) }
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

    private var routeColor: Color { FMDesign.routeColor(kind: map.journey.routeKind) }

    private var mapContent: some View {
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
            // 노선 전체(탈 구간 앞뒤 포함)는 흐린 흰 선. 그 위에 지나온 구간은 흰 선, 앞으로 갈 구간은 노선색 굵은 선
            // (항공 사진 위에서 보이게 어두운 외곽선을 아래에 깐다). 모두 도로 경로를 따른다.
            MapPolyline(coordinates: map.contextPoints.map(\.coordinate))
                .stroke(FMDesign.routeRemaining, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            MapPolyline(coordinates: map.travelledPoints.map(\.coordinate))
                .stroke(FMDesign.routePassed, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            MapPolyline(coordinates: map.remainingPoints.map(\.coordinate))
                .stroke(Color.black.opacity(0.55), style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
            MapPolyline(coordinates: map.remainingPoints.map(\.coordinate))
                .stroke(routeColor, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            // 버스가 서 있는 정류장 점은 버스 그림 위로 올라오므로(표식 순서는 정할 수 없다) 그리지 않는다.
            ForEach(showsMarks ? map.visibleStops.dropLast().filter { !map.isUnderBus($0) } : [], id: \.id) { stop in
                Annotation("", coordinate: stop.point.coordinate, anchor: .center) { stopDot(stop) }
                    .annotationTitles(.hidden)
            }
            // 도착: 검은 원에 노선색 테두리, 가운데 흰 점.
            if showsMarks {
                Annotation("", coordinate: map.destinationStop.point.coordinate, anchor: .center) {
                    Circle().fill(FMDesign.stopStroke).frame(width: 16, height: 16)
                        .overlay(Circle().strokeBorder(routeColor, lineWidth: 2.5))
                        .overlay(Circle().fill(.white).frame(width: 6, height: 6))
                }
                .annotationTitles(.hidden)
            }
            // 다음 정류장 이름표: 점 바로 아래 작은 검은 라벨.
            if showsMarks && map.state.showsStops && !map.bus.isArrived {
                Annotation("", coordinate: map.nextStop.point.coordinate, anchor: .top) {
                    Text(map.nextStop.name)
                        .font(FontCatalog.fixed(11, weight: .semibold)).foregroundStyle(.white)
                        .lineLimit(1).fixedSize()
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(FMDesign.ctaStroke, lineWidth: 1))
                        .padding(.top, 11)
                }
                .annotationTitles(.hidden)
            }
            Annotation("", coordinate: map.bus.point.coordinate, anchor: .center) {
                // 앞(위쪽)이 화면에서 진행 방향을 보게 돌린다. 기울인 카메라에서는 투영한 화면 각도를 쓴다.
                BusTopMarker(color: FMDesign.busBodyColor(kind: map.journey.routeKind), width: 30)
                    .rotationEffect(.degrees(busScreenAngle ?? (map.bus.headingDegrees - renderedHeading)))
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
        .onChange(of: map.cameraTarget) { _, target in
            withAnimation(target.animated ? .linear(duration: 1) : nil) { position = .camera(Self.camera(for: target)) }
        }
    }

    /// 지난 정류장 회색 작은 점, 다음 정류장 노선색 링 + 흰 점(조금 크게), 남은 정류장 흰 점.
    @ViewBuilder private func stopDot(_ stop: CourseStop) -> some View {
        if map.isPassed(stop) {
            Circle().fill(FMDesign.stopPassed).frame(width: 5, height: 5)
                .overlay(Circle().strokeBorder(FMDesign.stopStroke, lineWidth: 1))
        } else if stop.index == map.nextStopIndex {
            Circle().fill(.white).frame(width: 12, height: 12)
                .overlay(Circle().strokeBorder(routeColor, lineWidth: 3))
                .overlay(Circle().strokeBorder(FMDesign.stopStroke, lineWidth: 0.75).padding(-0.75))
        } else {
            Circle().fill(.white).frame(width: 7, height: 7)
                .overlay(Circle().strokeBorder(FMDesign.stopStroke, lineWidth: 1))
        }
    }

    /// 버스 위치와 진행 방향으로 20m 앞 지점을 화면 좌표로 바꿔 화면상 각도(위 0°, 시계 방향)를 구한다.
    /// 기울인 카메라에서는 북쪽 기준 방위에서 카메라 방위만 빼는 것으로는 화면 방향이 맞지 않는다.
    /// 앞뒤 값이 크게 뛰지 않게(359° → 1°) 직전 각도에 가까운 쪽으로 이어 붙인다.
    private func updateBusAngle(_ proxy: MapProxy) {
        let bus = map.bus.point
        let ahead = RouteShape.offset(bus, headingDegrees: map.bus.headingDegrees, meters: 20)
        guard let a = proxy.convert(bus.coordinate, to: .local), let b = proxy.convert(ahead.coordinate, to: .local),
              hypot(b.x - a.x, b.y - a.y) > 0.5 else { return }
        let angle = atan2(b.x - a.x, -(b.y - a.y)) * 180 / .pi
        let previous = busScreenAngle ?? angle
        busScreenAngle = previous + (angle - previous + 540).truncatingRemainder(dividingBy: 360) - 180
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
