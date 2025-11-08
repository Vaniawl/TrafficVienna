//
//  StationStore.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 08.11.25.
//

import Foundation

struct Station: Decodable {
    let diva: String
    let name: String
    let lat: Double
    let lon: Double

    enum CodingKeys: String, CodingKey {
        case diva = "DIVA"
        case name = "NAME"
        case lat  = "WGS84_LAT"
        case lon  = "WGS84_LON"
    }
}





