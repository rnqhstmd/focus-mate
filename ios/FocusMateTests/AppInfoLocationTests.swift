import Foundation
import XCTest

/// AC-29 회귀 가드(RED 불가: 현재도 통과). 위치 권한 문구가 Info.plist에 생기면 실패한다.
final class AppInfoLocationTests: XCTestCase {
    // 깨짐: Info.plist에 위치 사용 설명 키가 추가된다.
    func test_위치_권한_사용_설명_키가_하나도_없다() {
        let keys = [
            "NSLocationWhenInUseUsageDescription",
            "NSLocationAlwaysAndWhenInUseUsageDescription",
            "NSLocationAlwaysUsageDescription",
            "NSLocationUsageDescription",
        ]
        for key in keys {
            XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: key), key)
        }
    }
}
