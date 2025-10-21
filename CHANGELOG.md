# Changelog

All notable changes to Horizon Calendar will be documented in this file.

## How to Use This File

**Every time you add, remove, or change a feature:**

1. Add an entry below under the appropriate heading (Added/Changed/Removed)
2. Include the date and a clear description
3. Also update:
   - `/FEATURES_ROADMAP.md`
   - `/docs/user-flow.d2`

---

## [Unreleased]

### Added
- *No pending additions*

### Changed
- *No pending changes*

### Removed
- *No pending removals*

---

## [2025-10-21] - Initial Documentation

### Added
- **Event Tap Handling Fix**
  - Fixed multi-day event tap detection issue
  - Only event labels are now tappable, not the entire timeline
  - Used `IgnorePointer`, `HitTestBehavior.deferToChild` pattern
  - Documented in FEATURES_ROADMAP.md

- **Auto-Selection Features**
  - Calendar auto-selected after creating event
  - View scrolls to event's month after creation
  - Smart default calendar based on current filter

- **Calendar Management UX**
  - Event count display on each calendar
  - Calendar sheet stays open after creation
  - Auto-scroll to newly created calendar

- **Bottom Sheet Improvements**
  - Increased initial height (0.85 for events, 0.75 for calendars)
  - Better visibility of action buttons
  - Keyboard handling with dynamic padding

- **Documentation**
  - Created FEATURES_ROADMAP.md
  - Created user flow diagram (user-flow.d2)
  - Added documentation maintenance guidelines

### Changed
- Event form now returns date for scroll coordination
- Firebase service returns event ID on creation
- Smart calendar selection in event form based on filter state

---

## Template for New Entries

```markdown
## [YYYY-MM-DD] - Brief Description

### Added
- **Feature Name**
  - What it does
  - Why it's useful
  - Any important technical details

### Changed
- **What Changed**
  - Before vs. after
  - Why the change was made

### Removed
- **What Was Removed**
  - Why it was removed
  - Impact on users
```

---

**Note:** This changelog follows [Keep a Changelog](https://keepachangelog.com/) principles.
