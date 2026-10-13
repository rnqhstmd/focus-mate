import UIKit
import XCTest
@testable import FocusMate

final class PassFaceAssetTests: XCTestCase {
    // 깨짐: 에셋 카탈로그에서 PassDots를 빼거나 dotsAssetName이 다른 이름을 가리키면 실패
    func testAC15_점묘_이미지_에셋이_앱_번들에서_로드된다() {
        XCTAssertEqual(PassFace.dotsAssetName, "PassDots")
        XCTAssertNotNil(UIImage(named: PassFace.dotsAssetName, in: Bundle.main, compatibleWith: nil))
    }
}
