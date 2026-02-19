# State Update Implementation Guide for Native Apps

## Problem
The UI doesn't update on Android/iOS when buttons are clicked or state changes occur.

## Root Cause
The native apps need to:
1. Send the action to the Dart backend
2. **Wait for the response** containing the updated widget tree
3. **Parse the new JSON** and update the native UI

## How State Updates Work

### Flow Diagram
```
User clicks button in native app
    ↓
Native app sends POST /action with widget ID
    ↓
Dart backend finds widget and calls callback
    ↓
Callback calls setState() to update state
    ↓
Backend waits for microtask queue (setState completes)
    ↓
Backend rebuilds entire widget tree
    ↓
Backend serializes tree to JSON
    ↓
Backend sends JSON response back to native app
    ↓
Native app receives updated JSON
    ↓
Native app parses JSON and updates UI
```

## Testing State Updates

### 1. Test Counter Increment
```bash
# Get initial state
curl http://localhost:8080/

# Click increment button
curl -X POST http://localhost:8080/action \
  -H "Content-Type: application/json" \
  -d '{"id": "btn_increment"}'
```

**Expected Response:**
The JSON should contain updated counter value. Look for the Text widget showing the counter:
```json
{
  "id": "root.1.0.0.0",
  "type": "Text",
  "text": "Counter: 1"
}
```

### 2. Test Switch Toggle
```bash
curl -X POST http://localhost:8080/action \
  -H "Content-Type: application/json" \
  -d '{"id": "switch_test", "value": true}'
```

**Expected Response:**
```json
{
  "id": "switch_test",
  "type": "Switch",
  "value": true,
  "enabled": true
}
```

### 3. Test Slider Change
```bash
curl -X POST http://localhost:8080/action \
  -H "Content-Type: application/json" \
  -d '{"id": "slider_test", "value": 0.75}'
```

**Expected Response:**
```json
{
  "id": "slider_test",
  "type": "Slider",
  "value": 0.75,
  "min": 0.0,
  "max": 1.0
}
```

## Native App Implementation

### Android (Kotlin) Example

```kotlin
class NeonRenderer(private val context: Context) {
    private val client = OkHttpClient()
    private val baseUrl = "http://localhost:8080"
    
    // Store current widget tree
    private var widgetTree: JsonObject? = null
    
    // Fetch initial state
    suspend fun initialize() {
        val request = Request.Builder()
            .url(baseUrl)
            .get()
            .build()
            
        client.newCall(request).execute().use { response ->
            widgetTree = Json.parseToJsonElement(response.body!!.string()).jsonObject
            renderUI(widgetTree!!)
        }
    }
    
    // Send action and update UI
    suspend fun sendAction(widgetId: String, value: Any? = null, index: Int? = null) {
        val json = buildJsonObject {
            put("id", widgetId)
            value?.let { put("value", it) }
            index?.let { put("index", it) }
        }
        
        val request = Request.Builder()
            .url("$baseUrl/action")
            .post(json.toString().toRequestBody("application/json".toMediaType()))
            .build()
            
        client.newCall(request).execute().use { response ->
            // CRITICAL: Parse the response and update UI
            widgetTree = Json.parseToJsonElement(response.body!!.string()).jsonObject
            renderUI(widgetTree!!)
        }
    }
    
    // Render the UI from widget tree
    private fun renderUI(tree: JsonObject) {
        // Parse tree and create/update native views
        val rootView = parseWidget(tree)
        // Update your activity/fragment view
        activity.setContentView(rootView)
    }
    
    // Parse individual widget
    private fun parseWidget(widget: JsonObject): View {
        val type = widget["type"]?.jsonPrimitive?.content
        val id = widget["id"]?.jsonPrimitive?.content
        
        return when (type) {
            "Button" -> {
                Button(context).apply {
                    text = widget["text"]?.jsonPrimitive?.content
                    setOnClickListener {
                        // Send action when clicked
                        lifecycleScope.launch {
                            sendAction(id!!)
                        }
                    }
                }
            }
            "Switch" -> {
                SwitchCompat(context).apply {
                    isChecked = widget["value"]?.jsonPrimitive?.boolean ?: false
                    setOnCheckedChangeListener { _, isChecked ->
                        lifecycleScope.launch {
                            sendAction(id!!, value = isChecked)
                        }
                    }
                }
            }
            "Text" -> {
                TextView(context).apply {
                    text = widget["text"]?.jsonPrimitive?.content
                }
            }
            // ... handle other widget types
            else -> View(context)
        }
    }
}
```

### iOS (Swift) Example

```swift
class NeonRenderer {
    private let baseURL = "http://localhost:8080"
    private var widgetTree: [String: Any]?
    
    // Fetch initial state
    func initialize() async throws {
        let url = URL(string: baseURL)!
        let (data, _) = try await URLSession.shared.data(from: url)
        widgetTree = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        renderUI(widgetTree!)
    }
    
    // Send action and update UI
    func sendAction(widgetId: String, value: Any? = nil, index: Int? = nil) async throws {
        var json: [String: Any] = ["id": widgetId]
        if let value = value { json["value"] = value }
        if let index = index { json["index"] = index }
        
        let url = URL(string: "\(baseURL)/action")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: json)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // CRITICAL: Parse response and update UI
        widgetTree = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        renderUI(widgetTree!)
    }
    
    // Render UI from widget tree
    private func renderUI(_ tree: [String: Any]) {
        let rootView = parseWidget(tree)
        // Update your view controller
        viewController.view = rootView
    }
    
    // Parse individual widget
    private func parseWidget(_ widget: [String: Any]) -> UIView {
        let type = widget["type"] as? String
        let id = widget["id"] as? String
        
        switch type {
        case "Button":
            let button = UIButton()
            button.setTitle(widget["text"] as? String, for: .normal)
            button.addAction(UIAction { _ in
                Task {
                    try? await self.sendAction(widgetId: id!)
                }
            }, for: .touchUpInside)
            return button
            
        case "Switch":
            let toggle = UISwitch()
            toggle.isOn = widget["value"] as? Bool ?? false
            toggle.addAction(UIAction { _ in
                Task {
                    try? await self.sendAction(widgetId: id!, value: toggle.isOn)
                }
            }, for: .valueChanged)
            return toggle
            
        case "Text":
            let label = UILabel()
            label.text = widget["text"] as? String
            return label
            
        default:
            return UIView()
        }
    }
}
```

## Key Points for Native Apps

### ✅ DO:
1. **Always wait for the response** from `/action` endpoint
2. **Parse the entire response** - it contains the updated widget tree
3. **Update your entire UI** based on the new tree (or diff and update changed widgets)
4. **Store the widget tree** so you can reference it later
5. **Handle async operations** properly (use coroutines/async-await)

### ❌ DON'T:
1. Don't ignore the response from `/action`
2. Don't only update the clicked widget - the entire tree might have changed
3. Don't cache widget state locally - the Dart backend is the source of truth
4. Don't send actions without waiting for the response

## Debugging

### Check Dart Console
When you send an action, you should see:
```
📥 RECEIVED ACTION 📥
  Target ID: btn_increment
  Value:     null
✅ Button found! Executing tap()...
⏳ Waiting for setState to complete...
🔄 Rebuilding tree after action...

═════════════ 🔄 NEON REBUILD FRAME ═══════════════
📦 StateTestApp [id: root]
│   ├── Text [id: root.1.0.0.0]: "Counter: 1"
...
═══════════════════════════════════════════════════════
```

### Verify JSON Response
The response should contain the updated values:
```bash
curl -X POST http://localhost:8080/action \
  -H "Content-Type: application/json" \
  -d '{"id": "btn_increment"}' | jq '.children[] | select(.type=="Text" and (.text | contains("Counter")))'
```

Should show: `"text": "Counter: 1"` (or whatever the new value is)

## Common Issues

### Issue: UI doesn't update
**Cause**: Native app isn't parsing the response
**Fix**: Make sure you're reading and parsing the response body from `/action`

### Issue: State resets on every action
**Cause**: Widget IDs are changing between rebuilds
**Fix**: Ensure all stateful widgets have stable `key` parameters

### Issue: Wrong state shown
**Cause**: Native app is caching old state
**Fix**: Always use the state from the latest response, don't cache locally

### Issue: Delayed updates
**Cause**: Network latency or slow JSON parsing
**Fix**: Show loading indicator while waiting for response

## Test App

A simple test app is available at `my_2nd_test_app/lib/state_test.dart`. Run it with:
```bash
dart run my_2nd_test_app/lib/state_test.dart
```

Then test with curl commands above to verify state updates work correctly.
