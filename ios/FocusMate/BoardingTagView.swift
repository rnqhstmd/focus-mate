import SwiftUI

/// 승차 태그(시안 kxUUR·JmXmQ·Vts6F). 화면에는 단말기·카드·올림 안내만 두고, 제목·정류장·단계·안내 문구는 낭독용으로만 둔다.
@MainActor
struct BoardingTagView: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    /// 컨트롤러는 화면이 처음 나타날 때 한 번만 만든다(뷰 값이 다시 만들어져도 새로 만들지 않는다).
    @State private var controller: BoardingTagController?

    var body: some View {
        Group {
            if let controller { BoardingTagScreen(model: model, services: services, controller: controller) }
            else { Color.clear }
        }
        .onAppear {
            guard controller == nil else { return }
            controller = BoardingTagController(
                boarder: services.makeBoarder(model), haptics: services.haptics, announcer: services.announcer,
                sleep: services.sleep, holdSleep: services.boardingHoldSleep,
                onFinished: { [weak model] in
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { model?.finishBoardingTransition() }
                })
        }
    }
}

@MainActor
private struct BoardingTagScreen: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    let controller: BoardingTagController
    @State private var entered = false
    @State private var blink = false
    /// 터치 튐 연출을 실제로 실행한 횟수(동작 줄이기에서는 연출 없이 횟수만 센다).
    @State private var tapBounces = 0
    @State private var bounceOffset: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private static let space = "boarding"
    private let geometry = BoardingGeometry()

    private var reduceMotion: Bool { services.reduceMotion(system: systemReduceMotion) }

    var body: some View {
        VStack(spacing: 0) {
            Text(titleLabel).font(.system(size: 1)).foregroundStyle(.clear).frame(width: 1, height: 1)
                .accessibilityLabel(titleLabel).accessibilityAddTraits(.isHeader).accessibilityIdentifier("boarding.title")
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
        .background(Color(red: 0x0F / 255, green: 0x13 / 255, blue: 0x11 / 255).ignoresSafeArea())
        .overlay(alignment: .bottom) { notices }
        .opacity(controller.phase == .fading || controller.phase == .finished ? 0 : 1)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: controller.phase == .fading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.boarding")
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        // 인식 후에도 뒤로가기는 남긴다 — 이탈하면 늦은 전환만 취소하고 저장은 유지한다(AC-14).
        .onAppear {
            guard !reduceMotion else { entered = true; return }
            withAnimation(.easeOut(duration: 0.38).delay(0.12)) { entered = true }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { blink = true }
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { controller.cancelPendingTransition() }
            else if phase == .active { controller.returnToForeground() }
        }
        #if DEBUG
        .overlay(alignment: .topLeading) { diagnostics }
        #endif
    }

    private var titleLabel: String {
        let origin = model.confirmedPreparation?.originName ?? ""
        return "승차 태그, \(origin), 승차 단계. 카드를 위로 밀어 단말기에 대주세요"
    }

    private var terminal: some View {
        TimelineView(.everyMinute) { context in
            let time = BoardingClock.text(for: context.date)
            VStack(spacing: 16) {
                Capsule().fill(controller.isRecognized ? Color(red: 0.7, green: 0.85, blue: 0.75) : .gray.opacity(0.6))
                    .frame(height: 4).padding(.horizontal, 24)
                lcd(time: time)
                RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.18)))
                    .overlay(Image(systemName: "wave.3.right").font(.system(size: 40)).foregroundStyle(.white.opacity(0.7)))
                    .frame(width: geometry.tagAreaSize.width, height: geometry.tagAreaSize.height)
                    .background(GeometryReader { proxy in
                        Color.clear.onAppear { tagFrame = proxy.frame(in: .named(Self.space)); syncLayout() }
                            .onChange(of: proxy.frame(in: .named(Self.space))) { _, frame in tagFrame = frame; syncLayout() }
                    })
                    .accessibilityHidden(true)
                    .overlay(Color.clear.accessibilityElement().accessibilityLabel("태그 영역").accessibilityIdentifier("boarding.tagArea"))
            }
            .padding(.vertical, 18)
            .frame(width: 274)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color(white: 0.11)))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.2)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Focus Mate 승차 단말기, \(time), \(controller.isRecognized ? "집중동행카드 인식됨" : "승차 준비")")
            .accessibilityIdentifier("boarding.terminal")
        }
        .dynamicTypeSize(.large)
    }

    private func lcd(time: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Focus Mate").font(.footnote).foregroundStyle(.secondary)
                Spacer()
                Text(time).font(.footnote.weight(.semibold)).monospacedDigit()
            }
            Divider()
            Group {
                if controller.isRecognized {
                    VStack(spacing: 6) {
                        Text(PassIdentity.displayName).font(.title3.bold())
                        Image(systemName: "checkmark").font(.title3).foregroundStyle(Color(red: 0.7, green: 0.85, blue: 0.75))
                    }
                } else {
                    Text("승차 준비").font(.title3.bold())
                }
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .accessibilityElement(children: .ignore)
            .accessibilityValue(controller.isRecognized ? PassIdentity.displayName : "승차 준비")
            .accessibilityIdentifier("boarding.lcdStatus")
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2)))
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
                    .foregroundStyle(.white.opacity(controller.isRecognized ? 0 : (blink && !reduceMotion ? 0.25 : 0.7))))
                .offset(x: controller.cardOffset.width, y: controller.cardOffset.height + bounceOffset)
                // 끄는 동안은 손가락을 바로 따라가고, 되돌아갈 때만 부드럽게 움직인다.
                .animation(reduceMotion || controller.phase == .dragging ? nil : .spring(duration: 0.3), value: controller.cardOffset)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
                    .onChanged { controller.dragChanged(translation: $0.translation, reduceMotion: reduceMotion) }
                    .onEnded { controller.dragEnded(translation: $0.translation, reduceMotion: reduceMotion) })
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(PassIdentity.displayName)
                .accessibilityHint("카드를 여기에 대면 승차해요. 눌러서 태그하기")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { controller.activate(reduceMotion: reduceMotion) }
                .accessibilityIdentifier("boarding.card")
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
                    .accessibilityIdentifier("boarding.tapHint")
            }
            if controller.showsSaveFailure {
                Text("승차 정보를 저장하지 못했어요. 카드를 다시 대주세요.").font(.subheadline).foregroundStyle(.orange)
                    .accessibilityIdentifier("boarding.saveFailure")
            }
        }
        .multilineTextAlignment(.center)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .padding(.horizontal, 24).padding(.bottom, 8)
    }

    #if DEBUG
    private var diagnostics: some View {
        VStack(spacing: 0) {
            Text("승차 진단").accessibilityValue(diagnosticJSON).accessibilityIdentifier("test.boarding")
            Button { controller.activate(reduceMotion: reduceMotion) } label: {
                Text("카드 활성화").font(.system(size: 1)).foregroundStyle(.clear)
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .accessibilityLabel("카드 활성화").accessibilityIdentifier("test.activateBoardingCard")
        }
        .font(.system(size: 1)).foregroundStyle(.clear)
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
                                     "showsTapHint": controller.showsTapHint, "tapBounces": tapBounces]
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }
    #endif
}
