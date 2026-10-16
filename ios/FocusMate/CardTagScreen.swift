import SwiftUI

/// 승차·하차 태그 화면의 차이. 조작·기하·타이밍은 같고 식별자·문구·이탈 규칙만 다르다.
enum CardTagKind: Equatable {
    case boarding, alighting

    var idPrefix: String { self == .boarding ? "boarding" : "alighting" }
    var screenID: String { self == .boarding ? "screen.boarding" : "alighting.tag" }
    var readyLCDText: String { self == .boarding ? "승차 준비" : "하차 준비" }
    var failureText: String {
        self == .boarding ? "승차 정보를 저장하지 못했어요. 카드를 다시 대주세요." : JourneyTimerDisplay.transitionFailureText
    }
    /// 하차는 되돌아갈 곳이 없다 — 뒤로가기를 숨기고 스와이프를 막고 첫 초점을 카드에 둔다(FR-3, AC-6).
    var locksNavigation: Bool { self == .alighting }
    fileprivate var terminalName: String { self == .boarding ? "승차 단말기" : "하차 단말기" }
    fileprivate var cardHint: String { self == .boarding ? "카드를 여기에 대면 승차해요. 눌러서 태그하기" : "카드를 여기에 대면 하차해요. 눌러서 태그하기" }
    fileprivate var debugActivateID: String { self == .boarding ? "test.activateBoardingCard" : "test.activateAlightingCard" }
}

/// 카드 태그(시안 kxUUR·JmXmQ·Vts6F). 화면에는 단말기·카드·올림 안내만 두고, 제목·정류장·단계·안내 문구는 낭독용으로만 둔다.
@MainActor
struct CardTagScreen: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    let controller: BoardingTagController
    let kind: CardTagKind
    let title: String
    /// 화면이 다시 나타나거나 상태가 바뀔 때 부른다. 하차는 저장 뒤 중단된 경로를 요약으로 정리한다.
    var onSettle: () -> Void = {}
    @State private var entered = false
    @State private var blink = false
    /// 터치 튐 연출을 실제로 실행한 횟수(동작 줄이기에서는 연출 없이 횟수만 센다).
    @State private var tapBounces = 0
    @State private var bounceOffset: CGFloat = 0
    @AccessibilityFocusState private var cardFocused: Bool
    @State private var requestsCardFocus = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private static let space = "cardTag"
    private let geometry = BoardingGeometry()

    private var reduceMotion: Bool { services.reduceMotion(system: systemReduceMotion) }
    private var prefix: String { kind.idPrefix }

    var body: some View {
        VStack(spacing: 0) {
            Text(title).font(.system(size: 1)).foregroundStyle(.clear).frame(width: 1, height: 1)
                .accessibilityLabel(title).accessibilityAddTraits(.isHeader).accessibilityIdentifier("\(prefix).title")
            Spacer(minLength: 24)
            terminal
                .opacity(entered || reduceMotion ? 1 : 0)
            Spacer(minLength: 40)
            Image(systemName: "chevron.up.2").font(.title2).foregroundStyle(.white.opacity(0.85))
                .accessibilityHidden(true)
                .padding(.bottom, 12)
            card
                .offset(y: entered || reduceMotion ? 0 : 80)
                .opacity(entered || reduceMotion ? 1 : 0)
            Spacer(minLength: 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(name: Self.space)
        .background(Color(red: 0x10 / 255, green: 0x11 / 255, blue: 0x12 / 255).ignoresSafeArea())
        .overlay(alignment: .bottom) { notices }
        .opacity(controller.phase == .fading || controller.phase == .finished ? 0 : 1)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: controller.phase == .fading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(kind.screenID)
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        // 승차는 뒤로가기를 남긴다 — 이탈하면 늦은 전환만 취소하고 저장은 유지한다(AC-14). 하차는 잠근다.
        .navigationBarBackButtonHidden(kind.locksNavigation)
        .background { if kind.locksNavigation { NavigationPopBlocker() } }
        .onAppear {
            if kind.locksNavigation {
                requestsCardFocus = true
                cardFocused = true
            }
            onSettle()
            guard !reduceMotion else { entered = true; return }
            withAnimation(.easeOut(duration: 0.38).delay(0.12)) { entered = true }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { blink = true }
        }
        .onDisappear {
            controller.cancelPendingTransition()
        }
        .onChange(of: controller.tapBounceCount) { _, count in
            tapBounces = count
            guard !reduceMotion else { return }
            withAnimation(.spring(duration: 0.18)) { bounceOffset = -14 }
            withAnimation(.spring(duration: 0.3).delay(0.18)) { bounceOffset = 0 }
        }
        .onChange(of: controller.phase) { _, _ in onSettle() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { controller.cancelPendingTransition() }
            else if phase == .active {
                controller.returnToForeground()
                onSettle()
            }
        }
        #if DEBUG
        .overlay(alignment: .topLeading) { diagnostics }
        #endif
    }

    private var terminal: some View {
        TimelineView(.everyMinute) { context in
            let time = BoardingClock.text(for: context.date)
            VStack(spacing: 16) {
                Capsule().fill(controller.isRecognized ? Color(red: 0.7, green: 0.85, blue: 0.75) : .gray.opacity(0.6))
                    .frame(height: 4).padding(.horizontal, 24)
                lcd(time: time)
                RoundedRectangle(cornerRadius: 20).fill(Color(red: 0x20 / 255, green: 0x23 / 255, blue: 0x24 / 255))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.32)))
                    .overlay(Image(systemName: "wave.3.right").font(.system(size: 40)).foregroundStyle(.white.opacity(0.7)))
                    .frame(width: geometry.tagAreaSize.width, height: geometry.tagAreaSize.height)
                    .background(GeometryReader { proxy in
                        Color.clear.onAppear { tagFrame = proxy.frame(in: .named(Self.space)); syncLayout() }
                            .onChange(of: proxy.frame(in: .named(Self.space))) { _, frame in tagFrame = frame; syncLayout() }
                    })
                    .accessibilityHidden(true)
                    .overlay(Color.clear.accessibilityElement().accessibilityLabel("태그 영역").accessibilityIdentifier("\(prefix).tagArea"))
            }
            .padding(.vertical, 15)
            .frame(width: 274)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color(red: 0x1B / 255, green: 0x1D / 255, blue: 0x1E / 255)))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.2)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Focus Mate \(kind.terminalName), \(time), \(controller.isRecognized ? "집중동행카드 인식됨" : kind.readyLCDText)")
            .accessibilityIdentifier("\(prefix).terminal")
        }
        .dynamicTypeSize(.large)
    }

    private func lcd(time: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Focus Mate").font(.system(size: 9)).foregroundStyle(Color(red: 0.75, green: 0.78, blue: 0.76))
                Spacer()
                Text(time).font(.system(size: 10, weight: .semibold)).monospacedDigit()
            }
            Divider()
            Group {
                if controller.isRecognized {
                    VStack(spacing: 6) {
                        Text(PassIdentity.displayName).font(.system(size: 18, weight: .semibold))
                        Image(systemName: "checkmark").font(.title3).foregroundStyle(Color(red: 0.7, green: 0.85, blue: 0.75))
                    }
                } else {
                    Text(kind.readyLCDText).font(.system(size: 18, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityValue(controller.isRecognized ? PassIdentity.displayName : kind.readyLCDText)
            .accessibilityIdentifier("\(prefix).lcdStatus")
        }
        .padding(12)
        .frame(height: 112)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0x09 / 255, green: 0x0B / 255, blue: 0x0C / 255)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.35)))
        .padding(.horizontal, 18)
    }

    @State private var tagFrame: CGRect = .zero

    @State private var cardRest: CGRect = .zero

    /// 바깥 틀(움직이지 않음)로 카드 기준 위치를 재고, 안쪽 카드만 오프셋으로 움직인다.
    private var card: some View {
        ZStack {
            PassFace(style: model.currentCardStyle)
                .frame(width: geometry.cardWidth)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 22)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .foregroundStyle(.white.opacity(controller.isRecognized ? 0 : (blink && !reduceMotion ? 0.18 : 0.55))))
                .offset(x: controller.cardOffset.width, y: controller.cardOffset.height + bounceOffset)
                // 끄는 동안은 손가락을 바로 따라가고, 되돌아갈 때만 부드럽게 움직인다.
                .animation(reduceMotion || controller.phase == .dragging ? nil : .spring(duration: 0.3), value: controller.cardOffset)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
                    .onChanged { controller.dragChanged(translation: $0.translation, reduceMotion: reduceMotion) }
                    .onEnded { controller.dragEnded(translation: $0.translation, reduceMotion: reduceMotion) })
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(PassIdentity.displayName)
                .accessibilityHint(kind.cardHint)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { controller.activate(reduceMotion: reduceMotion) }
                .accessibilityIdentifier("\(prefix).card")
                .accessibilityFocused($cardFocused)
        }
        .background(GeometryReader { proxy in
            Color.clear
                .onAppear { cardRest = proxy.frame(in: .named(Self.space)).insetBy(dx: 8, dy: 8); syncLayout() }
                .onChange(of: proxy.frame(in: .named(Self.space))) { _, frame in cardRest = frame.insetBy(dx: 8, dy: 8); syncLayout() }
        })
    }

    private func syncLayout() { controller.updateLayout(cardRest: cardRest, tagArea: tagFrame) }

    @ViewBuilder private var notices: some View {
        VStack(spacing: 8) {
            if controller.showsTapHint {
                Text("카드를 위로 밀어 단말기에 대주세요").font(.subheadline)
                    .accessibilityIdentifier("\(prefix).tapHint")
            }
            if controller.showsSaveFailure {
                Text(kind.failureText).font(.subheadline).foregroundStyle(.orange)
                    .accessibilityIdentifier("\(prefix).saveFailure")
            }
        }
        .multilineTextAlignment(.center)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .padding(.horizontal, 24).padding(.bottom, 8)
    }

    #if DEBUG
    private var diagnostics: some View {
        VStack(spacing: 0) {
            Text("태그 진단").accessibilityValue(diagnosticJSON).accessibilityIdentifier("test.\(prefix)")
            debugButton("카드 활성화", id: kind.debugActivateID) { controller.activate(reduceMotion: reduceMotion) }
            if kind == .alighting, let failure = services.failNextSave {
                debugButton("다음 저장 실패", id: "test.alighting.failNextSave") { failure.arm() }
            }
        }
        .font(.system(size: 1)).foregroundStyle(.clear)
    }

    private func debugButton(_ label: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 1)).foregroundStyle(.clear)
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .accessibilityLabel(label).accessibilityIdentifier(id)
    }

    private var diagnosticJSON: String {
        let phase: String = switch controller.phase {
        case .ready: "ready"
        case .dragging: "dragging"
        case .contacting: "contacting"
        case .held: "held"
        case .fading: "fading"
        case .finished: "finished"
        case .failed: "failed"
        case .abandoned: "abandoned"
        }
        let object: [String: Any] = ["phase": phase, "offsetY": Double(controller.cardOffset.height),
                                     "showsTapHint": controller.showsTapHint, "tapBounces": tapBounces,
                                     "focus": requestsCardFocus ? "card" : NSNull()]
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }
    #endif
}
