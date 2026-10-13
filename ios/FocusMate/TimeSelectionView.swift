import SwiftUI

/// 저장된 현재 정류장에서 출발하는 시간·버스·도착지 선택 화면.
/// 휠에는 접근성 수정자를 붙이지 않는다 — 시스템 기본 조절(한 칸 = 1분)과 PickerWheel 노출을 유지하기 위해서다.
@MainActor
struct TimeSelectionView: View {
    @Bindable var model: AppModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // 휠과 진행 버튼은 아래에 고정하고 출발지·후보만 스크롤한다. 스크롤 영역은 고정 영역과 겹치지 않는다.
        VStack(spacing: 8) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 제목·현재 분은 상단 바 제목·휠 값과 같은 정보라 크기 상한을 둬 큰 글자에서 후보가 들어갈 자리를 남긴다.
                    Text(Destination.time.title).font(.largeTitle.bold())
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1).accessibilityIdentifier("screen.time")
                    origin
                    Text("\(model.journeyPlan.minutes)분").font(.title.bold())
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .accessibilityValue("\(model.journeyPlan.minutes)").accessibilityIdentifier("time.minutesLabel")
                    ForEach(model.journeyCandidates) { candidateButton($0) }
                }
            }
            VStack(spacing: 8) {
                Picker("여행 시간", selection: minutes) {
                    ForEach(JourneyPlanner.minuteRange, id: \.self) { Text("\($0)분").tag($0) }
                }
                .pickerStyle(.wheel).frame(height: 120)
                Button(model.journeyProceedState.title) { model.proceedToPreparation() }
                    .buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                    .disabled(!model.journeyProceedState.isEnabled)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .accessibilityIdentifier("time.proceed")
            }
        }
    }

    @ViewBuilder private var origin: some View {
        if let station = model.snapshot?.currentStation {
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name).font(.title2.bold())
                    .accessibilityValue(station.name).accessibilityIdentifier("time.origin")
                if let position = model.journeyOrigin {
                    Text(RouteStops.boundLabel(from: position)).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var minutes: Binding<Int> {
        Binding(get: { model.journeyPlan.minutes }, set: { model.journeyPlan.setMinutes($0) })
    }

    private func candidateButton(_ candidate: JourneyCandidate) -> some View {
        let isSelected = model.journeyPlan.selectedBusID == candidate.bus.id
        return Button {
            if let origin = model.journeyOrigin { _ = model.journeyPlan.choose(busID: candidate.bus.id, from: origin) }
        } label: {
            // 접근성 글자 크기에서는 버튼이 길어져 아래가 고정 영역에 가려지므로 같은 정보를 두 줄로 압축한다.
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if dynamicTypeSize.isAccessibilitySize {
                        Text("\(candidate.bus.kind) \(candidate.bus.number) · \(candidate.destination)").font(.headline)
                    } else {
                        Text("\(candidate.bus.kind) \(candidate.bus.number)").font(.headline)
                        Text(candidate.destination)
                    }
                    Text("\(candidate.minutes)분 · \(candidate.stops)정류장 · \(candidate.distanceText)")
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if isSelected { Image(systemName: "checkmark.circle.fill") }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(candidate.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("time.candidate.\(candidate.bus.id)")
    }
}
