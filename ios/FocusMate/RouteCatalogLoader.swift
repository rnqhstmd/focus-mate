import Foundation

/// 변환 스크립트(scripts/build_route_data.py)가 만든 JSON을 카탈로그로 읽는다.
enum RouteCatalogLoader {
    static func load(data: Data) throws -> RouteCatalog {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              root["format"] as? Int == 1,
              let source = root["source"] as? [String: String],
              let rawStops = root["stops"] as? [[Any]],
              let rawRoutes = root["routes"] as? [[Any]]
        else { throw RouteCatalogIssue.malformed }

        let stops = try rawStops.map(stop)
        let indexByID = Dictionary(stops.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })
        let routes = try rawRoutes.map { try route($0, indexByID: indexByID) }
        return try RouteCatalog(stops: stops, routes: routes, metadata: metadata(source))
    }

    private static func stop(_ row: [Any]) throws -> RouteCatalog.Stop {
        guard row.count == 5, let id = row[0] as? String, let name = row[1] as? String, let ars = row[2] as? String,
              let latitude = row[3] as? Int, let longitude = row[4] as? Int
        else { throw RouteCatalogIssue.malformed }
        return RouteCatalog.Stop(id: id, name: name, ars: ars.isEmpty ? nil : ars,
                                 point: CoursePoint(latitude: Double(latitude) / 1_000_000,
                                                    longitude: Double(longitude) / 1_000_000))
    }

    private static func route(_ row: [Any], indexByID: [String: Int]) throws -> RouteCatalog.Route {
        guard row.count == 6, let id = row[0] as? String, let number = row[1] as? String, let kind = row[2] as? String,
              let stopIDs = row[3] as? [String], let seconds = row[4] as? [Int], let meters = row[5] as? [Int]
        else { throw RouteCatalogIssue.malformed }
        let stops = try stopIDs.map { stopID in
            guard let index = indexByID[stopID] else { throw RouteCatalogIssue.unknownStop(stopID) }
            return index
        }
        return RouteCatalog.Route(id: id, number: number, kind: kind, stops: stops, seconds: seconds, meters: meters)
    }

    private static func metadata(_ source: [String: String]) throws -> RouteDataMetadata {
        func value(_ key: String) throws -> String {
            guard let text = source[key] else { throw RouteCatalogIssue.malformed }
            return text
        }
        return RouteDataMetadata(
            baseDate: try value("baseDate"), dataset: try value("dataset"), datasetID: try value("datasetID"),
            provider: try value("provider"), copyright: try value("copyright"), license: try value("license"),
            routeInfoDataset: try value("routeInfoDataset"), routeInfoDatasetID: try value("routeInfoDatasetID"),
            stopsFile: try value("stopsFile"), routeInfoFile: try value("routeInfoFile"))
    }
}
