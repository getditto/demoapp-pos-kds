///
//  DateUtils.swift
//  DittoPOS
//
//  Created by Eric Turner on 4/19/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import SwiftUI


extension DateFormatter {
    static var shortTime: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }

    static var isoDate: ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions.insert(.withFractionalSeconds)
        return f
    }
    
    static var isoDateFull: ISO8601DateFormatter {
        let f = Self.isoDate
        f.formatOptions = [.withFullDate]
        return f
    }
    
    static func isoTimeFromNowString(_ seconds: TimeInterval) -> String {
        isoDate.string(from: Date.now.addingTimeInterval(seconds))
    }
}

extension Date {
    func isoString() -> String {
        DateFormatter.isoDate.string(from: self)
    }
    
    static func fromIsoString(_ str: String) -> Date? {
        DateFormatter.isoDate.date(from: str)
    }
}

// For Eviction
//extension Calendar {

extension Date {
    var localTimeSeconds: TimeInterval {
        let comps = Calendar.autoupdatingCurrent.dateComponents(in: TimeZone.current, from: self)
        return TimeInterval((comps.hour! * 3600 + comps.minute! * 60 + comps.second!))
    }
    
    func shortFormat() -> String {
        self.formatted(date: .numeric, time: .shortened)
    }
    
    func standardFormat() -> String {
        self.formatted(date: .numeric, time: .standard)
    }
    
    static func secondsBetween(_ start: Date, _ end: Date) -> TimeInterval {
        TimeInterval(Calendar.autoupdatingCurrent.dateComponents([.second], from: start, to: end).second!)
    }

    static func minutesBetween(_ start: Date, _ end: Date) -> TimeInterval {
        TimeInterval(Calendar.autoupdatingCurrent.dateComponents([.minute], from: start, to: end).minute!)
    }
    
    static var startOfToday: Date { Calendar.autoupdatingCurrent.startOfDay(for: Date.now) }
    
    static var startOfTomorrow: Date { startOfToday.addingTimeInterval(dayInSeconds) }
    
    static var endOfToday: Date {
        let comps = Calendar.autoupdatingCurrent.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: startOfToday
        )
        return Calendar.autoupdatingCurrent.date(
            from: DateComponents(
                timeZone: TimeZone.autoupdatingCurrent,
                year: comps.year,month: comps.month, day: comps.day,
                hour: 23, minute: 59, second: 59
            )
        )!
    }
    static var endOfTomorrow: Date { endOfToday.addingTimeInterval(TimeInterval(dayInSeconds)) }
    
    
    static var dayInSeconds: TimeInterval { TimeInterval(86400) }
    
    static func timeIntervalToDHM(_ timeInterval: TimeInterval) -> (days: Int, hours: Int, minutes: Int) {
        let totalMinutes = Int(timeInterval) / 60
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        let minutes = totalMinutes % 60
        return (days, hours, minutes)
    }

}
