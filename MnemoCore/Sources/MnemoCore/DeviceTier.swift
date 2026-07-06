public enum DeviceTier: String, Codable, Sendable {
    case full
    case standard
    case mlxOnly
    case cloudPrimary
    case unsupported
}

public enum ProcessingMode: String, Codable, Sendable {
    case onDeviceFull
    case onDeviceStandard
    case onDeviceMLXOnly
    case cloudPrimary
}

public struct DeviceCapability: Sendable {
    public let tier: DeviceTier
    public let appleIntelligenceAvailable: Bool
    public let appleIntelligenceAdvanced: Bool
    public let mnemoOnDeviceAvailable: Bool
    public let recommendedProcessingMode: ProcessingMode

    public init(
        tier: DeviceTier,
        appleIntelligenceAvailable: Bool,
        appleIntelligenceAdvanced: Bool,
        mnemoOnDeviceAvailable: Bool,
        recommendedProcessingMode: ProcessingMode
    ) {
        self.tier = tier
        self.appleIntelligenceAvailable = appleIntelligenceAvailable
        self.appleIntelligenceAdvanced = appleIntelligenceAdvanced
        self.mnemoOnDeviceAvailable = mnemoOnDeviceAvailable
        self.recommendedProcessingMode = recommendedProcessingMode
    }
}
