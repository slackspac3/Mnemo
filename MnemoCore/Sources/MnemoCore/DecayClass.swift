public enum DecayClass: String, Codable, Sendable {
    case persistent
    case timeBound
    case session
}

public enum PersistenceState: String, Codable, Sendable {
    case active
    case dormant
    case review
}
