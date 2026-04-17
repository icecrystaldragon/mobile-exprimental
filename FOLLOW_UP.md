# Follow Up

**What was done**: Added power-user features to Developer mode (project detail view, spreadsheet/table view, quota monitoring, inline task editing, multi-select batch actions) and palmr-inspired Owner mode enhancements (activity timeline, chat list, quick resolve buttons, today timeline on home screen). Owner mode now has 5 tabs (Home, New Task, Messages, Activity, Settings) instead of 3.

**What needs review**:
- Verify DevSpreadsheetView horizontal scrolling works on smaller iPhones (SE/mini)
- Verify inline editing in DevTaskDetailView Info tab saves changes to Firestore correctly
- Check that batch delete in DevTaskListView refreshes the task list after deletion
- Confirm OwnerChatListView navigation to OwnerTaskDetailView works from the Messages tab
- Test quick resolve buttons (Looks Good / Needs Work / Try Again) on OwnerHomeView attention cards
- Verify the TimelineDot component renders the connecting line correctly between events
- Test DevQuotaView with workers that have rate limit data

**Action items**:
- Install Xcode 16+ and build the project to catch compile errors
- Run `xcodegen generate` to regenerate `.xcodeproj` with new files
- Register Firebase iOS app and replace `GoogleService-Info.plist` with real config
- Replace `GIDClientID` and `REVERSED_CLIENT_ID` in `project.yml` / `Info.plist`
- Create GitHub repo and push: `git remote add origin <url> && git push -u origin main`
- Test on a physical device to verify haptic feedback works correctly
- Add app icon (1024x1024 PNG to `Assets.xcassets/AppIcon.appiconset/`)

**Files changed**:

New files (5):
- `MobileCommander/Views/Developer/DevProjectDetailView.swift` - Project-scoped task list with progress, stats, and filtering
- `MobileCommander/Views/Developer/DevSpreadsheetView.swift` - Compact sortable table view of all tasks with horizontal scroll
- `MobileCommander/Views/Developer/DevQuotaView.swift` - Worker quota monitoring, cost overview, rate limit tracking
- `MobileCommander/Views/Owner/OwnerActivityView.swift` - Simplified activity timeline grouped by date with friendly language
- `MobileCommander/Views/Owner/OwnerChatListView.swift` - Aggregate chat/messages view showing active and past task conversations

Modified files (8):
- `MobileCommander/Design/DesignSystem.swift` - Added TimelineDot, QuickActionButton, CompactStatRow, SectionHeader, InlineEditField components
- `MobileCommander/Services/FirebaseService.swift` - Added updateTaskField, batchRetryFailed, batchDeleteTasks methods
- `MobileCommander/Views/ContentView.swift` - Owner mode now has 5 tabs (added Messages, Activity)
- `MobileCommander/Views/Developer/DevDashboardView.swift` - Navigable project cards, links to Quota and Spreadsheet views
- `MobileCommander/Views/Developer/DevTaskDetailView.swift` - Inline editing of project, path, description, priority, worker on Info tab
- `MobileCommander/Views/Developer/DevTaskListView.swift` - Multi-select mode with batch retry and batch delete
- `MobileCommander/Views/Owner/OwnerHomeView.swift` - Inline quick resolve buttons on attention cards, today timeline section
- `MobileCommander/Models/MockData.swift` - Added additional activity events for testing
