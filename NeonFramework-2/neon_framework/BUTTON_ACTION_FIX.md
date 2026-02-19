# Button Action Listener Fix

## Problem
The `onPressed` action listeners were not working for buttons in the showcase app.

## Root Causes

### 1. Missing Keys
Buttons didn't have stable keys, making them hard to target from native apps.

### 2. Empty Callbacks
Many buttons had empty callbacks like `onPressed: () {}` which did nothing.

### 3. StatelessWidget in NavigationScreen
The `NavigationScreen` was a `StatelessWidget`, so even when callbacks were triggered, there was no state to update and no rebuild would occur.

## Fixes Applied

### 1. Added Keys to All Buttons (showcase.dart)
```dart
// BEFORE:
FilledButton(onPressed: () {}, child: const Text('Filled'))

// AFTER:
FilledButton(
  key: 'btn_filled',
  onPressed: () => print('Filled button pressed'),
  child: const Text('Filled'),
)
```

All buttons now have keys:
- `'btn_filled'`, `'btn_elevated'`, `'btn_outlined'`, `'btn_text'`

### 2. Made NavigationScreen Stateful (navigation_screen.dart)
```dart
// BEFORE:
class NavigationScreen extends NeonWidget { ... }

// AFTER:
class NavigationScreen extends StatefulWidget { ... }
class NavigationScreenState extends NeonState<NavigationScreen> {
  int tabIndex = 0;
  int navIndex = 0;
  
  // Now callbacks can call setState() to trigger rebuilds
}
```

Added keys:
- `'tab_bar'` for TabBar
- `'nav_bar'` for NavigationBar

### 3. Functional Callbacks
All interactive widgets now have proper callbacks that:
- Print debug messages (for testing)
- Call `setState()` to update state (for stateful widgets)
- Trigger visual updates

## How to Test from Native Apps

### Test Button Click
```bash
curl -X POST http://localhost:8080/action \
  -H "Content-Type: application/json" \
  -d '{"id": "btn_filled"}'
```

Expected console output:
```
📥 RECEIVED ACTION 📥
  Target ID: btn_filled
  Index:     null
  Value:     null
✅ Button found! Executing tap()...
Filled button pressed
🔄 Rebuilding tree after action...
```

### Test NavigationBar
```bash
curl -X POST http://localhost:8080/action \
  -H "Content-Type: application/json" \
  -d '{"id": "nav_bar", "index": 1}'
```

Expected: Navigation bar updates to index 1, content area changes.

### Test TabBar
```bash
curl -X POST http://localhost:8080/action \
  -H "Content-Type: application/json" \
  -d '{"id": "tab_bar", "index": 2}'
```

Expected: Tab bar updates to index 2, content changes to "Profile Content".

## Widget Keys Reference

### Showcase App (showcase.dart)
- Navigation: `'main_nav'`
- Buttons: `'btn_filled'`, `'btn_elevated'`, `'btn_outlined'`, `'btn_text'`
- Chips: `'action_chip'`, `'filter_chip'`
- Segmented: `'segmented_btn'`
- Controls: `'switch_notifications'`, `'checkbox_terms'`, `'radio_light'`, `'radio_dark'`
- Sliders: `'slider_volume'`, `'range_slider_price'`

### Navigation Screen (navigation_screen.dart)
- TabBar: `'tab_bar'`
- NavigationBar: `'nav_bar'`

## Debugging Tips

1. **Check Console Output**: When you send an action, you should see the "📥 RECEIVED ACTION 📥" message
2. **Verify Widget ID**: The framework logs the target ID - make sure it matches your key
3. **Look for Callback Execution**: You should see "✅ Button found!" or similar messages
4. **Check Rebuild**: After the action, you should see "🔄 Rebuilding tree after action..."

## Common Issues

### "Widget not found"
- The key doesn't match any widget in the tree
- Check the widget tree output to see actual IDs

### "Callback not triggered"
- Widget might not have an `onPressed` callback
- Check that the widget is interactive (not disabled)

### "No visual update"
- Widget might be in a StatelessWidget (no state to update)
- Convert to StatefulWidget if you need state changes
