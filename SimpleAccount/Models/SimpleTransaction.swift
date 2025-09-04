import Foundation
import SwiftData

@Model
final class SimpleTransaction {
    var id: UUID
    var date: Date
    var amount: Decimal
    var transactionDescription: String
    var type: TransactionType
    
    init(amount: Decimal, description: String, type: TransactionType, date: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.transactionDescription = description
        self.type = type
        self.date = date
    }
    
    var signedAmount: Decimal {
        switch type {
        case .income, .sale:
            return amount  // Positive amounts increase balance
        case .expense:
            return -amount // Negative amounts decrease balance
        }
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "Income"
    case expense = "Expense" 
    case sale = "Sale"
    
    var color: Color {
        switch self {
        case .income: return .green
        case .expense: return .red
        case .sale: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .income: return "plus.circle.fill"
        case .expense: return "cart.fill"
        case .sale: return "tag.fill"
        }
    }
}

import SwiftUI