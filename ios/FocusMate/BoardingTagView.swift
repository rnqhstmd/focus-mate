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
            if let controller {
                CardTagScreen(model: model, services: services, controller: controller, kind: .boarding, title: titleLabel)
            }
            else { Color.clear }
        }
        .onAppear {
            guard controller == nil else { return }
            let model = model
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

    private var titleLabel: String {
        let origin = model.confirmedPreparation?.originName ?? ""
        return "승차 태그, \(origin), 승차 단계. 카드를 위로 밀어 단말기에 대주세요"
    }
}
