# Horizon Calendar - Flutter

A beautiful calendar app built with Flutter, focusing on the main flow functionality of adding entries and viewing an infinite calendar with mobile-optimized calendar cells showing events.

## Features

✨ **Core Features Implemented:**
- **Infinite Calendar View** - Scrollable calendar that loads months dynamically
- **Mobile-First Calendar Grid** - Optimized calendar cells with event indicators
- **Add/Edit Events** - Simple event creation with date range selection
- **Event Display in Calendar** - Events shown as colored bars in calendar cells
- **Firebase Authentication** - Email/password authentication
- **Firebase Firestore** - Real-time event syncing
- **Responsive Design** - Works on both mobile and desktop

## Project Structure

```
lib/
├── models/
│   ├── event_model.dart       # Event data model with date handling
│   └── calendar_model.dart    # Calendar data model
├── providers/
│   ├── events_provider.dart   # State management for events
│   └── auth_provider.dart     # State management for authentication
├── services/
│   └── firebase_service.dart  # Firebase operations
├── screens/
│   ├── calendar_screen.dart   # Main infinite calendar view
│   ├── event_form_screen.dart # Add/edit event form
│   └── auth_screen.dart       # Sign in/sign up screen
├── widgets/
│   ├── calendar_grid.dart     # Calendar month grid component
│   └── calendar_day_cell.dart # Individual day cell with events
└── main.dart                  # App entry point
```

## Setup Instructions

### Prerequisites

- Flutter SDK (3.9.2 or later)
- Firebase project with Firestore and Authentication enabled
- iOS/Android development environment set up

### 1. Install Dependencies

```bash
cd horizon_app_flutter
flutter pub get
```

### 2. Firebase Setup

You can use your **existing Firebase project** from the Svelte app!

#### Quick Setup:

1. Open `lib/firebase_options.dart`
2. Replace placeholder values with your Firebase config
3. Get your config from:
   - Your Svelte app's Firebase config, OR
   - Firebase Console > Project Settings > Your apps

**Detailed instructions:** See [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

#### Minimum Required:

For iOS:
- Download `GoogleService-Info.plist` from Firebase Console
- Place in `ios/Runner/GoogleService-Info.plist`
- Update values in `lib/firebase_options.dart`

For Android:
- Download `google-services.json` from Firebase Console
- Place in `android/app/google-services.json`
- Update values in `lib/firebase_options.dart`
- Add Google Services plugin (see FIREBASE_SETUP.md)

### 3. Run the App

```bash
# For iOS
flutter run -d ios

# For Android
flutter run -d android
```

## Usage

### Creating an Event

1. **Sign in** or create an account
2. **Tap a date** on the calendar or use the **+ FAB** button
3. **Select emoji** and **color** for your event
4. **Enter title** and adjust date range if needed
5. **Tap "Create Event"**

### Viewing Events

- Events appear as **colored bars** at the bottom of calendar cells
- **Up to 3 events** are shown per day
- **Scroll infinitely** through months
- **Past days** are marked with X pattern

### Infinite Calendar

- **Mobile**: Loads 3 months initially, adds more as you scroll
- **Desktop**: Shows all 12 months of current year
- **"Show prev month"** button to load previous months
- **"Go to today"** button to jump to current date

## Technology Stack

- **Flutter 3.9.2** - UI framework
- **Firebase Core 3.6.0** - Firebase initialization
- **Firebase Auth 5.3.1** - Authentication
- **Cloud Firestore 5.4.4** - Database
- **Provider 6.1.1** - State management
- **Intl 0.19.0** - Date formatting

## License

ISC
