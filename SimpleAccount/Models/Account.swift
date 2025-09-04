import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID
    var name: String
    var type: AccountType
    var isActive: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .deny, inverse: \JournalLine.account)
    var journalLines: [JournalLine] = []
    
    init(name: String = "", type: AccountType = .asset, isActive: Bool = true) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.isActive = isActive
        self.createdAt = Date()
    }
    
    var balance: Decimal {
        journalLines.reduce(Decimal.zero) { total, line in
            let amount = line.amount
            if line.entryType == type.normalBalance {
                return total + amount
            } else {
                return total - amount
            }
        }
    }
    
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: balance)) ?? "$0.00"
    }
}