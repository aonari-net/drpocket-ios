# CGM Monitor iOS App

Native iOS app that fetches CareLink data and stores locally.

## Features

- **First Launch Setup**: Prompts for CareLink credentials only
- **Local Storage**: All data stored in SQLite on device
- **Auto-Wipe**: Data older than 24 hours automatically deleted
- **Automatic Data Sync**: Fetches data from CareLink every 5 minutes
- **Minimal UI**: Clean interface showing:
  - Current glucose value with color coding (red < 70, green 70-180, yellow > 180)
  - Trend arrow
  - Time since last reading
  - 3-hour glucose chart with target range lines

## Requirements

- iOS 15.0 or later
- Xcode 15.0 or later
- Active CareLink account with connected pump

## Setup

1. Open `CGMMonitor.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run on device or simulator

## First Launch

On first launch, you'll be prompted to enter:

1. **CareLink Credentials**
   - Username/Email
   - Password
   - Server region (US or EU)

After setup, the app will:
- Authenticate with CareLink
- Start syncing data every 5 minutes to local SQLite database
- Display real-time glucose readings
- Auto-delete data older than 24 hours

## Architecture

- **LocalDatabase**: SQLite storage with auto-cleanup
- **BridgeManager**: Handles CareLink authentication and data fetching
- **NightscoutManager**: Reads from local database and updates UI
- **SetupView**: First-run configuration screen
- **MonitorView**: Main glucose monitoring interface with chart

## Privacy

- All data stored locally on device
- No cloud sync or external uploads
- Data automatically wiped after 24 hours
- Each user has isolated data storage
