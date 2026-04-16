# Test Report

## Current Status: BLOCKED

Cannot run tests because full Xcode is not installed (only Command Line Tools).

## What exists
- SwiftUI Preview providers on all views for visual testing
- MockData.swift provides sample data for previews and unit tests

## How to test

### SwiftUI Previews
1. Open `MobileCommander.xcodeproj` in Xcode
2. Open any view file (e.g., `DevDashboardView.swift`)
3. Canvas should render the preview with mock data

### Manual Testing
1. Build and run on iOS Simulator
2. Test login flow (requires real GoogleService-Info.plist)
3. Verify Developer mode: Dashboard -> Tasks -> Workers -> Activity -> Settings
4. Switch to Owner mode in Settings
5. Verify Owner mode: Home -> New Task -> Settings
6. Test task creation in both modes (Owner mode has task templates now)
7. Test task detail view navigation
8. Test Follow Up tab in Developer task detail
9. Test pull-to-refresh on Dashboard, Tasks, Workers, Owner Home
10. Test tab badge counts update for items needing attention
11. Test Approve/Request Changes from task detail menu
12. Test Delete Task from task detail menu
13. Verify listeners clean up when leaving task detail view

### Unit Tests (to be added)
- `DataStore` task filtering and computed properties
- `CommanderTask.effectiveStatus` logic
- `CommanderTask.durationString` formatting
- `Date` extension formatting methods

## Test Environment
- iOS 17+ Simulator or device
- Requires Xcode 16+
- Requires real Firebase configuration for integration testing
