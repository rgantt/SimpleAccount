import Foundation

enum AccountType: String, Codable, CaseIterable {
    case asset = "Asset"
    case income = "Income"
    case expense = "Expense"
    
    var normalBalance: EntryType {
        switch self {
        case .asset, .expense: return .debit
        case .income: return .credit
        }
    }
    
    var multiplier: Decimal {
        switch self {
        case .asset: return 1
        case .income: return -1
        case .expense: return -1
        }
    }
}

enum EntryType: String, Codable, CaseIterable {
    case debit = "Debit"
    case credit = "Credit"
    
    var abbreviation: String {
        switch self {
        case .debit: return "Dr"
        case .credit: return "Cr"
        }
    }
}