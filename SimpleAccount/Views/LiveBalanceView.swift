import SwiftUI
import SwiftData

struct LiveBalanceView: View {
    @Query private var accounts: [Account]
    @Query private var journalLines: [JournalLine]
    
    private var spendingAccount: Account? {
        accounts.first { $0.name == "Spending Money" }
    }
    
    private var currentBalance: Decimal {
        guard let spendingAccount = spendingAccount else { return 0 }
        
        let spendingLines = journalLines.filter { $0.account?.name == "Spending Money" }
        let balance = spendingLines.reduce(Decimal.zero) { total, line in
            if line.entryType == .debit {
                return total + line.amount  // Debits increase assets
            } else {
                return total - line.amount  // Credits decrease assets
            }
        }
        return balance
    }
    
    private var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: currentBalance)) ?? "$0.00"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Current Balance")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text(formattedBalance)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            print("💰 LiveBalanceView: Found \(accounts.count) accounts, \(journalLines.count) journal lines")
            print("   Balance calculation: \(currentBalance)")
        }
    }
}

#Preview {
    LiveBalanceView()
        .modelContainer(for: [Account.self, JournalEntry.self, JournalLine.self], inMemory: true)
}