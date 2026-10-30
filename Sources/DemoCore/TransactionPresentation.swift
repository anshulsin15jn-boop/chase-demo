import Foundation

public enum TransactionPresentation {
    /// Keep the payment's original civil day when the device changes time zones.
    public static func date(for payment: Payment, calendar: Calendar) -> Date {
        let zone = payment.timeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? TimeZone(secondsFromGMT: 0)!
        return LocalDay.project(payment.date, from: zone, into: calendar)
    }

    public static func status(date: Date, scheduled: Bool, isZelle: Bool, now: Date, calendar: Calendar) -> String {
        if scheduled { return "Scheduled" }
        return isZelle && calendar.isDate(date, inSameDayAs: now) ? "Pending" : "Posted"
    }
}
