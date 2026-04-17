# Blocked Items

## Cannot build — Xcode not installed

**What I tried:** Ran `xcodebuild` to compile the project after generating the .xcodeproj with XcodeGen.

**What went wrong:** Only Command Line Tools are installed at `/Library/Developer/CommandLineTools`. Full Xcode is required for iOS app compilation, SPM package resolution, and simulator testing.

**What you need to do:**
1. Install Xcode 16+ from the Mac App Store
2. Run `xcode-select -s /Applications/Xcode.app/Contents/Developer`
3. Open `MobileCommander.xcodeproj` in Xcode
4. Wait for SPM to resolve Firebase and Google Sign-In packages
5. Build for iOS Simulator (Cmd+B)

## GoogleService-Info.plist is a placeholder

**What I tried:** Used the Firebase project ID (`fir-web-codelab-8ace9`) from the Commander web app to create a placeholder config.

**What went wrong:** The iOS app needs its own registered iOS app entry in Firebase Console to get a real GoogleService-Info.plist with valid API keys and client IDs.

**What you need to do:**
1. Go to Firebase Console -> Project Settings -> Add App -> iOS
2. Enter bundle ID: `com.commander.mobile`
3. Download the generated GoogleService-Info.plist
4. Replace `MobileCommander/GoogleService-Info.plist` with the real file
5. Copy the `REVERSED_CLIENT_ID` from the real plist into `Info.plist`

## Cannot push to GitHub — repo needs to be created first

**Git remote is configured:** `origin -> git@github.com:palmr-jing/mobile-exprimental.git`

**What you need to do:**
```bash
# Option 1: Use gh CLI (recommended)
gh auth login
gh repo create mobile-exprimental --public --source=. --push

# Option 2: Create repo on github.com manually, then:
cd ~/repos/mobile-exprimental
git push -u origin main

# Option 3: Use the other GitHub account (jamesc-terminator)
git remote set-url origin git@github-m37:jamesc-terminator/mobile-exprimental.git
# (create repo on github.com under jamesc-terminator first)
git push -u origin main
```
