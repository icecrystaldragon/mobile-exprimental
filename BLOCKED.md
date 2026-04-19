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

## 3. GitHub Push: Needs Auth Re-login
**Status**: BLOCKED — `gh` CLI token expired, needs interactive browser login
**Impact**: Cannot create repo or push to GitHub
**What was tried**: SSH works (authenticates as `palmr-jing`), but the repo `palmr-jing/mobile-exprimental` doesn't exist on GitHub. Creating it requires `gh` API access, and the token for `realeverbor` is invalid/expired. Device code auth was attempted but requires user to complete browser flow.
**Resolution** (run from this directory):
```bash
./push-to-github.sh
```
Or manually:
```bash
gh auth login --hostname github.com --git-protocol ssh --web
gh repo create mobile-exprimental --public --source=. --push
```
Then on macbook-air-3:
```bash
git clone git@github.com:<your-username>/mobile-exprimental.git
```

## 4. XcodeGen Regeneration Needed After New Files
**Status**: BLOCKED (after this commit)
**Impact**: New Swift files (5 new views) won't appear in Xcode until project is regenerated
**Resolution**: Run `xcodegen generate` - the `project.yml` auto-includes all files under `MobileCommander/`
