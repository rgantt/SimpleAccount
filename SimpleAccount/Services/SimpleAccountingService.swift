import Foundation
import SwiftData

@MainActor
class SimpleAccountingService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getAccount(name: String) -> Account? {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { account in
                account.name == name
            }
        )
        let result = try? modelContext.fetch(descriptor).first
        print("🔍 Looking for account '\(name)': \(result?.name ?? "NOT FOUND")")
        return result
    }
    
    func addMoney(amount: Decimal, description: String, isSale: Bool = false) throws {
        print("💰 Attempting to add money: \(amount) - \(description)")
        
        let spending = getAccount(name: "Spending Money")
        let income = getAccount(name: isSale ? "Sales" : "Contributions")
        
        guard spending != nil, income != nil else {
            print("❌ Missing accounts - Spending: \(spending?.name ?? "nil"), Income: \(income?.name ?? "nil")")
            throw AccountingError.accountsNotInitialized
        }
        
        let entry = JournalEntry(description: description)
        
        // Debit spending account (increase asset)
        let debitLine = JournalLine(
            account: spending!,
            entry: entry,
            entryType: .debit,
            amount: amount
        )
        
        // Credit income account
        let creditLine = JournalLine(
            account: income!,
            entry: entry,
            entryType: .credit,
            amount: amount
        )
        
        entry.lines.append(debitLine)
        entry.lines.append(creditLine)
        spending!.journalLines.append(debitLine)
        income!.journalLines.append(creditLine)
        
        modelContext.insert(entry)
        modelContext.insert(debitLine)
        modelContext.insert(creditLine)
        
        try modelContext.save()
    }
    
    func spendMoney(amount: Decimal, description: String) throws {
        print("💸 Attempting to spend money: \(amount) - \(description)")
        
        let spending = getAccount(name: "Spending Money")
        let expense = getAccount(name: "Purchases")
        
        guard spending != nil, expense != nil else {
            print("❌ Missing accounts - Spending: \(spending?.name ?? "nil"), Expense: \(expense?.name ?? "nil")")
            throw AccountingError.accountsNotInitialized
        }
        
        let entry = JournalEntry(description: description)
        
        // Debit expense account
        let debitLine = JournalLine(
            account: expense!,
            entry: entry,
            entryType: .debit,
            amount: amount
        )
        
        // Credit spending account (decrease asset)
        let creditLine = JournalLine(
            account: spending!,
            entry: entry,
            entryType: .credit,
            amount: amount
        )
        
        entry.lines.append(debitLine)
        entry.lines.append(creditLine)
        expense!.journalLines.append(debitLine)
        spending!.journalLines.append(creditLine)
        
        modelContext.insert(entry)
        modelContext.insert(debitLine)
        modelContext.insert(creditLine)
        
        try modelContext.save()
    }
}

// Using the AccountingError from AccountingService.swift