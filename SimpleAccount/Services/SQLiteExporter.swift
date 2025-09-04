import Foundation
import SwiftData
import SQLite3

class SQLiteExporter {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func export() throws -> URL {
        let fileName = "spending_money_\(Date().timeIntervalSince1970).db"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        var db: OpaquePointer?
        
        guard sqlite3_open(fileURL.path, &db) == SQLITE_OK else {
            throw ExportError.databaseCreationFailed
        }
        
        defer {
            sqlite3_close(db)
        }
        
        try createTables(db: db)
        try exportAccounts(db: db)
        try exportJournalEntries(db: db)
        try exportJournalLines(db: db)
        
        return fileURL
    }
    
    private func createTables(db: OpaquePointer?) throws {
        let createAccountsTable = """
            CREATE TABLE IF NOT EXISTS accounts (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                type TEXT NOT NULL,
                is_active INTEGER NOT NULL,
                created_at REAL NOT NULL,
                balance REAL NOT NULL
            );
        """
        
        let createEntriesTable = """
            CREATE TABLE IF NOT EXISTS journal_entries (
                id TEXT PRIMARY KEY,
                date REAL NOT NULL,
                description TEXT NOT NULL,
                created_at REAL NOT NULL,
                is_balanced INTEGER NOT NULL,
                total_debits REAL NOT NULL,
                total_credits REAL NOT NULL
            );
        """
        
        let createLinesTable = """
            CREATE TABLE IF NOT EXISTS journal_lines (
                id TEXT PRIMARY KEY,
                entry_id TEXT NOT NULL,
                account_id TEXT NOT NULL,
                entry_type TEXT NOT NULL,
                amount REAL NOT NULL,
                FOREIGN KEY (entry_id) REFERENCES journal_entries(id),
                FOREIGN KEY (account_id) REFERENCES accounts(id)
            );
        """
        
        for statement in [createAccountsTable, createEntriesTable, createLinesTable] {
            guard sqlite3_exec(db, statement, nil, nil, nil) == SQLITE_OK else {
                throw ExportError.tableCreationFailed
            }
        }
    }
    
    private func exportAccounts(db: OpaquePointer?) throws {
        let descriptor = FetchDescriptor<Account>()
        let accounts = try modelContext.fetch(descriptor)
        
        let insertSQL = """
            INSERT INTO accounts (id, name, type, is_active, created_at, balance)
            VALUES (?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            throw ExportError.statementPreparationFailed
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        for account in accounts {
            sqlite3_bind_text(statement, 1, account.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, account.name, -1, nil)
            sqlite3_bind_text(statement, 3, account.type.rawValue, -1, nil)
            sqlite3_bind_int(statement, 4, account.isActive ? 1 : 0)
            sqlite3_bind_double(statement, 5, account.createdAt.timeIntervalSince1970)
            sqlite3_bind_double(statement, 6, NSDecimalNumber(decimal: account.balance).doubleValue)
            
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw ExportError.insertionFailed
            }
            
            sqlite3_reset(statement)
        }
    }
    
    private func exportJournalEntries(db: OpaquePointer?) throws {
        let descriptor = FetchDescriptor<JournalEntry>()
        let entries = try modelContext.fetch(descriptor)
        
        let insertSQL = """
            INSERT INTO journal_entries (id, date, description, created_at, is_balanced, total_debits, total_credits)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            throw ExportError.statementPreparationFailed
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        for entry in entries {
            sqlite3_bind_text(statement, 1, entry.id.uuidString, -1, nil)
            sqlite3_bind_double(statement, 2, entry.date.timeIntervalSince1970)
            sqlite3_bind_text(statement, 3, entry.entryDescription, -1, nil)
            sqlite3_bind_double(statement, 4, entry.createdAt.timeIntervalSince1970)
            sqlite3_bind_int(statement, 5, entry.isBalanced ? 1 : 0)
            sqlite3_bind_double(statement, 6, NSDecimalNumber(decimal: entry.totalDebits).doubleValue)
            sqlite3_bind_double(statement, 7, NSDecimalNumber(decimal: entry.totalCredits).doubleValue)
            
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw ExportError.insertionFailed
            }
            
            sqlite3_reset(statement)
        }
    }
    
    private func exportJournalLines(db: OpaquePointer?) throws {
        let descriptor = FetchDescriptor<JournalEntry>()
        let entries = try modelContext.fetch(descriptor)
        
        let insertSQL = """
            INSERT INTO journal_lines (id, entry_id, account_id, entry_type, amount)
            VALUES (?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            throw ExportError.statementPreparationFailed
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        for entry in entries {
            for line in entry.lines {
                sqlite3_bind_text(statement, 1, line.id.uuidString, -1, nil)
                sqlite3_bind_text(statement, 2, entry.id.uuidString, -1, nil)
                sqlite3_bind_text(statement, 3, line.account?.id.uuidString ?? "", -1, nil)
                sqlite3_bind_text(statement, 4, line.entryType.rawValue, -1, nil)
                sqlite3_bind_double(statement, 5, NSDecimalNumber(decimal: line.amount).doubleValue)
                
                guard sqlite3_step(statement) == SQLITE_DONE else {
                    throw ExportError.insertionFailed
                }
                
                sqlite3_reset(statement)
            }
        }
    }
}

enum ExportError: LocalizedError {
    case databaseCreationFailed
    case tableCreationFailed
    case statementPreparationFailed
    case insertionFailed
    
    var errorDescription: String? {
        switch self {
        case .databaseCreationFailed:
            return "Failed to create SQLite database"
        case .tableCreationFailed:
            return "Failed to create database tables"
        case .statementPreparationFailed:
            return "Failed to prepare SQL statement"
        case .insertionFailed:
            return "Failed to insert data into database"
        }
    }
}