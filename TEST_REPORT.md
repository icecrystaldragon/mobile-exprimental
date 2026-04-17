# Test Report

## Build Status

**BLOCKED** - Cannot compile or run tests. Full Xcode 16+ is required but only Command Line Tools are installed.

## What Exists

- SwiftUI Preview providers on all 25 views for visual testing
- MockData.swift provides sample data for previews
- All new views have #Preview providers

## How to Test

### Prerequisites
1. Install Xcode 16+ from the Mac App Store
2. Run `xcode-select -s /Applications/Xcode.app/Contents/Developer`
3. Run `xcodegen generate` to regenerate the project with new files
4. Open `MobileCommander.xcodeproj` in Xcode
5. Wait for SPM to resolve Firebase and GoogleSignIn packages
6. Replace `GoogleService-Info.plist` with real Firebase config

### SwiftUI Previews
Open any view file in Xcode and the canvas should render with mock data.

### Manual Test Checklist

**Developer Mode - Dashboard**
- [ ] Stats grid filters recent tasks on tap
- [ ] Project cards navigate to DevProjectDetailView
- [ ] Quick links: Quota & Costs, Spreadsheet View, Activity Log
- [ ] Worker fleet horizontal scroll
- [ ] Pull-to-refresh

**Developer Mode - Tasks**
- [ ] Select/Done toolbar toggle enters multi-select mode
- [ ] Batch action bar appears with retry/delete buttons
- [ ] Batch delete shows confirmation and deletes selected tasks
- [ ] Status and project filters work
- [ ] Search filters correctly
- [ ] Context menu: retry, approve, delete

**Developer Mode - Task Detail**
- [ ] Output, Chat, Follow Up, Info tabs render
- [ ] Info tab: Edit button toggles inline editing
- [ ] Inline edit saves project, path, priority, description, worker to Firestore
- [ ] Menu actions work with haptic feedback
- [ ] Delete confirmation dialog appears

**Developer Mode - Spreadsheet**
- [ ] Column headers sort ascending/descending on tap
- [ ] Status filter chips work
- [ ] Horizontal scroll shows all columns
- [ ] Tap row navigates to task detail

**Developer Mode - Quota & Costs**
- [ ] Today/All Time cost summary
- [ ] Worker quota bars render with correct percentages
- [ ] Rate limit warnings display for limited workers
- [ ] Cost by project breakdown sums correctly

**Developer Mode - Project Detail**
- [ ] Progress bar shows correct done/total
- [ ] Status stat cards filter task list
- [ ] Context menu actions (retry, approve, delete) work

**Developer Mode - Alerts & Reports**
- [ ] Notification filters by type
- [ ] Report time range filters
- [ ] Metrics calculations match expectations

**Owner Mode - Home**
- [ ] Sticky header with status message
- [ ] Running task cards with live dot
- [ ] Quick resolve buttons: Looks Good, Needs Work, Try Again
- [ ] Today timeline shows recent activity
- [ ] Pull-to-refresh

**Owner Mode - Messages**
- [ ] Active conversations section with running tasks
- [ ] Previous tasks section
- [ ] Tap navigates to task detail view
- [ ] Active tasks show "Tap to send a message" hint

**Owner Mode - Activity**
- [ ] Events grouped by Today/Yesterday/date
- [ ] Friendly action descriptions (not raw action names)
- [ ] Detail text shows task name or project

**Owner Mode - New Task**
- [ ] 6 templates fill description
- [ ] Submit creates Firestore document
- [ ] Success animation and haptic

**Shared**
- [ ] Mode switching in Settings works (5 tabs each mode)
- [ ] Auth flow (login/logout)
- [ ] Pull-to-refresh on all scrollable views

### Unit Tests (to be added)
- `DataStore` task filtering and computed properties
- `CommanderTask.effectiveStatus` logic
- `CommanderTask.durationString` formatting
- `Date` extension formatting methods
