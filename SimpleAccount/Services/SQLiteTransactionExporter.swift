import Foundation
import SQLite3

class SQLiteTransactionExporter {
    
    func exportTransactions(_ transactions: [Transaction]) throws -> URL {
        let fileName = "spending_money_\(Date().timeIntervalSince1970).db"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Remove existing file if it exists
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        var db: OpaquePointer?
        
        guard sqlite3_open(fileURL.path, &db) == SQLITE_OK else {
            throw SQLiteExportError.databaseCreationFailed
        }
        
        defer {
            sqlite3_close(db)
        }
        
        try createTables(db: db)
        try insertTransactions(db: db, transactions: transactions)
        
        return fileURL
    }
    
    private func createTables(db: OpaquePointer?) throws {
        let createTransactionsTable = """
            CREATE TABLE IF NOT EXISTS transactions (
                id TEXT PRIMARY KEY,
                date REAL NOT NULL,
                amount REAL NOT NULL,
                description TEXT NOT NULL,
                type TEXT NOT NULL,
                signed_amount REAL NOT NULL
            );
        """
        
        let createSummaryView = """
            CREATE VIEW IF NOT EXISTS account_summary AS
            SELECT 
                COUNT(*) as total_transactions,
                SUM(CASE WHEN signed_amount > 0 THEN signed_amount ELSE 0 END) as total_income,
                SUM(CASE WHEN signed_amount < 0 THEN ABS(signed_amount) ELSE 0 END) as total_expenses,
                SUM(signed_amount) as current_balance,
                MIN(date) as first_transaction_date,
                MAX(date) as last_transaction_date
            FROM transactions;
        """
        
        for statement in [createTransactionsTable, createSummaryView] {
            guard sqlite3_exec(db, statement, nil, nil, nil) == SQLITE_OK else {
                throw SQLiteExportError.tableCreationFailed
            }
        }
    }
    
    private func insertTransactions(db: OpaquePointer?, transactions: [Transaction]) throws {
        let insertSQL = """
            INSERT INTO transactions (id, date, amount, description, type, signed_amount)
            VALUES (?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteExportError.statementPreparationFailed
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        for transaction in transactions {
            let transientPtr = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            
            sqlite3_bind_text(statement, 1, transaction.id.uuidString, -1, transientPtr)
            sqlite3_bind_double(statement, 2, transaction.date.timeIntervalSince1970)
            sqlite3_bind_double(statement, 3, NSDecimalNumber(decimal: transaction.amount).doubleValue)
            sqlite3_bind_text(statement, 4, transaction.description, -1, transientPtr)
            sqlite3_bind_text(statement, 5, transaction.type.rawValue, -1, transientPtr)
            sqlite3_bind_double(statement, 6, NSDecimalNumber(decimal: transaction.signedAmount).doubleValue)
            
            let result = sqlite3_step(statement)
            if result != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("❌ SQLite insertion failed for transaction \(transaction.description): \(errorMessage)")
                print("   Values: id=\(transaction.id.uuidString), date=\(transaction.date.timeIntervalSince1970), amount=\(transaction.amount), desc='\(transaction.description)', type=\(transaction.type.rawValue), signed=\(transaction.signedAmount)")
                throw SQLiteExportError.insertionFailed
            }
            
            sqlite3_reset(statement)
        }
    }
}

enum SQLiteExportError: LocalizedError {
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