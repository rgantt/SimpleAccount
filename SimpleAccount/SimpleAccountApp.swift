//
//  SimpleAccountApp.swift
//  SimpleAccount
//
//  Created by Ryan Gantt on 9/3/25.
//

import SwiftUI

@main
struct SimpleAccountApp: App {
    @StateObject private var transactionStore = TransactionStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(transactionStore)
        }
    }
}
