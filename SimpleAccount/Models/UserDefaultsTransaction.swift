import Foundation
import SwiftUI

struct Transaction: Codable, Identifiable {
    let id: UUID
    let date: Date
    let amount: Decimal
    let description: String
    let type: TxType
    
    init(amount: Decimal, description: String, type: TxType, date: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.description = description
        self.type = type
        self.date = date
    }
    
    var signedAmount: Decimal {
        switch type {
        case .income, .sale:
            return amount
        case .expense:
            return -amount
        }
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

enum TxType: String, Codable, CaseIterable {
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

// Make Decimal Codable
extension Decimal: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let doubleValue = try container.decode(Double.self)
        self.init(doubleValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(NSDecimalNumber(decimal: self).doubleValue)
    }
}

@MainActor
class TransactionStore: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private let localStore = UserDefaults.standard
    private let key = "savedTransactions"
    
    init() {
        loadTransactions()
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        saveTransactions()
        print("✅ UserDefaults: Saved transaction, now have \(transactions.count) total")
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        saveTransactions()
    }
    
    var currentBalance: Decimal {
        transactions.reduce(Decimal.zero) { total, transaction in
            total + transaction.signedAmount
        }
    }
    
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: currentBalance)) ?? "$0.00"
    }
    
    private func saveTransactions() {
        do {
            let data = try JSONEncoder().encode(transactions)
            
            // Save to both iCloud and local storage
            iCloudStore.set(data, forKey: key)
            localStore.set(data, forKey: key)
            
            // Force iCloud sync
            iCloudStore.synchronize()
            
            print("💾 iCloud + Local: Saved \(transactions.count) transactions")
        } catch {
            print("❌ Error saving transactions: \(error)")
        }
    }
    
    private func loadTransactions() {
        // Try iCloud first, fall back to local storage
        var data = iCloudStore.data(forKey: key)
        var source = "iCloud"
        
        if data == nil {
            data = localStore.data(forKey: key)
            source = "Local"
        }
        
        guard let data = data else {
            print("📂 No saved transactions found in iCloud or local storage")
            return
        }
        
        do {
            transactions = try JSONDecoder().decode([Transaction].self, from: data)
            print("📂 \(source): Loaded \(transactions.count) transactions")
        } catch {
            print("❌ Error loading transactions: \(error)")
        }
    }
}