import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Query(sort: \JournalEntry.date, order: .reverse)
    private var entries: [JournalEntry]
    
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    
    var filteredEntries: [JournalEntry] {
        let validEntries = entries.filter { !$0.entryDescription.isEmpty }
        
        if searchText.isEmpty {
            return validEntries
        } else {
            return validEntries.filter { entry in
                entry.entryDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredEntries) { entry in
                TransactionRow(entry: entry)
            }
            .onDelete(perform: deleteEntries)
        }
        .searchable(text: $searchText, prompt: "Search transactions")
        .overlay {
            if filteredEntries.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Add your first transaction to get started")
                )
            }
        }
        .onAppear {
            print("📝 TransactionListView: Found \(entries.count) entries")
            for entry in entries.prefix(5) {
                print("   - \(entry.entryDescription) (\(entry.date))")
            }
        }
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredEntries[index])
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
}

struct TransactionRow: View {
    let entry: JournalEntry
    
    var transactionAmount: String {
        if let line = entry.lines.first {
            return line.formattedAmount
        }
        return "$0.00"
    }
    
    var transactionType: String {
        if entry.lines.contains(where: { $0.account?.name == "Purchases" }) {
            return "expense"
        } else if entry.lines.contains(where: { $0.account?.name == "Sales" }) {
            return "sale"
        } else {
            return "contribution"
        }
    }
    
    var transactionIcon: String {
        switch transactionType {
        case "expense": return "cart.fill"
        case "sale": return "tag.fill"
        default: return "plus.circle.fill"
        }
    }
    
    var transactionColor: Color {
        switch transactionType {
        case "expense": return .red
        case "sale": return .blue
        default: return .green
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: transactionIcon)
                .foregroundStyle(transactionColor)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.entryDescription)
                    .font(.body)
                    .lineLimit(1)
                
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(transactionAmount)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(transactionType == "expense" ? .red : .primary)
        }
        .padding(.vertical, 4)
    }
}