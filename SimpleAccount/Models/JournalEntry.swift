import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var date: Date
    var entryDescription: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \JournalLine.entry)
    var lines: [JournalLine] = []
    
    init(date: Date = Date(), description: String = "") {
        self.id = UUID()
        self.date = date
        self.entryDescription = description
        self.createdAt = Date()
    }
    
    var isBalanced: Bool {
        let debits = lines
            .filter { $0.entryType == .debit }
            .reduce(Decimal.zero) { $0 + $1.amount }
        
        let credits = lines
            .filter { $0.entryType == .credit }
            .reduce(Decimal.zero) { $0 + $1.amount }
        
        return debits == credits
    }
    
    var totalDebits: Decimal {
        lines
            .filter { $0.entryType == .debit }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    var totalCredits: Decimal {
        lines
            .filter { $0.entryType == .credit }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    func addLine(account: Account, entryType: EntryType, amount: Decimal) {
        let line = JournalLine(
            account: account,
            entry: self,
            entryType: entryType,
            amount: amount
        )
        lines.append(line)
        account.journalLines.append(line)
    }
}