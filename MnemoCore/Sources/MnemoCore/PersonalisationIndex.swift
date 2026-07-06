public enum PersonalisationLevel: String, Sendable {
    case learningYou
    case gettingPersonal
    case mostlyYou
    case highlyPersonal
    case fullyPersonalised
}

public struct PersonalisationIndex: Codable, Sendable {
    public let overall: Double
    public let voiceProfileActive: Bool
    public let imageProfileActive: Bool
    public let persistencePreferencesLearned: Double
    public let threadDetectionCalibrated: Bool

    public var displayLevel: PersonalisationLevel {
        switch overall {
        case 0.0..<0.2:  return .learningYou
        case 0.2..<0.4:  return .gettingPersonal
        case 0.4..<0.6:  return .mostlyYou
        case 0.6..<0.8:  return .highlyPersonal
        default:          return .fullyPersonalised
        }
    }

    public init(
        overall: Double = 0.0,
        voiceProfileActive: Bool = false,
        imageProfileActive: Bool = false,
        persistencePreferencesLearned: Double = 0.0,
        threadDetectionCalibrated: Bool = false
    ) {
        self.overall = overall
        self.voiceProfileActive = voiceProfileActive
        self.imageProfileActive = imageProfileActive
        self.persistencePreferencesLearned = persistencePreferencesLearned
        self.threadDetectionCalibrated = threadDetectionCalibrated
    }
}
