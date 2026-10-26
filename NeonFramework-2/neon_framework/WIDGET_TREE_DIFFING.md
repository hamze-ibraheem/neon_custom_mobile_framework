# Widget Tree Diffing & Patch Update System

## 1. Overview & Architecture

The Neon Framework features a production-ready **Widget Tree Diffing and Patch Update** engine. Rather than serializing and transmitting the complete widget tree across the HTTP bridge on every user interaction, Neon computes the delta between the previous and current serialized widget trees and transmits only the atomic patch operations required to update the UI.

This architecture delivers:
- **Up to 98% reduction in JSON payload size** for typical interactions (e.g. counter increments, form field edits, toggle switches).
- **In-place native view property updates** avoiding destructive view tear-downs.
- **Native view state preservation**: Text input focus, cursor position, selection, and scroll positions remain intact across state mutations.
- **Stable key preservation**: Views with unchanged types and stable keys are preserved in memory.
- **Deterministic revision tracking** with transactional application and full-tree fallback recovery.

---

## 2. Full-Tree vs. Patch Rendering

```
┌────────────────────────────────────────────────────────┐
│                   Initial Request                      │
│                  GET /api/tree                         │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│           Full Tree Response (Revision: 1)             │
│        { "type": "full", "version": 1, ... }           │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│      Subsequent Interaction: POST /action              │
│      Headers: X-Neon-Client-Revision: 1                │
└──────────────────────────┬─────────────────────────────┘
                           │
            ┌──────────────┴──────────────┐
     Revision match                Revision mismatch /
  (Client Rev == Base Rev)         Recovery requested
            │                             │
            ▼                             ▼
┌────────────────────────┐   ┌─────────────────────────┐
│     Patch Response     │   │   Full-Tree Fallback    │
│  type: "patch", rev: 2 │   │  type: "full", rev: n   │
│  ops: [update/replace] │   │  resets synchronization │
└────────────────────────┘   └─────────────────────────┘
```

---

## 3. Protocol & Response Format

### Patch Response (`type: "patch"`)
Emitted when diffing is enabled, a previous snapshot exists, and the client's `clientRevision` matches `revision - 1`.

```json
{
  "type": "patch",
  "version": 1,
  "revision": 2,
  "baseRevision": 1,
  "operations": [
    {
      "op": "update",
      "path": "/children/0",
      "properties": {
        "text": "Count: 1"
      }
    },
    {
      "op": "replace",
      "path": "/children/1",
      "value": {
        "id": "status_badge",
        "key": "badge_key",
        "type": "Badge",
        "label": "Active"
      }
    },
    {
      "op": "remove",
      "path": "/children/2"
    },
    {
      "op": "insert",
      "path": "/children/3",
      "value": {
        "id": "new_label",
        "type": "Text",
        "text": "Completed"
      }
    }
  ]
}
```

### Full-Tree Response (`type: "full"`)
Emitted on initial load (`GET /api/tree`), when diffing is disabled, on revision mismatch, or when recovery is requested.

```json
{
  "type": "full",
  "version": 1,
  "revision": 3,
  "fallbackReason": "revision_mismatch",
  "tree": {
    "id": "root",
    "type": "Column",
    "children": [ ... ]
  }
}
```

---

## 4. Supported Operations & Safe Ordering

| Operation | Target Path | Value / Payload | Behavior |
| :--- | :--- | :--- | :--- |
| `update` | RFC 6901 Pointer (`/children/0`) | `properties: { ... }` | Modifies existing native view attributes in place (text, color, state) without recreating view. |
| `replace` | RFC 6901 Pointer (`/children/1`) | `value: { ... }` | Removes old child and renders new widget hierarchy in place. Triggered when type or stable key changes. |
| `remove` | RFC 6901 Pointer (`/children/2`) | None | Removes child from parent view. Emitted in **descending index order** to prevent index shifts. |
| `insert` | RFC 6901 Pointer (`/children/3`) | `value: { ... }` | Inserts newly created child view at the target index. |

---

## 5. Configuration

Diffing is enabled by default and can be configured via `NeonConfig`:

```dart
NeonApp.run(
  const MyApp(),
  config: const NeonConfig(
    port: 8080,
    enableDiffing: true, // Set to false to force full-tree responses
  ),
);
```

You can also override diffing via `NeonFeatureFlags`:
```dart
config: NeonConfig(
  featureFlags: NeonFeatureFlags({'disable_diffing': true}),
)
```

---

## 6. Client Synchronization & Recovery Protocol

1. **Revision Tracking**: Clients track `lastAppliedRevision`, initialized to `revision` from the first `full` tree response.
2. **Request Headers & Payload**: Every `/action` request transmits:
   - Header: `X-Neon-Client-Revision: <lastAppliedRevision>`
   - Header: `X-Neon-Patch-Version: 1`
   - Body: `{"clientRevision": <lastAppliedRevision>, "patchVersion": 1}`
3. **Validation**: The client applies a patch if and only if `patch.baseRevision == lastAppliedRevision` and `patch.version == 1`.
4. **Stale / Out-of-Order Rejection**: If `baseRevision != lastAppliedRevision`, the client rejects the patch and sends a full tree recovery request (`GET /api/tree` or `POST /action` with `recovery: true`).
5. **Transactional Integrity**: If any native patch operation encounters an invalid path or type mismatch, the client immediately aborts the patch and initiates full-tree recovery.

---

## 7. Performance Benchmarks

Measured on a representative 79-node dashboard screen using `tool/benchmark_diff.dart`:

| Interaction Scenario | Full Tree Size | Patch Size | Reduction | Diff Time | View Reuse |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Small Update** (Single Label) | 7,223 bytes | 186 bytes | **97.4%** | ~4.1 ms | **98.7%** (0 recreated) |
| **Medium Update** (3 Properties) | 7,223 bytes | 250 bytes | **96.5%** | ~0.9 ms | **96.2%** (0 recreated) |
| **Large Update** (100 Items + Inserts) | 27,961 bytes | 349 bytes | **98.8%** | ~2.7 ms | **98.4%** (~5 recreated) |

---

## 8. Known Limitations & Best Practices

1. **Stable Keys for Dynamic Lists**: Always specify explicit `key` parameters for dynamic items in scrollable lists to ensure accurate reconciliation and avoid unneeded subtree recreation:
   ```dart
   Card(
     key: 'order_${order.id}',
     child: Text(order.title),
   )
   ```
2. **Dart State vs. Native State**: Dart owns application state (`NeonState`). Ephemeral view state (such as text field cursor positions) is preserved by in-place text replacement rather than view recreation.
3. **Complex Layout Restructuring**: When major layout containers alter their axes (e.g. Row to Column), the diff engine emits `replace` on the container node, safely rebuilding that subtree.
