import SwiftUI
import SwiftData

struct SimpleTransactionList: View {
    @Environment(\.modelContext) private var modelContext
    @State private var transactions: [SimpleTransaction] = []
    
    private func loadTransactions() {
        do {
            let descriptor = FetchDescriptor<SimpleTransaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            transactions = try modelContext.fetch(descriptor)
            print("📋 Manually loaded \(transactions.count) transactions")
        } catch {
            print("❌ Error loading transactions: \(error)")
        }
    }
    
    var body: some View {
        List {
            ForEach(transactions) { transaction in
                HStack {
                    Image(systemName: transaction.type.icon)
                        .foregroundStyle(transaction.type.color)
                        .font(.title2)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.transactionDescription)
                            .font(.body)
                            .lineLimit(1)
                        
                        Text(transaction.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(transaction.formattedAmount)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundStyle(transaction.type == .expense ? .red : .primary)
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteTransactions)
        }
        .overlay {
            if transactions.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Add your first transaction to get started")
                )
            }
        }
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
    
    private func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(transactions[index])
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting transaction: \(error)")
        }
    }
}