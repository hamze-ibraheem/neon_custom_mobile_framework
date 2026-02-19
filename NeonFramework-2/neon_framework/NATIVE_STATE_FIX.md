# Native State & Action Event Fix

## Problem Summary
The states and action events were not functional in Android and iOS apps due to:
1. **Unstable Widget IDs**: Widget IDs were being generated with `.u` suffixes during unwrapping, making them unpredictable
2. **Missing Keys**: Interactive widgets in the showcase app lacked stable keys
3. **Type Conversion Issues**: Native apps send values as strings/numbers, but the framework expected specific types
4. **JSON Serialization Crash**: `double.infinity` values caused JSON encoding to fail

## Solutions Implemented

### 1. Fixed Widget ID Generation (`widget_tree.dart`)
**Problem**: The ID generation logic was appending `.u` to every unwrapped layer, creating IDs like `root.0.u.u` instead of using the widget's key.

**Solution**: Modified the unwrapping logic to preserve keys:
```dart
// BEFORE:
currentId = "${currentContext.id!}.u";

// AFTER:
if (builtResult.key == null || builtResult.key == currentWidget.key) {
  // Keep ID but update context for the new widget type
  currentContext = currentContext.spawn(builtResult, currentId);
} else {
  currentId = "${currentContext.id!}.${builtResult.key}";
  currentContext = currentContext.spawn(builtResult, currentId);
}
```

### 2. Added Stable Keys to Showcase App (`showcase.dart`)
Added explicit keys to all interactive widgets:
- `'action_chip'`, `'filter_chip'`, `'segmented_btn'`
- `'switch_notifications'`, `'checkbox_terms'`
- `'radio_light'`, `'radio_dark'`
- `'slider_volume'`, `'range_slider_price'`

### 3. Enhanced Action Handler (`neon_app.dart`)
**Added robust logging**:
```dart
print('\n📥 RECEIVED ACTION 📥');
print('  Target ID: $targetId');
print('  Index:     $index');
print('  Value:     $value');
```

**Improved type conversion**:
```dart
// Switch/Checkbox: Handle both bool and string/int values
final newVal = value is bool ? value : (value == 'true' || value == 1);
widget.onChanged?.call(newVal);

// Slider: Handle both num and string values
final newVal = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
widget.onChanged?.call(newVal);
```

### 4. Fixed JSON Serialization (`widget_tree.dart`)
**Problem**: `double.infinity` (used in `Container(width: double.infinity)`) cannot be JSON-encoded.

**Solution**: Added `_sanitizeDouble` helper:
```dart
dynamic _sanitizeDouble(double? value) {
  if (value == null) return null;
  if (value.isInfinite || value.isNaN) {
    return -1.0; // Sentinel value for native apps
  }
  return value;
}
```

Applied to all double properties: `width`, `height`, `left`, `top`, `right`, `bottom`, `value`, `min`, `max`, `start`, `end`.

### 5. Propagated Keys in M3 Widgets
Updated Material 3 button wrappers to pass keys down:
```dart
// FilledButton, ElevatedButton, OutlinedButton, TextButton, IconButton
return Button(
  key: key,  // ← Added this
  onPressed: onPressed,
  color: color,
  child: child,
);
```

## Testing

### Unit Tests
- ✅ `test/json_fix_test.dart`: Verifies `double.infinity` handling
- ✅ `test/m3_widgets_test.dart`: All M3 widgets (11 tests passing)
- ✅ `test/core_test.dart`: Full framework integration (343 tests passing)

### Integration Test
- `test/native_action_test.dart`: End-to-end test of native action flow

## How Native Apps Should Send Actions

### Button/Chip Click
```json
POST /action
{
  "id": "action_chip"
}
```

### Switch/Checkbox Toggle
```json
POST /action
{
  "id": "switch_notifications",
  "value": true
}
```

### Slider Change
```json
POST /action
{
  "id": "slider_volume",
  "value": 0.75
}
```

### RangeSlider Change
```json
POST /action
{
  "id": "range_slider_price",
  "start": 20.0,
  "end": 80.0
}
```

### Radio/SegmentedButton Selection
```json
POST /action
{
  "id": "segmented_btn",
  "index": 1
}
```

## Expected Response
After any action, the server responds with the updated widget tree JSON, including the new state values.

## Debugging Tips

1. **Check Widget IDs**: Look at the JSON response from `GET /` to see the actual IDs assigned
2. **Enable Logging**: The framework now logs all received actions with full details
3. **Verify Keys**: Ensure all interactive widgets have explicit `key` parameters
4. **Type Matching**: Native apps should send values in the correct type (bool for Switch, double for Slider, etc.)

## Next Steps for Native Apps

1. **Parse Initial State**: On app start, fetch `GET /` and parse the widget tree
2. **Render UI**: Use the widget types and properties to render native components
3. **Handle Interactions**: When user interacts, send POST to `/action` with the widget ID and new value
4. **Update UI**: Parse the response and update the native UI with the new state

## Files Modified
- `lib/src/widgets/widget_tree.dart`: ID generation, JSON serialization
- `lib/src/core/neon_app.dart`: Action handling, logging
- `lib/src/widgets/m3_buttons.dart`: Key propagation
- `lib/src/widgets/icon_button.dart`: Key propagation
- `my_2nd_test_app/lib/screens/showcase.dart`: Added stable keys
- `test/json_fix_test.dart`: New test file
- `test/native_action_test.dart`: New integration test
