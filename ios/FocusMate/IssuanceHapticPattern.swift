import CoreHaptics
import Foundation

/// 발급 진동 패턴. 카드가 슬롯에서 나오는 동안 약→강으로 커지는 연속 진동과 끝의 짧은 탭("점점 세게 → 끝에 뚝").
/// 순수 값으로 두어 테스트가 구조를 직접 확인하고, CoreHaptics 변환은 `makeCHHapticPattern()`이 맡는다.
struct IssuanceHapticPattern: Equatable {
    struct CurvePoint: Equatable {
        let time: TimeInterval
        let intensity: Float
    }
    struct Tap: Equatable {
        let time: TimeInterval
        let intensity: Float
        let sharpness: Float
    }

    let continuousDuration: TimeInterval
    let continuousSharpness: Float
    let intensityCurve: [CurvePoint]
    let taps: [Tap]

    var duration: TimeInterval { max(continuousDuration, taps.map(\.time).max() ?? 0) }

    static let issuance = IssuanceHapticPattern(
        continuousDuration: CardIssuanceTiming.hapticDuration,
        continuousSharpness: 0.3,
        intensityCurve: [
            CurvePoint(time: 0, intensity: 0.15),
            CurvePoint(time: 0.45, intensity: 0.45),
            CurvePoint(time: CardIssuanceTiming.hapticDuration, intensity: 1.0),
        ],
        taps: [Tap(time: CardIssuanceTiming.hapticDuration, intensity: 1.0, sharpness: 0.9)]
    )

    /// 승차 접촉: 짧고 약한 연속 진동 뒤 또렷한 탭 한 번("딸깍").
    static let boardingContact = IssuanceHapticPattern(
        continuousDuration: 0.12,
        continuousSharpness: 0.4,
        intensityCurve: [CurvePoint(time: 0, intensity: 0.35), CurvePoint(time: 0.12, intensity: 0.5)],
        taps: [Tap(time: 0.12, intensity: 0.9, sharpness: 0.8)]
    )

    func makeCHHapticPattern() throws -> CHHapticPattern {
        let continuous = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: continuousSharpness),
            ],
            relativeTime: 0,
            duration: continuousDuration
        )
        let tapEvents = taps.map { tap in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: tap.intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: tap.sharpness),
                ],
                relativeTime: tap.time
            )
        }
        let curve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: intensityCurve.map { .init(relativeTime: $0.time, value: $0.intensity) },
            relativeTime: 0
        )
        return try CHHapticPattern(events: [continuous] + tapEvents, parameterCurves: [curve])
    }
}
