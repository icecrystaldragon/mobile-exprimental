# Blocked Items

## 1. Xcode Not Installed
**Status**: BLOCKED
**Impact**: Cannot compile or run the iOS app
**Resolution**:
1. Install Xcode 16+ from the Mac App Store
2. Run `xcode-select -s /Applications/Xcode.app/Contents/Developer`
3. Run `xcodegen generate` to regenerate project with all 25 Swift files
4. Open `MobileCommander.xcodeproj` in Xcode
5. Wait for SPM to resolve Firebase and GoogleSignIn packages
6. Build for iOS Simulator (Cmd+B)

## 2. Firebase Configuration is Placeholder
**Status**: BLOCKED
**Impact**: App will crash on launch without real Firebase config
**Resolution**:
1. Go to Firebase Console > Project Settings > Add iOS app
2. Use bundle ID: `com.commander.mobile`
3. Download `GoogleService-Info.plist` and replace the placeholder file
4. Copy the `GIDClientID` from the plist into `project.yml` and `Info.plist`
5. Set `REVERSED_CLIENT_ID` (reverse the client ID segments)

## 3. GitHub Push
**Status**: RESOLVED
**Resolution**: Repo created and pushed to https://github.com/icecrystaldragon/mobile-exprimental
- Authenticated as `icecrystaldragon` via `gh auth login`
- Remote URL updated to HTTPS (was SSH under `palmr-jing`)
- All 7 commits pushed to `main` branch

Clone on macbook-air-3:
```bash
git clone https://github.com/icecrystaldragon/mobile-exprimental.git
```

## 4. XcodeGen Regeneration Needed After New Files
**Status**: BLOCKED (after this commit)
**Impact**: New Swift files (5 new views) won't appear in Xcode until project is regenerated
**Resolution**: Run `xcodegen generate` - the `project.yml` auto-includes all files under `MobileCommander/`
