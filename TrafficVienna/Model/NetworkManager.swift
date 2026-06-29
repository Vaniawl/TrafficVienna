//
//  NetworkManager.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//

import Foundation

// Error body returned by the API (e.g. when the request limit is reached).
nonisolated struct MonitorErrorEnvelope: Decodable {
    nonisolated struct Message: Decodable {
        let value: String
        let messageCode: Int
    }

    let message: Message
}

enum MonitorApiError: Error {
    // too many requests. request limit reached (code 316)
    case rateLimited
}

// Wiener Linien rate-limit message code (returned with an HTTP 200 body).
private nonisolated let rateLimitMessageCode = 316


protocol NetworkManaging: Sendable {
    func fetchMonitorData(for stopId: Int) async throws -> MonitorResponse
    func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse
    func fetchTrafficInfoList() async throws -> MonitorResponse
}
nonisolated final class NetworkManager: NetworkManaging {

    // Uses stopId to get monitor data for a single stop/direction.
    func fetchMonitorData(for stopId: Int) async throws -> MonitorResponse {
        try await perform("https://www.wienerlinien.at/ogd_realtime/monitor?stopId=\(stopId)")
    }

    /// Uses DIVA to get monitor data for all directions at a station, including
    /// any active service disruptions / info notices for its lines.
    func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse {
        var urlString = "https://www.wienerlinien.at/ogd_realtime/monitor?diva=\(diva)"
        if includeArea { urlString += "&aArea=1" }
        urlString += "&activateTrafficInfo=stoerunglang"
        urlString += "&activateTrafficInfo=stoerungkurz"
        return try await perform(urlString)
    }

    func fetchTrafficInfoList() async throws -> MonitorResponse {
        try await perform("https://www.wienerlinien.at/ogd_realtime/trafficInfoList")
    }

    // Shared request pipeline: fetch, detect the rate-limit body, then decode.
    private func perform(_ urlString: String) async throws -> MonitorResponse {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)

        // The API signals throttling with an HTTP 200 body whose message code is
        // 316, so inspect the message before trusting the status code.
        if let envelope = try? JSONDecoder().decode(MonitorErrorEnvelope.self, from: data),
           envelope.message.messageCode == rateLimitMessageCode {
            throw MonitorApiError.rateLimited
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(MonitorResponse.self, from: data)
    }
}

// MARK: - example of answer

/*
 {
   "data": {
     "monitors": [
       {
         "locationStop": {
           "properties": {
             "title": "Hauptbahnhof",
             "attributes": {
               "rbl": 4113
             }
           },
           "geometry": {
             "coordinates": [16.375, 48.185]  
           }
         },
         "lines": [
           {
             "name": "U1",
             "towards": "Leopoldau",
             "departures": {
               "departure": [
                 {
                   "departureTime": {
                     "countdown": 2,
                     "timePlanned": "2025-01-06T16:45:00.000+01:00",
                     "timeReal": "2025-01-06T16:47:00.000+01:00"
                   }
                 },
                 {
                   "departureTime": {
                     "countdown": 7,
                     "timePlanned": "2025-01-06T16:50:00.000+01:00",
                     "timeReal": null
                   }
                 }
               ]
             }
           }
         ]
       }
     ]
   }
 }
 */
