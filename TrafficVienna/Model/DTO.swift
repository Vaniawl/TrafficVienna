//
//  DTO.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//
//  Pure data models decoded from the Wiener Linien monitor API. They are
//  marked `nonisolated` so they can be decoded and passed across actors
//  (e.g. MonitorService) freely.
//
//  Decoding is intentionally lenient: the live feed often omits sub-objects
//  (e.g. a U-Bahn line with an empty `departures`, a platform without
//  geometry). Missing collections default to empty so one malformed line
//  never fails the whole response.
//

import Foundation

// MARK: - Monitor

nonisolated enum NetworkResponseSource: Sendable {
    case network
    case urlCache(storedAt: Date)
}

nonisolated struct MonitorResponse: Decodable {
    let data: DataBlock
    let source: NetworkResponseSource

    init(data: DataBlock, source: NetworkResponseSource = .network) {
        self.data = data
        self.source = source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode(DataBlock.self, forKey: .data)
        source = .network
    }

    private enum CodingKeys: String, CodingKey { case data }
}

nonisolated struct DataBlock: Decodable {
    let monitors: [Monitor]
    let trafficInfos: [TrafficInfo]?

    enum CodingKeys: String, CodingKey { case monitors, trafficInfos }

    init(monitors: [Monitor], trafficInfos: [TrafficInfo]?) {
        self.monitors = monitors
        self.trafficInfos = trafficInfos
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        monitors = try c.decodeIfPresent([Monitor].self, forKey: .monitors) ?? []
        trafficInfos = try c.decodeIfPresent([TrafficInfo].self, forKey: .trafficInfos)
    }
}

// A service disruption / info notice (roadworks, delays, lift outages…).
nonisolated struct TrafficInfo: Decodable, Identifiable {
    let name: String              // stable id, e.g. "I20260503-0024"
    let title: String
    let description: String?
    let priority: String?
    let relatedLines: [String]?

    var id: String { name }
}

nonisolated struct Monitor: Decodable {
    let locationStop: LocationStop
    let lines: [Lines]

    enum CodingKeys: String, CodingKey { case locationStop, lines }

    init(locationStop: LocationStop, lines: [Lines]) {
        self.locationStop = locationStop
        self.lines = lines
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        locationStop = try c.decode(LocationStop.self, forKey: .locationStop)
        lines = try c.decodeIfPresent([Lines].self, forKey: .lines) ?? []
    }
}

nonisolated struct LocationStop: Decodable {
    let properties: Properties
    let geometry: Geometry?
}

nonisolated struct Properties: Decodable {
    let title: String
    let attributes: Attributes
}

nonisolated struct Geometry: Decodable {
    let coordinates: [Double] // [lon, lat]
}

nonisolated struct Attributes: Decodable {
    let rbl: Int?
}

nonisolated struct Lines: Decodable {
    let name: String
    let towards: String
    let departures: Departures

    enum CodingKeys: String, CodingKey { case name, towards, departures }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        towards = try c.decodeIfPresent(String.self, forKey: .towards) ?? ""
        departures = try c.decodeIfPresent(Departures.self, forKey: .departures)
            ?? Departures(departure: [])
    }

    init(name: String, towards: String, departures: Departures) {
        self.name = name
        self.towards = towards
        self.departures = departures
    }
}

nonisolated struct Departures: Decodable {
    let departure: [Departure]

    enum CodingKeys: String, CodingKey { case departure }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        departure = try c.decodeIfPresent([Departure].self, forKey: .departure) ?? []
    }

    init(departure: [Departure]) {
        self.departure = departure
    }
}

nonisolated struct Departure: Decodable {
    let departureTime: DepartureTime
}

nonisolated struct DepartureTime: Decodable {
    let countdown: Int
    let timePlanned: String?   // null for U-Bahn departures
    let timeReal: String?
}

// MARK: - API reference
//
// https://www.wienerlinien.at/ogd_realtime/
//
// monitor?stopId=4113                         one platform (all routes through that RBL)
// monitor?stopId=4113&stopId=4114             merged monitors array for several RBLs
// monitor?diva=60201158&aArea=1               all platforms of a station
// monitor?diva=…&activateTrafficInfo=…        adds trafficInfos[] (disruptions, lifts…)
// trafficInfoList                             all current events
// ogd_routing/XML_STOPFINDER_REQUEST?…&name_sf=Hauptbahnhof   returns DIVA, RBL, name, coords
