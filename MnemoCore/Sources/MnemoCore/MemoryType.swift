public enum MemoryType: String, Codable, CaseIterable, Sendable {
    case preference
    case list
    case credential
    case event
    case fact
    case instruction
    case intention
}
