import Foundation

public struct ModalityThresholdProfile: Codable, Sendable {
    public var textThreshold: Double
    public var voiceThreshold: Double
    public var imageThreshold: Double
    public var lastUpdated: Date

    public init(
        textThreshold: Double = 0.90,
        voiceThreshold: Double = 0.75,
        imageThreshold: Double = 0.75,
        lastUpdated: Date = Date()
    ) {
        self.textThreshold = textThreshold
        self.voiceThreshold = voiceThreshold
        self.imageThreshold = imageThreshold
        self.lastUpdated = lastUpdated
    }

    public func threshold(for source: InputSource) -> Double {
        switch source {
        case .text:  return textThreshold
        case .voice: return voiceThreshold
        case .image: return imageThreshold
        }
    }
}
