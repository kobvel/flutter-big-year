# Google Sign-In Setup Instructions

Google Sign-In has been successfully integrated into the Horizon Calendar app. Follow the steps below to complete the configuration.

## What's Been Done

1. ✅ Added `google_sign_in: ^6.2.2` to `pubspec.yaml`
2. ✅ Updated `AuthProvider` with `signInWithGoogle()` method
3. ✅ Added Google Sign-In button to the auth screen
4. ✅ Configured iOS `Info.plist` with the required URL scheme
5. ✅ Verified Android configuration

## Required Steps to Complete Setup

### 1. Install Dependencies

Run the following command to install the new dependency:

```bash
flutter pub get
```

### 2. Firebase Console Configuration

You need to enable Google Sign-In in the Firebase Console:

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **deadliny-a8b76**
3. Navigate to **Authentication** > **Sign-in method**
4. Click on **Google** in the providers list
5. Toggle **Enable** to ON
6. Set the support email (your email address)
7. Click **Save**

### 3. Android Configuration

#### Add SHA-1 and SHA-256 Fingerprints to Firebase

For Google Sign-In to work on Android, you need to add your app's SHA fingerprints to Firebase:

**Get Debug SHA-1 fingerprint:**

```bash
cd android
./gradlew signingReport
```

Look for the SHA-1 and SHA-256 under the "debug" variant.

**Or use keytool directly:**

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Add to Firebase:**

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll to **Your apps** section
3. Select your Android app
4. Click **Add fingerprint**
5. Paste the SHA-1 fingerprint
6. Repeat for SHA-256 fingerprint
7. Download the updated `google-services.json` and replace the existing one in `android/app/google-services.json` (if needed)

#### Verify minSdkVersion

Ensure your `android/local.properties` or Flutter SDK settings have `minSdkVersion` of at least 21. This should be fine with the current Flutter version.

### 4. iOS Configuration

The iOS configuration has been completed automatically:

- ✅ `CFBundleURLTypes` added to `Info.plist` with the reversed client ID
- ✅ The client ID is from your existing `GoogleService-Info.plist`

**No additional steps needed for iOS**, but ensure you have:
- Xcode properly configured
- A valid bundle identifier matching: `com.horizon.horizonApp`

### 5. Test the Integration

1. Run `flutter pub get`
2. Rebuild the app:
   ```bash
   flutter run
   ```
3. On the auth screen, you should now see:
   - Email/Password fields
   - "Sign In" / "Sign Up" button
   - "OR" divider
   - "Continue with Google" button

4. Click "Continue with Google" and verify the flow works

## Code Structure

The implementation follows a clean architecture:

- **lib/providers/auth_provider.dart**: Contains the `signInWithGoogle()` method that handles the OAuth flow
- **lib/screens/auth_screen.dart**: UI with the Google Sign-In button
- **pubspec.yaml**: Dependencies configuration

## Troubleshooting

### Common Issues

**"PlatformException: sign_in_failed"**
- Ensure SHA-1/SHA-256 fingerprints are added to Firebase Console
- Verify Google Sign-In is enabled in Firebase Authentication
- Make sure you downloaded the latest `google-services.json`

**iOS: "Error 1000"**
- Verify the URL scheme in `Info.plist` matches the `REVERSED_CLIENT_ID` in `GoogleService-Info.plist`
- Clean and rebuild: `flutter clean && flutter run`

**"The application is not configured for Google Sign-In"**
- Verify the bundle ID (iOS) / application ID (Android) in your app matches what's configured in Firebase Console
- iOS: `com.horizon.horizonApp`
- Android: `com.horizon.horizon_app`

## Next Steps

After completing the Firebase Console setup and adding SHA fingerprints:

1. Run `flutter pub get`
2. Test on both iOS and Android devices/simulators
3. The Google Sign-In should work seamlessly alongside email/password authentication

---

**Note**: The signOut() method has been updated to sign out from both Firebase and Google, ensuring a clean logout experience.
