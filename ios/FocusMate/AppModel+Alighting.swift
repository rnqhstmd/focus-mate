import Foundation

/// 하차한 여행의 요약 화면 값.
struct AlightingSummary: Equatable {
    let recordID, task, destinationName: String
    let minutes: Int
    /// 요약 지도(시안 R17)에 그릴 노선과 구간 정류장 색인. 정류장 데이터가 없으면 nil이고 지도는 도착 정류장만 보인다.
    var routeID: String? = nil
    var legStops: [Int]? = nil
    var minutesText: String { ProfileTimeText.display(minutes: minutes) }
}

/// W09 도착 확인·하차·요약. 하차 저장은 기록 생성·도착지 반영·여정 제거를 한 번에 한다(BR-3).
/// 도착 저장의 주인은 타이머이고, 모델은 저장본이 도착 상태인지만 본다.
extension AppModel: JourneyAlighting, ArrivalConfirming {
    /// 메인 도착 카드의 하차하기. 저장 없이 여행 화면을 열면 도착 안내가 처음부터 나온다.
    @discardableResult
    func beginAlighting() -> LifecycleActionResult {
        guard launchState == .ready(.main), path.isEmpty, activeJourney?.isArrived == true else { return .rejected }
        path = [.journey]
        return .done
    }

    /// 도착 안내의 확인. 저장본이 도착 상태일 때만 하차 태그로 간다(재실행 시 도착 카드 보장, AC-14).
    @discardableResult
    func confirmArrival(timerArrived: Bool) -> LifecycleActionResult {
        guard launchState == .ready(.main), timerArrived, path.last == .journey,
              let active = activeJourney, active.phase == .departed else { return .rejected }
        guard active.isArrived else { return .saveFailed }
        path.append(.alighting)
        return .done
    }

    /// 하차 접촉 커밋. 이미 저장했으면 다시 쓰지 않고 성공으로 답한다 — 중단 뒤 재태그가 실패 안내를 띄우지 않게 한다.
    func alightJourney() -> Bool {
        guard launchState == .ready(.main), path.last == .alighting, let snapshot else { return false }
        if alightingSummary != nil { return true }
        guard snapshot.journey.active?.isArrived == true,
              let result = try? snapshot.alightingActiveJourney(completedAt: recordClock.now(),
                                                                timeZone: recordClock.timeZone()),
              saveHandlingFailure(result.snapshot) else { return false }
        let record = result.record
        let journey = snapshot.journey.active
        let leg = journey.flatMap { journey in
            routeCatalog.flatMap { catalog in
                catalog.routeIndex(id: journey.busID).flatMap { route in
                    catalog.stopIndex(id: journey.originStopID).flatMap { origin in
                        RouteLegFinder.leg(route: route, originStop: origin, minutes: journey.minutes, in: catalog)
                    }
                }
            }
        }
        alightingSummary = AlightingSummary(recordID: record.id, task: record.task,
                                            destinationName: record.to, minutes: record.minutes,
                                            routeID: leg == nil ? nil : journey?.busID, legStops: leg?.stopIndices)
        return true
    }

    /// 하차 저장 뒤 모든 경로(정상 전환·중단 복귀)의 단일 출구.
    @discardableResult
    func finishAlightingTransition() -> Bool {
        guard path.last == .alighting, alightingSummary != nil else { return false }
        path = [.alightingSummary]
        return true
    }

    /// 요약의 메인으로. 빈 메모는 저장하지 않는다. 경로를 먼저 비워 빈 요약이 그려지지 않게 한다.
    @discardableResult
    func finishAlightingSummary(memo: String) -> LifecycleActionResult {
        guard path.last == .alightingSummary, let summary = alightingSummary else { return .rejected }
        if !RecordMemoDraft(text: memo).isBlank {
            let result = updateRecordMemo(memo, forJourneyID: summary.recordID)
            guard result == .done else { return result }
        }
        path = []
        alightingSummary = nil
        return .done
    }

    /// 메인 메뉴. 시안 R34대로 도착 여정이 있어도 "새 여정 시작"(여행 준비)을 보인다(AC-21 시안 우선 변경).
    /// 누르면 진행 여정과 같은 새 여정 확인 창을 거친다.
    var mainMenuDestinations: [Destination] { Destination.mainMenu }
}
