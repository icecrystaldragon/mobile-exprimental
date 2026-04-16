# Mobile Commander

iOS mobile frontend for [Commander](../experimental) — an autonomous AI task execution platform.

## Two Modes

### Developer Mode (5 tabs)
Full control over the entire Commander system:
- **Dashboard** — Stats grid, worker fleet, project progress, task overview
- **Tasks** — Filterable task list with search, create, retry, status management
- **Workers** — Worker fleet monitoring with quota, rate limits, heartbeat status
- **Activity** — Timeline of all system events with filtering
- **Settings** — Mode switch, account info, sign out

### Owner Mode (3 tabs)
Simplified interface for non-technical users (gym owners, etc.):
- **Home** — Status cards, active tasks, items needing attention, recent completions
- **New Task** — Simple form: pick a project, describe what you need, submit
- **Settings** — Mode switch, account info

## Setup

### Prerequisites
- Xcode 16+
- iOS 17+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Steps

1. **Clone the repo**
   ```bash
   git clone https://github.com/YOUR_USER/mobile-exprimental.git
   cd mobile-exprimental
   ```

2. **Download GoogleService-Info.plist**
   - Go to [Firebase Console](https://console.firebase.google.com) → Project `fir-web-codelab-8ace9`
   - Add an iOS app with bundle ID `com.commander.mobile`
   - Download the generated `GoogleService-Info.plist`
   - Replace `MobileCommander/GoogleService-Info.plist` with the real one

3. **Configure Google Sign-In**
   - In Firebase Console → Authentication → Sign-in method → Google → Enable
   - Copy the `CLIENT_ID` from your `GoogleService-Info.plist`
   - Update `Info.plist` with the `REVERSED_CLIENT_ID` value

4. **Generate Xcode project**
   ```bash
   xcodegen generate
   ```

5. **Open in Xcode**
   ```bash
   open MobileCommander.xcodeproj
   ```

6. **Resolve packages** — Xcode will automatically fetch Firebase and Google Sign-In SDKs

7. **Build and run** on simulator or device

## Architecture

```
MobileCommander/
├── Design/DesignSystem.swift       # Colors, typography, shared components
├── Models/
│   ├── Models.swift                # Data models (Task, Worker, etc.)
│   └── MockData.swift              # Sample data for previews
├── Services/
│   └── FirebaseService.swift       # Firestore CRUD, Auth, real-time listeners
├── Views/
│   ├── RootView.swift              # Auth gate
│   ├── LoginView.swift             # Google Sign-In
│   ├── ContentView.swift           # Mode router + tab views
│   ├── Developer/                  # Developer mode screens
│   ├── Owner/                      # Owner mode screens
│   └── Shared/SettingsView.swift   # Shared settings with mode switch
└── MobileCommanderApp.swift        # App entry point
```

## Firebase Collections

Connects to the same Firestore backend as the web Commander:
- `commander_tasks` — Task documents
- `commander_workers` — Worker status
- `commander_activity` — Activity audit log

## Tech Stack
- SwiftUI (iOS 17+)
- Firebase Auth + Firestore
- Google Sign-In
- XcodeGen for project generation
