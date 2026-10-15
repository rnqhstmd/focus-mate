import SwiftUI
import UIKit

/// 여행 화면에서 스와이프 뒤로가기를 막는다. 뒤로가기 버튼 숨김만으로는 iOS 26의 화면 전체 스와이프가 남는다.
/// 내비게이션 컨트롤러는 시간 선택·준비 화면과 공유하므로 사라질 때 원래 값으로 되돌린다.
struct NavigationPopBlocker: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) {}
    static func dismantleUIViewController(_ controller: Controller, coordinator: ()) { controller.restore() }

    final class Controller: UIViewController {
        private var saved: [(UIGestureRecognizer, Bool)] = []

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard saved.isEmpty, let navigation = navigationController else { return }
            var recognizers = [navigation.interactivePopGestureRecognizer]
            if #available(iOS 26, *) { recognizers.append(navigation.interactiveContentPopGestureRecognizer) }
            for recognizer in recognizers.compactMap({ $0 }) {
                saved.append((recognizer, recognizer.isEnabled))
                recognizer.isEnabled = false
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            restore()
        }

        func restore() {
            saved.forEach { $0.0.isEnabled = $0.1 }
            saved = []
        }
    }
}
