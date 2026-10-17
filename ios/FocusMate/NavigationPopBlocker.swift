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

/// 내비 막대를 숨긴 화면에서도 화면 왼쪽 가장자리 스와이프 뒤로가기를 살린다(승차 태그, C단계 결정).
/// 막대를 숨기면 UIKit 기본 위임이 가장자리 스와이프를 거절하므로, 보이는 동안만 위임을 바꾸고 떠날 때 되돌린다.
/// `canBegin`이 false면(태그 인식·전환 중) 시작하지 않는다.
struct NavigationEdgeSwipeEnabler: UIViewControllerRepresentable {
    var canBegin: @MainActor () -> Bool = { true }

    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) { controller.canBegin = canBegin }
    static func dismantleUIViewController(_ controller: Controller, coordinator: ()) { controller.restore() }

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        var canBegin: @MainActor () -> Bool = { true }
        private weak var navigation: UINavigationController?
        private weak var savedDelegate: UIGestureRecognizerDelegate?
        private var savedEnabled = true
        private var installed = false

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard !installed, let navigation = navigationController,
                  let recognizer = navigation.interactivePopGestureRecognizer else { return }
            self.navigation = navigation
            savedDelegate = recognizer.delegate
            savedEnabled = recognizer.isEnabled
            recognizer.delegate = self
            recognizer.isEnabled = true
            installed = true
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            restore()
        }

        func restore() {
            guard installed else { return }
            if let recognizer = navigation?.interactivePopGestureRecognizer {
                recognizer.delegate = savedDelegate
                recognizer.isEnabled = savedEnabled
            }
            installed = false
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigation?.viewControllers.count ?? 0) > 1 && canBegin()
        }
    }
}
