# Horizon Calendar App - Features & Roadmap

## ⚠️ IMPORTANT: Keep Documentation Updated!

**When you add, remove, or change ANY feature, update these 3 files:**

1. ✅ **`/FEATURES_ROADMAP.md`** (this file) - Update the relevant section
2. ✅ **`/docs/user-flow.d2`** - Add/remove/update the diagram nodes
3. ✅ **`/CHANGELOG.md`** - Add entry with date and description

**These documents MUST stay synchronized with the actual codebase.**

See [/docs/README.md](/docs/README.md) for detailed update instructions and examples.

---

## Overview
Horizon is a Flutter-based calendar application with a focus on visual clarity, intuitive UX, and multi-day event management. Built with Firebase backend for authentication and data storage.

**📊 Visual Diagram:** See `/docs/user-flow.d2` for a comprehensive visual representation of user personas and app capabilities. [View instructions in `/docs/README.md`](/docs/README.md)

## Tech Stack
- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication)
- **State Management**: Provider
- **Authentication**: Google Sign-In, Firebase Auth
- **Platform**: macOS (primary), iOS/Android capable

---

## ✅ Implemented Features

### 1. Authentication System
- **Google Sign-In Integration**
  - macOS, iOS, Android support
  - Custom client ID configuration
  - Persistent authentication state
- **Anonymous Mode** (planned but not yet implemented)
- **Sign Out Functionality**

**Technical Notes:**
- Custom configuration for macOS Google Sign-In
- See `GOOGLE_SIGNIN_SETUP.md` for setup instructions

---

### 2. Calendar Management

#### Multiple Calendars
- **Create/Edit/Delete Calendars**
  - Custom names with emoji icons
  - 12 pre-defined color options (Horizon palette)
  - Auto-ordering system
- **Reorderable Calendar List**
  - Drag and drop reordering
  - Persistent order via Firestore
- **Event Count Display**
  - Shows number of events per calendar
  - Real-time updates

#### Calendar Filtering
- **Filter Chips Interface**
  - Horizontal scrollable chip list at top of screen
  - Toggle calendars on/off to filter events
  - Visual feedback with selection state
- **Auto-Selection on Creation**
  - New calendars automatically selected
  - Sheet stays open, auto-scrolls to new calendar
  - Smooth UX for rapid calendar creation

**Technical Notes:**
- Calendar order stored as numeric field in Firestore
- Filter state managed in `EventsProvider`
- Null state = show all, empty list = show none

---

### 3. Event Management

#### Event Creation & Editing
- **Rich Event Details**
  - Title with emoji picker (100+ emojis across categories)
  - Start and end date selection
  - Color customization (8 preset colors)
  - Calendar assignment via dropdown
- **Multi-Day Event Support**
  - Visual timeline spanning multiple cells
  - Event label only on start date
  - Colored border across entire duration
- **Smart Default Calendar**
  - Defaults to currently selected calendar filter
  - Falls back to first calendar if no filter active
  - Intelligent UX that matches user context

#### Event Display
- **Single-Day Events**
  - Stacked at bottom of cell
  - Shows up to 3 events per cell
  - Compact emoji + title format
- **Multi-Day Events**
  - Event title/label on start date only
  - Colored border spanning all days
  - Background tint on start cell
  - Title can extend up to 1.5 cells width

#### Event Interaction - **CRITICAL TAP HANDLING**
**Problem Solved:** Multi-day events were causing tap conflicts where clicking anywhere in the timeline would open edit form.

**Solution Architecture:**
1. **Visual Borders** - Wrapped in `IgnorePointer`, purely decorative
2. **Event Labels** - Have `GestureDetector` with `HitTestBehavior.opaque`
3. **Day Numbers/Visual Elements** - Wrapped in `IgnorePointer`
4. **Parent Cell** - Uses `HitTestBehavior.deferToChild` to defer to event labels
5. **Event Label Tap Area** - Increased with transparent padding for better touch targets

**Behavior:**
- Tap on event label → Edit event ✓
- Tap on empty cell space → Create new event ✓
- Tap on multi-day timeline (non-label area) → Create new event ✓
- Long press → Start drag selection ✓

**Code Location:** `/lib/widgets/calendar_day_cell.dart`

---

### 4. Drag Selection
- **Multi-Date Selection**
  - Long press to start
  - Drag across cells to select range
  - Visual feedback with blue highlight
  - Auto-opens event creation with selected range
- **Gesture Conflict Resolution**
  - Works alongside scrolling
  - Doesn't interfere with single taps
  - Cancels on invalid gesture

**Technical Notes:**
- Custom `DragSelectionManager` handles state
- Pointer position broadcast to all cells
- Visual selection state updated in real-time

---

### 5. Calendar UI/UX

#### Infinite Scrolling Calendar
- **Lazy Loading**
  - Loads 3 months before, 9 months after initially
  - Auto-loads 6 months when approaching edges
  - Maintains scroll position during prepend
- **Smart Scroll Restoration**
  - Calculates added height when prepending months
  - Preserves user's view position
- **Auto-Scroll Features**
  - "Today" button scrolls to current month
  - Creating event scrolls to event's month
  - Smooth animations (500ms ease-in-out)

#### Visual Design
- **Gradient Background**
  - Blue/purple/pink gradient
  - Subtle, non-distracting
- **Glassmorphic Floating Buttons**
  - Menu and Today buttons
  - Backdrop blur effect
  - Positioned at bottom with safe area
- **Color-Coded Events**
  - Calendar colors on event borders
  - Event-specific colors on labels
  - Visual hierarchy maintained
- **Weekend Highlighting**
  - Subtle blue tint on weekends
  - Today indicator with blue gradient circle
  - Past days with strike-through pattern

#### Week Start Preference
- **Settings Toggle**
  - Monday or Sunday start
  - Updates all calendar views
  - Persistent via provider

---

### 6. Bottom Sheet Forms

#### Keyboard Handling - **CRITICAL UX FIX**
**Problem Solved:** Keyboard covering Create/Update buttons in bottom sheets.

**Solution:**
1. **Dynamic Padding**
   - Detects keyboard height via `MediaQuery.of(context).viewInsets.bottom`
   - Adds extra bottom padding when keyboard appears
   - Formula: `bottomPadding > 0 ? bottomPadding + 24 : 24`
2. **DraggableScrollableSheet Config**
   - `snap: false` - Allows smooth dragging
   - High `initialChildSize` (0.85 for events, 0.75 for calendars)
   - Content scrollable even when keyboard visible
3. **ListView with KeyboardDismissBehavior**
   - `ScrollViewKeyboardDismissBehavior.onDrag`
   - User can scroll to reveal buttons
   - Can dismiss keyboard by dragging

**Best Practice:**
- Never use fixed padding, always dynamic based on keyboard height
- Content extends below keyboard, users can scroll to access
- Matches iOS Messages, WhatsApp, Instagram patterns

**Code Locations:**
- `/lib/widgets/event_form_bottom_sheet.dart`
- `/lib/widgets/calendar_form_bottom_sheet.dart`

#### Form Features
- **Validation**
  - Required fields marked
  - Inline error messages
- **Success Feedback**
  - SnackBar confirmations
  - Colored (green for create, blue for update)
  - Auto-dismiss after 1-2 seconds
- **Auto-Selection on Event Creation**
  - Calendar auto-selected if not in filter
  - View scrolls to event's month
  - Returns date to parent for scroll coordination

---

### 7. Data Architecture

#### Firebase Structure
```
/users/{userId}
  - uid
  - email
  - displayName
  - photoURL

/calendars/{calendarId}
  - ownerId
  - name
  - emoji
  - color (hex string)
  - order (numeric for sorting)
  - createdAt

/events/{eventId}
  - userId
  - title
  - calendarId
  - emoji
  - categoryColor (hex string)
  - dateStart (object: year, month, date)
  - dateEnd (object: year, month, date)
  - shared (boolean)
  - sharedWithUserIds (array)
  - sharedWithEmails (array)
```

#### State Management
- **Providers**
  - `AuthProvider` - User authentication state
  - `EventsProvider` - Events list, filtering
  - `CalendarsProvider` - Calendars list, ordering
  - `SettingsProvider` - User preferences
- **Real-time Listeners**
  - Firestore streams for live updates
  - Auto-refresh on data changes

**Technical Notes:**
- Custom date model (`DateProps`) for 0-indexed months
- Events filtered in provider based on selected calendars
- Null filter state = show all (initial), empty list = show none

---

## 🔧 Technical Solutions & Patterns

### 1. Event Tap Detection (Detailed Documentation)
See "Event Interaction - CRITICAL TAP HANDLING" section above for complete implementation details.

### 2. Calendar Auto-Selection Pattern
**Flow:**
1. User creates event with Calendar X
2. Event saved to Firestore
3. `EventsProvider.ensureCalendarSelected(calendarId)` called
4. If Calendar X not in filter → Add it
5. Form returns start date to parent
6. Calendar scrolls to event's month
7. User immediately sees their new event

### 3. Smart Default Calendar Selection
**Logic:**
```dart
if (selectedCalendarIds.isNotEmpty) {
  // Use first selected calendar
  defaultCalendarId = selectedCalendarIds.first;
} else {
  // Fall back to first calendar in list
  defaultCalendarId = calendars.first.id;
}
```

### 4. Infinite Scroll Implementation
- Monitor scroll position in `ScrollController` listener
- Load threshold: 50% of viewport from edge
- Batch load 6 months at a time
- Restore scroll position after prepending

---

## 🎨 Design System

### Color Palette (Horizon Theme)
- **Cerulean**: `#6f97b8`
- **Grape**: `#806d8c`
- **Turquoise**: `#83b7b8`
- **Green**: `#90a583`
- **Wildfire**: `#d4a373`
- **Rose**: `#c8a5b3`
- **Brick**: `#a39088`
- **Chrome**: `#d5d5d5`
- **Orange**: `#deb168`
- **Coral**: `#bc8a8d`
- **Slate**: `#8994a1`
- **Stone**: `#a8a196`

### Event Colors
- Blue: `#3B82F6`
- Red: `#EF4444`
- Green: `#10B981`
- Yellow: `#F59E0B`
- Purple: `#8B5CF6`
- Pink: `#EC4899`
- Teal: `#14B8A6`
- Orange: `#F97316`

---

## 📋 Future Features

This section is reserved for features you want to build. Add your ideas here as you plan the app's evolution.

### Ideas / Backlog
- [ ] _(Add your planned features here)_

### Known Issues / Tech Debt
- [ ] _(Document any bugs or improvements needed)_

---

## 🔄 Recent Updates

### Latest Session (2025-10-21)
- ✅ Fixed event tap handling for multi-day events
- ✅ Implemented auto-selection of calendar after event creation
- ✅ Added scroll-to-event-month after creation
- ✅ Smart default calendar selection based on filter
- ✅ Improved bottom sheet heights for better button visibility
- ✅ Fixed keyboard UX in event/calendar forms
- ✅ Added event count display on calendars
- ✅ Keep calendar sheet open after creation with auto-scroll

### Previous Sessions
- ✅ Calendar reordering with drag and drop
- ✅ Multi-calendar management system
- ✅ Calendar filter chips UI
- ✅ Infinite scrolling calendar
- ✅ Drag selection for multi-day events
- ✅ Google Sign-In integration
- ✅ Basic event CRUD operations

---

## 📝 Development Notes

### Important Files
- `/lib/widgets/calendar_day_cell.dart` - **Critical:** Event tap handling logic
- `/lib/widgets/event_form_bottom_sheet.dart` - Event creation/editing, keyboard handling
- `/lib/widgets/calendar_form_bottom_sheet.dart` - Calendar management, keyboard handling
- `/lib/widgets/app_drawer.dart` - Calendar list with reordering
- `/lib/screens/calendar_screen.dart` - Main calendar view, infinite scroll
- `/lib/providers/events_provider.dart` - Event state, filtering logic
- `/lib/providers/calendars_provider.dart` - Calendar state, ordering
- `/lib/utils/drag_selection_manager.dart` - Multi-day selection logic

### Setup Requirements
1. Firebase project configuration (`google-services.json`, `GoogleService-Info.plist`)
2. Google Sign-In client IDs (see `GOOGLE_SIGNIN_SETUP.md`)
3. Flutter SDK (latest stable)
4. Xcode (for macOS/iOS builds)

### Development Commands
```bash
# Run on macOS
flutter run -d macos

# Clean build
flutter clean && flutter pub get

# Generate icons
flutter pub run flutter_launcher_icons

# Build release
flutter build macos --release
```

---

## 🎯 Success Metrics

### User Experience Goals
- **Event Creation**: < 5 seconds from tap to event visible
- **Calendar Switching**: Instant filter response (< 100ms)
- **Scroll Performance**: 60fps even with 100+ events
- **Tap Accuracy**: 99%+ correct tap detection on event labels

### Code Quality Goals
- Zero runtime errors in production
- < 500ms Firebase response times
- Proper memory management (no leaks)
- Comprehensive error handling

---

## 🤝 Contributing Notes

### Code Style
- Follow Flutter/Dart conventions
- Use `const` constructors where possible
- Prefer composition over inheritance
- Keep widgets small and focused

### Git Workflow
- Feature branches from `main`
- Descriptive commit messages
- Reference issue numbers in commits

### Testing Checklist
- [ ] Test on multiple screen sizes
- [ ] Test with 0 calendars, 1 calendar, 10+ calendars
- [ ] Test with 0 events, 1 event, 100+ events
- [ ] Test multi-day events spanning weeks/months
- [ ] Test keyboard interactions in all forms
- [ ] Test drag selection edge cases
- [ ] Test Google Sign-In flow

---

**Last Updated:** 2025-10-21
**Version:** 1.0.0-beta
**Maintainer:** Development Team
