import Foundation
import SwiftData

@MainActor
@Observable
class AccountingService {
    private var modelContext: ModelContext?
    
    var spendingAccount: Account?
    var incomeAccount: Account?
    var expenseAccount: Account?
    var salesAccount: Account?
    
    init() {
    }
    
    func setup(with context: ModelContext) {
        self.modelContext = context
        setupDefaultAccounts()
    }
    
    private func setupDefaultAccounts() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<Account>()
        
        do {
            let existingAccounts = try modelContext.fetch(descriptor)
            
            spendingAccount = existingAccounts.first { $0.name == "Spending Money" }
            incomeAccount = existingAccounts.first { $0.name == "Contributions" }
            expenseAccount = existingAccounts.first { $0.name == "Purchases" }
            salesAccount = existingAccounts.first { $0.name == "Sales" }
            
            if spendingAccount == nil {
                spendingAccount = Account(name: "Spending Money", type: .asset)
                modelContext.insert(spendingAccount!)
            }
            
            if incomeAccount == nil {
                incomeAccount = Account(name: "Contributions", type: .income)
                modelContext.insert(incomeAccount!)
            }
            
            if expenseAccount == nil {
                expenseAccount = Account(name: "Purchases", type: .expense)
                modelContext.insert(expenseAccount!)
            }
            
            if salesAccount == nil {
                salesAccount = Account(name: "Sales", type: .income)
                modelContext.insert(salesAccount!)
            }
            
            try modelContext.save()
        } catch {
            print("Error setting up accounts: \(error)")
        }
    }
    
    func addMoney(amount: Decimal, description: String, isSale: Bool = false) throws {
        guard let modelContext = modelContext,
              let spending = spendingAccount,
              let income = isSale ? salesAccount : incomeAccount else {
            throw AccountingError.accountsNotInitialized
        }
        
        let entry = JournalEntry(description: description)
        entry.addLine(account: spending, entryType: .debit, amount: amount)
        entry.addLine(account: income, entryType: .credit, amount: amount)
        
        guard entry.isBalanced else {
            throw AccountingError.unbalancedEntry
        }
        
        modelContext.insert(entry)
        try modelContext.save()
    }
    
    func spendMoney(amount: Decimal, description: String) throws {
        guard let modelContext = modelContext,
              let spending = spendingAccount,
              let expense = expenseAccount else {
            throw AccountingError.accountsNotInitialized
        }
        
        let entry = JournalEntry(description: description)
        entry.addLine(account: expense, entryType: .debit, amount: amount)
        entry.addLine(account: spending, entryType: .credit, amount: amount)
        
        guard entry.isBalanced else {
            throw AccountingError.unbalancedEntry
        }
        
        modelContext.insert(entry)
        try modelContext.save()
    }
    
    var currentBalance: Decimal {
        spendingAccount?.balance ?? 0
    }
    
    var formattedBalance: String {
        spendingAccount?.formattedBalance ?? "$0.00"
    }
}

enum AccountingError: LocalizedError {
    case accountsNotInitialized
    case unbalancedEntry
    
    var errorDescription: String? {
        switch self {
        case .accountsNotInitialized:
            return "Accounts have not been properly initialized"
        case .unbalancedEntry:
            return "Journal entry is not balanced"
        }
    }
}