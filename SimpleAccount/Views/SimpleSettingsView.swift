import SwiftUI
import SwiftData

struct SimpleSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var transactions: [SimpleTransaction] = []
    
    private func loadTransactions() {
        do {
            let descriptor = FetchDescriptor<SimpleTransaction>()
            transactions = try modelContext.fetch(descriptor)
        } catch {
            print("❌ Error loading transactions: \(error)")
        }
    }
    
    var body: some View {
        Form {
            Section("Statistics") {
                HStack {
                    Text("Total Transactions")
                    Spacer()
                    Text("\(transactions.count)")
                        .foregroundStyle(.secondary)
                }
                
                if let oldest = transactions.map(\.date).min() {
                    HStack {
                        Text("Oldest Transaction")
                        Spacer()
                        Text(oldest, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("2.0.0 (Simple)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadTransactions()
            print("⚙️ Settings: \(transactions.count) transactions found")
        }
    }
}