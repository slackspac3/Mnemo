public enum MnemoError: Error, Sendable {
    case extractionFailed(String)
    case modelUnavailable
    case cloudEscalationDenied
    case corruptedMemory(String)
    case backupFailed(String)
    case restoreFailed(String)
    case securityError(String)
    case vectorStoreFailed(String)
    case threadDetectionFailed(String)
}
