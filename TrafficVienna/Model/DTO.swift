//
//  DTO.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//

import Foundation
//Mark: Monitor Start
struct MonitorResponse: Decodable {
    let data: DataBlock
}

struct DataBlock: Decodable {
    let monitors: [Monitor]
}

struct Monitor: Decodable {
    let locationStop: LocationStop
    let lines: [Lines]
}

struct LocationStop: Decodable {
    let properties: Properties
    let geometry: Geometry
}

struct Properties: Decodable {
    let title: String
    let attributes: Attributes
}

struct Geometry: Decodable {
    let coordinates: [Double] // [lon, lat]
}

struct Attributes: Decodable {
    let rbl: Int?
}

struct Lines: Decodable {
    let name: String
    let towards: String
    let departures: Departures
}

struct Departures: Decodable {
    let departure: [Departure]
}

struct Departure: Decodable {
    let departureTime: DepartureTime
}

struct DepartureTime: Decodable {
    let countdown: Int
    let timePlanned: String
    let timeReal: String?
}
//Mark: Monitor End





//https://www.wienerlinien.at/ogd_realtime/

//https://www.wienerlinien.at/ogd_realtime/monitor?stopId=4113 одна платформа(дає всі рейси, що проходять через цю платформу)
//https://www.wienerlinien.at/ogd_realtime/monitor?stopId=4113&stopId=4114&stopId=4115 повертає об’єднаний масив monitors для кількох RBL
//https://www.wienerlinien.at/ogd_realtime/monitor?diva=60201158&aArea=1 дає всі платформи станції Hauptbahnhof Wien
//https://www.wienerlinien.at/ogd_realtime/monitor?stopId=4113&activateTrafficInfo=stoerunglang&activateTrafficInfo=information у відповіді з’явиться trafficInfos[] із ремонтами, збоями, ліфтами тощо
//https://www.wienerlinien.at/ogd_realtime/trafficInfoList Усі актуальні події
//https://www.wienerlinien.at/ogd_realtime/trafficInfoList?relatedLine=O Тільки для трамвая O



//https://www.wienerlinien.at/ogd_realtime/trafficInfo?name=bms_I20251026-0026 поверне повний опис, час дії, лінії, зупинки тощо
//https://www.wienerlinien.at/ogd_routing/XML_STOPFINDER_REQUEST?locationServerActive=1&outputFormat=JSON&type_sf=any&name_sf=Hauptbahnhof поверне DIVA, RBL, назву та координати
