import SwiftUI

/// 승차·하차 태그 화면의 차이. 조작·기하·타이밍은 같고 식별자·문구·이탈 규칙만 다르다.
enum CardTagKind: Equatable {
    case boarding, alighting

    var idPrefix: String { self == .boarding ? "boarding" : "alighting" }
    var screenID: String { self == .boarding ? "screen.boarding" : "alighting.tag" }
    /// 낭독용 LCD 상태 값.
    var readyLCDText: String { self == .boarding ? "승차 준비" : "하차 준비" }
    /// 화면에 보이는 LCD 대기 문구(R27 "작은 시작이 / 오늘을 바꿔요.", R28 "하차 준비").
    var readyLCDDisplay: String { self == .boarding ? "작은 시작이\n오늘을 바꿔요." : "하차 준비" }
    /// LCD 아래쪽 안내(R28). 승차 시안에는 없다.
    var readyLCDHint: String? { self == .boarding ? nil : "아래 태그 영역에 카드를 대주세요" }
    /// 화면 아래 안내. 승차는 카드를 눌렀을 때만, 하차는 늘 보인다(R27·R28).
    static let pushHint = "카드를 위의 단말기로 올려주세요"
    /// 하차 인식 뒤 아래 안내(R29).
    static let alightedHint = "하차 완료 · 이번 여행을 기록했어요"
    var failureText: String {
        self == .boarding ? "승차 정보를 저장하지 못했어요. 카드를 다시 대주세요." : JourneyTimerDisplay.transitionFailureText
    }
    /// 하차는 되돌아갈 곳이 없다 — 스와이프를 막고 첫 초점을 카드에 둔다(FR-3, AC-6).
    /// 뒤로 버튼은 시안(R27 DISABLED)대로 승차·하차 모두 숨긴다(AC-14 시안 우선 변경).
    var locksNavigation: Bool { self == .alighting }
    fileprivate var terminalName: String { self == .boarding ? "승차 단말기" : "하차 단말기" }
    fileprivate var cardHint: String { self == .boarding ? "카드를 여기에 대면 승차해요. 눌러서 태그하기" : "카드를 여기에 대면 하차해요. 눌러서 태그하기" }
    fileprivate var debugActivateID: String { self == .boarding ? "test.activateBoardingCard" : "test.activateAlightingCard" }
}

/// 카드 태그(시안 R27·R12·R42 승차, R28·R29 하차). 승차는 단말기·카드·올림 화살표만 보이고, 하차는 단계·제목·도착 정류장·안내까지 보인다.
@MainActor
struct CardTagScreen: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    let controller: BoardingTagController
    let kind: CardTagKind
    let title: String
    /// LCD 오른쪽 위 값. 하차는 노선 번호(R28 "2014"), 없으면 현재 시각(R27 "20:00").
    var lcdTrailing: String? = nil
    /// 하차 제목 아래 "○○에 도착"(R28).
    var subtitle: String? = nil
    /// 화면이 다시 나타나거나 상태가 바뀔 때 부른다. 하차는 저장 뒤 중단된 경로를 요약으로 정리한다.
    var onSettle: () -> Void = {}
    @State private var entered = false
    /// 터치 튐 연출을 실제로 실행한 횟수(동작 줄이기에서는 연출 없이 횟수만 센다).
    @State private var tapBounces = 0
    @State private var bounceOffset: CGFloat = 0
    @AccessibilityFocusState private var cardFocused: Bool
    @State private var requestsCardFocus = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private static let space = "cardTag"
    private let geometry = BoardingGeometry()
    /// 시안 R12·R29: 인식되면 카드가 211x123(0.78배)으로 줄어 태그 영역 가운데에 놓인다.
    private static let recognizedScale: CGFloat = 211 / 270
    private static let background = Color(hex: 0x101411)
    private static let hintColor = Color(hex: 0xBDC8BF)

    private var reduceMotion: Bool { services.reduceMotion(system: systemReduceMotion) }
    private var prefix: String { kind.idPrefix }

    var body: some View {
        VStack(spacing: 0) {
            Text(title).font(.system(size: 1)).foregroundStyle(.clear).frame(width: 1, height: 1)
                .accessibilityLabel(title).accessibilityAddTraits(.isHeader).accessibilityIdentifier("\(prefix).title")
            if kind == .alighting {
                alightingHeader
            } else {
                Color.clear.frame(height: 128)
            }
            terminal
                .opacity(entered || reduceMotion ? 1 : 0)
            if kind == .alighting {
                Color.clear.frame(height: 61)
            } else {
                Color.clear.frame(height: 73)
                Image(systemName: "chevron.up.2").font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(hex: 0xC5CFC7))
                    .frame(width: 22, height: 22)
                    .opacity(controller.isRecognized ? 0 : 1)
                    .accessibilityHidden(true)
                Color.clear.frame(height: 21)
            }
            card
                .offset(y: entered || reduceMotion ? 0 : 80)
                .opacity(entered || reduceMotion ? 1 : 0)
            Color.clear.frame(height: 21)
            notices
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(name: Self.space)
        .background(Self.background.ignoresSafeArea())
        .opacity(controller.phase == .fading || controller.phase == .finished ? 0 : 1)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: controller.phase == .fading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(kind.screenID)
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background { if kind.locksNavigation { NavigationPopBlocker() } }
        .onAppear {
            if kind.locksNavigation {
                requestsCardFocus = true
                cardFocused = true
            }
            onSettle()
            guard !reduceMotion else { entered = true; return }
            withAnimation(.easeOut(duration: 0.38).delay(0.12)) { entered = true }
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

    // MARK: 하차 머리(R28)

    private var alightingHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("여행의 마지막 정류장").font(FontCatalog.fixed(11))
                Spacer(minLength: 8)
                Text("하차 태그").font(FontCatalog.fixed(12))
            }
            .foregroundStyle(Color(hex: 0x9AA59C))
            .padding(.leading, 24).padding(.trailing, 25)
            .frame(height: 16)
            .padding(.top, 12)
            Text("도착했어요.\n하차 태그를 해주세요.")
                .font(FontCatalog.fixed(27, weight: .bold)).foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 30)
            Text(subtitle ?? " ").font(FontCatalog.fixed(13)).foregroundStyle(Color(hex: 0xAAB5AC))
                .padding(.top, 12)
            Color.clear.frame(height: 15)
        }
        .accessibilityHidden(true)
    }

    // MARK: 단말기(237x286)

    private var terminal: some View {
        TimelineView(.everyMinute) { context in
            let trailing = lcdTrailing ?? BoardingClock.text(for: context.date)
            VStack(spacing: 0) {
                Capsule().fill(controller.isRecognized ? Color(hex: 0xB2C9B9) : Color(hex: 0x737C76))
                    .frame(width: 156, height: 4).padding(.top, 13)
                lcd(trailing: trailing).padding(.top, 18)
                tagArea.padding(.top, 25)
                Text("FOCUS MATE").font(FontCatalog.fixed(8)).foregroundStyle(Color(hex: 0xA8B0AC))
                    .padding(.top, 5)
                Spacer(minLength: 0)
            }
            .frame(width: 237, height: 286)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: 0x1B1D1E)))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color(hex: 0x525454), lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Focus Mate \(kind.terminalName), \(trailing), \(controller.isRecognized ? "집중동행카드 인식됨" : kind.readyLCDText)")
            .accessibilityIdentifier("\(prefix).terminal")
        }
        .dynamicTypeSize(.large)
    }

    private var tagArea: some View {
        let recognized = controller.isRecognized
        return RoundedRectangle(cornerRadius: 18).fill(Color(hex: recognized ? 0x242829 : 0x141617))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color(hex: recognized ? 0xA6B6AC : 0x707874), lineWidth: 1))
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    Image(systemName: "dot.radiowaves.right").font(.system(size: 30, weight: .light))
                        .foregroundStyle(Color(hex: recognized ? 0xE5EEE7 : 0xE1E6E2))
                        .frame(height: 32)
                    Text(recognized ? "태그 완료" : "카드를 여기에").font(FontCatalog.fixed(10))
                        .foregroundStyle(Color(hex: recognized ? 0xDCE5DF : 0xB7C1BA))
                        .padding(.top, 7)
                }
                .padding(.top, 13)
            }
            .frame(width: geometry.tagAreaSize.width, height: geometry.tagAreaSize.height)
            .background(GeometryReader { proxy in
                Color.clear.onAppear { tagFrame = proxy.frame(in: .named(Self.space)); syncLayout() }
                    .onChange(of: proxy.frame(in: .named(Self.space))) { _, frame in tagFrame = frame; syncLayout() }
            })
            .accessibilityHidden(true)
            .overlay(Color.clear.accessibilityElement().accessibilityLabel("태그 영역").accessibilityIdentifier("\(prefix).tagArea"))
    }

    // MARK: LCD(201x125)

    private func lcd(trailing: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(kind == .boarding ? "Focus Mate" : "FOCUS MATE").font(FontCatalog.fixed(kind == .boarding ? 9 : 8))
                    .foregroundStyle(Color(hex: 0xC0C7C2))
                Spacer()
                Text(trailing).font(FontCatalog.fixed(kind == .boarding ? 10 : 11, weight: .bold)).monospacedDigit()
                    .foregroundStyle(Color(hex: 0xF1F3F1))
            }
            .frame(height: 14)
            .padding(.horizontal, 11).padding(.top, 9)
            Rectangle().fill(.white.opacity(0.14)).frame(height: 1).padding(.horizontal, 11).padding(.top, 4)
            Group {
                if controller.isRecognized { recognizedLCD } else { readyLCD }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .accessibilityElement(children: .ignore)
            .accessibilityValue(controller.isRecognized ? PassIdentity.displayName : kind.readyLCDText)
            .accessibilityIdentifier("\(prefix).lcdStatus")
        }
        .frame(width: 201, height: 125)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x090B0C)))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(Color(hex: controller.isRecognized ? 0x848F87 : 0x5D625F), lineWidth: 1))
    }

    @ViewBuilder private var readyLCD: some View {
        if kind == .boarding {
            Text(kind.readyLCDDisplay).font(FontCatalog.fixed(15, weight: .bold)).foregroundStyle(.white)
                .multilineTextAlignment(.center).lineSpacing(1)
                .frame(maxWidth: .infinity).padding(.top, 12)
        } else {
            VStack(spacing: 0) {
                Text(kind.readyLCDDisplay).font(FontCatalog.fixed(18, weight: .bold)).foregroundStyle(.white)
                    .padding(.top, 13)
                Spacer(minLength: 0)
                if let hint = kind.readyLCDHint {
                    Text(hint).font(FontCatalog.fixed(9)).foregroundStyle(Color(hex: 0xB5B5BA)).padding(.bottom, 15)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// 시안 R12(승차)·R29(하차): 왼쪽 카드 썸네일, 오른쪽 카드 이름·상태.
    private var recognizedLCD: some View {
        HStack(alignment: .top, spacing: 0) {
            PassFace(style: model.currentCardStyle, layout: .ticket, numberText: model.currentCardNumberText)
                .frame(width: 100, height: 64)
                .padding(.leading, 10).padding(.top, 16)
            if kind == .boarding {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(PassIdentity.displayName).font(FontCatalog.fixed(12, weight: .bold)).foregroundStyle(.white)
                        Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(Color(hex: 0xEEF2EF))
                    }
                    .padding(.top, 20)
                    Text("나의 Focus Mate").font(FontCatalog.fixed(8, weight: .bold)).foregroundStyle(Color(hex: 0xCBD3CE))
                        .padding(.top, 17)
                    if let number = model.currentCardNumberText {
                        Text(number).font(FontCatalog.fixed(7)).foregroundStyle(Color(hex: 0xB7C1BA)).padding(.top, 6)
                    }
                }
                .padding(.leading, 6)
                Spacer(minLength: 0)
            } else {
                VStack(spacing: 0) {
                    Text("하차 완료").font(FontCatalog.fixed(14, weight: .bold)).foregroundStyle(.white).padding(.top, 33)
                    Text(PassIdentity.displayName).font(FontCatalog.fixed(9, weight: .bold)).foregroundStyle(Color(hex: 0xCBD3CE))
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "checkmark").font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xEEF2EF)).padding(.top, 18).padding(.trailing, 15)
                }
            }
        }
    }

    // MARK: 카드(270x158)

    @State private var tagFrame: CGRect = .zero

    @State private var cardRest: CGRect = .zero

    /// 인식되면 카드 중심을 태그 영역 중심에 맞춘다(축소는 가운데 기준).
    private var cardOffset: CGSize {
        guard controller.isRecognized, tagFrame != .zero, cardRest != .zero else { return controller.cardOffset }
        return CGSize(width: tagFrame.midX - cardRest.midX, height: tagFrame.midY - cardRest.midY)
    }

    /// 바깥 틀(움직이지 않음)로 카드 기준 위치를 재고, 안쪽 카드만 오프셋으로 움직인다.
    private var card: some View {
        ZStack {
            PassFace(style: model.currentCardStyle, layout: .ticket, numberText: model.currentCardNumberText)
                .frame(width: geometry.cardWidth)
                .overlay(alignment: .bottomTrailing) {
                    if controller.isRecognized {
                        Circle().fill(Color(hex: 0xD7EFDC)).frame(width: 34.6, height: 34.6)
                            .overlay(Image(systemName: "checkmark").font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(hex: 0x183822)))
                            .padding(.trailing, 10).padding(.bottom, 9)
                            .accessibilityHidden(true)
                    }
                }
                .scaleEffect(controller.isRecognized ? Self.recognizedScale : 1)
                .offset(x: cardOffset.width, y: cardOffset.height + bounceOffset)
                // 끄는 동안은 손가락을 바로 따라가고, 되돌아가거나 단말기에 들어갈 때만 부드럽게 움직인다.
                .animation(reduceMotion || controller.phase == .dragging ? nil : .spring(duration: 0.3), value: cardOffset)
                .animation(reduceMotion ? nil : .spring(duration: 0.3), value: controller.isRecognized)
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
                .onAppear { cardRest = proxy.frame(in: .named(Self.space)); syncLayout() }
                .onChange(of: proxy.frame(in: .named(Self.space))) { _, frame in cardRest = frame; syncLayout() }
        })
    }

    private func syncLayout() { controller.updateLayout(cardRest: cardRest, tagArea: tagFrame) }

    // MARK: 아래 안내(시안 y=772)

    @ViewBuilder private var notices: some View {
        VStack(spacing: 0) {
            if controller.showsSaveFailure {
                Text(kind.failureText).font(FontCatalog.fixed(12)).foregroundStyle(.orange)
                    .accessibilityIdentifier("\(prefix).saveFailure")
            } else if kind == .alighting {
                Text(controller.isRecognized ? CardTagKind.alightedHint : CardTagKind.pushHint)
                    .font(FontCatalog.fixed(12)).foregroundStyle(Self.hintColor)
                    .accessibilityIdentifier("\(prefix).tapHint")
            } else if controller.showsTapHint {
                Text(CardTagKind.pushHint).font(FontCatalog.fixed(12)).foregroundStyle(Self.hintColor)
                    .accessibilityIdentifier("\(prefix).tapHint")
            }
            if kind == .alighting {
                // 끌기 대신 바로 태그하는 대체 경로(R28 "눌러서 태그하기"). 카드 낭독 동작과 같은 활성화다.
                Button { controller.activate(reduceMotion: reduceMotion) } label: {
                    Text("눌러서 태그하기").font(FontCatalog.fixed(11)).underline()
                        .foregroundStyle(Color(hex: 0x94A098))
                        .frame(minWidth: 88, minHeight: 36).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(controller.isRecognized)
                .padding(.top, 14)
                .accessibilityIdentifier("\(prefix).tapToTag")
            }
        }
        .multilineTextAlignment(.center)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .padding(.horizontal, 24)
    }

    #if DEBUG
    private var diagnostics: some View {
        VStack(spacing: 0) {
            Text("태그 진단").accessibilityValue(diagnosticJSON).accessibilityIdentifier("test.\(prefix)")
            debugButton("카드 활성화", id: kind.debugActivateID) { controller.activate(reduceMotion: reduceMotion) }
            if kind == .boarding {
                // 시안대로 뒤로 버튼을 숨겼으므로(AC-14 변경) 테스트만 이 경로로 승차권에 돌아간다.
                debugButton("뒤로", id: "test.boarding.back") { model.goBack() }
            }
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
