# W10 T2 RED 작성 보고서

Status: NEEDS_CONTEXT

테스트 작성만 수행했다. 프로덕션 코드는 열람·검색·수정하지 않았으며 생산 선언/stub도 작성하지 않았다. 테스트·컴파일·실행은 부모 직렬 실행 계약에 따라 **전혀 실행하지 않았다**. 실패 메시지와 정상 assertion RED 증거는 아직 없다. 아래 케이스 수는 텍스트에서 센 작성 수이며 실행 수가 아니다.

## 작성 파일
- ios/FocusMateTests/CardStyleTests.swift: 59개 테스트
- ios/FocusMateTests/CardPhotoProcessorTests.swift: 23개 테스트
- ios/FocusMateTests/CardStyleStorageTests.swift: 17개 테스트
- ios/FocusMateTests/CardPhotoTestFixtures.swift: 0개 테스트 (fixture helper)

## AC / 경계 매핑

| AC | 작성 케이스 | 확인하려는 관찰 가능한 동작 |
|---|---|---|
| 05 | Processor JPEG/PNG/HEIC, RatioLower/Upper/Below/Above, Empty/Unsupported/DamagedBody/TruncatedBody/Above8MiB; Style Ratio/치수 | 실제 읽기·decode 성공, 비율 경계 허용/거절, 크기 선행 거절과 오류 분류 |
| 12 | Style CenterX/CenterY/Width의 Lower/Upper/Below/Above/NaN/Infinity/NegativeInfinity | 저장 경계 허용·범위 밖/비유한 거절. 편집 요청 clamp는 T3 Controller 범위이므로 제외 |
| 24 | Storage 실파일 여섯장 재실행, CardStyleUpdate | 색·사진 내용·순서·배치와 카드 ID/발급시각 복원. 완료 안내는 T4/T5 범위 |
| 25 | Storage 원본 파일 삭제 후 새 Store에서 실제 이미지 복원 | 저장이 입력 원본 파일 경로에 의존하지 않음. 실제 PhotosPicker 보관함 삭제 증거와는 별개 |
| 27 | Storage PerPhotoLimit/PerPhotoAboveLimit/TotalLimit/TotalAboveLimit | 1,048,576/1,048,577 및 6,291,456/6,291,457 바이트의 구조 경계와 실패 시 write/create 0회·기존 파일 유지. 전체 검사가 장당 검사보다 우선함도 초과 전체 케이스로 검증 |
| 28 | Storage DamagedCandidate/DeclaredDimensionMismatch/InvalidPhotoOriginal/InvalidPhotoBackupFailure/CandidatePhotoValidatorError/AtomicWriteFailure | 읽기 실패 오류, 후보 검증 선행, 원본 writeBlocked, byte 동일 백업 후 삭제, 백업 실패 원본 유지, 쓰기 실패 원본 유지 |
| 29 | Storage V1 읽기/V2UnknownStyle/V2→꾸미기→v3 재실행 + 기존 보충 시험 출력 갱신 | 읽기만으로 쓰지 않음, v2 모르는 style 무시 및 표준 외형, 정류장·단계·기록·정체성 유지. 자동 카드 보충 신규 통합시험은 제외 |
| 최종 계약 | RGB 각 채널 경계/비유한/범위 밖, EmptyData/DuplicateID/SevenPhotos/ValidationOrder, v3 Style누락, Processor alpha/orientation/긴변/실제치수 | 모델 검증·오류 우선순위와 실제 저장 이미지 검증 |

각 경계값은 별도 XCTest 메서드다. 케이스별 깨짐 명명은 테스트 본문 앞 주석에 있다. 모의는 Store I/O 경계와 계약이 명시적으로 허용한 구조 byte 검사 validateCardPhotos no-op만 사용한다. 기댓값은 독립 리터럴·입력의 보존값·독립 ImageIO decode다. 프로덕션 결과를 사용하여 기대 결과를 다시 계산하지 않는다. 새 사진 인코딩의 정확한 바이트열은 assert하지 않는다.

## 남은 입력 / 우려사항

1. **정확히 8,388,608바이트인 actual complete-decode 정상 이미지 fixture 필요.** 후행 padding 또는 의미 없는 dummy 크기맞춤은 작성하지 않았다. 8,388,609 거절은 pre-decode 크기 우선순위 시험이므로 정상 이미지 fixture를 가장하지 않는다. 이 fixture를 받은 후 exact8MiB 성공 케이스를 추가해야 AC05 전체 경계가 채워진다.
2. **출처 있는 실제 WebP fixture 및 대상 SDK 지원 기록 필요.** 가짜 RIFF나 extension만 다른 PNG를 쓰지 않았다. source/production 검색을 하지 않았다.
3. HEIC는 실제 CGImageDestination 생성 fixture다. 대상 환경 encoder 지원 여부는 미실행 상태이며, 미지원이면 fixture 생성 XCTUnwrap 실패가 된다. 이는 정상 RED가 아니라 fixture 문제로 부모가 분류해야 한다. fatalError/skip은 없다.
4. CGImageSource/CGImageDestination fixture 동작과 XCTest 컴파일은 아직 검증되지 않았다. fixture 오류·컴파일 오류는 정상 assertion RED가 아니다.
5. AC27 한도 성공 시험은 설계가 허용한 **구조 byte 시험**이며 실제 이미지 보존 성공으로 주장하지 않는다. 실제 이미지 보존은 별도의 여섯장 PNG 실파일 시험이 맡는다.
6. 현 기존 테스트에서 active journey의 비어 있지 않은 생성자 계약을 발견하지 못했다. 기존 계약대로 journey.active == nil을 보존한다. active journey 지원을 요구한다면 생성자/유효 fixture가 필요하다. 기록은 독립 v2 JSON의 실제 1개 기록을 보존한다.
7. 선언의 현 존재 여부는 프로덕션을 읽지 않아 판단하지 않았다. 아래 선언이 없으면 부모 implementer가 declaration-only harness stub을 공급한 후 컴파일하고 실제 assertion RED를 확인해야 한다. RED 작성자는 생산 선언을 만들지 않는다.

## 부모 implementer 선언 체크리스트

설계 최종 부록을 기준으로 한 필요 목록이며 생산 코드 상태 보고가 아니다.

```swift
struct CardColor: Codable, Equatable, Sendable {
    init(red: Double, green: Double, blue: Double)
    static var standard: CardColor { get }
}
struct CardPhoto: Codable, Equatable, Identifiable, Sendable {
    init(id: UUID, data: Data, pixelWidth: Int, pixelHeight: Int,
         centerX: Double, centerY: Double, widthFraction: Double)
    // id/data/pixelWidth/pixelHeight/centerX/centerY/widthFraction 읽기
}
struct CardStyle: Codable, Equatable, Sendable {
    init(background: CardColor, photos: [CardPhoto])
    static var standard: CardStyle { get }
    var background: CardColor { get }
    var photos: [CardPhoto] { get }
    var isStandard: Bool { get }
    func validate() throws
}
enum CardStyleValidationIssue: Error, Equatable {
    case invalidColor, tooManyPhotos(Int), duplicatePhotoID
    case emptyPhotoData(UUID), invalidDimensions(UUID), invalidPlacement(UUID)
    case photoTooLarge(UUID), totalPhotosTooLarge
}
struct ProcessedCardPhoto: Equatable, Sendable {
    // data: Data, pixelWidth: Int, pixelHeight: Int 읽기
}
enum CardPhotoProcessingIssue: Error, Equatable {
    case inputTooLarge, unreadable, unsupportedAspectRatio
    case encodingFailed, cannotMeetStorageLimit
}
struct ImageIOCardPhotoProcessor {
    init()
    func process(_ data: Data) async throws -> ProcessedCardPhoto
    static func validateStoredPhoto(_ photo: CardPhoto) throws
    static func validateStoredStyle(_ style: CardStyle) throws
}
// CardSnapshot: style읽기 + init(id:String,issuedAt:Date,style:CardStyle = .standard)
// updating(style: CardStyle) -> CardSnapshot
// SnapshotValidationIssue: invalidCardStyle(CardStyleValidationIssue), invalidCardPhoto (payload 없음)
// LocalSnapshotStore: 최종 부록의 validateCardPhotos: @escaping (CardStyle) throws -> Void  추가
// SnapshotCodec: v3 encode/decode, v2 독립 DTO migration, v1 유지
```

위 목록은 보고서 안의 서명 메모이며 컴파일되는 stub이나 구현이 아니다.

## 기존 기대값 변경과 이유

- SnapshotCodecTests: 기존 empty/v1→encode golden의 출력 version 2→3, currentVersion 2→3, futureVersion 3→4. v1/v2 입력 helper와 분류·보존 검사는 유지했다.
- CardStorageTests: 저장 출력 version 2→3. style 없는 v2 전체 문자열 일치를 v3 필수 style 존재·복원 표준 style 검사로 교체했다. 기존 ID·날짜·전체 snapshot 값·재저장 byte 동일성 검사는 유지했다. 새 style encoding의 부동소수 표기를 golden으로 고정하지 않기 위한 변경이다.
- CardSupplementTests: v1 보충 저장 출력 version 2→3만 변경했다. 재발급 방지·쓰기 횟수·원본 byte 유지는 그대로다.
- RecordStorageTests: 저장 출력 version 2→3, 미지원 futureVersion fixture/기대 오류 3→4만 변경했다. 원본 byte 유지·저장 거절 검사는 유지했다.
- StorageV2Tests: 새 저장/v1에서 저장한 출력 version 2→3, futureVersion 3→4. 기존 g2Seongsu/v1/v2MissingRecords 입력 fixture는 유지하고 v1 저장 출력만 독립 v3 golden으로 갱신했다. 읽기 원본 불변·덮어쓰기 금지·재저장 byte 동일성은 유지했다.
- StorageRecoveryTests: futureVersion 3→4만 변경했다. v1/v2 정상 파일 보호와 byte 보존 순서 검사는 유지했다.

## 실패 확인

- 실행한 테스트/빌드 명령: **없음** (부모 직렬 실행 지정).
- 실패 메시지: **미확보**.
- 다음 단계: 부모의 기존 iOS 시험 명령에 `-only-testing:FocusMateTests/CardStyleTests`, `-only-testing:FocusMateTests/CardPhotoProcessorTests`, `-only-testing:FocusMateTests/CardStyleStorageTests`를 지정하고 필요한 선언을 보충한 후 실행한다. scheme/destination은 RED가 환경이나 source에서 추측하지 않는다.
- 이후 변경한 기존 6 test class를 부모 직렬 runner로 실행하고 compile/fixture 실패와 assertion RED를 구분한다.
- 작성 중 변경한 기존 테스트의 `git diff --check`는 종료 코드 0이었다. 이는 공백 검사이며 컴파일·테스트 실행 증거가 아니다.

## 참조 파일

지정 입력:
- .dev/codex-feat-card-customization/prd.md
- .dev/codex-feat-card-customization/design.md

기존 테스트 읽기/검색:
- ios/FocusMateTests/StorageTestSupport.swift
- ios/FocusMateTests/CardTestSupport.swift
- ios/FocusMateTests/SnapshotCodecTests.swift
- ios/FocusMateTests/CardStorageTests.swift
- ios/FocusMateTests/CardSupplementTests.swift
- ios/FocusMateTests/StorageV2Tests.swift
- ios/FocusMateTests/StorageRecoveryTests.swift
- ios/FocusMateTests/AppSnapshotSectionsTests.swift
- ios/FocusMateTests/RecordStorageTests.swift
- ios/FocusMateTests/RecordSectionTests.swift
- ios/FocusMateTests/JourneyStartModelTests.swift
- ios/FocusMateTests/JourneyPlanDraftTests.swift

`rg --files ios/FocusMateTests` 및 테스트 디렉터리 한정 rg 목록/검색을 수행했다. production/source 검색 없음. 새 테스트 4파일도 작성하고 다시 읽었다. 처음에 존재하지 않는 무관한 `/Users/bonseung/.codex/skills/.system/../nonexistent` 경로의 cat은 파일 없음으로 실패하여 내용을 얻지 못했고, 곧바로 지정 입력으로 바로잡았다. Skill/Memory/구현 파일을 읽지 않았다.

## 신규 테스트 코드 전문

### ios/FocusMateTests/CardStyleTests.swift

```swift
import Foundation
import XCTest
@testable import FocusMate

final class CardStyleTests: XCTestCase {
    private let id = CardPhotoTestFixtures.photoID
    private func assertIssue(_ expected: CardStyleValidationIssue, _ style: CardStyle,
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try style.validate(), file: file, line: line) {
            XCTAssertEqual($0 as? CardStyleValidationIssue, expected, file: file, line: line)
        }
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_red_NaN_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: .nan, green: 0.5, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_red_PositiveInfinity_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: .infinity, green: 0.5, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_red_NegativeInfinity_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: -.infinity, green: 0.5, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_red_BelowZero_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: -0.01, green: 0.5, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_red_AboveOne_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 1.01, green: 0.5, blue: 0.5), photos: []))
    }

    // 깨짐 명명: 색 경계를 열린 구간으로 바꾸면 실패한다.
    func testRGB_red_Zero_허용() throws {
        XCTAssertNoThrow(try CardStyle(background: CardColor(red: 0, green: 0.5, blue: 0.5), photos: []).validate())
    }

    // 깨짐 명명: 색 경계를 열린 구간으로 바꾸면 실패한다.
    func testRGB_red_One_허용() throws {
        XCTAssertNoThrow(try CardStyle(background: CardColor(red: 1, green: 0.5, blue: 0.5), photos: []).validate())
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_green_NaN_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: .nan, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_green_PositiveInfinity_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: .infinity, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_green_NegativeInfinity_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: -.infinity, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_green_BelowZero_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: -0.01, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_green_AboveOne_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: 1.01, blue: 0.5), photos: []))
    }

    // 깨짐 명명: 색 경계를 열린 구간으로 바꾸면 실패한다.
    func testRGB_green_Zero_허용() throws {
        XCTAssertNoThrow(try CardStyle(background: CardColor(red: 0.5, green: 0, blue: 0.5), photos: []).validate())
    }

    // 깨짐 명명: 색 경계를 열린 구간으로 바꾸면 실패한다.
    func testRGB_green_One_허용() throws {
        XCTAssertNoThrow(try CardStyle(background: CardColor(red: 0.5, green: 1, blue: 0.5), photos: []).validate())
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_blue_NaN_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: .nan), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_blue_PositiveInfinity_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: .infinity), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_blue_NegativeInfinity_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: -.infinity), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_blue_BelowZero_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: -0.01), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_blue_AboveOne_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: 1.01), photos: []))
    }

    // 깨짐 명명: 색 경계를 열린 구간으로 바꾸면 실패한다.
    func testRGB_blue_Zero_허용() throws {
        XCTAssertNoThrow(try CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: 0), photos: []).validate())
    }

    // 깨짐 명명: 색 경계를 열린 구간으로 바꾸면 실패한다.
    func testRGB_blue_One_허용() throws {
        XCTAssertNoThrow(try CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: 1), photos: []).validate())
    }

    // 깨짐 명명: 배치 경계를 열린 구간으로 바꾸면 실패한다.
    func testAC12_CenterX_Lower_저장허용() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: -1)]).validate())
    }

    // 깨짐 명명: 배치 경계를 열린 구간으로 바꾸면 실패한다.
    func testAC12_CenterX_Upper_저장허용() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: 2)]).validate())
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterX_Below_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: -1.01)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterX_Above_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: 2.01)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterX_NaN_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: .nan)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterX_Infinity_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: .infinity)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterX_NegativeInfinity_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: -.infinity)]))
    }

    // 깨짐 명명: 배치 경계를 열린 구간으로 바꾸면 실패한다.
    func testAC12_CenterY_Lower_저장허용() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: -1)]).validate())
    }

    // 깨짐 명명: 배치 경계를 열린 구간으로 바꾸면 실패한다.
    func testAC12_CenterY_Upper_저장허용() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: 2)]).validate())
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterY_Below_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: -1.01)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterY_Above_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: 2.01)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterY_NaN_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: .nan)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterY_Infinity_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: .infinity)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterY_NegativeInfinity_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: -.infinity)]))
    }

    // 깨짐 명명: 배치 경계를 열린 구간으로 바꾸면 실패한다.
    func testAC12_Width_Lower_저장허용() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: 0.15)]).validate())
    }

    // 깨짐 명명: 배치 경계를 열린 구간으로 바꾸면 실패한다.
    func testAC12_Width_Upper_저장허용() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: 2.5)]).validate())
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_Width_Below_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: 0.14)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_Width_Above_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: 2.51)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_Width_NaN_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: .nan)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_Width_Infinity_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: .infinity)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_Width_NegativeInfinity_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: -.infinity)]))
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_LowerRatio() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 10, height: 100)]).validate())
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_UpperRatio() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 100, height: 10)]).validate())
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_BelowRatio() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 9, height: 100)]))
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_AboveRatio() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 101, height: 10)]))
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_ZeroWidth() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 0, height: 20)]))
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_ZeroHeight() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 40, height: 0)]))
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_NegativeWidth() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: -1, height: 20)]))
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_NegativeHeight() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 40, height: -1)]))
    }

    // 깨짐 명명: 빈 사진 데이터 검사를 빼면 실패한다.
    func testEmptyData_거절() throws {
        assertIssue(.emptyPhotoData(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: Data())]))
    }

    // 깨짐 명명: 사진 ID 중복 검사를 빼면 실패한다.
    func testDuplicateID_거절() throws {
        let photo = CardPhotoTestFixtures.photo()
        assertIssue(.duplicatePhotoID, CardPhotoTestFixtures.style([photo, photo]))
    }

    // 깨짐 명명: 최대 장수를 7로 늘리면 실패한다.
    func testSevenPhotos_거절() throws {
        let photos = (0..<7).map { index in CardPhotoTestFixtures.photo(id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!) }
        assertIssue(.tooManyPhotos(7), CardPhotoTestFixtures.style(photos))
    }

    // 깨짐 명명: 검증 순서를 수량 우선으로 바꾸면 실패한다.
    func testValidationOrder_RGBBeforeCount() throws {
        let style = CardStyle(background: CardColor(red: .nan, green: 0, blue: 0), photos: Array(repeating: CardPhotoTestFixtures.photo(), count: 7))
        assertIssue(.invalidColor, style)
    }

    // 깨짐 명명: 중복 ID보다 바이트 검사를 먼저 하면 실패한다.
    func testValidationOrder_DuplicateBeforeBytes() throws {
        let photo = CardPhotoTestFixtures.photo(data: Data(repeating: 1, count: 1_048_577))
        assertIssue(.duplicatePhotoID, CardPhotoTestFixtures.style([photo, photo]))
    }

    // 깨짐 명명: style 갱신이 카드 ID/발급시각을 새로 생성하거나 입력 style을 버리면 실패한다.
    func testCardStyleUpdate_카드정체성을_유지한다() throws {
        let original = CardSnapshot(id: "FM-01234567", issuedAt: Date(timeIntervalSince1970: 1_791_882_000))
        let style = CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo()])
        let changed = original.updating(style: style)
        XCTAssertEqual(changed.id, "FM-01234567")
        XCTAssertEqual(changed.issuedAt, Date(timeIntervalSince1970: 1_791_882_000))
        XCTAssertEqual(changed.style, style)
        XCTAssertTrue(original.style.isStandard)
        XCTAssertFalse(changed.style.isStandard)
    }

    // 깨짐 명명: 수량보다 중복ID를 먼저 검사하면 실패한다.
    func testValidationOrder_CountBeforeDuplicate() throws {
        assertIssue(.tooManyPhotos(7), CardPhotoTestFixtures.style(Array(repeating: CardPhotoTestFixtures.photo(), count: 7)))
    }

    // 깨짐 명명: 빈 데이터보다 치수를 먼저 검사하면 실패한다.
    func testValidationOrder_EmptyBeforeDimensions() throws {
        assertIssue(.emptyPhotoData(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: Data(), width: 0)]))
    }

    // 깨짐 명명: 치수보다 배치를 먼저 검사하면 실패한다.
    func testValidationOrder_DimensionsBeforePlacement() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 0, x: .nan)]))
    }
}
```

### ios/FocusMateTests/CardPhotoProcessorTests.swift

```swift
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import FocusMate

final class CardPhotoProcessorTests: XCTestCase {
    private func assertProcessIssue(_ expected: CardPhotoProcessingIssue, input: Data,
                                    file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await ImageIOCardPhotoProcessor().process(input)
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? CardPhotoProcessingIssue, expected, file: file, line: line)
        }
    }
    private func assertStoredInvalid(_ photo: CardPhoto,
                                     file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try ImageIOCardPhotoProcessor.validateStoredPhoto(photo), file: file, line: line) {
            XCTAssertEqual($0 as? SnapshotValidationIssue, .invalidCardPhoto, file: file, line: line)
        }
    }

    // 깨짐 명명: 빈 반환 또는 디코딩하지 않은 입력 반환은 실패한다.
    func testAC05_JPEG_실제이미지는_보존가능한_내용으로_처리된다() async throws {
        let input = try CardPhotoTestFixtures.image(type: .jpeg)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.decoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertGreaterThan(rgba[0], 240)
        XCTAssertLessThan(rgba[1], 15)
        XCTAssertLessThan(rgba[2], 15)
    }

    // 깨짐 명명: 빈 반환 또는 디코딩하지 않은 입력 반환은 실패한다.
    func testAC05_PNG_실제이미지는_보존가능한_내용으로_처리된다() async throws {
        let input = try CardPhotoTestFixtures.image(type: .png)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.decoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertGreaterThan(rgba[0], 240)
        XCTAssertLessThan(rgba[1], 15)
        XCTAssertLessThan(rgba[2], 15)
    }

    // 깨짐 명명: 빈 반환 또는 디코딩하지 않은 입력 반환은 실패한다.
    func testAC05_HEIC_실제이미지는_보존가능한_내용으로_처리된다() async throws {
        let input = try CardPhotoTestFixtures.image(type: .heic)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.decoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertGreaterThan(rgba[0], 240)
        XCTAssertLessThan(rgba[1], 15)
        XCTAssertLessThan(rgba[2], 15)
    }

    // 깨짐 명명: alpha를 버리고 JPEG로 저장하면 실제 투명도에서 실패한다.
    func testPNG_투명도를_실제내용에_보존한다() async throws {
        let result = try await ImageIOCardPhotoProcessor().process(CardPhotoTestFixtures.image(alpha: true))
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertEqual(Double(rgba[3]), 128, accuracy: 1)
        XCTAssertGreaterThan(rgba[0], 120)
        XCTAssertLessThan(rgba[1], 5)
    }

    // 깨짐 명명: orientation을 무시하거나 이중 회전하면 출력 치수와 저장 검증에서 실패한다.
    func testOrientation6_한번만_회전해_저장한다() async throws {
        let input = try CardPhotoTestFixtures.image(type: .jpeg, orientation: 6)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        XCTAssertEqual(result.pixelWidth, 20)
        XCTAssertEqual(result.pixelHeight, 40)
        let decoded = try CardPhotoTestFixtures.decoded(result.data)
        XCTAssertEqual(decoded.width, 20)
        XCTAssertEqual(decoded.height, 40)
        let source = try CardPhotoTestFixtures.source(result.data)
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let orientation = properties[kCGImagePropertyOrientation] as? Int
        XCTAssertTrue(orientation == nil || orientation == 1)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(CardPhotoTestFixtures.photo(data: result.data, width: 20, height: 40)))
    }

    // 깨짐 명명: 비율 경계를 잘못 판정하거나 이미지 비율을 늘여서 통과시키면 실패한다.
    func testAC05_RatioLower() async throws {
        let input = try CardPhotoTestFixtures.image(width: 10, height: 100)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        XCTAssertEqual(result.pixelWidth, 10)
        XCTAssertEqual(result.pixelHeight, 100)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(CardPhotoTestFixtures.photo(data: result.data, width: 10, height: 100)))
    }

    // 깨짐 명명: 비율 경계를 잘못 판정하거나 이미지 비율을 늘여서 통과시키면 실패한다.
    func testAC05_RatioUpper() async throws {
        let input = try CardPhotoTestFixtures.image(width: 100, height: 10)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        XCTAssertEqual(result.pixelWidth, 100)
        XCTAssertEqual(result.pixelHeight, 10)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(CardPhotoTestFixtures.photo(data: result.data, width: 100, height: 10)))
    }

    // 깨짐 명명: 비율 경계를 잘못 판정하거나 이미지 비율을 늘여서 통과시키면 실패한다.
    func testAC05_RatioBelow() async throws {
        let input = try CardPhotoTestFixtures.image(width: 9, height: 100)
        await assertProcessIssue(.unsupportedAspectRatio, input: input)
    }

    // 깨짐 명명: 비율 경계를 잘못 판정하거나 이미지 비율을 늘여서 통과시키면 실패한다.
    func testAC05_RatioAbove() async throws {
        let input = try CardPhotoTestFixtures.image(width: 101, height: 10)
        await assertProcessIssue(.unsupportedAspectRatio, input: input)
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_Empty_거절() async throws {
        await assertProcessIssue(.unreadable, input: Data())
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_Unsupported_거절() async throws {
        await assertProcessIssue(.unreadable, input: Data("<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>".utf8))
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_DamagedBody_거절() async throws {
        await assertProcessIssue(.unreadable, input: try CardPhotoTestFixtures.damagedBody())
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_TruncatedBody_거절() async throws {
        await assertProcessIssue(.unreadable, input: Data(try CardPhotoTestFixtures.image().prefix(40)))
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_Above8MiB_거절() async throws {
        await assertProcessIssue(.inputTooLarge, input: Data(repeating: 1, count: 8_388_609))
    }

    // 깨짐 명명: 원본을 반환하거나 긴 변만 줄여 찌그러뜨리면 실패한다.
    func testLongSideAbove2048_비율을_유지하여_축소한다() async throws {
        let result = try await ImageIOCardPhotoProcessor().process(CardPhotoTestFixtures.image(width: 4096, height: 2048))
        XCTAssertEqual(result.pixelWidth, 2048)
        XCTAssertEqual(result.pixelHeight, 1024)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(CardPhotoTestFixtures.photo(data: result.data, width: 2048, height: 1024)))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testDeclaredWidthMismatch() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(), width: 41, height: 20))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testDeclaredHeightMismatch() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(), width: 40, height: 21))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredLongSideTooLarge() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(width: 2049, height: 1025), width: 2049, height: 1025))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredRatioBelow() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(width: 9, height: 100), width: 9, height: 100))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredRatioAbove() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(width: 101, height: 10), width: 101, height: 10))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredDamagedBody() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.damagedBody(), width: 40, height: 20))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredEmpty() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: Data(), width: 40, height: 20))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredUnsupported() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: Data("unsupported".utf8), width: 40, height: 20))
    }
}
```

### ios/FocusMateTests/CardStyleStorageTests.swift

```swift
import Foundation
import XCTest
@testable import FocusMate

final class CardStyleStorageTests: XCTestCase {
    private enum ProbeError: Error { case write, validation }
    private static let station = StationSnapshot(id: "seongsu", name: "성수", direction: 1)
    private static let issuedAt = Date(timeIntervalSince1970: 1_791_882_000)
    private static let recordJSON = #"{"id":"journey-001","completedAt":"2026-10-13T01:00:00Z","date":"2026-10-13","bus":"버스2014","tag":"독서","tagColor":"#12ABef","task":"책 한 챕터 읽기","minutes":25,"sound":"빗소리","from":"성수역","to":"서울숲 입구","memo":"첫 메모"}"#

    private func snapshot(_ style: CardStyle) -> AppSnapshot {
        Self.stage(true, Self.station, Self.station)
            .issuingCard(CardSnapshot(id: "FM-01234567", issuedAt: Self.issuedAt, style: style))
    }

    /// legacy 입력은 프로덕션 encoder를 사용하지 않는다. v2 style 필드는 모르는 키다.
    private func legacyV2(extraCardKey: String = "") -> Data {
        Data(#"{"version":2,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seoulForest","name":"서울숲","direction":-1},"cards":{"items":[{"id":"FM-01234567","issuedAt":"2026-10-13T09:00:00Z"\#(extraCardKey)}]},"journey":{"active":null},"records":{"items":[\#(Self.recordJSON)]}}}"#.utf8)
    }

    /// v3 손상자료 생성은 독립 JSON fixture를 기반으로 하며 encode의 검증 우회를 요구하지 않는다.
    private func rawV3(photoData: Data, width: Int = 40, height: Int = 20) throws -> Data {
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: legacyV2()) as? [String: Any])
        root["version"] = 3
        var state = try XCTUnwrap(root["state"] as? [String: Any])
        let photo: [String: Any] = ["id": "11111111-2222-3333-4444-555555555555",
            "data": photoData.base64EncodedString(), "pixelWidth": width, "pixelHeight": height,
            "centerX": 0.5, "centerY": 0.5, "widthFraction": 0.6]
        state["cards"] = ["items": [["id": "FM-01234567", "issuedAt": "2026-10-13T09:00:00Z",
            "style": ["background": ["red": 0.2, "green": 0.3, "blue": 0.4], "photos": [photo]]]]]
        root["state"] = state
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    // 깨짐 명명: 사진 순서/배치/바이트를 버리거나 카드 정체성을 재생성하면 실패한다.
    func testAC24_실파일_재실행은_여섯장_내용_배치_순서_정체성을_복원한다() throws {
        try withTemporaryFile { url in
            let bytes = try CardPhotoTestFixtures.image(alpha: true)
            let photos = (0..<6).map { index in
                CardPhotoTestFixtures.photo(data: bytes,
                    id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!,
                    x: Double(index) * 0.2, y: 0.4, fraction: 0.3)
            }
            let original = snapshot(CardPhotoTestFixtures.style(photos))
            try LocalSnapshotStore(fileURL: url).save(original)
            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: url).load())
            let card = try XCTUnwrap(loaded.currentCard)
            XCTAssertEqual(card.id, "FM-01234567")
            XCTAssertEqual(card.issuedAt, Date(timeIntervalSince1970: 1_791_882_000))
            XCTAssertEqual(card.style.background, CardColor(red: 0.2, green: 0.3, blue: 0.4))
            XCTAssertEqual(card.style.photos.count, 6)
            XCTAssertEqual(card.style.photos.map(\.id), [
                UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
                UUID(uuidString: "00000000-0000-0000-0000-000000000006")!])
            for (photo, expectedX) in zip(card.style.photos, [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]) {
                XCTAssertEqual(photo.centerX, expectedX, accuracy: 0.000001)
            }
            XCTAssertEqual(card.style.photos.map(\.centerY), [0.4, 0.4, 0.4, 0.4, 0.4, 0.4])
            XCTAssertEqual(card.style.photos.map(\.widthFraction), [0.3, 0.3, 0.3, 0.3, 0.3, 0.3])
            for photo in card.style.photos {
                XCTAssertEqual(photo.data, bytes)
                XCTAssertEqual(Double(try CardPhotoTestFixtures.rgba(photo.data)[3]), 128, accuracy: 1)
            }
        }
    }

    // 깨짐 명명: 원본 파일 경로에 의존하거나 재로드 시 사진을 잃으면 실패한다.
    func testAC25_입력원본파일_삭제후에도_실제사진을_복원한다() throws {
        try withTemporaryFile { url in
            let sourceURL = url.deletingLastPathComponent().appendingPathComponent("picker-source.png")
            try CardPhotoTestFixtures.seed(CardPhotoTestFixtures.image(alpha: true), at: sourceURL)
            let bytes = try Data(contentsOf: sourceURL)
            let original = snapshot(CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: bytes)]))
            try LocalSnapshotStore(fileURL: url).save(original)
            try FileManager.default.removeItem(at: sourceURL)
            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: url).load())
            XCTAssertEqual(loaded, original)
            XCTAssertEqual(Double(try CardPhotoTestFixtures.rgba(XCTUnwrap(loaded.currentCard?.style.photos.first).data)[3]), 128, accuracy: 1)
        }
    }

    // 깨짐 명명: v3의 필수 style 누락을 기본 외형으로 채우면 실패한다.
    func testV3_Style누락은_corrupt이며_자동덮어쓰기하지_않는다() throws {
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: legacyV2()) as? [String: Any])
        root["version"] = 3
        let bytes = try JSONSerialization.data(withJSONObject: root)
        try withTemporaryFile { url in
            try CardPhotoTestFixtures.seed(bytes, at: url)
            assertStorageIssue(.corrupt) { _ = try LocalSnapshotStore(fileURL: url).load() }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: v2에서 알 수 없는 style 키를 해석하면 손상/꾸민 외형으로 읽혀 실패한다.
    func testAC29_V2UnknownStyle은_무시하고_표준외형으로_마이그레이션한다() throws {
        let input = legacyV2(extraCardKey: #", "style":{"photos":"broken","background":null},"unknown":7"#)
        let decoded = try SnapshotCodec.decode(input)
        XCTAssertEqual(decoded.currentCard?.style, .standard)
        XCTAssertEqual(decoded.currentCard?.id, "FM-01234567")
        XCTAssertEqual(decoded.currentCard?.issuedAt, Date(timeIntervalSince1970: 1_791_882_000))
        XCTAssertTrue(try XCTUnwrap(decoded.currentCard).style.isStandard)
    }

    // 깨짐 명명: v2 읽기가 재저장되거나 꾸미기 저장이 기존 단계/기록을 잃으면 실패한다.
    func testAC29_V2_읽기는_원본보존_꾸미기저장후_v3로_이용상태를_유지한다() throws {
        try withTemporaryFile { url in
            let bytes = legacyV2()
            try CardPhotoTestFixtures.seed(bytes, at: url)
            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: url).load())
            XCTAssertEqual(try Data(contentsOf: url), bytes)
            XCTAssertEqual(loaded.currentCard?.style, .standard)
            let card = try XCTUnwrap(loaded.currentCard)
            let styledCard = card.updating(style: CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image())]))
            let updated = loaded.updating(cards: snapshot(styledCard.style).cards)
            try LocalSnapshotStore(fileURL: url).save(updated)
            let restored = try XCTUnwrap(try LocalSnapshotStore(fileURL: url).load())
            XCTAssertEqual(restored, updated)
            XCTAssertTrue(restored.cardIssued)
            XCTAssertEqual(restored.initialStation, Self.station)
            XCTAssertEqual(restored.currentStation, StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1))
            XCTAssertNil(restored.journey.active)
            XCTAssertEqual(restored.records.items.count, 1)
            let record = try XCTUnwrap(restored.records.items.first)
            XCTAssertEqual(record.id, "journey-001")
            XCTAssertEqual(record.minutes, 25)
            XCTAssertEqual(record.memo, "첫 메모")
            XCTAssertEqual(restored.records, loaded.records)
            XCTAssertEqual(restored.currentCard?.id, "FM-01234567")
            XCTAssertEqual(restored.currentCard?.issuedAt, Date(timeIntervalSince1970: 1_791_882_000))
            let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
            XCTAssertEqual(root["version"] as? Int, 3)
        }
    }

    // 깨짐 명명: v1 변환을 제거하거나 읽기 중 쓰면 실패한다. 자동 카드 보충은 기존 별도 통합 시험이다.
    func testAC29_V1_읽기는_단계와_정류장을_유지하고_쓰지_않는다() throws {
        let bytes = Data(#"{"version":1,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seongsu","name":"성수","direction":1}}}"#.utf8)
        try withTemporaryFile { url in
            try CardPhotoTestFixtures.seed(bytes, at: url)
            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: url).load())
            XCTAssertTrue(loaded.cardIssued)
            XCTAssertEqual(loaded.initialStation, Self.station)
            XCTAssertEqual(loaded.currentStation, Self.station)
            XCTAssertTrue(loaded.cards.items.isEmpty)
            XCTAssertNil(loaded.journey.active)
            XCTAssertTrue(loaded.records.items.isEmpty)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: atomic write 오류를 성공으로 처리하거나 원본 사진 바이트를 지우면 실패한다.
    func testAtomicWriteFailure_기존외형과_사진_원본을_유지한다() throws {
        try withTemporaryFile { url in
            let original = snapshot(CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image())]))
            try LocalSnapshotStore(fileURL: url).save(original)
            let bytes = try Data(contentsOf: url)
            let failing = LocalSnapshotStore(fileURL: url, writeData: { _, _ in throw ProbeError.write })
            assertStorageIssue(.writeFailed) { try failing.save(snapshot(.standard)) }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
            XCTAssertEqual(try LocalSnapshotStore(fileURL: url).load(), original)
        }
    }

    // 깨짐 명명: 실제 사진 검사 실패를 무시하거나 다른 오류로 포장하면 쓰기가 발생해서 실패한다.
    func testCandidatePhotoValidatorError는_invalidCardPhoto이며_IO를_하지않는다() throws {
        var reads = 0; var directories = 0; var writes = 0
        let store = LocalSnapshotStore(fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in reads += 1; throw CocoaError(.fileReadNoSuchFile) },
            createDirectory: { _ in directories += 1 }, writeData: { _, _ in writes += 1 },
            validateCardPhotos: { _ in throw ProbeError.validation })
        assertStorageIssue(.invalidState(.invalidCardPhoto)) {
            try store.save(snapshot(CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo()])))
        }
        XCTAssertEqual(reads, 0)
        XCTAssertEqual(directories, 0)
        XCTAssertEqual(writes, 0)
    }

    // 깨짐 명명: 원본 이미지 실패를 후보 오류로 분류하거나 기존 데이터를 덮어쓰면 실패한다.
    func testAC28_InvalidPhotoOriginal은_writeBlocked이며_바이트를_유지한다() throws {
        let bytes = try rawV3(photoData: CardPhotoTestFixtures.damagedBody())
        try withTemporaryFile { url in
            try CardPhotoTestFixtures.seed(bytes, at: url)
            var writes = 0; var directories = 0
            let store = LocalSnapshotStore(fileURL: url, createDirectory: { _ in directories += 1 }, writeData: { _, _ in writes += 1 })
            assertStorageIssue(.invalidState(.invalidCardPhoto)) { _ = try store.load() }
            assertStorageIssue(.writeBlocked(.invalidState(.invalidCardPhoto))) { try store.save(snapshot(.standard)) }
            XCTAssertEqual(writes, 0)
            XCTAssertEqual(directories, 0)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: 실제 사진검증을 정상파일 판정에서 빼면 notRequired가 되어 복구가 실패한다.
    func testAC28_InvalidPhotoOriginal은_원본을_그대로_백업한_후에만_제거한다() throws {
        let bytes = try rawV3(photoData: CardPhotoTestFixtures.damagedBody())
        try withTemporaryFile { url in
            try CardPhotoTestFixtures.seed(bytes, at: url)
            let backupID = UUID(uuidString: "99999999-2222-3333-4444-555555555555")!
            let expectedBackup = url.deletingLastPathComponent().appendingPathComponent("app-state.recovery-\(backupID.uuidString).backup")
            let store = LocalSnapshotStore(fileURL: url, backupID: { backupID }, removeData: { original in
                XCTAssertEqual(try Data(contentsOf: expectedBackup), bytes)
                XCTAssertEqual(try Data(contentsOf: original), bytes)
                try FileManager.default.removeItem(at: original)
            })
            let backup = try store.backupAndClear(expectedSource: .bytes(bytes))
            XCTAssertEqual(try Data(contentsOf: backup), bytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        }
    }

    // 깨짐 명명: 손상사진 백업 실패 뒤 원본을 삭제하면 실패한다.
    func testAC28_InvalidPhotoBackupFailure는_원본삭제를_하지않는다() throws {
        let bytes = try rawV3(photoData: CardPhotoTestFixtures.damagedBody())
        try withTemporaryFile { url in
            try CardPhotoTestFixtures.seed(bytes, at: url)
            var removals = 0
            let store = LocalSnapshotStore(fileURL: url,
                writeBackup: { _, _ in throw ProbeError.write }, removeData: { _ in removals += 1 })
            XCTAssertThrowsError(try store.backupAndClear(expectedSource: .bytes(bytes))) {
                XCTAssertEqual($0 as? StorageRecoveryIssue, .backupFailed)
            }
            XCTAssertEqual(removals, 0)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: 장당/전체 byte 경계를 잘못 판정하거나 실패 후보를 쓰면 실패한다.
    // 구조 byte 경계 전용: actual image validator는 no-op이며 실제 이미지 성공 증거가 아니다.
    func testAC27_PerPhotoLimit() throws {
        let counts = [1048576]
        let photos = counts.enumerated().map { index, count in
            CardPhotoTestFixtures.photo(data: Data(repeating: 1, count: count),
                id: index == 0 ? CardPhotoTestFixtures.photoID : UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!)
        }
        let candidate = snapshot(CardPhotoTestFixtures.style(photos))
        try withTemporaryFile { url in
            try LocalSnapshotStore(fileURL: url).save(snapshot(.standard))
            let original = try Data(contentsOf: url)
            var writes = 0; var directories = 0
            let store = LocalSnapshotStore(fileURL: url,
                createDirectory: { target in directories += 1; try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true) },
                writeData: { data, target in writes += 1; try data.write(to: target, options: .atomic) },
                validateCardPhotos: { _ in })
            try store.save(candidate)
            XCTAssertEqual(writes, 1)
            let restarted = LocalSnapshotStore(fileURL: url, validateCardPhotos: { _ in })
            XCTAssertEqual(try restarted.load(), candidate)
        }
    }

    // 깨짐 명명: 장당/전체 byte 경계를 잘못 판정하거나 실패 후보를 쓰면 실패한다.
    // 구조 byte 경계 전용: actual image validator는 no-op이며 실제 이미지 성공 증거가 아니다.
    func testAC27_PerPhotoAboveLimit() throws {
        let counts = [1048577]
        let photos = counts.enumerated().map { index, count in
            CardPhotoTestFixtures.photo(data: Data(repeating: 1, count: count),
                id: index == 0 ? CardPhotoTestFixtures.photoID : UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!)
        }
        let candidate = snapshot(CardPhotoTestFixtures.style(photos))
        try withTemporaryFile { url in
            try LocalSnapshotStore(fileURL: url).save(snapshot(.standard))
            let original = try Data(contentsOf: url)
            var writes = 0; var directories = 0
            let store = LocalSnapshotStore(fileURL: url,
                createDirectory: { target in directories += 1; try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true) },
                writeData: { data, target in writes += 1; try data.write(to: target, options: .atomic) },
                validateCardPhotos: { _ in })
            assertStorageIssue(.invalidState(.invalidCardStyle(.photoTooLarge(CardPhotoTestFixtures.photoID)))) { try store.save(candidate) }
            XCTAssertEqual(writes, 0)
            XCTAssertEqual(directories, 0)
            XCTAssertEqual(try Data(contentsOf: url), original)
            XCTAssertEqual(try LocalSnapshotStore(fileURL: url).load(), snapshot(.standard))
        }
    }

    // 깨짐 명명: 장당/전체 byte 경계를 잘못 판정하거나 실패 후보를 쓰면 실패한다.
    // 구조 byte 경계 전용: actual image validator는 no-op이며 실제 이미지 성공 증거가 아니다.
    func testAC27_TotalLimit() throws {
        let counts = [1048576, 1048576, 1048576, 1048576, 1048576, 1048576]
        let photos = counts.enumerated().map { index, count in
            CardPhotoTestFixtures.photo(data: Data(repeating: 1, count: count),
                id: index == 0 ? CardPhotoTestFixtures.photoID : UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!)
        }
        let candidate = snapshot(CardPhotoTestFixtures.style(photos))
        try withTemporaryFile { url in
            try LocalSnapshotStore(fileURL: url).save(snapshot(.standard))
            let original = try Data(contentsOf: url)
            var writes = 0; var directories = 0
            let store = LocalSnapshotStore(fileURL: url,
                createDirectory: { target in directories += 1; try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true) },
                writeData: { data, target in writes += 1; try data.write(to: target, options: .atomic) },
                validateCardPhotos: { _ in })
            try store.save(candidate)
            XCTAssertEqual(writes, 1)
            let restarted = LocalSnapshotStore(fileURL: url, validateCardPhotos: { _ in })
            XCTAssertEqual(try restarted.load(), candidate)
        }
    }

    // 깨짐 명명: 장당/전체 byte 경계를 잘못 판정하거나 실패 후보를 쓰면 실패한다.
    // 구조 byte 경계 전용: actual image validator는 no-op이며 실제 이미지 성공 증거가 아니다.
    func testAC27_TotalAboveLimit() throws {
        let counts = [1048576, 1048576, 1048576, 1048576, 1048576, 1048577]
        let photos = counts.enumerated().map { index, count in
            CardPhotoTestFixtures.photo(data: Data(repeating: 1, count: count),
                id: index == 0 ? CardPhotoTestFixtures.photoID : UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!)
        }
        let candidate = snapshot(CardPhotoTestFixtures.style(photos))
        try withTemporaryFile { url in
            try LocalSnapshotStore(fileURL: url).save(snapshot(.standard))
            let original = try Data(contentsOf: url)
            var writes = 0; var directories = 0
            let store = LocalSnapshotStore(fileURL: url,
                createDirectory: { target in directories += 1; try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true) },
                writeData: { data, target in writes += 1; try data.write(to: target, options: .atomic) },
                validateCardPhotos: { _ in })
            assertStorageIssue(.invalidState(.invalidCardStyle(.totalPhotosTooLarge))) { try store.save(candidate) }
            XCTAssertEqual(writes, 0)
            XCTAssertEqual(directories, 0)
            XCTAssertEqual(try Data(contentsOf: url), original)
            XCTAssertEqual(try LocalSnapshotStore(fileURL: url).load(), snapshot(.standard))
        }
    }

    // 깨짐 명명: 실제 손상 후보의 이미지 검증을 빼면 read/create/write가 발생한다.
    func testAC28_DamagedCandidate_기존원본_읽기전에_거절한다() throws {
        var reads = 0; var directories = 0; var writes = 0
        let store = LocalSnapshotStore(fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in reads += 1; throw CocoaError(.fileReadNoSuchFile) },
            createDirectory: { _ in directories += 1 }, writeData: { _, _ in writes += 1 })
        let candidate = snapshot(CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.damagedBody())]))
        assertStorageIssue(.invalidState(.invalidCardPhoto)) { try store.save(candidate) }
        XCTAssertEqual(reads, 0)
        XCTAssertEqual(directories, 0)
        XCTAssertEqual(writes, 0)
    }

    // 깨짐 명명: load에서 actual/declared 치수 검사를 빼면 잘못된 배치를 성공으로 읽어 실패한다.
    func testAC28_DeclaredDimensionMismatch_읽기실패는_원본을_유지한다() throws {
        let bytes = try rawV3(photoData: CardPhotoTestFixtures.image(), width: 41)
        try withTemporaryFile { url in
            try CardPhotoTestFixtures.seed(bytes, at: url)
            assertStorageIssue(.invalidState(.invalidCardPhoto)) { _ = try LocalSnapshotStore(fileURL: url).load() }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }
}
```

### ios/FocusMateTests/CardPhotoTestFixtures.swift

```swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import FocusMate

/// 실제 ImageIO 입력. 프로덕션 processor/encoder로 기대 이미지를 만들지 않는다.
enum CardPhotoTestFixtures {
    static let photoID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!

    static func image(width: Int = 40, height: Int = 20, alpha: Bool = false,
                      type: UTType = .png, orientation: Int = 1) throws -> Data {
        let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: alpha ? 0.5 : 1))
        context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        let image = try XCTUnwrap(context.makeImage())
        let bytes = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(bytes, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw FixtureIssue.encoding }
        return bytes as Data
    }

    static func source(_ bytes: Data) throws -> CGImageSource {
        try XCTUnwrap(CGImageSourceCreateWithData(bytes as CFData, nil))
    }

    static func decoded(_ bytes: Data) throws -> CGImage {
        let source = try source(bytes)
        return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }

    static func rgba(_ bytes: Data) throws -> [UInt8] {
        let image = try decoded(bytes)
        let context = try XCTUnwrap(CGContext(data: nil, width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let pointer = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
        return Array(UnsafeBufferPointer(start: pointer, count: 4))
    }

    /// PNG signature와 IHDR은 남기고 IDAT payload를 깨뜨린다. 헤더만 읽는 구현을 잡는다.
    static func damagedBody() throws -> Data {
        var bytes = try image()
        let range = try XCTUnwrap(bytes.range(of: Data("IDAT".utf8)))
        let start = range.upperBound
        guard start + 4 < bytes.count else { throw FixtureIssue.encoding }
        bytes.replaceSubrange(start..<(bytes.count - 12), with: Data(repeating: 0, count: bytes.count - 12 - start))
        return bytes
    }

    static func photo(data: Data = Data([1]), width: Int = 40, height: Int = 20,
                      id: UUID = photoID, x: Double = 0.5, y: Double = 0.5,
                      fraction: Double = 0.6) -> CardPhoto {
        CardPhoto(id: id, data: data, pixelWidth: width, pixelHeight: height,
                  centerX: x, centerY: y, widthFraction: fraction)
    }

    static func style(_ photos: [CardPhoto]) -> CardStyle {
        CardStyle(background: CardColor(red: 0.2, green: 0.3, blue: 0.4), photos: photos)
    }

    static func seed(_ bytes: Data, at url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try bytes.write(to: url)
    }

    enum FixtureIssue: Error { case encoding }
}
```

## 기존 기대값 변경 diff (테스트 파일 한정)

```diff
diff --git a/ios/FocusMateTests/CardStorageTests.swift b/ios/FocusMateTests/CardStorageTests.swift
index cb10329..3688423 100644
--- a/ios/FocusMateTests/CardStorageTests.swift
+++ b/ios/FocusMateTests/CardStorageTests.swift
@@ -18,7 +18,7 @@ final class CardStorageTests: XCTestCase {
 
     private static let nullStations = #""currentStation":null,"initialStation":null"#
 
-    // 깨짐 명명: id를 숫자로 바꿔 앞자리 0을 잃거나, 날짜를 다른 형식으로 쓰거나, 재저장 바이트가 달라지거나, version이 2가 아니면 실패.
+    // 깨짐 명명: id를 숫자로 바꿔 앞자리 0을 잃거나, 날짜를 다른 형식으로 쓰거나, 재저장 바이트가 달라지거나, v3 필수 style을 누락하면 실패.
     func testAC13_카드항목은_저장_로드_재저장해도_값과_바이트가_같다() throws {
         try withTemporaryFile { fileURL in
             let snapshot = Self.stage(true, Self.seongsu, Self.seongsu)
@@ -36,11 +36,12 @@ final class CardStorageTests: XCTestCase {
             XCTAssertEqual(try Data(contentsOf: fileURL), firstBytes)
 
             let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: firstBytes) as? [String: Any])
-            XCTAssertEqual(root["version"] as? Int, 2)
-            XCTAssertEqual(
-                String(decoding: firstBytes, as: UTF8.self),
-                #"{"state":{"cardIssued":true,"cards":{"items":[{"id":"FM-01234567","issuedAt":"2026-10-13T09:00:00Z"}]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":null},"records":{"items":[]}},"version":2}"#
-            )
+            XCTAssertEqual(root["version"] as? Int, 3)
+            let state = try XCTUnwrap(root["state"] as? [String: Any])
+            let cards = try XCTUnwrap(state["cards"] as? [String: Any])
+            let items = try XCTUnwrap(cards["items"] as? [[String: Any]])
+            XCTAssertNotNil(try XCTUnwrap(items.first)["style"])
+            XCTAssertEqual(loaded.currentCard?.style, .standard)
         }
     }
 
diff --git a/ios/FocusMateTests/CardSupplementTests.swift b/ios/FocusMateTests/CardSupplementTests.swift
index 73e2d54..21fa322 100644
--- a/ios/FocusMateTests/CardSupplementTests.swift
+++ b/ios/FocusMateTests/CardSupplementTests.swift
@@ -30,7 +30,7 @@ final class CardSupplementTests: XCTestCase {
 
         let saved = try decode(fake.bytes())
         let root = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(fake.bytes())) as? [String: Any])
-        XCTAssertEqual(root["version"] as? Int, 2)
+        XCTAssertEqual(root["version"] as? Int, 3)
         XCTAssertEqual(saved.cards.items.count, 1)
         assertCardID(saved.currentCard?.id)
         XCTAssertEqual(saved.initialStation, Self.seongsu)
diff --git a/ios/FocusMateTests/RecordStorageTests.swift b/ios/FocusMateTests/RecordStorageTests.swift
index 947ee35..d5d6937 100644
--- a/ios/FocusMateTests/RecordStorageTests.swift
+++ b/ios/FocusMateTests/RecordStorageTests.swift
@@ -66,20 +66,20 @@ final class RecordStorageTests: XCTestCase {
         try assertProtected(bytes, loadIssue: issue, saveIssue: .writeBlocked(issue))
     }
 
-    // 깨짐 명명: 미지원 v3에서 완료·메모 저장이 파일을 쓰거나 원인을 잃으면 실패.
+    // 깨짐 명명: 미지원 v4에서 완료·메모 저장이 파일을 쓰거나 원인을 잃으면 실패.
     @MainActor
     func testAC12_미지원버전_AppModel은_완료와_메모저장을_차단하고_원본을_보존한다() throws {
-        let bytes = Data(#"{"version":3,"state":null}"#.utf8)
+        let bytes = Data(#"{"version":4,"state":null}"#.utf8)
         try withTemporaryFile { fileURL in
             try seed(fileURL, bytes)
             let model = AppModel(store: LocalSnapshotStore(fileURL: fileURL))
             model.loadIfNeeded()
-            XCTAssertEqual(model.launchState, .failed(.unsupportedVersion(3)))
+            XCTAssertEqual(model.launchState, .failed(.unsupportedVersion(4)))
 
             XCTAssertFalse(model.recordCompletion(Self.input(), outcome: .alighted, timeZone: Self.seoul))
-            XCTAssertEqual(model.saveFailure, .writeBlocked(.unsupportedVersion(3)))
+            XCTAssertEqual(model.saveFailure, .writeBlocked(.unsupportedVersion(4)))
             XCTAssertFalse(model.saveRecordMemo("메모", forJourneyID: "journey-001"))
-            XCTAssertEqual(model.saveFailure, .writeBlocked(.unsupportedVersion(3)))
+            XCTAssertEqual(model.saveFailure, .writeBlocked(.unsupportedVersion(4)))
             XCTAssertEqual(try Data(contentsOf: fileURL), bytes)
         }
     }
@@ -94,7 +94,7 @@ final class RecordStorageTests: XCTestCase {
             XCTAssertTrue(model.recordCompletion(Self.input(), outcome: .alighted, timeZone: Self.seoul))
 
             let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as? [String: Any])
-            XCTAssertEqual(root["version"] as? Int, 2)
+            XCTAssertEqual(root["version"] as? Int, 3)
             let state = try XCTUnwrap(root["state"] as? [String: Any])
             XCTAssertEqual(state["cardIssued"] as? Bool, true)
             XCTAssertEqual(((state["cards"] as? [String: Any])?["items"] as? [Any])?.count, 0)
diff --git a/ios/FocusMateTests/SnapshotCodecTests.swift b/ios/FocusMateTests/SnapshotCodecTests.swift
index 97b3e1c..c8f449c 100644
--- a/ios/FocusMateTests/SnapshotCodecTests.swift
+++ b/ios/FocusMateTests/SnapshotCodecTests.swift
@@ -34,7 +34,7 @@ final class SnapshotCodecTests: XCTestCase {
         let out = try SnapshotCodec.encode(AppSnapshot.empty)
         XCTAssertEqual(
             String(decoding: out, as: UTF8.self),
-            #"{"state":{"cardIssued":false,"cards":{"items":[]},"currentStation":null,"initialStation":null,"journey":{"active":null},"records":{"items":[]}},"version":2}"#
+            #"{"state":{"cardIssued":false,"cards":{"items":[]},"currentStation":null,"initialStation":null,"journey":{"active":null},"records":{"items":[]}},"version":3}"#
         )
     }
 
@@ -43,7 +43,7 @@ final class SnapshotCodecTests: XCTestCase {
         let out = try SnapshotCodec.encode(try SnapshotCodec.decode(data(Self.v1Issued)))
         XCTAssertEqual(
             String(decoding: out, as: UTF8.self),
-            #"{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":null},"records":{"items":[]}},"version":2}"#
+            #"{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":null},"records":{"items":[]}},"version":3}"#
         )
     }
 
@@ -65,9 +65,9 @@ final class SnapshotCodecTests: XCTestCase {
         XCTAssertEqual(first, second)
     }
 
-    func testCurrentVersionIsTwo() {
-        // 깨짐 명명: currentVersion이 2가 아니면 실패한다.
-        XCTAssertEqual(SnapshotCodec.currentVersion, 2)
+    func testCurrentVersionIsThree() {
+        // 깨짐 명명: currentVersion이 3이 아니면 실패한다.
+        XCTAssertEqual(SnapshotCodec.currentVersion, 3)
     }
 
     // 깨짐 명명: 헤더/버전 검사 순서나 분류가 틀리면 해당 입력에서 실패한다.
@@ -81,7 +81,7 @@ final class SnapshotCodecTests: XCTestCase {
             (#"{"state":{}}"#, .corrupt),
             (#"{"version":0,"state":{}}"#, .unsupportedVersion(0)),
             (#"{"version":-1,"state":{}}"#, .unsupportedVersion(-1)),
-            (#"{"version":3,"state":{}}"#, .unsupportedVersion(3)),
+            (#"{"version":4,"state":{}}"#, .unsupportedVersion(4)),
             (#"{"version":999}"#, .unsupportedVersion(999)),
         ]
         for (input, issue) in cases {
diff --git a/ios/FocusMateTests/StorageRecoveryTests.swift b/ios/FocusMateTests/StorageRecoveryTests.swift
index 98f032e..a45f7fb 100644
--- a/ios/FocusMateTests/StorageRecoveryTests.swift
+++ b/ios/FocusMateTests/StorageRecoveryTests.swift
@@ -397,7 +397,7 @@ final class StorageRecoveryTests: XCTestCase {
     func testAC8_오류버전은_원본바이트_그대로_백업에_보존된다() throws {
         let cases: [(name: String, bytes: Data)] = [
             ("version 0", Data(#"{"version":0,"state":null}"#.utf8)),
-            ("version 3", Data(#"{"version":3,"state":null}"#.utf8)),
+            ("version 4", Data(#"{"version":4,"state":null}"#.utf8)),
             ("string version", Data(#"{"version":"2","state":null}"#.utf8)),
         ]
 
diff --git a/ios/FocusMateTests/StorageV2Tests.swift b/ios/FocusMateTests/StorageV2Tests.swift
index e8be7fa..4bdc7c3 100644
--- a/ios/FocusMateTests/StorageV2Tests.swift
+++ b/ios/FocusMateTests/StorageV2Tests.swift
@@ -56,14 +56,14 @@ final class StorageV2Tests: XCTestCase {
     }
 
     // 깨짐 명명: save가 version 1로 쓰거나 새 영역 키를 빠뜨리면 실패.
-    func testAC2a_파일없음에서_저장하면_v2형식이고_재로드와_재저장이_동일하다() throws {
+    func testAC2a_파일없음에서_저장하면_v3형식이고_재로드와_재저장이_동일하다() throws {
         try withTemporaryFile { fileURL in
             let snapshot = Self.stage(true, Self.seongsu, Self.seoulForest)
             try LocalSnapshotStore(fileURL: fileURL).save(snapshot)
             let firstBytes = try Data(contentsOf: fileURL)
 
             let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: firstBytes) as? [String: Any])
-            XCTAssertEqual(root["version"] as? Int, 2)
+            XCTAssertEqual(root["version"] as? Int, 3)
             let state = try XCTUnwrap(root["state"] as? [String: Any])
             XCTAssertEqual(
                 Set(state.keys),
@@ -77,8 +77,8 @@ final class StorageV2Tests: XCTestCase {
         }
     }
 
-    // 깨짐 명명: v1 로드 실패 또는 저장 바이트가 G2와 다르면(키 누락·version 1·정류장 값 손실) 실패.
-    func testAC2b_v1에서_읽은_상태를_저장하면_정확한_v2바이트가_기록된다() throws {
+    // 깨짐 명명: v1 로드 실패 또는 저장 바이트가 v3 기대값과 다르면(키 누락·version 1/2·정류장 값 손실) 실패.
+    func testAC2b_v1에서_읽은_상태를_저장하면_정확한_v3바이트가_기록된다() throws {
         try withTemporaryFile { fileURL in
             try seed(fileURL, Self.v1Seongsu)
             let store = LocalSnapshotStore(fileURL: fileURL)
@@ -86,7 +86,7 @@ final class StorageV2Tests: XCTestCase {
 
             try store.save(loaded)
 
-            XCTAssertEqual(try Data(contentsOf: fileURL), Self.g2Seongsu)
+            XCTAssertEqual(try Data(contentsOf: fileURL), Data(#"{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":null},"records":{"items":[]}},"version":3}"#.utf8))
             let reloaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())
             XCTAssertEqual(reloaded, Self.stage(true, Self.seongsu, Self.seongsu))
         }
@@ -164,7 +164,7 @@ final class StorageV2Tests: XCTestCase {
     }
 
     private static let protectedCases: [(name: String, bytes: Data, issue: StorageIssue)] = [
-        ("버전 3", Data(#"{"version":3,"state":null}"#.utf8), .unsupportedVersion(3)),
+        ("버전 4", Data(#"{"version":4,"state":null}"#.utf8), .unsupportedVersion(4)),
         ("버전 999", Data(#"{"version":999,"state":null}"#.utf8), .unsupportedVersion(999)),
         ("버전 0", Data(#"{"version":0,"state":null}"#.utf8), .unsupportedVersion(0)),
         ("빈 파일", Data(), .corrupt),
```


## T2 RED 컨텍스트 보강 — 실제 WebP / 정확히 8MiB PNG

Status: DONE_WITH_CONCERNS

신규 processor 테스트 **2개**를 추가했다(23→25, 기존 작성 99→101). 기존 99 case와 기존 6파일 expectation은 변경하지 않았다. 이번 쓰기 소유 범위는 CardPhotoProcessorTests.swift, CardPhotoTestFixtures.swift, 이 보고서뿐이다. 프로덕션 source 읽기/검색/수정, 다른 agent, commit/push/삭제, build/test 실행 없음.

### 입력 provenance 및 기존 요청 해소
- WebP: 부모가 번들 Python3 Pillow lossless encoder로 자체 생성한 40×20 RGB(220,40,80), 38bytes. 외부 사진/라이선스 없음. 지정 base64를 helper에 그대로 넣었고 출처를 주석으로 기록했다. 확장자 변경이나 PNG 위장은 없다.
- 부모 입력 기록: reports/t2-fixture-input.md, t2-fixture-validation.log, test-webp-base64.txt. 부모 macOS ImageIO 기록은 두 입력의 40×20, source/index complete(0), decode/draw 성공이다. 이 기록은 대상 iOS processor 성공 증거가 아니다.
- exact8MiB: 기존 독립 ImageIO image() PNG를 사용하고 IEND 앞 정상 tEXt를 삽입한다. payload = 8_388_608 - 기존 PNG 크기 - 12 - 8. `padding`+NUL(8bytes) 뒤 Latin-1 x payload, big-endian length 및 type+data 표준 CRC32(polynomial 0xEDB88320)를 작성한다. 전체 입력에는 메타데이터를 포함하며 후행 padding은 없다.
- 기존 남은 입력 1·2는 코드 작성 기준으로 해소했다. 각 신규 케이스는 독립 ImageIO source/index complete, decode/draw로 실제 입력 유효성을 확인한 다음 실제 processor를 호출한다. 출력도 complete/decode, 실제 40×20 및 비율2, <=1MiB, 불투명 색 내용, validateStoredPhoto 성공으로 검증한다. standalone 선언 field change detector가 아니다. WebP JPEG 변환 색 오차 ±8 허용, alpha255 요구. skip 없음.
- 선언 요청: 새 fixture/test에 추가 프로덕션 인터페이스 요청은 없다. 기존 설계의 process/결과 읽기/validateStoredPhoto만 사용한다. 기존 선언 체크리스트는 부모가 확인할 계약 참고이며 이 보강에서 선언/stub을 작성하지 않았다. 현 생산 선언 존재 여부를 확인했다는 뜻이 아니다.

### 신규 케이스 / 변이 점검
1. `testAC05_WebP_실제이미지는_보존가능한_내용으로_처리된다`: 읽을 수 있는 WebP 거절, 빈 반환, 다른 색 반환, 잘못된 치수 또는 저장 불가 결과를 검출한다.
2. `testAC05_Exact8MiB_완전한PNG는_내용을_보존하여_처리된다`: >=8MiB 잘못된 경계 거절, 메타데이터 포함 원본 반환(1MiB 초과), 빈/다른 색/치수 반환을 검출한다.

### 실행 / 우려사항
실패 확인 명령 실행 없음(부모만 실행 지시). 실패 메시지 미확보이며 정상 RED/컴파일/fixture 오류를 아직 분류하지 않았다. 부모는 기존 직렬 iOS runner에서 CardPhotoProcessorTests를 실행하고 대상 iOS WebP 지원 및 exact8MiB 생성 fixture의 complete/decode를 확인해야 한다. skip으로 우회하지 않는다. 정적 삽입 검사는 기존 두 파일 내용이 그대로 남음을 확인했으며 실행 검증을 대체하지 않는다.

### 이번 참조 파일
- .dev/codex-feat-card-customization/reports/t2-red.md
- .dev/codex-feat-card-customization/design.md
- .dev/codex-feat-card-customization/prd.md
- .dev/codex-feat-card-customization/reports/t2-fixture-input.md
- .dev/codex-feat-card-customization/t2-fixture-validation.log
- .dev/codex-feat-card-customization/test-webp-base64.txt
- ios/FocusMateTests/CardPhotoProcessorTests.swift
- ios/FocusMateTests/CardPhotoTestFixtures.swift
- /Users/bonseung/.codex/plugins/cache/superpowers-marketplace/superpowers/7.0.0/skills/using-superpowers/SKILL.md (지정 RED 디스패치이므로 SUBAGENT-STOP 적용; 별도 workflow/agent 실행 없음)

### 전체 추가 테스트 코드
```swift

    // 깨짐 명명: 읽을 수 있는 WebP를 거절하거나 빈/다른 색 이미지로 반환하면 실패한다.
    func testAC05_WebP_실제이미지는_보존가능한_내용으로_처리된다() async throws {
        let input = try CardPhotoTestFixtures.losslessWebP()
        let inputImage = try CardPhotoTestFixtures.completeDecoded(input)
        XCTAssertEqual(inputImage.width, 40)
        XCTAssertEqual(inputImage.height, 20)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.completeDecoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(Double(decoded.width) / Double(decoded.height), 2)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        // 불투명 입력. JPEG 재인코딩 오차는 허용하되 다른 색으로 대체하면 실패한다.
        XCTAssertEqual(Double(rgba[0]), 220, accuracy: 8)
        XCTAssertEqual(Double(rgba[1]), 40, accuracy: 8)
        XCTAssertEqual(Double(rgba[2]), 80, accuracy: 8)
        XCTAssertEqual(rgba[3], 255)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(
            CardPhotoTestFixtures.photo(data: result.data, width: 40, height: 20)))
    }

    // 깨짐 명명: 입력 한도를 >=8MiB로 거절하거나 메타데이터 포함 원본을 그대로 반환하면 실패한다.
    func testAC05_Exact8MiB_완전한PNG는_내용을_보존하여_처리된다() async throws {
        let input = try CardPhotoTestFixtures.exact8MiBPNG()
        XCTAssertEqual(input.count, 8_388_608)
        let inputImage = try CardPhotoTestFixtures.completeDecoded(input)
        XCTAssertEqual(inputImage.width, 40)
        XCTAssertEqual(inputImage.height, 20)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.completeDecoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(Double(decoded.width) / Double(decoded.height), 2)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertGreaterThan(rgba[0], 240)
        XCTAssertLessThan(rgba[1], 15)
        XCTAssertLessThan(rgba[2], 15)
        XCTAssertEqual(rgba[3], 255)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(
            CardPhotoTestFixtures.photo(data: result.data, width: 40, height: 20)))
    }
```

### 전체 추가 fixture 코드
```swift

    /// 부모가 번들 Python3 Pillow lossless WebP encoder로 자체 생성한 40×20 RGB(220,40,80), 38bytes.
    /// 외부 사진/라이선스 없음. 출처: .dev/codex-feat-card-customization/reports/t2-fixture-input.md,
    /// test-webp-base64.txt 및 t2-fixture-validation.log (macOS ImageIO complete/decode/draw 성공).
    /// 대상 iOS 지원은 skip 없이 실제 processor 테스트에서 검증한다.
    static func losslessWebP() throws -> Data {
        try XCTUnwrap(Data(base64Encoded: "UklGRh4AAABXRUJQVlA4TBEAAAAvJ8AEAAdQlHIXqv+BiOh/AAA="))
    }

    /// 기존 ImageIO PNG의 IEND 앞에 정상 tEXt 메타데이터를 삽입한다. 후행 padding이 아니다.
    /// 전체 입력 한도에는 메타데이터도 포함된다: base + 12(chunk overhead) + 8(key+NUL) + payload.
    static func exact8MiBPNG() throws -> Data {
        var bytes = try image()
        let targetCount = 8_388_608
        let keyword = Data("padding\0".utf8)
        let payloadCount = targetCount - bytes.count - 12 - keyword.count
        guard payloadCount >= 0 else { throw FixtureIssue.encoding }

        // PNG chunk 경계를 따라 IEND를 찾는다. 압축 본문 안의 우연한 문자열과 혼동하지 않는다.
        var offset = 8
        var iendOffset: Int?
        while offset <= bytes.count - 12 {
            let length = bytes[offset..<(offset + 4)].reduce(0) { ($0 << 8) | Int($1) }
            guard length <= bytes.count - offset - 12 else { throw FixtureIssue.encoding }
            let type = bytes[(offset + 4)..<(offset + 8)]
            if Data(type) == Data("IEND".utf8) {
                guard length == 0, offset + 12 == bytes.count else { throw FixtureIssue.encoding }
                iendOffset = offset
                break
            }
            offset += length + 12
        }
        let insertionOffset = try XCTUnwrap(iendOffset)
        var text = keyword
        text.append(Data(repeating: 0x78, count: payloadCount)) // 유효한 Latin-1 tEXt 값 'x'.
        var crcInput = Data("tEXt".utf8)
        crcInput.append(text)
        var chunk = bigEndianBytes(UInt32(text.count))
        chunk.append(crcInput)
        chunk.append(bigEndianBytes(crc32(crcInput)))
        bytes.insert(contentsOf: chunk, at: insertionOffset)
        return bytes
    }

    private static func bigEndianBytes(_ value: UInt32) -> Data {
        Data([UInt8(truncatingIfNeeded: value >> 24), UInt8(truncatingIfNeeded: value >> 16),
              UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)])
    }

    // PNG CRC는 chunk type+data를 대상으로 하는 표준 reflected CRC32다.
    private static func crc32(_ bytes: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in bytes {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xEDB8_8320 : 0)
            }
        }
        return crc ^ 0xFFFF_FFFF
    }

    /// 프로덕션 processor와 독립적인 ImageIO 검사. 부분 복구 입력도 성공으로 인정하지 않는다.
    static func completeDecoded(_ bytes: Data) throws -> CGImage {
        let source = try source(bytes)
        guard CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
            XCTFail("Fixture/output ImageIO source and index must be complete")
            throw FixtureIssue.encoding
        }
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let context = try XCTUnwrap(CGContext(data: nil, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
        _ = try XCTUnwrap(context.data)
        return image
    }
```

정적 최종 확인: 소유 3파일 한정 `git diff --check` exit0. CardPhotoProcessorTests 텍스트 작성 수 25, 신규 각 메서드 1회 확인. build/test 실행 수 0.


## T2 RED 테스트 컴파일 오류 수리 — recordJSON delimiter

Status: DONE_WITH_CONCERNS

- 수정 파일: `ios/FocusMateTests/CardStyleStorageTests.swift:9`. `recordJSON` raw string의 시작/끝 구분자를 `#" … "#`에서 `##" … "##`로 변경했다. `tagColor`의 `"#12ABef`가 문자열을 조기 종료하던 문법 오류를 수리했다. JSON 본문과 모든 기대값·assertion·케이스는 그대로 유지했다.
- 수정한 `recordJSON`에는 interpolation이 없다. 다른 raw string의 기존 single-hash 구분자와 `\#(...)` interpolation은 변경하지 않았다.
- `.dev/codex-feat-card-customization/t2-red-test.log`의 같은 파일 오류는 arm64/x86_64 모두 line 9의 invalid digit / consecutive declarations / expected declaration이며, 같은 조기 종료에서 파생된 진단이다. 로그에 같은 파일의 다른 문법 오류는 없었다.
- 이전 부모 test 명령의 exit 65는 **컴파일 오류이며 정상 RED가 아니다**. `TEST FAILED` 표기만으로 assertion RED를 확인한 것으로 간주하지 않는다. 기존 로그는 수정하지 않았다.
- **actual compile 미실행**: 이번 작업에서는 컴파일·빌드·테스트·xcodebuild·checkios를 실행하지 않았다. 오류 수리는 텍스트 기준이며 컴파일 성공이나 정상 assertion RED는 아직 확인되지 않았다. 재실행과 결과 분류는 부모 담당이다.
- 정적 확인: 수정 전후 JSON 본문 동일, 해당 줄에 interpolation 없음, 추가된 문자는 delimiter용 hash 2개뿐임을 확인했다. 이는 컴파일 증거가 아니다.
- 참조 파일: `ios/FocusMateTests/CardStyleStorageTests.swift`, `.dev/codex-feat-card-customization/reports/t2-red.md`, `.dev/codex-feat-card-customization/t2-red-test.log`. 프로덕션 source 열람·검색·수정 없음. 최초 루트 `reports/` 조회는 파일 없음으로 실패하여 실제 W10 보고서 경로로 바로잡았다.

## 부모 직접 verify_red
문법오류수리후 지정9개unit파일 실제174시험/98failures(11unexpected),exit65. 컴파일성공, 정상 assertion RED와 미구현 processor 오류 확인. WebP/exact8MiB/HEICfixture생성·decode관련오류없음; 처리stub unreadable에서성공시나리오실패. 모델수치거절·v3저장·style보존·실제 사진 Store 검증이 미구현이라 실패. t2-red-test-recheck.log actual. 테스트작성자production비열람로그검토, hash기준 t2-test-hashes.json/porcelain보존.


## 2026-10-14 T2 fixture 색공간 정의 수리 (append)

Status: DONE_WITH_CONCERNS — 정적 검토 완료, 실행·빌드·Swift compile 미확인(부모 전담).

### actual test defect 근거
- t2-impl-test.log 250/254/257/260/288행: exact8MiB PNG/HEIC/JPEG/PNG는 green 38/38/39/38로 기존 `<15` 실패, alpha PNG는 green 19로 `<5` 실패.
- t2-impl-test-attempt5.log 원본 픽셀 진단 259/267/273/279/329행: exactPNG `[255,38,0,255]`, HEIC `[255,38,1,255]`, JPEG `[255,39,0,255]`, PNG `[255,38,0,255]`, alphaPNG `[128,19,0,128]`; 인접 thumbnail 값도 유사하다. 출력만의 색 손실로 단정할 수 없고 입력부터 pure red 기대값을 위반한다.
- fixture image()는 DeviceRGB CGContext에 기본 색공간 CGColor(red:...)를 채웠다. 입력과 판독 공간을 고정하지 않은 fixture 결함을 수리한다. design.md 외형 값 정책의 불투명 sRGB 0...1 및 ImageIO 독립 실제 decode 경계를 참조했다. 사진 전체의 새 색보정 정책을 도입하거나 생산 데이터에서 green을 빼지 않는다.

### 수정 및 영향 목록
- image(): 생성 bitmap context를 명시적 sRGB로 변경하고 같은 context.colorSpace에 components `[1,0,0,alpha ? 0.5 : 1]`를 지정했다. 기본/각 포맷/alpha/orientation/치수 fixture와 이를 사용하는 ratio·resize·저장 검증 입력, damagedBody 및 exact8MiBPNG의 기반 PNG에 영향을 준다. 선언 치수·orientation·alpha 의미는 그대로다.
- rgba(): 독립 ImageIO decode 후 1×1 판독 context를 명시적 sRGB로 고정했다. processor 입력·출력과 WebP 판독 공간이 일관된다. WebP bytes와 Pillow RGB(220,40,80)의 의미는 그대로다.
- completeDecoded(): 전체 bitmap draw context를 명시적 sRGB로 고정했다. source/index complete, 전체 decode, dimension 검증 구조는 그대로다.
- JPEG/PNG/HEIC/alphaPNG/exact8MiBPNG 다섯 기존 성공 시나리오에서 processor 호출 전에 complete ImageIO decode와 rgba 입력 sanity를 검사한다. 손으로 정의한 기존 pure red/alpha literal 경계를 적용하며 processor 결과로 기대값을 계산하지 않는다. fixture sanity는 입력 색 정의 오류를 검출하고 기존 출력 assertion은 빈 반환/잘못된 색 분기/alpha 누락을 계속 검출한다.
- 기존 RGB·alpha·dimension·byte·identity assertion 및 case는 삭제/완화하지 않았다. 기존 output assertion 전체가 문자 그대로 남았음을 정적으로 확인했다. CRC32/chunk 탐색/정확 8MiB chunk overhead·CRC, 손상 PNG 생성, WebP 입력·시험 본문, 구조 byte 검증용 storage helper는 그대로 유지했다. 다른 test와 production 파일은 수정하지 않았다.

### 검증 한계 및 부모 인계
- Python 정적 비교 PASS: 명시적 sRGB context 3개, 입력 sanity 5개, 모든 기존 assertion/case 유지, PNG 손상/CRC/8MiB와 WebP 본문 불변.
- 테스트 실행·빌드·Swift compile은 요청에 따라 수행하지 않았다. 새 RED/GREEN 또는 unit/UI PASS를 주장하지 않는다.
- 부모가 재실행할 때 먼저 다섯 원본 sanity 결과를 확인한다. JPEG/HEIC 실제 encoder 색관리로 원본이 기존 pureRed 경계를 만족하지 않으면 포맷·원본 sRGB 판독값·실패 경계를 기록하여 입력 인코딩 경계 문제로 보고한다. threshold 완화, 생산 색보정, 실제 product 결과로 기대값 대체는 하지 않는다. 이 실행에서는 새 픽셀값을 확인하지 않았다.

### 참조 파일 전체
- ios/FocusMateTests/CardPhotoTestFixtures.swift
- ios/FocusMateTests/CardPhotoProcessorTests.swift
- .dev/codex-feat-card-customization/prd.md
- .dev/codex-feat-card-customization/design.md
- .dev/codex-feat-card-customization/t2-impl-test-attempt5.log (원본 픽셀 진단만 근거)
- .dev/codex-feat-card-customization/t2-impl-test.log (actual failure만 근거)
- 파일 목록 탐색 외 production source/report 본문은 열람·검색하지 않았다. 이 report는 기존 본문을 읽거나 덮어쓰지 않고 append했다.

### 수정 후 코드 전문

#### ios/FocusMateTests/CardPhotoTestFixtures.swift

```swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import FocusMate

/// 실제 ImageIO 입력. 프로덕션 processor/encoder로 기대 이미지를 만들지 않는다.
enum CardPhotoTestFixtures {
    static let photoID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!

    static func image(width: Int = 40, height: Int = 20, alpha: Bool = false,
                      type: UTType = .png, orientation: Int = 1) throws -> Data {
        let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4, space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        // 입력의 pure red는 context와 같은 명시적 sRGB에서 정의한다.
        let color = try XCTUnwrap(CGColor(colorSpace: try XCTUnwrap(context.colorSpace),
            components: [1, 0, 0, alpha ? 0.5 : 1]))
        context.setFillColor(color)
        context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        let image = try XCTUnwrap(context.makeImage())
        let bytes = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(bytes, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw FixtureIssue.encoding }
        return bytes as Data
    }

    static func source(_ bytes: Data) throws -> CGImageSource {
        try XCTUnwrap(CGImageSourceCreateWithData(bytes as CFData, nil))
    }

    static func decoded(_ bytes: Data) throws -> CGImage {
        let source = try source(bytes)
        return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }

    static func rgba(_ bytes: Data) throws -> [UInt8] {
        let image = try decoded(bytes)
        let context = try XCTUnwrap(CGContext(data: nil, width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4, space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let pointer = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
        return Array(UnsafeBufferPointer(start: pointer, count: 4))
    }

    /// PNG signature와 IHDR은 남기고 IDAT payload를 깨뜨린다. 헤더만 읽는 구현을 잡는다.
    static func damagedBody() throws -> Data {
        var bytes = try image()
        let range = try XCTUnwrap(bytes.range(of: Data("IDAT".utf8)))
        let start = range.upperBound
        guard start + 4 < bytes.count else { throw FixtureIssue.encoding }
        bytes.replaceSubrange(start..<(bytes.count - 12), with: Data(repeating: 0, count: bytes.count - 12 - start))
        return bytes
    }

    static func photo(data: Data = Data([1]), width: Int = 40, height: Int = 20,
                      id: UUID = photoID, x: Double = 0.5, y: Double = 0.5,
                      fraction: Double = 0.6) -> CardPhoto {
        CardPhoto(id: id, data: data, pixelWidth: width, pixelHeight: height,
                  centerX: x, centerY: y, widthFraction: fraction)
    }

    static func style(_ photos: [CardPhoto]) -> CardStyle {
        CardStyle(background: CardColor(red: 0.2, green: 0.3, blue: 0.4), photos: photos)
    }

    static func seed(_ bytes: Data, at url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try bytes.write(to: url)
    }


    /// 부모가 번들 Python3 Pillow lossless WebP encoder로 자체 생성한 40×20 RGB(220,40,80), 38bytes.
    /// 외부 사진/라이선스 없음. 출처: .dev/codex-feat-card-customization/reports/t2-fixture-input.md,
    /// test-webp-base64.txt 및 t2-fixture-validation.log (macOS ImageIO complete/decode/draw 성공).
    /// 대상 iOS 지원은 skip 없이 실제 processor 테스트에서 검증한다.
    static func losslessWebP() throws -> Data {
        try XCTUnwrap(Data(base64Encoded: "UklGRh4AAABXRUJQVlA4TBEAAAAvJ8AEAAdQlHIXqv+BiOh/AAA="))
    }

    /// 기존 ImageIO PNG의 IEND 앞에 정상 tEXt 메타데이터를 삽입한다. 후행 padding이 아니다.
    /// 전체 입력 한도에는 메타데이터도 포함된다: base + 12(chunk overhead) + 8(key+NUL) + payload.
    static func exact8MiBPNG() throws -> Data {
        var bytes = try image()
        let targetCount = 8_388_608
        let keyword = Data("padding\0".utf8)
        let payloadCount = targetCount - bytes.count - 12 - keyword.count
        guard payloadCount >= 0 else { throw FixtureIssue.encoding }

        // PNG chunk 경계를 따라 IEND를 찾는다. 압축 본문 안의 우연한 문자열과 혼동하지 않는다.
        var offset = 8
        var iendOffset: Int?
        while offset <= bytes.count - 12 {
            let length = bytes[offset..<(offset + 4)].reduce(0) { ($0 << 8) | Int($1) }
            guard length <= bytes.count - offset - 12 else { throw FixtureIssue.encoding }
            let type = bytes[(offset + 4)..<(offset + 8)]
            if Data(type) == Data("IEND".utf8) {
                guard length == 0, offset + 12 == bytes.count else { throw FixtureIssue.encoding }
                iendOffset = offset
                break
            }
            offset += length + 12
        }
        let insertionOffset = try XCTUnwrap(iendOffset)
        var text = keyword
        text.append(Data(repeating: 0x78, count: payloadCount)) // 유효한 Latin-1 tEXt 값 'x'.
        var crcInput = Data("tEXt".utf8)
        crcInput.append(text)
        var chunk = bigEndianBytes(UInt32(text.count))
        chunk.append(crcInput)
        chunk.append(bigEndianBytes(crc32(crcInput)))
        bytes.insert(contentsOf: chunk, at: insertionOffset)
        return bytes
    }

    private static func bigEndianBytes(_ value: UInt32) -> Data {
        Data([UInt8(truncatingIfNeeded: value >> 24), UInt8(truncatingIfNeeded: value >> 16),
              UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)])
    }

    // PNG CRC는 chunk type+data를 대상으로 하는 표준 reflected CRC32다.
    private static func crc32(_ bytes: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in bytes {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xEDB8_8320 : 0)
            }
        }
        return crc ^ 0xFFFF_FFFF
    }

    /// 프로덕션 processor와 독립적인 ImageIO 검사. 부분 복구 입력도 성공으로 인정하지 않는다.
    static func completeDecoded(_ bytes: Data) throws -> CGImage {
        let source = try source(bytes)
        guard CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
            XCTFail("Fixture/output ImageIO source and index must be complete")
            throw FixtureIssue.encoding
        }
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let context = try XCTUnwrap(CGContext(data: nil, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4, space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
        _ = try XCTUnwrap(context.data)
        return image
    }

    enum FixtureIssue: Error { case encoding }
}
```

#### ios/FocusMateTests/CardPhotoProcessorTests.swift

```swift
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import FocusMate

final class CardPhotoProcessorTests: XCTestCase {
    private func assertProcessIssue(_ expected: CardPhotoProcessingIssue, input: Data,
                                    file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await ImageIOCardPhotoProcessor().process(input)
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? CardPhotoProcessingIssue, expected, file: file, line: line)
        }
    }
    private func assertStoredInvalid(_ photo: CardPhoto,
                                     file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try ImageIOCardPhotoProcessor.validateStoredPhoto(photo), file: file, line: line) {
            XCTAssertEqual($0 as? SnapshotValidationIssue, .invalidCardPhoto, file: file, line: line)
        }
    }

    // 깨짐 명명: 빈 반환 또는 디코딩하지 않은 입력 반환은 실패한다.
    func testAC05_JPEG_실제이미지는_보존가능한_내용으로_처리된다() async throws {
        let input = try CardPhotoTestFixtures.image(type: .jpeg)
        _ = try CardPhotoTestFixtures.completeDecoded(input)
        // 원본 fixture sanity: processor와 독립적으로 sRGB 입력 의미를 확인한다.
        let inputRGBA = try CardPhotoTestFixtures.rgba(input)
        XCTAssertGreaterThan(inputRGBA[0], 240, "원본 fixture sRGB red")
        XCTAssertLessThan(inputRGBA[1], 15, "원본 fixture sRGB green")
        XCTAssertLessThan(inputRGBA[2], 15, "원본 fixture sRGB blue")
        XCTAssertEqual(inputRGBA[3], 255, "원본 fixture alpha")
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.decoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertGreaterThan(rgba[0], 240)
        XCTAssertLessThan(rgba[1], 15)
        XCTAssertLessThan(rgba[2], 15)
    }

    // 깨짐 명명: 빈 반환 또는 디코딩하지 않은 입력 반환은 실패한다.
    func testAC05_PNG_실제이미지는_보존가능한_내용으로_처리된다() async throws {
        let input = try CardPhotoTestFixtures.image(type: .png)
        _ = try CardPhotoTestFixtures.completeDecoded(input)
        // 원본 fixture sanity: processor와 독립적으로 sRGB 입력 의미를 확인한다.
        let inputRGBA = try CardPhotoTestFixtures.rgba(input)
        XCTAssertGreaterThan(inputRGBA[0], 240, "원본 fixture sRGB red")
        XCTAssertLessThan(inputRGBA[1], 15, "원본 fixture sRGB green")
        XCTAssertLessThan(inputRGBA[2], 15, "원본 fixture sRGB blue")
        XCTAssertEqual(inputRGBA[3], 255, "원본 fixture alpha")
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.decoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertGreaterThan(rgba[0], 240)
        XCTAssertLessThan(rgba[1], 15)
        XCTAssertLessThan(rgba[2], 15)
    }

    // 깨짐 명명: 빈 반환 또는 디코딩하지 않은 입력 반환은 실패한다.
    func testAC05_HEIC_실제이미지는_보존가능한_내용으로_처리된다() async throws {
        let input = try CardPhotoTestFixtures.image(type: .heic)
        _ = try CardPhotoTestFixtures.completeDecoded(input)
        // 원본 fixture sanity: processor와 독립적으로 sRGB 입력 의미를 확인한다.
        let inputRGBA = try CardPhotoTestFixtures.rgba(input)
        XCTAssertGreaterThan(inputRGBA[0], 240, "원본 fixture sRGB red")
        XCTAssertLessThan(inputRGBA[1], 15, "원본 fixture sRGB green")
        XCTAssertLessThan(inputRGBA[2], 15, "원본 fixture sRGB blue")
        XCTAssertEqual(inputRGBA[3], 255, "원본 fixture alpha")
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.decoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertGreaterThan(rgba[0], 240)
        XCTAssertLessThan(rgba[1], 15)
        XCTAssertLessThan(rgba[2], 15)
    }

    // 깨짐 명명: alpha를 버리고 JPEG로 저장하면 실제 투명도에서 실패한다.
    func testPNG_투명도를_실제내용에_보존한다() async throws {
        let input = try CardPhotoTestFixtures.image(alpha: true)
        _ = try CardPhotoTestFixtures.completeDecoded(input)
        // 원본 fixture sanity: processor와 독립적으로 sRGB 입력 의미를 확인한다.
        let inputRGBA = try CardPhotoTestFixtures.rgba(input)
        XCTAssertEqual(Double(inputRGBA[3]), 128, accuracy: 1, "원본 fixture alpha")
        XCTAssertGreaterThan(inputRGBA[0], 120, "원본 fixture sRGB red")
        XCTAssertLessThan(inputRGBA[1], 5, "원본 fixture sRGB green")
        XCTAssertLessThan(inputRGBA[2], 5, "원본 fixture sRGB blue")
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertEqual(Double(rgba[3]), 128, accuracy: 1)
        XCTAssertGreaterThan(rgba[0], 120)
        XCTAssertLessThan(rgba[1], 5)
    }

    // 깨짐 명명: orientation을 무시하거나 이중 회전하면 출력 치수와 저장 검증에서 실패한다.
    func testOrientation6_한번만_회전해_저장한다() async throws {
        let input = try CardPhotoTestFixtures.image(type: .jpeg, orientation: 6)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        XCTAssertEqual(result.pixelWidth, 20)
        XCTAssertEqual(result.pixelHeight, 40)
        let decoded = try CardPhotoTestFixtures.decoded(result.data)
        XCTAssertEqual(decoded.width, 20)
        XCTAssertEqual(decoded.height, 40)
        let source = try CardPhotoTestFixtures.source(result.data)
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let orientation = properties[kCGImagePropertyOrientation] as? Int
        XCTAssertTrue(orientation == nil || orientation == 1)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(CardPhotoTestFixtures.photo(data: result.data, width: 20, height: 40)))
    }

    // 깨짐 명명: 비율 경계를 잘못 판정하거나 이미지 비율을 늘여서 통과시키면 실패한다.
    func testAC05_RatioLower() async throws {
        let input = try CardPhotoTestFixtures.image(width: 10, height: 100)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        XCTAssertEqual(result.pixelWidth, 10)
        XCTAssertEqual(result.pixelHeight, 100)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(CardPhotoTestFixtures.photo(data: result.data, width: 10, height: 100)))
    }

    // 깨짐 명명: 비율 경계를 잘못 판정하거나 이미지 비율을 늘여서 통과시키면 실패한다.
    func testAC05_RatioUpper() async throws {
        let input = try CardPhotoTestFixtures.image(width: 100, height: 10)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        XCTAssertEqual(result.pixelWidth, 100)
        XCTAssertEqual(result.pixelHeight, 10)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(CardPhotoTestFixtures.photo(data: result.data, width: 100, height: 10)))
    }

    // 깨짐 명명: 비율 경계를 잘못 판정하거나 이미지 비율을 늘여서 통과시키면 실패한다.
    func testAC05_RatioBelow() async throws {
        let input = try CardPhotoTestFixtures.image(width: 9, height: 100)
        await assertProcessIssue(.unsupportedAspectRatio, input: input)
    }

    // 깨짐 명명: 비율 경계를 잘못 판정하거나 이미지 비율을 늘여서 통과시키면 실패한다.
    func testAC05_RatioAbove() async throws {
        let input = try CardPhotoTestFixtures.image(width: 101, height: 10)
        await assertProcessIssue(.unsupportedAspectRatio, input: input)
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_Empty_거절() async throws {
        await assertProcessIssue(.unreadable, input: Data())
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_Unsupported_거절() async throws {
        await assertProcessIssue(.unreadable, input: Data("<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>".utf8))
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_DamagedBody_거절() async throws {
        await assertProcessIssue(.unreadable, input: try CardPhotoTestFixtures.damagedBody())
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_TruncatedBody_거절() async throws {
        await assertProcessIssue(.unreadable, input: Data(try CardPhotoTestFixtures.image().prefix(40)))
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_Above8MiB_거절() async throws {
        await assertProcessIssue(.inputTooLarge, input: Data(repeating: 1, count: 8_388_609))
    }

    // 깨짐 명명: 원본을 반환하거나 긴 변만 줄여 찌그러뜨리면 실패한다.
    func testLongSideAbove2048_비율을_유지하여_축소한다() async throws {
        let result = try await ImageIOCardPhotoProcessor().process(CardPhotoTestFixtures.image(width: 4096, height: 2048))
        XCTAssertEqual(result.pixelWidth, 2048)
        XCTAssertEqual(result.pixelHeight, 1024)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(CardPhotoTestFixtures.photo(data: result.data, width: 2048, height: 1024)))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testDeclaredWidthMismatch() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(), width: 41, height: 20))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testDeclaredHeightMismatch() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(), width: 40, height: 21))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredLongSideTooLarge() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(width: 2049, height: 1025), width: 2049, height: 1025))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredRatioBelow() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(width: 9, height: 100), width: 9, height: 100))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredRatioAbove() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(width: 101, height: 10), width: 101, height: 10))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredDamagedBody() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.damagedBody(), width: 40, height: 20))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredEmpty() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: Data(), width: 40, height: 20))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredUnsupported() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: Data("unsupported".utf8), width: 40, height: 20))
    }

    // 깨짐 명명: 읽을 수 있는 WebP를 거절하거나 빈/다른 색 이미지로 반환하면 실패한다.
    func testAC05_WebP_실제이미지는_보존가능한_내용으로_처리된다() async throws {
        let input = try CardPhotoTestFixtures.losslessWebP()
        let inputImage = try CardPhotoTestFixtures.completeDecoded(input)
        XCTAssertEqual(inputImage.width, 40)
        XCTAssertEqual(inputImage.height, 20)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.completeDecoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(Double(decoded.width) / Double(decoded.height), 2)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        // 불투명 입력. JPEG 재인코딩 오차는 허용하되 다른 색으로 대체하면 실패한다.
        XCTAssertEqual(Double(rgba[0]), 220, accuracy: 8)
        XCTAssertEqual(Double(rgba[1]), 40, accuracy: 8)
        XCTAssertEqual(Double(rgba[2]), 80, accuracy: 8)
        XCTAssertEqual(rgba[3], 255)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(
            CardPhotoTestFixtures.photo(data: result.data, width: 40, height: 20)))
    }

    // 깨짐 명명: 입력 한도를 >=8MiB로 거절하거나 메타데이터 포함 원본을 그대로 반환하면 실패한다.
    func testAC05_Exact8MiB_완전한PNG는_내용을_보존하여_처리된다() async throws {
        let input = try CardPhotoTestFixtures.exact8MiBPNG()
        XCTAssertEqual(input.count, 8_388_608)
        let inputImage = try CardPhotoTestFixtures.completeDecoded(input)
        XCTAssertEqual(inputImage.width, 40)
        XCTAssertEqual(inputImage.height, 20)
        // 원본 fixture sanity: processor와 독립적으로 sRGB 입력 의미를 확인한다.
        let inputRGBA = try CardPhotoTestFixtures.rgba(input)
        XCTAssertGreaterThan(inputRGBA[0], 240, "원본 fixture sRGB red")
        XCTAssertLessThan(inputRGBA[1], 15, "원본 fixture sRGB green")
        XCTAssertLessThan(inputRGBA[2], 15, "원본 fixture sRGB blue")
        XCTAssertEqual(inputRGBA[3], 255, "원본 fixture alpha")
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.completeDecoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(Double(decoded.width) / Double(decoded.height), 2)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertGreaterThan(rgba[0], 240)
        XCTAssertLessThan(rgba[1], 15)
        XCTAssertLessThan(rgba[2], 15)
        XCTAssertEqual(rgba[3], 255)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(
            CardPhotoTestFixtures.photo(data: result.data, width: 40, height: 20)))
    }
}
```
