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
    
    init(id: UUID, date: Date, amount: Decimal, description: String, type: TxType) {
        self.id = id
        self.date = date
        self.amount = amount
        self.description = description
        self.type = type
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
    
    func updateTransaction(_ oldTransaction: Transaction, with newTransaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == oldTransaction.id }) {
            var updated = newTransaction
            updated = Transaction(
                id: oldTransaction.id,
                date: newTransaction.date,
                amount: newTransaction.amount,
                description: newTransaction.description,
                type: newTransaction.type
            )
            transactions[index] = updated
            saveTransactions()
            print("✅ UserDefaults: Updated transaction")
        }
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