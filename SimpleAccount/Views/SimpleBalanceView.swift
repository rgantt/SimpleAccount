import SwiftUI
import SwiftData

struct SimpleBalanceView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var transactions: [SimpleTransaction] = []
    @State private var refreshTrigger = 0
    
    private var currentBalance: Decimal {
        transactions.reduce(Decimal.zero) { total, transaction in
            total + transaction.signedAmount
        }
    }
    
    private var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: currentBalance)) ?? "$0.00"
    }
    
    private func loadTransactions() {
        do {
            let descriptor = FetchDescriptor<SimpleTransaction>(sortBy: [SortDescriptor(\.date)])
            transactions = try modelContext.fetch(descriptor)
            print("🔄 Balance view loaded \(transactions.count) transactions from context \(modelContext)")
            for tx in transactions {
                print("   - \(tx.transactionDescription): \(tx.amount)")
            }
        } catch {
            print("❌ Error loading transactions: \(error)")
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Current Balance")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(formattedBalance)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .onAppear {
                    loadTransactions()
                }
                .refreshable {
                    loadTransactions()
                }
                .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                    loadTransactions()
                }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}