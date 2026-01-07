//
//  NetworkManager.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//

import Foundation

//error abou rate limit
struct MonitorErrorEnvelope: Decodable {
    struct Message: Decodable {
        let value: String
        let messageCode: Int
    }
    
    let message: Message
}

enum MonitorApiError: Error{
    // too many requests. request limit reached (code 316)
    case rateLimited
}


protocol NetworkManaging {
    func fetchMonitorData(for stopId: Int) async throws -> MonitorResponse
    func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse

}
final class NetworkManager: NetworkManaging {

    // Uses stopId to get monitor data for a single stop/direction.
    func fetchMonitorData(for stopId: Int) async throws -> MonitorResponse {
        // Build URL with stopId parameter
        let urlString = "https://www.wienerlinien.at/ogd_realtime/monitor?stopId=\(stopId)"
        // Validate URL
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        // Perform request and get raw JSON + HTTP response
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        // Decode JSON into MonitorResponse model
        let decoded = try JSONDecoder().decode(MonitorResponse.self, from: data)
        return decoded
    }
    /// Uses DIVA to get monitor data for all directions at a station.
    func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse {
        // Build base URL with DIVA parameter
        var urlString = "https://www.wienerlinien.at/ogd_realtime/monitor?diva=\(diva)"
        // Optionally include area parameter to get all directions
        if includeArea { urlString += "&aArea=1" }
        
        print("➡️ diva request:", urlString)

        // Validate final URL
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        // Perform request for DIVA-based monitor data
        let (data, responce) = try await URLSession.shared.data(from: url)
        
        if let http = responce as? HTTPURLResponse {
            print("⬅️ status:", http.statusCode)   // 👈 і це
        }

        guard let http = responce as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        // Decode and return MonitorResponse
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
