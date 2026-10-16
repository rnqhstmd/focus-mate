import Foundation

enum WidgetEntryLinks {
    static func focus(state: WidgetReadState) -> URL? {
        guard let snapshot = WidgetPresentation.content(state: state).snapshot else { return URL(string: "focusmate://widget") }
        return WidgetLinkCodec.makeURL(WidgetLink(issuedAt: snapshot.generatedAt, target: .journey(expectedID: snapshot.journey.journeyID)))
    }
    static func analytics(state: WidgetReadState, day: String? = nil, tag: WidgetTag? = nil) -> URL? {
        guard let snapshot = WidgetPresentation.content(state: state).snapshot else { return URL(string: "focusmate://widget") }
        let name: String?
        if let tag, case .named(let value) = tag.id { name = value } else { name = nil }
        return WidgetLinkCodec.makeURL(WidgetLink(issuedAt: snapshot.generatedAt,
            target: .analytics(day: day ?? snapshot.basisDay, tag: name, kind: .week)))
    }
}
