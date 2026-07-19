//
//  RouteMatching.swift
//  TrafficVienna
//
//  Shared logic for matching a saved favourite (line + destination) against a
//  line in a fresh monitor response. Lives in WidgetShared so the app and the
//  widget normalise identically.
//
//  The previous implementation stripped the substrings " U" / " S" *anywhere*
//  in the destination, which could corrupt names that legitimately contain
//  them (e.g. "Wien Mitte"). This only removes a trailing standalone " U"/" S"
//  marker (the interchange hint the feed sometimes appends), then folds
//  diacritics and collapses whitespace so comparisons are robust.
//

import Foundation

nonisolated enum RouteMatching {
    /// Normalises a line destination for tolerant equality comparison.
    static func normalize(_ destination: String) -> String {
        var s = destination
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Drop a trailing " u" / " s" interchange marker, but only as a whole
        // trailing token — never mid-string.
        for marker in [" u", " s"] where s.hasSuffix(marker) {
            s = String(s.dropLast(marker.count))
        }

        // Collapse any internal runs of whitespace to single spaces.
        s = s.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return s
    }

    /// Whether a feed line matches a saved favourite by name + destination.
    static func matches(lineName: String, towards: String,
                        favoriteLine: String, favoriteDestination: String) -> Bool {
        lineName == favoriteLine &&
        normalize(towards) == normalize(favoriteDestination)
    }
}
