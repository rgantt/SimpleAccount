import SwiftUI
import SwiftData

struct NewTransactionEntry: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var selectedType = TransactionType.expense
    
    var decimalAmount: Decimal? {
        guard !amount.isEmpty else { return nil }
        return Decimal(string: amount.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Transaction Type", selection: $selectedType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
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
                    Button("Save Transaction") {
                        saveTransaction()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(decimalAmount == nil || decimalAmount! <= 0 || description.isEmpty)
                }
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveTransaction() {
        guard let amount = decimalAmount, amount > 0 else { return }
        
        let transaction = SimpleTransaction(
            amount: amount,
            description: description,
            type: selectedType
        )
        
        modelContext.insert(transaction)
        
        do {
            try modelContext.save()
            print("✅ Saved: \(selectedType.rawValue) \(amount) - \(description)")
            
            // Immediately verify the save by fetching
            let descriptor = FetchDescriptor<SimpleTransaction>()
            let allTransactions = try modelContext.fetch(descriptor)
            print("🔍 Verification fetch found \(allTransactions.count) transactions in save context")
            for tx in allTransactions {
                print("   - \(tx.transactionDescription): \(tx.amount)")
            }
            
            // Notify views to refresh
            NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: nil)
            
            dismiss()
        } catch {
            print("❌ Save error: \(error)")
        }
    }
}