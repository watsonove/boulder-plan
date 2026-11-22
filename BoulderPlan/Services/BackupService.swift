import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Exportformat

/// Komplettes Backup als JSON: Einstellungen, alle Sessions inkl. Übungen, Benchmarks.
struct BackupFile: Codable {
    var formatVersion: Int = 1
    var exportedAt: Date
    var settings: SettingsDTO?
    var sessions: [SessionDTO]
    var benchmarks: [BenchmarkDTO]
}

struct SettingsDTO: Codable {
    var startDate: Date
    var daysPerWeek: Int
    var weekdays: [Int]
    var hasHangboard: Bool
    var showMobility: Bool
    var remindersEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var shiftDays: Int
    var forceDarkMode: Bool

    init(_ s: AppSettings) {
        startDate = s.startDate
        daysPerWeek = s.daysPerWeek
        weekdays = s.weekdays
        hasHangboard = s.hasHangboard
        showMobility = s.showMobility
        remindersEnabled = s.remindersEnabled
        reminderHour = s.reminderHour
        reminderMinute = s.reminderMinute
        shiftDays = s.shiftDays
        forceDarkMode = s.forceDarkMode
    }

    func apply(to s: AppSettings) {
        s.startDate = startDate
        s.daysPerWeek = daysPerWeek
        s.weekdays = weekdays
        s.hasHangboard = hasHangboard
        s.showMobility = showMobility
        s.remindersEnabled = remindersEnabled
        s.reminderHour = reminderHour
        s.reminderMinute = reminderMinute
        s.shiftDays = shiftDays
        s.forceDarkMode = forceDarkMode
        s.planGenerated = true
    }
}

struct ExerciseDTO: Codable {
    var id: UUID
    var sortIndex: Int
    var key: String
    var name: String
    var info: String
    var category: String
    var sets: Int
    var reps: String
    var restSeconds: Int
    var intensity: String
    var weightKg: Double?
    var minutes: Int
    var isCore: Bool
    var isLimit: Bool
    var benchmarkRaw: String?
    var alternatives: [String]
    var notes: String
    var isCompleted: Bool
    var completedSets: [Bool]
    var isCustom: Bool
    var quickSets: Int?
    var quickReps: String?
    var quickMinutes: Int?

    init(_ e: SessionExercise) {
        id = e.id; sortIndex = e.sortIndex; key = e.key; name = e.name; info = e.info
        category = e.category; sets = e.sets; reps = e.reps; restSeconds = e.restSeconds
        intensity = e.intensity; weightKg = e.weightKg; minutes = e.minutes; isCore = e.isCore
        isLimit = e.isLimit; benchmarkRaw = e.benchmarkRaw; alternatives = e.alternatives
        notes = e.notes; isCompleted = e.isCompleted; completedSets = e.completedSets
        isCustom = e.isCustom; quickSets = e.quickSets; quickReps = e.quickReps; quickMinutes = e.quickMinutes
    }

    func makeModel() -> SessionExercise {
        let e = SessionExercise(key: key, name: name, info: info, category: category)
        e.id = id; e.sortIndex = sortIndex; e.sets = sets; e.reps = reps; e.restSeconds = restSeconds
        e.intensity = intensity; e.weightKg = weightKg; e.minutes = minutes; e.isCore = isCore
        e.isLimit = isLimit; e.benchmarkRaw = benchmarkRaw; e.alternatives = alternatives
        e.notes = notes; e.isCompleted = isCompleted; e.completedSets = completedSets
        e.isCustom = isCustom; e.quickSets = quickSets; e.quickReps = quickReps; e.quickMinutes = quickMinutes
        return e
    }
}

struct SessionDTO: Codable {
    var id: UUID
    var date: Date
    var originalDate: Date
    var week: Int
    var phaseId: String
    var typeRaw: String
    var title: String
    var isOptional: Bool
    var isSkipped: Bool
    var lightMode: Bool
    var quickMode: Bool
    var wasMoved: Bool
    var contentEdited: Bool
    var checkInSleep: Int?
    var checkInEnergy: Int?
    var checkInFingers: Int?
    var completedAt: Date?
    var notes: String
    var exercises: [ExerciseDTO]

    init(_ s: TrainingSession) {
        id = s.id; date = s.date; originalDate = s.originalDate; week = s.week; phaseId = s.phaseId
        typeRaw = s.typeRaw; title = s.title; isOptional = s.isOptional; isSkipped = s.isSkipped
        lightMode = s.lightMode; quickMode = s.quickMode; wasMoved = s.wasMoved; contentEdited = s.contentEdited
        checkInSleep = s.checkInSleep; checkInEnergy = s.checkInEnergy; checkInFingers = s.checkInFingers
        completedAt = s.completedAt; notes = s.notes
        exercises = s.sortedExercises.map(ExerciseDTO.init)
    }

    func insert(into context: ModelContext) {
        let s = TrainingSession(date: date, week: week, phaseId: phaseId,
                                type: SessionType(rawValue: typeRaw) ?? .A, title: title, isOptional: isOptional)
        s.id = id; s.originalDate = originalDate; s.isSkipped = isSkipped; s.lightMode = lightMode
        s.quickMode = quickMode; s.wasMoved = wasMoved; s.contentEdited = contentEdited
        s.checkInSleep = checkInSleep; s.checkInEnergy = checkInEnergy; s.checkInFingers = checkInFingers
        s.completedAt = completedAt; s.notes = notes
        context.insert(s)
        for dto in exercises {
            let e = dto.makeModel()
            context.insert(e)
            e.session = s
        }
    }
}

struct BenchmarkDTO: Codable {
    var kindRaw: String
    var week: Int
    var value: Double?
    var grade: String?
    var date: Date
    var note: String

    init(_ r: BenchmarkResult) {
        kindRaw = r.kindRaw; week = r.week; value = r.value; grade = r.grade; date = r.date; note = r.note
    }

    func makeModel() -> BenchmarkResult {
        let r = BenchmarkResult(kind: BenchmarkKind(rawValue: kindRaw) ?? .maxHang, week: week)
        r.value = value; r.grade = grade; r.date = date; r.note = note
        return r
    }
}

// MARK: - Service

enum BackupService {
    static func exportData(context: ModelContext) throws -> Data {
        let file = BackupFile(
            exportedAt: .now,
            settings: ScheduleService.fetchSettings(context).map(SettingsDTO.init),
            sessions: ScheduleService.fetchSessions(context).map(SessionDTO.init),
            benchmarks: ((try? context.fetch(FetchDescriptor<BenchmarkResult>())) ?? []).map(BenchmarkDTO.init)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(file)
    }

    /// Ersetzt Sessions und Benchmarks durch den Inhalt des Backups.
    /// Das Settings-Objekt wird aktualisiert statt ersetzt (offene Views behalten ihre Referenz).
    static func importData(_ data: Data, context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let file = try decoder.decode(BackupFile.self, from: data) // erst validieren, dann löschen

        ScheduleService.fetchSessions(context).forEach { context.delete($0) }
        ((try? context.fetch(FetchDescriptor<BenchmarkResult>())) ?? []).forEach { context.delete($0) }

        if let dto = file.settings {
            let settings: AppSettings
            if let existing = ScheduleService.fetchSettings(context) {
                settings = existing
            } else {
                settings = AppSettings()
                context.insert(settings)
            }
            dto.apply(to: settings)
        }
        file.sessions.forEach { $0.insert(into: context) }
        file.benchmarks.forEach { context.insert($0.makeModel()) }
        try context.save()
        NotificationService.reschedule(context: context)
    }
}

/// Dokument für `.fileExporter`.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
