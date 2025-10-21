# Horizon Calendar - Documentation

## ⚠️ IMPORTANT: Keeping Documentation In Sync

**Whenever you add, remove, or change a feature, you MUST update ALL 3 files:**

1. **`/docs/user-flow.d2`** - Add/remove/update the corresponding node and connections
2. **`/FEATURES_ROADMAP.md`** - Document the feature in the "Implemented Features" section
3. **`/CHANGELOG.md`** - Add a dated entry describing what changed

**All three files must stay synchronized** - If you implement a feature, it should appear in all three places

### When Adding a Feature:
1. ✅ Implement the feature in code
2. ✅ Add a node in `user-flow.d2` with connections showing user flow
3. ✅ Document it in `FEATURES_ROADMAP.md` under the appropriate section
4. ✅ Add entry to `CHANGELOG.md` under "Added" with date and description

### When Removing a Feature:
1. ✅ Remove from codebase
2. ✅ Remove the node from `user-flow.d2`
3. ✅ Remove from `FEATURES_ROADMAP.md`
4. ✅ Add entry to `CHANGELOG.md` under "Removed" explaining why

### When Changing a Feature:
1. ✅ Update the code
2. ✅ Update the node description in `user-flow.d2`
3. ✅ Update the feature description in `FEATURES_ROADMAP.md`
4. ✅ Add entry to `CHANGELOG.md` under "Changed" explaining what and why

**Why this matters:** These documents are your single source of truth for what the app does. Outdated docs are worse than no docs!

---

## Diagrams

### User Flow Diagram (`user-flow.d2`)

A simple business flowchart showing:
- What users can do in the app
- All available actions and features
- Clear branching for user choices
- No technical jargon

### How to View

#### Option 1: Online (Quickest)
1. Visit [D2 Playground](https://play.d2lang.com/)
2. Copy the contents of `user-flow.d2`
3. Paste into the playground
4. View the rendered diagram

#### Option 2: VS Code Extension
1. Install [D2 extension](https://marketplace.visualstudio.com/items?itemName=terrastruct.d2) in VS Code
2. Open `user-flow.d2`
3. Use the preview pane to view

#### Option 3: CLI (Generate SVG/PNG)
```bash
# Install D2
brew install d2  # macOS
# or
curl -fsSL https://d2lang.com/install.sh | sh -s --

# Generate SVG
d2 user-flow.d2 user-flow.svg

# Generate PNG
d2 user-flow.d2 user-flow.png

# With specific layout engine (elk, dagre, tala)
d2 --layout elk user-flow.d2 user-flow.svg
```

### Diagram Sections

1. **Authentication** - Google Sign-In flow
2. **Calendar View** - Main interface features
3. **Calendar Management** - Create, edit, delete, reorder, filter
4. **Event Management** - Create, edit, delete, single/multi-day
5. **Drag Selection** - Multi-date selection flow
6. **Critical UX Solutions** - Documented fixes for tap handling, keyboard, auto-selection
7. **Firebase Backend** - Data structure and real-time sync
8. **Implementation Notes** - Key technical details

### Updating the Diagram

#### Example: Adding a New Feature

**Scenario:** You just added a "Share Event" feature.

1. **Add the node** in the "Manage Events" section:
```d2
share_event: Share Event {
  shape: rectangle
  description: "Send event to others"
}
```

2. **Connect it to the flow:**
```d2
manage_events -> share_event: Can share
```

3. **Add sub-actions if needed:**
```d2
share_email: Share via Email {
  shape: rectangle
}

share_link: Copy Share Link {
  shape: rectangle
}

share_event -> share_email: Option 1
share_event -> share_link: Option 2
```

4. **Test it:** Paste the entire updated file into https://play.d2lang.com/ to verify it renders correctly

5. **Update FEATURES_ROADMAP.md** with the same feature details

#### Tips for Good Diagrams:
- Use **rectangles** for actions/features
- Use **diamonds** for decisions/choices
- Use **ovals** for start/end points
- Use **pages** for forms/screens
- Keep descriptions short (1-2 lines max)
- Use color coding from the Horizon palette (see below)

### Color Coding

Sections use colors from the Horizon palette:
- **User**: Cerulean (#6f97b8)
- **Authentication**: Turquoise (#83b7b8)
- **Calendar View**: Green (#90a583)
- **Calendar Management**: Grape (#806d8c)
- **Event Management**: Wildfire (#d4a373)
- **Drag Selection**: Rose (#c8a5b3)
- **UX Solutions**: Orange (#deb168)
- **Firebase**: Brick (#a39088)

---

**Last Updated:** 2025-10-21
