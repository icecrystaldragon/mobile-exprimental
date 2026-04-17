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

## 3. GitHub Remote Not Configured
**Status**: BLOCKED
**Impact**: Cannot push to GitHub
**Resolution**:
```bash
# Option 1: Use gh CLI
gh repo create mobile-exprimental --public --source=. --push

# Option 2: Create repo on github.com manually, then:
git remote add origin https://github.com/<user>/mobile-exprimental.git
git push -u origin main
```

## 4. XcodeGen Regeneration Needed After New Files
**Status**: BLOCKED (after this commit)
**Impact**: New Swift files (5 new views) won't appear in Xcode until project is regenerated
**Resolution**: Run `xcodegen generate` - the `project.yml` auto-includes all files under `MobileCommander/`
