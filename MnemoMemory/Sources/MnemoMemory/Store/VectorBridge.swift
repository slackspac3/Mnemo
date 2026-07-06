import Foundation
import SQLite3
import MnemoCore

/// Actor-isolated interface to the sqlite-vec vector store.
/// Phase 12: live sqlite-vec implementation replacing the Phase 3 mock.
/// Uses SQLite3 directly (built-in iOS framework -- no external dependency).
///
/// Embedding model: deterministic character-frequency vector (placeholder).
/// Replace with real MLX embedding model when On-Demand Resources are configured.
///
/// Database file: mnemo_vectors.sqlite in the app's Application Support directory.
public actor VectorBridge {

    public static let shared = VectorBridge()

    private var db: OpaquePointer?
    private let dbURL: URL
    private static let dimensions = 26

    public init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        try? FileManager.default.createDirectory(
            at: appSupport,
            withIntermediateDirectories: true
        )
        self.dbURL = appSupport.appendingPathComponent("mnemo_vectors.sqlite")
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Setup

    public func open() throws {
        guard db == nil else { return }
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(dbURL.path, &db, flags, nil) == SQLITE_OK else {
            throw VectorBridgeError.openFailed(dbURL.path)
        }
        guard sqlite3_busy_timeout(db, 5_000) == SQLITE_OK else {
            throw VectorBridgeError.executionFailed("busy timeout")
        }
        try createTable()
    }

    private func createTable() throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS embeddings (
            id TEXT PRIMARY KEY,
            summary TEXT NOT NULL,
            source TEXT NOT NULL,
            embedding BLOB NOT NULL,
            created_at REAL NOT NULL
        );
        """
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw VectorBridgeError.executionFailed("createTable")
        }
        try migrateTableIfNeeded()

        guard sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_embeddings_source ON embeddings(source);", nil, nil, nil) == SQLITE_OK else {
            throw VectorBridgeError.executionFailed("create source index")
        }
    }

    private func migrateTableIfNeeded() throws {
        let columns = try tableColumns()
        if !columns.contains("source") {
            try execute("ALTER TABLE embeddings ADD COLUMN source TEXT NOT NULL DEFAULT 'unknown';")
        }
        if !columns.contains("created_at") {
            try execute("ALTER TABLE embeddings ADD COLUMN created_at REAL NOT NULL DEFAULT 0;")
        }
    }

    private func tableColumns() throws -> Set<String> {
        let sql = "PRAGMA table_info(embeddings);"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw VectorBridgeError.prepareFailed("tableColumns")
        }

        var columns = Set<String>()
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let namePtr = sqlite3_column_text(stmt, 1) else { continue }
            columns.insert(String(cString: namePtr))
        }
        return columns
    }

    private func execute(_ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw VectorBridgeError.executionFailed(sql)
        }
    }

    // MARK: - Upsert

    public func upsert(id: UUID, embedding: [Float], summary: String) async throws {
        try ensureOpen()
        let sql = """
        INSERT INTO embeddings (id, summary, source, embedding, created_at)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            summary = excluded.summary,
            embedding = excluded.embedding;
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw VectorBridgeError.prepareFailed("upsert")
        }

        let idStr = id.uuidString
        let embeddingData = embedding.withUnsafeBytes { Data($0) }
        let destructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        sqlite3_bind_text(stmt, 1, (idStr as NSString).utf8String, -1, destructor)
        sqlite3_bind_text(stmt, 2, (summary as NSString).utf8String, -1, destructor)
        sqlite3_bind_text(stmt, 3, ("unknown" as NSString).utf8String, -1, destructor)
        let bindBlobResult = embeddingData.withUnsafeBytes { ptr in
            sqlite3_bind_blob(stmt, 4, ptr.baseAddress, Int32(embeddingData.count), destructor)
        }
        guard bindBlobResult == SQLITE_OK else {
            throw VectorBridgeError.executionFailed("upsert bind blob")
        }
        sqlite3_bind_double(stmt, 5, Date().timeIntervalSince1970)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw VectorBridgeError.executionFailed("upsert step")
        }
    }

    // MARK: - Search

    public func search(queryEmbedding: [Float], limit: Int) async throws -> [UUID] {
        try ensureOpen()
        let allEmbeddings = try fetchAllEmbeddings()
        let ranked = allEmbeddings
            .map { (id: $0.id, score: cosineSimilarity(queryEmbedding, $0.embedding)) }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .compactMap { UUID(uuidString: $0.id) }
        return Array(ranked)
    }

    // MARK: - Cluster

    public func cluster(limit: Int) async throws -> [[UUID]] {
        try ensureOpen()
        let allEmbeddings = try fetchAllEmbeddings()
        guard allEmbeddings.count >= 3 else { return [] }

        var clusters: [[String]] = []
        var assigned = Set<String>()
        let threshold: Float = 0.75

        for source in allEmbeddings {
            guard !assigned.contains(source.id) else { continue }
            var cluster = [source.id]
            assigned.insert(source.id)

            for candidate in allEmbeddings {
                guard !assigned.contains(candidate.id) else { continue }
                let sim = cosineSimilarity(source.embedding, candidate.embedding)
                if sim >= threshold {
                    cluster.append(candidate.id)
                    assigned.insert(candidate.id)
                }
            }

            if cluster.count >= 2 {
                clusters.append(cluster)
            }
        }

        return clusters
            .prefix(limit)
            .map { $0.compactMap { UUID(uuidString: $0) } }
    }

    // MARK: - Cross-modal corroboration

    public func findCorroborating(
        embedding: [Float],
        excludingSource: InputSource,
        threshold: Float
    ) async throws -> [UUID] {
        try ensureOpen()
        let all = try fetchAllEmbeddings()
        return all
            .filter { $0.source != excludingSource.rawValue }
            .filter { cosineSimilarity(embedding, $0.embedding) >= threshold }
            .compactMap { UUID(uuidString: $0.id) }
    }

    // MARK: - Delete

    public func delete(id: UUID) async throws {
        try ensureOpen()
        let sql = "DELETE FROM embeddings WHERE id = ?;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw VectorBridgeError.prepareFailed("delete")
        }

        let idStr = id.uuidString
        let destructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(stmt, 1, (idStr as NSString).utf8String, -1, destructor)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw VectorBridgeError.executionFailed("delete step")
        }
    }

    // MARK: - Wipe (for Delete All Data)

    public func wipe() throws {
        try ensureOpen()
        guard sqlite3_exec(db, "DELETE FROM embeddings;", nil, nil, nil) == SQLITE_OK else {
            throw VectorBridgeError.executionFailed("wipe")
        }
    }

    // MARK: - Private helpers

    private func ensureOpen() throws {
        if db == nil { try open() }
    }

    private struct EmbeddingRow {
        let id: String
        let source: String
        let embedding: [Float]
    }

    private func fetchAllEmbeddings() throws -> [EmbeddingRow] {
        let sql = "SELECT id, source, embedding FROM embeddings;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw VectorBridgeError.prepareFailed("fetchAll")
        }

        var rows: [EmbeddingRow] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard
                let idPtr = sqlite3_column_text(stmt, 0),
                let sourcePtr = sqlite3_column_text(stmt, 1)
            else { continue }

            let id = String(cString: idPtr)
            let source = String(cString: sourcePtr)

            let blobPtr = sqlite3_column_blob(stmt, 2)
            let blobSize = sqlite3_column_bytes(stmt, 2)
            guard let blobPtr, blobSize > 0 else { continue }

            let data = Data(bytes: blobPtr, count: Int(blobSize))
            let embedding = data.withUnsafeBytes { ptr in
                Array(ptr.bindMemory(to: Float.self))
            }

            rows.append(EmbeddingRow(id: id, source: source, embedding: embedding))
        }
        return rows
    }

    // MARK: - Cosine similarity

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        let count = min(a.count, b.count)
        guard count > 0 else { return 0 }

        var dot: Float = 0
        var magA: Float = 0
        var magB: Float = 0

        for i in 0..<count {
            dot += a[i] * b[i]
            magA += a[i] * a[i]
            magB += b[i] * b[i]
        }

        let denominator = sqrt(magA) * sqrt(magB)
        guard denominator > 0 else { return 0 }
        return dot / denominator
    }
}

// MARK: - Errors

public enum VectorBridgeError: Error, Sendable {
    case openFailed(String)
    case prepareFailed(String)
    case executionFailed(String)
}
