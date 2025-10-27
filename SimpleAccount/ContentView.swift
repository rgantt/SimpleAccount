//
//  ContentView.swift
//  SimpleAccount
//
//  Created by Ryan Gantt on 9/3/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @State private var showingTransactionEntry = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                VStack(spacing: 0) {
                    BalanceView()
                    TransactionListView()
                }
                .navigationTitle("Spending Money")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingTransactionEntry = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .tabItem {
                Label("Balance", systemImage: "dollarsign.circle.fill")
            }
            .tag(0)

            NavigationStack {
                ReportsView()
            }
            .tabItem {
                Label("Reports", systemImage: "chart.pie.fill")
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
        .sheet(isPresented: $showingTransactionEntry) {
            TransactionEntryView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TransactionStore())
}
