# FlutterFire CLI Setup Guide

## Installation

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Make sure it's in your PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

## Configure Your Project

```bash
cd /Users/kobvel/Workspace/Hacks/horizon_app_flutter

# Run FlutterFire configure
flutterfire configure
```

This will:
1. Show you a list of your Firebase projects
2. Select your **existing project** (the one from your Svelte app)
3. Choose the platforms (iOS, Android, Web, macOS)
4. Automatically generate `lib/firebase_options.dart` with all the correct values
5. Download and place platform-specific config files

## What It Does

✅ Creates `lib/firebase_options.dart` with your Firebase config
✅ Downloads `GoogleService-Info.plist` for iOS
✅ Downloads `google-services.json` for Android
✅ Updates Android build files with Google Services plugin
✅ Registers your Flutter app in Firebase Console

## After Configuration

Just run the app:

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

## Verification

After running `flutterfire configure`, you should see:
- `lib/firebase_options.dart` created
- `ios/Runner/GoogleService-Info.plist` created (if you selected iOS)
- `android/app/google-services.json` created (if you selected Android)

## Using the Same Firebase Project

When you run `flutterfire configure`, **select the same project** you're using for your Svelte app. This way:
- Both apps share the same authentication users
- Both apps access the same Firestore database
- No need to duplicate data or setup

## Troubleshooting

### "flutterfire: command not found"
Add to your `~/.zshrc`:
```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```
Then run: `source ~/.zshrc`

### "No projects found"
Run `firebase login` again and make sure you're logged into the correct Google account.

### Want to reconfigure?
Just run `flutterfire configure` again. It will overwrite the existing configuration.

## Next Steps

After configuration completes:
1. Open the app: `flutter run`
2. Sign in with the same email you use in the Svelte app (or create new account)
3. Create some events - they'll sync to Firestore!

That's it! 🚀
