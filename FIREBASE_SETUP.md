# Firebase Setup Guide (Manual Configuration)

Since FlutterFire CLI is not available, follow these steps to manually configure Firebase:

## Step 1: Get Your Existing Firebase Project Info

You already have a Firebase project from your Svelte app. We'll use the same one.

### Option A: Copy from Existing Svelte App

If you have the Svelte app's Firebase config, you can find it in:
- `Horizon App/frontend/src/services/firebaseClient/client.ts` or similar

The config looks like:
```javascript
const firebaseConfig = {
  apiKey: "...",
  authDomain: "...",
  projectId: "...",
  storageBucket: "...",
  messagingSenderId: "...",
  appId: "..."
};
```

### Option B: Get from Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your existing project
3. Click the gear icon ⚙️ > **Project Settings**
4. Scroll down to **Your apps** section

#### For iOS:
1. Click the iOS icon to add an iOS app (or select existing)
2. Bundle ID: `com.horizon.horizonApp`
3. Download `GoogleService-Info.plist`
4. Move it to: `horizon_app_flutter/ios/Runner/GoogleService-Info.plist`

#### For Android:
1. Click the Android icon to add an Android app (or select existing)
2. Package name: `com.horizon.horizon_app`
3. Download `google-services.json`
4. Move it to: `horizon_app_flutter/android/app/google-services.json`

#### For Web (if needed):
1. Click the web icon `</>`
2. Register app, then copy the config

## Step 2: Update firebase_options.dart

Open `lib/firebase_options.dart` and replace the placeholder values with your actual Firebase config:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_WEB_API_KEY',           // From Firebase Console
  appId: 'YOUR_ACTUAL_WEB_APP_ID',             // From Firebase Console
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID', // From Firebase Console
  projectId: 'your-project-id',                 // Your Firebase project ID
  authDomain: 'your-project-id.firebaseapp.com',
  storageBucket: 'your-project-id.appspot.com',
);

static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',              // From google-services.json
  appId: 'YOUR_ANDROID_APP_ID',                // From google-services.json
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'your-project-id',
  storageBucket: 'your-project-id.appspot.com',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',                  // From GoogleService-Info.plist
  appId: 'YOUR_IOS_APP_ID',                    // From GoogleService-Info.plist
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'your-project-id',
  storageBucket: 'your-project-id.appspot.com',
  iosBundleId: 'com.horizon.horizonApp',
);
```

### Quick Reference - Where to Find Values:

**From Firebase Console (Web config):**
- Go to Project Settings > General > Your apps
- Click on web app or "Add app" > Web
- Copy the config object values

**From `google-services.json` (Android):**
```json
{
  "project_info": {
    "project_id": "YOUR_PROJECT_ID"
  },
  "client": [{
    "client_info": {
      "mobilesdk_app_id": "YOUR_ANDROID_APP_ID"
    },
    "api_key": [{
      "current_key": "YOUR_ANDROID_API_KEY"
    }]
  }],
  "project_number": "YOUR_MESSAGING_SENDER_ID"
}
```

**From `GoogleService-Info.plist` (iOS):**
```xml
<key>API_KEY</key>
<string>YOUR_IOS_API_KEY</string>
<key>GOOGLE_APP_ID</key>
<string>YOUR_IOS_APP_ID</string>
<key>GCM_SENDER_ID</key>
<string>YOUR_MESSAGING_SENDER_ID</string>
<key>STORAGE_BUCKET</key>
<string>YOUR_PROJECT_ID.appspot.com</string>
```

## Step 3: Configure Android (if targeting Android)

### 3a. Add Google Services Plugin

Edit `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

### 3b. Apply Plugin

Edit `android/app/build.gradle`:
```gradle
// At the bottom of the file, add:
apply plugin: 'com.google.gms.google-services'
```

## Step 4: Configure iOS (if targeting iOS)

The `GoogleService-Info.plist` file should be in `ios/Runner/` directory.

That's it! iOS should work automatically.

## Step 5: Verify Firestore Rules

Make sure your Firestore security rules allow the Flutter app to read/write:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /events/{eventId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }

    match /calendars/{calendarId} {
      allow read, write: if request.auth != null && resource.data.ownerId == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.ownerId == request.auth.uid;
    }
  }
}
```

## Step 6: Test the App

```bash
cd horizon_app_flutter

# Run on iOS
flutter run -d ios

# Run on Android
flutter run -d android
```

## Troubleshooting

### "No Firebase App has been created"
- Make sure `firebase_options.dart` has the correct values
- Verify `main.dart` imports and initializes Firebase

### "API key not valid"
- Double-check the API key in `firebase_options.dart` matches Firebase Console
- Make sure you're using the correct platform's API key (iOS vs Android vs Web)

### Android build errors
- Ensure `google-services.json` is in `android/app/`
- Check that Google Services plugin is added to both `build.gradle` files

### iOS build errors
- Ensure `GoogleService-Info.plist` is in `ios/Runner/`
- Try cleaning: `cd ios && pod install && cd ..`
- Then: `flutter clean && flutter run`

## Quick Start (If you have the Svelte app's Firebase config)

1. Find your Firebase config from the Svelte app
2. Copy the values to `lib/firebase_options.dart`
3. Run: `flutter run`

That's it! The app will use the same Firebase project as your Svelte app, so all your existing data will be available.
