import SwiftUI

/// 여행 화면. 출발 확인 전에는 출발 안내(시안 DO8HO)만 보이고, '시작' 뒤에는 실제 분 타이머를 둔다.
/// 출발한 여행 화면에서 메인으로 가는 길은 일시정지 중 포기뿐이다(뒤로가기 숨김·스와이프 차단·모델 가드, W07).
@MainActor
struct JourneyView: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    /// 출발 안내·타이머 컨트롤러는 화면이 처음 나타날 때 한 번만 만든다.
    @State private var briefing: DepartureBriefingController?
    @State private var timer: JourneyTimerController?
    /// 지도 상태는 이 화면 수명 동안만 있다. 다시 들어오면 기본값으로 시작한다(FR-9).
    @State private var map: JourneyMapController?
    /// 도착 안내. 타이머가 생긴 뒤 여정 내용으로 한 번 만든다(정류장 이름 고정).
    @State private var arrival: ArrivalBriefingController?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        Group {
            if let briefing {
                JourneyScreen(model: model, services: services, briefing: briefing, timer: timer, map: map, arrival: arrival)
            }
            else { Color.clear }
        }
        .onAppear {
            if briefing == nil { briefing = DepartureBriefingController(confirmer: model, sleep: services.sleep) }
            ensureTimer()
        }
        .onChange(of: model.activeJourney?.phase) { _, _ in ensureTimer() }
        // 정류장 데이터가 화면을 연 뒤에 준비되면 그때 지도를 붙인다.
        .onChange(of: model.routeCatalog != nil) { _, _ in ensureMap() }
        // 정상 경로에서는 이탈이 없다. 재생성될 때 일시정지 규칙과 저장을 맞추기 위한 방어다.
        .onDisappear {
            timer?.leave()
            map?.leave()
        }
    }

    /// '시작'을 이 화면에서 직접 봤거나 메인 이어가기로 들어온 경우에만 바로 진행한다. 저장된 진행 상태만으로는 자동 시작하지 않는다.
    private func ensureTimer() {
        guard timer == nil, let journey = model.activeJourney, journey.phase == .departed else { return }
        let resumed = model.consumeResumeEntry(journeyID: journey.id)
        let liveActivity = JourneyLiveActivitySync(journey: journey, gateway: services.liveActivities)
        timer = JourneyTimerController(journey: journey, autoStart: briefing?.isConfirmed == true || resumed, saver: model,
                                       clock: services.clock, ticker: services.makeTicker(), announcer: services.announcer,
                                       observer: liveActivity)
        if resumed { services.announcer.announce(JourneyLifecycleText.resumeAnnouncement) }
        if let timer {
            arrival = ArrivalBriefingController(content: ArrivalBriefingContent(journey: journey), progress: timer,
                                                confirmer: model, sleep: services.sleep)
        }
        ensureMap()
    }

    /// 정류장 데이터가 없거나 저장 도착지가 계산값과 다르면 지도 없이 W05 배치로 둔다(BR-12).
    private func ensureMap() {
        guard map == nil, let timer, let journey = model.activeJourney, let catalog = model.routeCatalog else { return }
        if let course = CourseJourney(journey: journey, catalog: catalog) {
            map = JourneyMapController(journey: course, status: timer.status, elapsedSeconds: timer.elapsedSeconds,
                                       reduceMotion: services.reduceMotion(system: systemReduceMotion))
        }
    }
}

@MainActor
private struct JourneyScreen: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    let briefing: DepartureBriefingController
    let timer: JourneyTimerController?
    let map: JourneyMapController?
    let arrival: ArrivalBriefingController?
    @AccessibilityFocusState private var startFocused: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private var reduceMotion: Bool { services.reduceMotion(system: systemReduceMotion) }
    private var awaitingDeparture: Bool { model.activeJourney?.phase == .awaitingDeparture && !briefing.isConfirmed }
    private var arrived: Bool { timer?.status == .arrived }

    var body: some View {
        // Group은 수식어를 자식마다 나눠 붙여 안쪽 식별자를 덮으므로, 컨테이너 하나로 감싼다.
        ZStack {
            if awaitingDeparture { departureBriefing }
            else if let timer {
                // 도착하면 타이머·지도 내용은 비우고 도착 안내를 덮는다(BR-7). 타이머 생명주기는 유지한다.
                let concealed = arrived && arrival != nil
                #if DEBUG
                JourneyTimerView(controller: timer, map: map, reduceMotion: reduceMotion, concealed: concealed, path: model.path)
                #else
                JourneyTimerView(controller: timer, map: map, reduceMotion: reduceMotion, concealed: concealed)
                #endif
                if concealed, let arrival {
                    ArrivalBriefingView(controller: arrival, model: model, reduceMotion: reduceMotion)
                }
            } else { Color.clear }
        }
        // 하단 자리를 예약하므로 큰 글씨에서도 타이머 버튼과 겹치지 않는다. 일시정지가 아니면 버튼 없이 아래 여백만 남는다.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let timer, !awaitingDeparture { JourneyAbandonBar(abandoner: model, timer: timer) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.journey")
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(NavigationPopBlocker())
        .task { if awaitingDeparture { await briefing.begin(reduceMotion: reduceMotion) } }
        .task(id: arrived) { if arrived, let arrival { await arrival.begin(reduceMotion: reduceMotion) } }
        // 생명주기는 여기 한 곳에서 단계별로 나눈다. 비활성(제어 센터 등)은 무시하고 시간은 계속 흐른다.
        .onChange(of: scenePhase) { _, phase in
            if awaitingDeparture {
                if phase == .background { briefing.reset() }
                else if phase == .active, !briefing.showsStart {
                    Task { await briefing.begin(reduceMotion: reduceMotion) }
                }
            } else if let timer {
                if phase == .background {
                    timer.enterBackground()
                    if arrived { arrival?.reset() }
                } else if phase == .active {
                    services.beforeForeground()
                    timer.returnToForeground()
                    if arrived, let arrival, !arrival.showsConfirm {
                        Task { await arrival.begin(reduceMotion: reduceMotion) }
                    }
                }
            }
        }
        .onChange(of: briefing.focusTarget) { _, target in startFocused = target == .startButton }
        #if DEBUG
        .overlay(alignment: .topLeading) { diagnostics }
        .overlay(alignment: .top) { testControls }
        #endif
    }

    private var departureBriefing: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Image(systemName: "bus.fill")
                        .font(.system(size: 44, weight: .regular)).accessibilityHidden(true)
                        .padding(.bottom, 36)
                    sentences
                    if briefing.showsStart {
                        Button { briefing.confirm() } label: {
                            Text("시작")
                                .font(FontCatalog.style(.body, weight: .semibold)).padding(.horizontal, 24)
                                .frame(minWidth: 160, minHeight: 52)
                                .foregroundStyle(.black)
                                .background(Color(white: 0.95), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .frame(width: 160)
                        .padding(.top, 64)
                        .transition(.opacity)
                        .accessibilityIdentifier("journey.start")
                        .accessibilityFocused($startFocused)
                    }
                    if briefing.showsSaveFailure {
                        Text("출발을 저장하지 못했어요. 다시 눌러주세요.").font(FontCatalog.style(.subheadline)).foregroundStyle(.orange)
                            .accessibilityIdentifier("journey.saveFailure")
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32).padding(.vertical, 24)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
        .foregroundStyle(.white)
        .background {
            GeometryReader { background in
                SceneMapBackdrop(model: model, stationID: model.activeJourney?.originStopID,
                                 bottomInset: max(0, background.size.height - 200))
                    .overlay(JourneyBriefingShade())
            }
            .ignoresSafeArea()
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: briefing.showsStart)
        // 중첩 컨테이너 식별자는 스크롤 뷰에 흡수될 수 있어, 안내 단계 표지는 별도 요소로 둔다.
        .overlay(alignment: .topLeading) {
            Color.clear.frame(width: 1, height: 1).accessibilityElement()
                .accessibilityLabel("출발 안내").accessibilityIdentifier("journey.briefing")
        }
    }

    @ViewBuilder private var sentences: some View {
        if briefing.showsAll {
            VStack(spacing: 12) {
                ForEach(DepartureBriefingController.sentences, id: \.self) { Text($0).font(FontCatalog.style(.title2, weight: .semibold)) }
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue(DepartureBriefingController.sentences.joined(separator: " "))
            .accessibilityIdentifier("journey.briefingSentence")
        } else {
            let sentence = DepartureBriefingController.sentences[briefing.visibleIndex]
            Text(sentence).font(FontCatalog.style(.title2, weight: .semibold))
                .id(briefing.visibleIndex)
                .transition(.opacity)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: briefing.visibleIndex)
                .accessibilityValue(sentence)
                .accessibilityIdentifier("journey.briefingSentence")
        }
    }

    #if DEBUG
    /// 수동 시계일 때만 상단 가운데에 겹쳐 둔다. 왼쪽 위 일시정지와 오른쪽 위 지도 도구 사이 빈 자리라 겹치지 않고,
    /// 자리를 예약하지 않으므로 상단 20% 배치(AC-2)를 밀어내지 않는다. 아래에 두면 지도 테마 시트에 가려진다.
    @ViewBuilder private var testControls: some View {
        if let clock = services.testClock {
            HStack(spacing: 0) {
                testButton("1초 진행", id: "test.clock.advance1") { clock.advance(by: .seconds(1)) }
                testButton("10초 진행", id: "test.clock.advance10") { clock.advance(by: .seconds(10)) }
                testButton("60초 진행", id: "test.clock.advance60") { clock.advance(by: .seconds(60)) }
                testButton("600초 진행", id: "test.clock.advance600") { clock.advance(by: .seconds(600)) }
                testButton("복귀 시 600초", id: "test.clock.armForeground600") { clock.armForegroundAdvance(by: .seconds(600)) }
                if let failure = services.failNextSave {
                    testButton("다음 저장 실패", id: "test.failNextSave") { failure.arm() }
                }
            }
            .frame(height: 44)
        }
    }

    private func testButton(_ label: String, id: String, action: @escaping () -> Void) -> some View {
        // 거의 투명한 opacity는 히트 테스트에서 빠질 수 있어, 불투명 뷰에 글자만 투명하게 두고 터치 영역을 명시한다.
        Button(action: action) {
            Text(label).font(.system(size: 1)).foregroundStyle(.clear)
                .frame(width: 44, height: 44).background(Color.black).contentShape(Rectangle())
        }
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }

    private var diagnostics: some View {
        let object: [String: Any] = ["index": briefing.visibleIndex, "showsAll": briefing.showsAll,
                                     "showsStart": briefing.showsStart,
                                     "focus": briefing.focusTarget == .startButton ? "start" : "none"]
        let json = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
            .map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return Text("출발 안내 진단").font(.system(size: 1)).foregroundStyle(.clear)
            .accessibilityValue(json).accessibilityIdentifier("test.briefing")
    }
    #endif
}

/// Full-screen briefing shade from the final HTML; shared only by departure and arrival.
struct JourneyBriefingShade: View {
    var body: some View {
        LinearGradient(stops: [
            .init(color: Color(red: 5 / 255, green: 8 / 255, blue: 10 / 255).opacity(0.25), location: 0),
            .init(color: Color(red: 5 / 255, green: 8 / 255, blue: 10 / 255).opacity(0.65), location: 0.38),
            .init(color: Color(red: 5 / 255, green: 8 / 255, blue: 10 / 255).opacity(0.94), location: 0.74),
            .init(color: .black, location: 1)
        ], startPoint: .top, endPoint: .bottom)
        // Keep native MapKit attribution in the upper 200pt readable beneath the shade.
        .mask {
            LinearGradient(stops: [
                .init(color: .black.opacity(0.4), location: 0),
                .init(color: .black.opacity(0.4), location: 0.25),
                .init(color: .black, location: 0.45),
                .init(color: .black, location: 1)
            ], startPoint: .top, endPoint: .bottom)
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}
