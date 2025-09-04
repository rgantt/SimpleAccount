# Setup Instructions for SimpleAccount

## iCloud Configuration

To enable iCloud sync for your app, you need to configure the following in Xcode:

1. **Open the project in Xcode:**
   ```bash
   open SimpleAccount.xcodeproj
   ```

2. **Add iCloud Capability:**
   - Select your project in the navigator
   - Select the "SimpleAccount" target
   - Go to the "Signing & Capabilities" tab
   - Click the "+ Capability" button
   - Add "iCloud" capability
   - Check "CloudKit" under iCloud Services
   - The container name will be automatically created (usually `iCloud.com.yourteam.SimpleAccount`)

3. **Configure App Groups (Optional but recommended):**
   - Add "App Groups" capability if you want to share data between app extensions
   - Create a new app group (e.g., `group.com.yourteam.SimpleAccount`)

4. **Build and Run:**
   - Select a simulator or your device
   - Press Cmd+R to build and run
   - The app should launch with:
     - A balance view showing $0.00
     - A "+" button to add transactions
     - Three tabs: Balance, Reports, and Settings

## Testing the App

1. **Add your first transaction:**
   - Tap the "+" button
   - Select transaction type (Add Money, Spend Money, or Record Sale)
   - Enter an amount and description
   - Tap the button to save

2. **View your balance:**
   - The main screen shows your current balance
   - Below it is a list of all transactions

3. **Check Reports:**
   - Switch to the Reports tab
   - View income, expenses, and net change
   - Filter by time period (Week, Month, Year, All Time)

4. **Export Data:**
   - Go to Settings tab
   - Tap "Export to SQLite"
   - Share the file via AirDrop, Messages, or save to Files

## Features Implemented

✅ **Double-Entry Bookkeeping**: Every transaction follows accounting principles with balanced debits and credits
✅ **SwiftData with iCloud Sync**: Automatic sync across all your devices
✅ **Clean UI**: Simple interface focused on balance and transactions
✅ **Reports & Analytics**: Track income, expenses, and net changes over time
✅ **SQLite Export**: Export your data for use in other applications
✅ **Audit Trail**: Complete transaction history with immutable entries

## Architecture Notes

The app uses a proper double-entry bookkeeping system with:
- **Asset Account**: "Spending Money" (your main balance)
- **Income Accounts**: "Contributions" and "Sales"
- **Expense Account**: "Purchases"

Every transaction creates balanced journal entries ensuring data integrity and professional accounting practices.