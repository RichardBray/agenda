import EventKit
import Foundation

let args = CommandLine.arguments
let days = args.count > 1 ? Int(args[1]) ?? 1 : 1
let excluded = Set(
    (ProcessInfo.processInfo.environment["CAL_EXCLUDE"]
        ?? "UK Holidays,Birthdays,Holidays in United Kingdom,Holidays in the United Kingdom,Reminders")
        .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })

let store = EKEventStore()
let sem = DispatchSemaphore(value: 0)
var granted = false
store.requestFullAccessToEvents { ok, _ in granted = ok; sem.signal() }
sem.wait()

guard granted else {
    FileHandle.standardError.write(Data("cal-events: calendar access denied\n".utf8))
    exit(2)
}

let cal = Calendar.current
let today = cal.startOfDay(for: Date())
let start = days < 0 ? cal.date(byAdding: .day, value: days, to: today)! : today
let end = cal.date(byAdding: .day, value: days < 0 ? 1 : days + 1, to: today)!

let calendars = store.calendars(for: .event).filter { !excluded.contains($0.title) }
let events = store.events(matching: store.predicateForEvents(withStart: start, end: end, calendars: calendars))
    .filter { !$0.isAllDay }
    .sorted { $0.startDate < $1.startDate }

let dateFmt = DateFormatter()
dateFmt.dateFormat = "yyyy-MM-dd"
let timeFmt = DateFormatter()
timeFmt.dateFormat = "HH:mm"

for e in events {
    let title = (e.title ?? "").replacingOccurrences(of: "|", with: "/")
    let name = e.calendar.title.replacingOccurrences(of: "|", with: "/")
    print("\(Int(e.startDate.timeIntervalSince1970))|\(dateFmt.string(from: e.startDate))|\(timeFmt.string(from: e.startDate))|\(title)|\(name)")
}
