import SwiftUI

/// 여행 화면. 출발 확인 전에는 출발 안내(시안 DO8HO)만 보이고, '시작' 뒤에는 실제 분 타이머를 둔다.
/// 출발한 여행 화면에서는 메인으로 돌아가지 않는다(뒤로가기 숨김·스와이프 차단·모델 가드). 나가기는 W07이다.
@MainActor
struct JourneyView: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    /// 출발 안내·타이머 컨트롤러는 화면이 처음 나타날 때 한 번만 만든다.
    @State private var briefing: DepartureBriefingController?
    @State private var timer: JourneyTimerController?

    var body: some View {
        Group {
            if let briefing { JourneyScreen(model: model, services: services, briefing: briefing, timer: timer) }
            else { Color.clear }
        }
        .onAppear {
            if briefing == nil { briefing = DepartureBriefingController(confirmer: model, sleep: services.sleep) }
            ensureTimer()
        }
        .onChange(of: model.activeJourney?.phase) { _, _ in ensureTimer() }
        // 정상 경로에서는 이탈이 없다. 재생성될 때 일시정지 규칙과 저장을 맞추기 위한 방어다.
        .onDisappear { timer?.leave() }
    }

    /// '시작'을 이 화면에서 직접 본 경우에만 바로 진행한다. 저장된 진행 상태만으로는 자동 시작하지 않는다.
    private func ensureTimer() {
        guard timer == nil, let journey = model.activeJourney, journey.phase == .departed else { return }
        timer = JourneyTimerController(journey: journey, autoStart: briefing?.isConfirmed == true, saver: model,
                                       clock: services.clock, ticker: services.makeTicker(), announcer: services.announcer)
    }
}

@MainActor
private struct JourneyScreen: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    let briefing: DepartureBriefingController
    let timer: JourneyTimerController?
    @AccessibilityFocusState private var startFocused: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private var reduceMotion: Bool { services.reduceMotion(system: systemReduceMotion) }
    private var awaitingDeparture: Bool { model.activeJourney?.phase == .awaitingDeparture && !briefing.isConfirmed }

    var body: some View {
        // Group은 수식어를 자식마다 나눠 붙여 안쪽 식별자를 덮으므로, 컨테이너 하나로 감싼다.
        ZStack {
            if awaitingDeparture { departureBriefing }
            else if let timer {
                #if DEBUG
                JourneyTimerView(controller: timer, reduceMotion: reduceMotion, path: model.path)
                #else
                JourneyTimerView(controller: timer, reduceMotion: reduceMotion)
                #endif
            } else { Color.clear }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.journey")
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(NavigationPopBlocker())
        .task { if awaitingDeparture { await briefing.begin(reduceMotion: reduceMotion) } }
        // 생명주기는 여기 한 곳에서 단계별로 나눈다. 비활성(제어 센터 등)은 무시하고 시간은 계속 흐른다.
        .onChange(of: scenePhase) { _, phase in
            if awaitingDeparture {
                if phase == .background { briefing.reset() }
                else if phase == .active, !briefing.showsStart {
                    Task { await briefing.begin(reduceMotion: reduceMotion) }
                }
            } else if let timer {
                if phase == .background { timer.enterBackground() }
                else if phase == .active {
                    services.beforeForeground()
                    timer.returnToForeground()
                }
            }
        }
        .onChange(of: briefing.focusTarget) { _, target in startFocused = target == .startButton }
        #if DEBUG
        .overlay(alignment: .topLeading) { diagnostics }
        .safeAreaInset(edge: .top) { testControls }
        #endif
    }

    private var departureBriefing: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 40) {
                    Image(systemName: "bus").font(.system(size: 44, weight: .semibold)).accessibilityHidden(true)
                    sentences
                    if briefing.showsStart {
                        Button { briefing.confirm() } label: {
                            Text("시작").font(.headline).foregroundStyle(.black)
                                .frame(minWidth: 160, minHeight: 44).padding(.vertical, 8).padding(.horizontal, 24)
                                .background(Color(white: 0.95), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("journey.start")
                        .accessibilityFocused($startFocused)
                    }
                    if briefing.showsSaveFailure {
                        Text("출발을 저장하지 못했어요. 다시 눌러주세요.").font(.subheadline).foregroundStyle(.orange)
                            .accessibilityIdentifier("journey.saveFailure")
                    }
                }
                .multilineTextAlignment(.center)
                .padding(24)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
        .foregroundStyle(.white)
        .background(LinearGradient(colors: [Color(white: 0.12), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        // 중첩 컨테이너 식별자는 스크롤 뷰에 흡수될 수 있어, 안내 단계 표지는 별도 요소로 둔다.
        .overlay(alignment: .topLeading) {
            Color.clear.frame(width: 1, height: 1).accessibilityElement()
                .accessibilityLabel("출발 안내").accessibilityIdentifier("journey.briefing")
        }
    }

    @ViewBuilder private var sentences: some View {
        if briefing.showsAll {
            VStack(spacing: 12) {
                ForEach(DepartureBriefingController.sentences, id: \.self) { Text($0).font(.title2.bold()) }
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue(DepartureBriefingController.sentences.joined(separator: " "))
            .accessibilityIdentifier("journey.briefingSentence")
        } else {
            let sentence = DepartureBriefingController.sentences[briefing.visibleIndex]
            Text(sentence).font(.title2.bold())
                .id(briefing.visibleIndex)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: briefing.visibleIndex)
                .accessibilityValue(sentence)
                .accessibilityIdentifier("journey.briefingSentence")
        }
    }

    #if DEBUG
    /// 수동 시계일 때만 상단 한 줄에 둔다. 레이아웃이 자리를 예약하므로 큰 글씨에서도 타이머 버튼과 겹치지 않는다.
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
                Spacer(minLength: 0)
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
