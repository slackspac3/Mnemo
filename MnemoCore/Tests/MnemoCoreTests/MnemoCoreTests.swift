import Testing
@testable import MnemoCore

@Suite("MnemoCore Types")
struct MnemoCoreTests {

    @Test("MemoryType has all expected cases")
    func memoryTypeAllCases() {
        #expect(MemoryType.allCases.count == 7)
    }

    @Test("ModalityThresholdProfile defaults are correct")
    func modalityThresholdDefaults() {
        let profile = ModalityThresholdProfile()
        #expect(profile.textThreshold == 0.90)
        #expect(profile.voiceThreshold == 0.75)
        #expect(profile.imageThreshold == 0.75)
    }

    @Test("ModalityThresholdProfile threshold lookup")
    func modalityThresholdLookup() {
        let profile = ModalityThresholdProfile()
        #expect(profile.threshold(for: .text) == 0.90)
        #expect(profile.threshold(for: .voice) == 0.75)
        #expect(profile.threshold(for: .image) == 0.75)
    }

    @Test("PersonalisationIndex display levels")
    func personalisationLevels() {
        #expect(PersonalisationIndex(overall: 0.1).displayLevel == .learningYou)
        #expect(PersonalisationIndex(overall: 0.3).displayLevel == .gettingPersonal)
        #expect(PersonalisationIndex(overall: 0.5).displayLevel == .mostlyYou)
        #expect(PersonalisationIndex(overall: 0.7).displayLevel == .highlyPersonal)
        #expect(PersonalisationIndex(overall: 0.9).displayLevel == .fullyPersonalised)
    }

    @Test("DeviceCapability initialises correctly")
    func deviceCapabilityInit() {
        let cap = DeviceCapability(
            tier: .full,
            appleIntelligenceAvailable: true,
            appleIntelligenceAdvanced: true,
            mnemoOnDeviceAvailable: true,
            recommendedProcessingMode: .onDeviceFull
        )
        #expect(cap.tier == .full)
        #expect(cap.appleIntelligenceAvailable == true)
    }
}
