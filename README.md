# SimpleAccount

A personal budgeting iOS app for tracking your "spending money" with simplicity and clarity.

## Overview

SimpleAccount is a SwiftUI-based iOS app that helps you track income, expenses, and sales in a single account. It uses double-entry bookkeeping principles under the hood while presenting a simple, intuitive interface for everyday use.

## Features

- **Real-time Balance Tracking**: See your current balance at a glance
- **Transaction Management**: Record income, expenses, and sales with ease
- **Search & Filter**: Find transactions quickly by description or type
- **Financial Reports**: View trends over time (Week, Month, Quarter, Year, All Time)
- **Visual Analytics**: Custom charts showing balance, income, and expense trends
- **iCloud Sync**: Automatic synchronization across your iOS devices
- **SQLite Export**: Export your complete transaction history to a professional SQLite database

## Requirements

- iOS 18.5 or later
- Xcode 16.0 or later (for development)
- iCloud account (for sync functionality)

## Installation

### For Users

1. Open the project in Xcode
2. Select your development team in the Signing & Capabilities tab
3. Build and run on your device or simulator

### For Developers

```bash
# Clone the repository
git clone <repository-url>
cd SimpleAccount

# Open in Xcode
open SimpleAccount.xcodeproj

# Build the project
xcodebuild -scheme SimpleAccount -destination 'platform=iOS Simulator,id=2981B45A-F168-4A1C-84E5-6FF50A9B63C0' build
```

## Usage

### Adding Transactions

1. Tap the **+** button in the top-right corner
2. Enter the amount and description
3. Select the transaction type (Income, Expense, or Sale)
4. Tap **Save**

### Viewing Reports

1. Navigate to the **Reports** tab
2. Select your time range (Week, Month, Quarter, Year, or All Time)
3. View summary statistics and financial trend charts
4. Switch between different metrics using the segmented picker

### Exporting Data

1. Go to the **Settings** tab
2. Tap **Export to SQLite**
3. Share the generated database file

## Technology Stack

- **Framework**: SwiftUI
- **Language**: Swift 5
- **Persistence**: NSUbiquitousKeyValueStore + UserDefaults
- **Cloud Sync**: iCloud Key-Value Storage
- **Charts**: Custom SwiftUI Path-based rendering
- **Export**: SQLite3

## Architecture Highlights

- **Data Model**: Codable `Transaction` struct with type-safe enums
- **State Management**: `@ObservableObject` TransactionStore with `@Published` properties
- **Persistence Strategy**: Dual storage (iCloud + local) for reliability and offline support
- **Chart Rendering**: Custom implementation using SwiftUI's GeometryReader and Path

## Development Notes

This app was originally built with SwiftData but migrated to NSUbiquitousKeyValueStore due to persistence reliability issues. The codebase has been cleaned of all legacy implementations, leaving only the active "Working" view hierarchy.

## License

[Add your license here]

## Contact

[Add your contact information here]
