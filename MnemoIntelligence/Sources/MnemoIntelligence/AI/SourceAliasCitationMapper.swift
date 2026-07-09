import Foundation

public struct SourceAliasMapping: Equatable, Sendable {
    public let alias: String
    public let sourceIdentifier: String

    public init(alias: String, sourceIdentifier: String) {
        self.alias = alias
        self.sourceIdentifier = sourceIdentifier
    }
}

public enum SourceAliasCitationMappingError: LocalizedError, Equatable, Sendable {
    case insufficientEvidence
    case emptyAnswer
    case emptySourceIdentifiers
    case unknownAlias(String)
    case malformedMappedSourceIdentifier(String)

    public var errorDescription: String? {
        switch self {
        case .insufficientEvidence:
            return "Model reported insufficient evidence."
        case .emptyAnswer:
            return "Model returned an empty answer."
        case .emptySourceIdentifiers:
            return "Model returned no source aliases."
        case .unknownAlias(let alias):
            return "Model cited unknown source alias \(alias)."
        case .malformedMappedSourceIdentifier:
            return "Mapped source identifier was malformed."
        }
    }
}

public struct SourceAliasCitationMapper: Sendable {
    private let aliasToSourceIdentifier: [String: String]

    public init(mappings: [SourceAliasMapping]) {
        self.aliasToSourceIdentifier = Dictionary(
            uniqueKeysWithValues: mappings.map { ($0.alias, $0.sourceIdentifier) }
        )
    }

    public func mapToSourceIdentifiers(
        _ output: SourceGroundedAnswerOutput
    ) throws -> SourceGroundedAnswerOutput {
        guard !output.insufficientEvidence else {
            throw SourceAliasCitationMappingError.insufficientEvidence
        }

        guard !output.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SourceAliasCitationMappingError.emptyAnswer
        }

        guard !output.sourceIdentifiers.isEmpty else {
            throw SourceAliasCitationMappingError.emptySourceIdentifiers
        }

        let mappedIdentifiers = try output.sourceIdentifiers.map { alias in
            guard let sourceIdentifier = aliasToSourceIdentifier[alias] else {
                throw SourceAliasCitationMappingError.unknownAlias(alias)
            }

            guard UUID(uuidString: sourceIdentifier) != nil else {
                throw SourceAliasCitationMappingError.malformedMappedSourceIdentifier(sourceIdentifier)
            }

            return sourceIdentifier
        }

        return SourceGroundedAnswerOutput(
            answer: output.answer,
            sourceIdentifiers: mappedIdentifiers,
            insufficientEvidence: output.insufficientEvidence
        )
    }
}
