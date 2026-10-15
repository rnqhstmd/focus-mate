import ActivityKit
import Foundation
import Observation

/// 앱 밖 표시(Live Activity) 요청 창구. 실패는 앱 동작에 영향을 주지 않으며 재시도하지 않는다(FR-7).
@MainActor protocol LiveActivityGateway: AnyObject {
    var activeActivities: [LiveActivityHandle] { get }
    /// 사용 불가·거부·실패면 nil. 실패도 시도로 본다.
    func start(attributes: JourneyActivityAttributes, request: JourneyActivityRequest) -> String?
    func update(id: String, request: JourneyActivityRequest)
    func end(id: String)
}

/// ActivityKit 어댑터. 상태를 갖지 않으므로 서비스 묶음이 다시 평가돼도 안전하다.
/// 시작은 동기 결과로 알 수 있고, 갱신·종료는 결과를 기다리지 않는다.
final class ActivityKitLiveActivityGateway: LiveActivityGateway {
    var activeActivities: [LiveActivityHandle] {
        Activity<JourneyActivityAttributes>.activities
            .filter { $0.activityState == .active || $0.activityState == .stale }
            .map { LiveActivityHandle(id: $0.id, journeyID: $0.attributes.journeyID) }
    }

    func start(attributes: JourneyActivityAttributes, request: JourneyActivityRequest) -> String? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }
        let content = ActivityContent(state: request.state, staleDate: request.staleDate)
        return try? Activity.request(attributes: attributes, content: content, pushType: nil).id
    }

    func update(id: String, request: JourneyActivityRequest) {
        guard let activity = activity(id) else { return }
        let content = ActivityContent(state: request.state, staleDate: request.staleDate)
        Task { await activity.update(content) }
    }

    func end(id: String) {
        guard let activity = activity(id) else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    private func activity(_ id: String) -> Activity<JourneyActivityAttributes>? {
        Activity<JourneyActivityAttributes>.activities.first { $0.id == id }
    }
}

#if DEBUG
/// 단위·UI 테스트용 기록기. 요청을 순서대로 남기고, 시작하면 "activity-N"을 활성 목록에 넣는다.
@MainActor @Observable
final class RecordingLiveActivityGateway: LiveActivityGateway {
    struct Entry: Equatable {
        enum Op: String { case start, update, end }
        let op: Op
        let activityID: String?
        let journeyID: String?
        let request: JourneyActivityRequest?
    }

    /// true면 시작이 실패한다(사용 불가·거부 재현). 시도는 기록한다.
    var failsStart = false
    private(set) var entries: [Entry] = []
    private(set) var activeActivities: [LiveActivityHandle]
    private(set) var lastStartAttributes: JourneyActivityAttributes?
    @ObservationIgnored private var issued = 0

    /// `existing`은 이전 실행이 남긴 활성 표시다.
    init(existing: [LiveActivityHandle] = []) { activeActivities = existing }

    func count(_ op: Entry.Op) -> Int { entries.filter { $0.op == op }.count }

    /// UI 테스트 진단(`test.liveActivity`). 시각은 epoch 초, 없으면 null.
    var diagnosticJSON: String {
        func seconds(_ date: Date?) -> Any { date.map { $0.timeIntervalSince1970 } ?? NSNull() }
        let object: [String: Any] = [
            "active": activeActivities.map { ["id": $0.id, "journeyID": $0.journeyID] },
            "requests": entries.map { entry -> [String: Any] in
                [
                    "op": entry.op.rawValue,
                    "id": entry.activityID ?? NSNull(),
                    "status": entry.request?.state.status.rawValue ?? NSNull(),
                    "endDate": seconds(entry.request?.state.endDate),
                    "staleDate": seconds(entry.request?.staleDate),
                    "pausedRemaining": entry.request?.state.pausedRemainingSeconds ?? NSNull(),
                ]
            },
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }

    func start(attributes: JourneyActivityAttributes, request: JourneyActivityRequest) -> String? {
        guard !failsStart else {
            entries.append(Entry(op: .start, activityID: nil, journeyID: attributes.journeyID, request: request))
            return nil
        }
        issued += 1
        let id = "activity-\(issued)"
        lastStartAttributes = attributes
        activeActivities.append(LiveActivityHandle(id: id, journeyID: attributes.journeyID))
        entries.append(Entry(op: .start, activityID: id, journeyID: attributes.journeyID, request: request))
        return id
    }

    func update(id: String, request: JourneyActivityRequest) {
        entries.append(Entry(op: .update, activityID: id, journeyID: nil, request: request))
    }

    func end(id: String) {
        activeActivities.removeAll { $0.id == id }
        entries.append(Entry(op: .end, activityID: id, journeyID: nil, request: nil))
    }
}
#endif
