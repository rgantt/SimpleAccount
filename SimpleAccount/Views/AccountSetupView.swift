import SwiftUI
import SwiftData

struct AccountSetupView<Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @State private var hasSetupAccounts = false
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .onAppear {
                if !hasSetupAccounts {
                    setupAccounts()
                    hasSetupAccounts = true
                }
            }
    }
    
    private func setupAccounts() {
        // Check if accounts already exist
        if accounts.isEmpty {
            let spending = Account(name: "Spending Money", type: .asset)
            let contributions = Account(name: "Contributions", type: .income)
            let purchases = Account(name: "Purchases", type: .expense)
            let sales = Account(name: "Sales", type: .income)
            
            modelContext.insert(spending)
            modelContext.insert(contributions)
            modelContext.insert(purchases)
            modelContext.insert(sales)
            
            do {
                try modelContext.save()
                print("✅ Accounts created successfully")
            } catch {
                print("❌ Error creating accounts: \(error)")
            }
        } else {
            print("✅ Accounts already exist: \(accounts.map(\.name))")
        }
    }
}