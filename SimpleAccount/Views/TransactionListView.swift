import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var store: TransactionStore
    @State private var searchText = ""
    @State private var showingAllTransactions = false
    @State private var editingTransaction: Transaction?
    
    private let maxDisplayedTransactions = 50
    
    var filteredTransactions: [Transaction] {
        let sorted = store.transactions.sorted { $0.date > $1.date }
        
        if searchText.isEmpty {
            return showingAllTransactions ? sorted : Array(sorted.prefix(maxDisplayedTransactions))
        } else {
            return sorted.filter { transaction in
                transaction.description.localizedCaseInsensitiveContains(searchText) ||
                transaction.type.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var hasMoreTransactions: Bool {
        !showingAllTransactions && searchText.isEmpty && store.transactions.count > maxDisplayedTransactions
    }
    
    var body: some View {
        List {
            ForEach(filteredTransactions) { transaction in
                HStack {
                    Image(systemName: transaction.type.icon)
                        .foregroundStyle(transaction.type.color)
                        .font(.title2)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.description)
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
                .contentShape(Rectangle())
                .onTapGesture {
                    editingTransaction = transaction
                }
                .swipeActions(edge: .leading) {
                    Button {
                        editingTransaction = transaction
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
            .onDelete(perform: deleteTransactions)
            
            if hasMoreTransactions {
                Button("Show All \(store.transactions.count) Transactions") {
                    withAnimation {
                        showingAllTransactions = true
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(.blue)
            }
        }
        .searchable(text: $searchText, prompt: "Search transactions")
        .overlay {
            if filteredTransactions.isEmpty && !store.transactions.isEmpty {
                ContentUnavailableView.search
            } else if store.transactions.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Add your first transaction to get started")
                )
            }
        }
        .sheet(item: $editingTransaction) { transaction in
            EditTransactionView(transaction: transaction)
        }
    }
    
    private func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            store.deleteTransaction(filteredTransactions[index])
        }
    }
}