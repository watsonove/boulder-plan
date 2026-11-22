import Foundation
import Observation

/// Zustand des Plans aus Sicht von „Heute“.
enum PlanState {
    case notStarted(Date)
    case running
    case finished
}

@Observable
final class TodayViewModel {
    /// Gewählte Session, falls heute mehrere anstehen (z. B. Training + optionale Mobility).
    var selectedID: UUID?

    /// Sessions eines Tages, Pflicht-Sessions zuerst.
    func sessions(on day: Date, from all: [TrainingSession]) -> [TrainingSession] {
        all.filter { $0.date.isSameDay(as: day) }
            .sorted { !$0.isOptional && $1.isOptional }
    }

    func selectedSession(from todays: [TrainingSession]) -> TrainingSession? {
        if let id = selectedID, let match = todays.first(where: { $0.id == id }) { return match }
        return todays.first
    }

    func missedSessions(from all: [TrainingSession]) -> [TrainingSession] {
        all.filter(\.isMissed)
    }

    func nextSession(after day: Date, from all: [TrainingSession]) -> TrainingSession? {
        all.first { !$0.isOptional && !$0.isSkipped && $0.date.startOfDay > day.startOfDay }
    }

    func planState(from all: [TrainingSession], today: Date) -> PlanState {
        let main = all.filter { !$0.isOptional }
        guard let first = main.first, let last = main.last else { return .running }
        if today.startOfDay < first.date.startOfDay { return .notStarted(first.date) }
        if today.startOfDay > last.date.startOfDay { return .finished }
        return .running
    }
}
