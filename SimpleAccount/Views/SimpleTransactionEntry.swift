import SwiftUI
import SwiftData

struct SimpleTransactionEntry: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var transactionType: TransactionType = .expense
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum TransactionType: String, CaseIterable {
        case expense = "Spend Money"
        case contribution = "Add Money"
        case sale = "Record Sale"
        
        var systemImage: String {
            switch self {
            case .expense: return "cart.fill"
            case .contribution: return "plus.circle.fill"
            case .sale: return "tag.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .expense: return .red
            case .contribution: return .green
            case .sale: return .blue
            }
        }
    }
    
    var decimalAmount: Decimal? {
        guard !amount.isEmpty else { return nil }
        let cleanedAmount = amount.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Decimal(string: cleanedAmount)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Type") {
                    Picker("Type", selection: $transactionType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Details") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Description", text: $description)
                }
                
                Section {
                    Button(action: saveTransaction) {
                        HStack {
                            Image(systemName: transactionType.systemImage)
                            Text(transactionType.rawValue)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .padding()
                        .background(transactionType.color)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(decimalAmount == nil || decimalAmount! <= 0 || description.isEmpty)
                }
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveTransaction() {
        guard let amount = decimalAmount, amount > 0 else {
            errorMessage = "Please enter a valid amount"
            showingError = true
            return
        }
        
        do {
            // Get accounts directly from current context
            let accounts = ensureAccountsExist()
            
            // Create transaction directly in this context
            switch transactionType {
            case .expense:
                try createExpenseTransaction(amount: amount, description: description, accounts: accounts)
            case .contribution:
                try createIncomeTransaction(amount: amount, description: description, accounts: accounts, isSale: false)
            case .sale:
                try createIncomeTransaction(amount: amount, description: description, accounts: accounts, isSale: true)
            }
            
            try modelContext.save()
            print("✅ Transaction saved successfully!")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func ensureAccountsExist() -> [String: Account] {
        let descriptor = FetchDescriptor<Account>()
        var existingAccounts = (try? modelContext.fetch(descriptor)) ?? []
        
        print("📊 Found \(existingAccounts.count) accounts: \(existingAccounts.map(\.name))")
        
        let requiredAccounts = ["Spending Money", "Contributions", "Purchases", "Sales"]
        let existingNames = Set(existingAccounts.map(\.name))
        
        for accountName in requiredAccounts {
            if !existingNames.contains(accountName) {
                let accountType: AccountType = {
                    switch accountName {
                    case "Spending Money": return .asset
                    case "Purchases": return .expense
                    default: return .income
                    }
                }()
                
                let account = Account(name: accountName, type: accountType)
                modelContext.insert(account)
                existingAccounts.append(account)
                print("➕ Created account: \(accountName)")
            }
        }
        
        do {
            try modelContext.save()
            print("💾 Accounts saved successfully")
        } catch {
            print("❌ Error saving accounts: \(error)")
        }
        
        // Return dictionary for easy lookup
        var accountDict: [String: Account] = [:]
        for account in existingAccounts {
            accountDict[account.name] = account
        }
        
        print("🎯 Returning accounts: \(accountDict.keys.sorted())")
        return accountDict
    }
    
    private func createIncomeTransaction(amount: Decimal, description: String, accounts: [String: Account], isSale: Bool) throws {
        guard let spending = accounts["Spending Money"],
              let income = accounts[isSale ? "Sales" : "Contributions"] else {
            throw AccountingError.accountsNotInitialized
        }
        
        print("💰 Creating income transaction: \(amount) - \(description)")
        
        let entry = JournalEntry(description: description)
        modelContext.insert(entry)
        
        // Debit spending account (increase asset)
        let debitLine = JournalLine(account: spending, entry: entry, entryType: .debit, amount: amount)
        modelContext.insert(debitLine)
        
        // Credit income account
        let creditLine = JournalLine(account: income, entry: entry, entryType: .credit, amount: amount)
        modelContext.insert(creditLine)
        
        entry.lines.append(debitLine)
        entry.lines.append(creditLine)
        spending.journalLines.append(debitLine)
        income.journalLines.append(creditLine)
    }
    
    private func createExpenseTransaction(amount: Decimal, description: String, accounts: [String: Account]) throws {
        guard let spending = accounts["Spending Money"],
              let expense = accounts["Purchases"] else {
            throw AccountingError.accountsNotInitialized
        }
        
        print("💸 Creating expense transaction: \(amount) - \(description)")
        
        let entry = JournalEntry(description: description)
        modelContext.insert(entry)
        
        // Debit expense account
        let debitLine = JournalLine(account: expense, entry: entry, entryType: .debit, amount: amount)
        modelContext.insert(debitLine)
        
        // Credit spending account (decrease asset)
        let creditLine = JournalLine(account: spending, entry: entry, entryType: .credit, amount: amount)
        modelContext.insert(creditLine)
        
        entry.lines.append(debitLine)
        entry.lines.append(creditLine)
        expense.journalLines.append(debitLine)
        spending.journalLines.append(creditLine)
    }
}