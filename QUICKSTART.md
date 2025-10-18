# Quick Start Guide

## TL;DR - Get Running in 3 Steps

### 1. Install Dependencies
```bash
cd horizon_app_flutter
flutter pub get
```

### 2. Configure Firebase

**Copy from your Svelte app:**

Find the Firebase config in your Svelte app (likely in `frontend/src/services/firebaseClient/client.ts`), then update `lib/firebase_options.dart` with those values.

**OR get from Firebase Console:**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ > Project Settings
4. Under "Your apps", copy the config values
5. Paste into `lib/firebase_options.dart`

### 3. Run
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

## What You Get

✅ **Infinite scrolling calendar** - swipe through unlimited months
✅ **Event creation** - tap a date or use the + button
✅ **Event display** - colored bars show up to 3 events per day
✅ **Firebase auth** - email/password sign in
✅ **Real-time sync** - events sync across devices instantly

## First Time Using the App

1. **Sign up** with email/password
2. **Tap any date** to create your first event
3. **Choose emoji** and **color**
4. **Enter title** and tap "Create Event"
5. Your event appears as a colored bar in the calendar! 🎉

## Project Location

The Flutter app is in: `/Users/kobvel/Workspace/Hacks/horizon_app_flutter`

Completely separate from your Svelte app, but uses the **same Firebase backend**!

## Key Features

- **Mobile-first** design with optimized calendar grid
- **Infinite scroll** - keeps loading months as you scroll
- **Responsive** - works on both mobile and desktop
- **Weekend highlighting** - weekends shown in light blue
- **Past days marked** - X pattern over past dates
- **Today indicator** - blue border around today
- **Multi-day events** - select date ranges

## Need Help?

- **Full setup:** See [README.md](README.md)
- **Firebase config:** See [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
- **Troubleshooting:** Check the Troubleshooting section in FIREBASE_SETUP.md

## File Structure

```
lib/
├── main.dart                    ← App entry point
├── firebase_options.dart        ← UPDATE THIS with your Firebase config
├── models/                      ← Data models
├── providers/                   ← State management
├── services/                    ← Firebase operations
├── screens/                     ← Main screens
└── widgets/                     ← Reusable components
```

## What's Different from Svelte App?

This Flutter version focuses on **core calendar functionality**:

✅ Implemented:
- Infinite calendar
- Event CRUD
- Mobile calendar grid
- Firebase auth & sync

📋 Simplified (for MVP):
- Calendar selection (uses 'general')
- Friend sharing
- Onboarding
- AI features
- Connections

All the data models are compatible though, so you can add these features later!

## Next Steps

Want to extend the app? Check out the "Extending the App" section in README.md for ideas on:
- Adding calendar selection
- Multi-day date range selection
- Event details view
- Todo items within events

Happy coding! 🚀
