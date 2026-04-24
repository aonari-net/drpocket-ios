# CGM Monitor iOS App

Native iOS app that runs Nightscout and Carelink-bridge automatically.

## Features

- **First Launch Setup**: Prompts for CareLink credentials and Nightscout configuration
- **Automatic Data Sync**: Fetches data from CareLink every 5 minutes and uploads to Nightscout
- **Minimal UI**: Clean interface showing:
  - Current glucose value with color coding (red < 70, green 70-180, yellow > 180)
  - Trend arrow
  - Time since last reading
  - 3-hour glucose chart with target range lines

## Requirements

- iOS 15.0 or later
- Xcode 15.0 or later
- Active CareLink account with connected pump
- Nightscout site URL and API secret

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

2. **Nightscout Configuration**
   - Nightscout URL (e.g., https://yoursite.herokuapp.com)
   - API Secret

After setup, the app will:
- Authenticate with CareLink
- Start syncing data every 5 minutes
- Display real-time glucose readings

## Architecture

- **BridgeManager**: Handles CareLink authentication and data fetching
- **NightscoutManager**: Manages Nightscout API communication and data display
- **SetupView**: First-run configuration screen
- **MonitorView**: Main glucose monitoring interface with chart

## Notes

- App uses background fetch to keep data updated
- Settings can be reset via gear icon in top-right
- Chart shows last 3 hours of data with 180 mg/dL high and 70 mg/dL low reference lines
