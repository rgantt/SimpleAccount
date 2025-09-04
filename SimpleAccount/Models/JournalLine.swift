import Foundation
import SwiftData

@Model
final class JournalLine {
    var id: UUID
    var entryType: EntryType
    var amount: Decimal
    
    var account: Account?
    var entry: JournalEntry?
    
    init(account: Account? = nil, entry: JournalEntry? = nil, entryType: EntryType = .debit, amount: Decimal = 0) {
        self.id = UUID()
        self.account = account
        self.entry = entry
        self.entryType = entryType
        self.amount = amount
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}