import SwiftUI
import SwiftData

struct BalanceView: View {
    @Environment(\.modelContext) private var modelContext
    let accountingService: AccountingService
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Current Balance")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text(accountingService.formattedBalance)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            accountingService.setup(with: modelContext)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Account.self, JournalEntry.self, JournalLine.self)
    let service = AccountingService()
    return BalanceView(accountingService: service)
        .modelContainer(container)
}