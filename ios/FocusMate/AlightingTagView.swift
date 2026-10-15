import SwiftUI

/// 하차 태그 목적지. 컨트롤러는 화면이 처음 나타날 때 한 번만 만든다.
/// 하차 저장 뒤 어떤 경로로 중단돼도 모델 상태로 다시 맞춰 요약으로 보낸다(화면에 갇히지 않게).
@MainActor
struct AlightingTagView: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    @State private var controller: BoardingTagController?

    var body: some View {
        Group {
            if let controller {
                CardTagScreen(model: model, services: services, controller: controller, kind: .alighting,
                              title: "하차 태그, 하차 단계. 카드를 위로 밀어 단말기에 대주세요",
                              onSettle: { reconcile(controller) })
            } else { Color.clear }
        }
        .onAppear {
            guard controller == nil else { return }
            let model = model
            controller = BoardingTagController(
                alighter: model, haptics: services.haptics, announcer: services.announcer,
                sleep: services.sleep, holdSleep: services.boardingHoldSleep,
                onFinished: { [weak model] in Self.finish(model) })
        }
    }

    private func reconcile(_ controller: BoardingTagController) {
        guard AlightingTagRecovery.shouldFinish(phase: controller.phase, alightingSaved: model.alightingSummary != nil) else { return }
        Self.finish(model)
    }

    private static func finish(_ model: AppModel?) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { _ = model?.finishAlightingTransition() }
    }
}
