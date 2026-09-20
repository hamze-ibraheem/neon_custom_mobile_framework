import 'dart:convert';

/// Represents an atomic patch operation on the widget tree.
class PatchOperation {
  /// The operation type: 'update', 'replace', 'remove', or 'insert'.
  final String op;

  /// The JSON Pointer path to the target node or child (e.g. '', '/children/0').
  final String path;

  /// Property changes when [op] is 'update'.
  final Map<String, dynamic>? properties;

  /// Serialized widget subtree when [op] is 'replace' or 'insert'.
  final Map<String, dynamic>? value;

  const PatchOperation({
    required this.op,
    required this.path,
    this.properties,
    this.value,
  });

  /// Factory for an 'update' operation on properties.
  factory PatchOperation.update(String path, Map<String, dynamic> properties) {
    return PatchOperation(
      op: 'update',
      path: path,
      properties: Map<String, dynamic>.unmodifiable(properties),
    );
  }

  /// Factory for a 'replace' operation on an entire subtree.
  factory PatchOperation.replace(String path, Map<String, dynamic> value) {
    return PatchOperation(
      op: 'replace',
      path: path,
      value: Map<String, dynamic>.unmodifiable(value),
    );
  }

  /// Factory for a 'remove' operation.
  factory PatchOperation.remove(String path) {
    return PatchOperation(
      op: 'remove',
      path: path,
    );
  }

  /// Factory for an 'insert' operation.
  factory PatchOperation.insert(String path, Map<String, dynamic> value) {
    return PatchOperation(
      op: 'insert',
      path: path,
      value: Map<String, dynamic>.unmodifiable(value),
    );
  }

  /// Deserializes a [PatchOperation] from a JSON map.
  factory PatchOperation.fromJson(Map<String, dynamic> json) {
    return PatchOperation(
      op: json['op'] as String,
      path: json['path'] as String,
      properties: json['properties'] != null
          ? Map<String, dynamic>.from(json['properties'] as Map)
          : null,
      value: json['value'] != null
          ? Map<String, dynamic>.from(json['value'] as Map)
          : null,
    );
  }

  /// Serializes the operation to a JSON map.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {
      'op': op,
      'path': path,
    };
    if (properties != null) {
      result['properties'] = properties;
    }
    if (value != null) {
      result['value'] = value;
    }
    return result;
  }

  @override
  String toString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchOperation &&
          runtimeType == other.runtimeType &&
          op == other.op &&
          path == other.path &&
          jsonEncode(properties) == jsonEncode(other.properties) &&
          jsonEncode(value) == jsonEncode(other.value);

  @override
  int get hashCode =>
      op.hashCode ^
      path.hashCode ^
      jsonEncode(properties).hashCode ^
      jsonEncode(value).hashCode;
}

/// A versioned container of patch operations transitioning the UI from
/// [baseRevision] to [revision].
class WidgetTreePatch {
  /// Always 'patch' to distinguish from full tree responses.
  final String type;

  /// The protocol version of this patch (currently 1).
  final int version;

  /// Monotonically increasing revision resulting from applying this patch.
  final int revision;

  /// The revision the client must currently be at to safely apply this patch.
  final int baseRevision;

  /// List of operations to apply sequentially.
  final List<PatchOperation> operations;

  const WidgetTreePatch({
    this.type = 'patch',
    this.version = 1,
    required this.revision,
    required this.baseRevision,
    required this.operations,
  });

  /// Deserializes a [WidgetTreePatch] from a JSON map.
  factory WidgetTreePatch.fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'patch') {
      throw FormatException(
          'Expected patch response with type="patch", received "${json['type']}"');
    }
    final int version = json['version'] as int? ?? 1;
    final int revision = json['revision'] as int;
    final int baseRevision = json['baseRevision'] as int;
    final rawOps = json['operations'] as List<dynamic>? ?? [];
    final operations = rawOps
        .map((op) => PatchOperation.fromJson(Map<String, dynamic>.from(op as Map)))
        .toList();

    return WidgetTreePatch(
      version: version,
      revision: revision,
      baseRevision: baseRevision,
      operations: operations,
    );
  }

  /// Serializes the patch to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'version': version,
      'revision': revision,
      'baseRevision': baseRevision,
      'operations': operations.map((op) => op.toJson()).toList(),
    };
  }

  /// Whether this patch contains no changes.
  bool get isEmpty => operations.isEmpty;

  /// Whether this patch contains one or more operations.
  bool get isNotEmpty => operations.isNotEmpty;

  @override
  String toString() => jsonEncode(toJson());
}

/// Pure Dart diffing engine for comparing serialized Neon widget trees.
class NeonWidgetTreeDiff {
  /// Compares [oldTree] and [newTree] and returns a [WidgetTreePatch].
  ///
  /// Uses stable widget keys when present, and positional matching when keys are absent.
  /// Never reuses a widget whose type or key has changed.
  static WidgetTreePatch diff(
    Map<String, dynamic> oldTree,
    Map<String, dynamic> newTree, {
    required int revision,
    required int baseRevision,
  }) {
    final List<PatchOperation> ops = [];
    _diffNode(oldTree, newTree, '', ops);

    return WidgetTreePatch(
      revision: revision,
      baseRevision: baseRevision,
      operations: List<PatchOperation>.unmodifiable(ops),
    );
  }

  /// Recursive node diff implementation.
  static void _diffNode(
    Map<String, dynamic> oldNode,
    Map<String, dynamic> newNode,
    String currentPath,
    List<PatchOperation> ops,
  ) {
    final String? oldType = oldNode['type'] as String?;
    final String? newType = newNode['type'] as String?;
    final String? oldKey = _extractKey(oldNode);
    final String? newKey = _extractKey(newNode);

    // If type or key changes, widget identity is broken: replace the node.
    if (oldType != newType || oldKey != newKey) {
      ops.add(PatchOperation.replace(currentPath, _deepCopy(newNode)));
      return;
    }

    // Compare properties on the current node.
    final Map<String, dynamic> propertyDiff = _diffProperties(oldNode, newNode);
    if (propertyDiff.isNotEmpty) {
      ops.add(PatchOperation.update(currentPath, propertyDiff));
    }

    // Compare children.
    _diffChildren(
      _extractChildren(oldNode),
      _extractChildren(newNode),
      currentPath,
      ops,
    );
  }

  /// Extracts key or stable identifier if present.
  static String? _extractKey(Map<String, dynamic> node) {
    final key = node['key'];
    if (key != null && key.toString().isNotEmpty) {
      return key.toString();
    }
    return null;
  }

  /// Extracts the list of children from a serialized node.
  static List<Map<String, dynamic>> _extractChildren(Map<String, dynamic> node) {
    final children = node['children'];
    if (children is List) {
      return children
          .whereType<Map>()
          .map((c) => Map<String, dynamic>.from(c))
          .toList();
    }
    return const [];
  }

  /// Diffs the scalar/collection properties of a node, excluding 'children'.
  static Map<String, dynamic> _diffProperties(
    Map<String, dynamic> oldNode,
    Map<String, dynamic> newNode,
  ) {
    final Map<String, dynamic> diff = {};

    // Check all keys in new node.
    for (final entry in newNode.entries) {
      final key = entry.key;
      if (key == 'children') continue;

      final newVal = entry.value;
      final oldVal = oldNode[key];

      if (!_areValuesEqual(oldVal, newVal)) {
        diff[key] = newVal;
      }
    }

    // Check for removed keys in new node that existed in old node.
    for (final oldKey in oldNode.keys) {
      if (oldKey == 'children') continue;
      if (!newNode.containsKey(oldKey)) {
        diff[oldKey] = null;
      }
    }

    return diff;
  }

  /// Diffs child lists using stable keys and positional matching.
  static void _diffChildren(
    List<Map<String, dynamic>> oldChildren,
    List<Map<String, dynamic>> newChildren,
    String parentPath,
    List<PatchOperation> ops,
  ) {
    final String childrenPath =
        parentPath.isEmpty ? '/children' : '$parentPath/children';

    // Fast path: both lists are empty.
    if (oldChildren.isEmpty && newChildren.isEmpty) {
      return;
    }

    // Check if both lists are keyed.
    final bool oldHasKeys = oldChildren.any((c) => _extractKey(c) != null);
    final bool newHasKeys = newChildren.any((c) => _extractKey(c) != null);

    if (!oldHasKeys && !newHasKeys) {
      // Unkeyed positional matching.
      _diffUnkeyedChildren(oldChildren, newChildren, childrenPath, ops);
    } else {
      // Keyed matching with fallback.
      _diffKeyedChildren(oldChildren, newChildren, childrenPath, ops);
    }
  }

  /// Positional child diffing (when neither list utilizes stable keys).
  static void _diffUnkeyedChildren(
    List<Map<String, dynamic>> oldChildren,
    List<Map<String, dynamic>> newChildren,
    String childrenPath,
    List<PatchOperation> ops,
  ) {
    final int commonLength =
        oldChildren.length < newChildren.length ? oldChildren.length : newChildren.length;

    // Diff existing overlapping items.
    for (int i = 0; i < commonLength; i++) {
      _diffNode(oldChildren[i], newChildren[i], '$childrenPath/$i', ops);
    }

    // Removals: if old has more items, remove trailing items in descending order.
    if (oldChildren.length > newChildren.length) {
      for (int i = oldChildren.length - 1; i >= newChildren.length; i--) {
        ops.add(PatchOperation.remove('$childrenPath/$i'));
      }
    }

    // Insertions: if new has more items, insert trailing items.
    if (newChildren.length > oldChildren.length) {
      for (int i = oldChildren.length; i < newChildren.length; i++) {
        ops.add(PatchOperation.insert('$childrenPath/$i', _deepCopy(newChildren[i])));
      }
    }
  }

  /// Keyed child diffing.
  static void _diffKeyedChildren(
    List<Map<String, dynamic>> oldChildren,
    List<Map<String, dynamic>> newChildren,
    String childrenPath,
    List<PatchOperation> ops,
  ) {
    // Map keys to original old indexes.
    final Map<String, int> oldKeyMap = {};
    for (int i = 0; i < oldChildren.length; i++) {
      final key = _extractKey(oldChildren[i]);
      if (key != null && !oldKeyMap.containsKey(key)) {
        oldKeyMap[key] = i;
      }
    }

    final Map<String, int> newKeyMap = {};
    for (int i = 0; i < newChildren.length; i++) {
      final key = _extractKey(newChildren[i]);
      if (key != null && !newKeyMap.containsKey(key)) {
        newKeyMap[key] = i;
      }
    }

    // If there is zero key overlap and lengths match, replace elements directly.
    final bool hasKeyOverlap = oldKeyMap.keys.any((k) => newKeyMap.containsKey(k));
    if (!hasKeyOverlap && oldChildren.length == newChildren.length) {
      _diffUnkeyedChildren(oldChildren, newChildren, childrenPath, ops);
      return;
    }

    // Check for removed children (keys present in old but missing in new).
    // Note: We remove in descending index order.
    final List<int> removeIndices = [];
    for (int i = 0; i < oldChildren.length; i++) {
      final key = _extractKey(oldChildren[i]);
      if (key != null && !newKeyMap.containsKey(key)) {
        removeIndices.add(i);
      }
    }

    // Simulate state after removals.
    final List<Map<String, dynamic>> simulatedOld = [];
    for (int i = 0; i < oldChildren.length; i++) {
      if (!removeIndices.contains(i)) {
        simulatedOld.add(oldChildren[i]);
      }
    }

    // Add removal operations in descending order.
    for (int i = removeIndices.length - 1; i >= 0; i--) {
      ops.add(PatchOperation.remove('$childrenPath/${removeIndices[i]}'));
    }

    // Check if remaining keys were reordered.
    bool requiresFullReplace = false;
    if (simulatedOld.length == newChildren.length) {
      for (int i = 0; i < simulatedOld.length; i++) {
        final oldK = _extractKey(simulatedOld[i]);
        final newK = _extractKey(newChildren[i]);
        if (oldK != newK && oldK != null && newK != null) {
          requiresFullReplace = true;
          break;
        }
      }
    }

    if (requiresFullReplace) {
      for (int i = 0; i < newChildren.length; i++) {
        if (i < simulatedOld.length) {
          _diffNode(simulatedOld[i], newChildren[i], '$childrenPath/$i', ops);
        } else {
          ops.add(PatchOperation.insert('$childrenPath/$i', _deepCopy(newChildren[i])));
        }
      }
      if (simulatedOld.length > newChildren.length) {
        for (int i = simulatedOld.length - 1; i >= newChildren.length; i--) {
          ops.add(PatchOperation.remove('$childrenPath/$i'));
        }
      }
      return;
    }

    // Diff simulatedOld and newChildren positionally / key-matched.
    int simIdx = 0;
    for (int newIdx = 0; newIdx < newChildren.length; newIdx++) {
      final newChild = newChildren[newIdx];
      final newK = _extractKey(newChild);

      if (simIdx < simulatedOld.length) {
        final oldChild = simulatedOld[simIdx];
        final oldK = _extractKey(oldChild);

        if (newK != null && oldK != null && newK == oldK) {
          _diffNode(oldChild, newChild, '$childrenPath/$newIdx', ops);
          simIdx++;
        } else if (newK != null && !oldKeyMap.containsKey(newK)) {
          ops.add(PatchOperation.insert('$childrenPath/$newIdx', _deepCopy(newChild)));
        } else {
          _diffNode(oldChild, newChild, '$childrenPath/$newIdx', ops);
          simIdx++;
        }
      } else {
        ops.add(PatchOperation.insert('$childrenPath/$newIdx', _deepCopy(newChild)));
      }
    }

    // Remove any remaining simulated old children.
    if (simIdx < simulatedOld.length) {
      for (int i = simulatedOld.length - 1; i >= simIdx; i--) {
        ops.add(PatchOperation.remove('$childrenPath/$i'));
      }
    }
  }

  /// Compares two dynamic values for equality.
  static bool _areValuesEqual(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a is num && b is num) return a == b;
    if (a is String && b is String) return a == b;
    if (a is bool && b is bool) return a == b;
    return jsonEncode(a) == jsonEncode(b);
  }

  /// Deep copies a JSON map.
  static Map<String, dynamic> _deepCopy(Map<String, dynamic> map) {
    return jsonDecode(jsonEncode(map)) as Map<String, dynamic>;
  }

  /// Applies a [WidgetTreePatch] to a target [tree] map and returns the updated tree.
  static Map<String, dynamic> apply(
    Map<String, dynamic> tree,
    WidgetTreePatch patch,
  ) {
    Map<String, dynamic> result = _deepCopy(tree);

    for (final op in patch.operations) {
      result = _applyOperation(result, op);
    }

    return result;
  }

  static Map<String, dynamic> _applyOperation(
    Map<String, dynamic> root,
    PatchOperation op,
  ) {
    if (op.path.isEmpty || op.path == '/') {
      if (op.op == 'replace' && op.value != null) {
        return _deepCopy(op.value!);
      }
      if (op.op == 'update' && op.properties != null) {
        final Map<String, dynamic> updated = _deepCopy(root);
        for (final entry in op.properties!.entries) {
          if (entry.value == null) {
            updated.remove(entry.key);
          } else {
            updated[entry.key] = entry.value;
          }
        }
        return updated;
      }
      return root;
    }

    final segments = op.path.split('/').where((s) => s.isNotEmpty).toList();
    final Map<String, dynamic> rootCopy = _deepCopy(root);

    dynamic current = rootCopy;
    for (int i = 0; i < segments.length - 1; i++) {
      final seg = segments[i];
      if (current is Map) {
        current = current[seg];
      } else if (current is List) {
        final idx = int.parse(seg);
        current = current[idx];
      } else {
        throw ArgumentError('Invalid path: ${op.path}');
      }
    }

    final lastSegment = segments.last;

    if (op.op == 'update') {
      Map<String, dynamic> target;
      if (current is Map) {
        target = current[lastSegment] as Map<String, dynamic>;
      } else if (current is List) {
        final idx = int.parse(lastSegment);
        target = current[idx] as Map<String, dynamic>;
      } else {
        throw ArgumentError('Target is not a map or list element: ${op.path}');
      }
      for (final entry in op.properties!.entries) {
        if (entry.value == null) {
          target.remove(entry.key);
        } else {
          target[entry.key] = entry.value;
        }
      }
    } else if (op.op == 'replace') {
      if (current is Map) {
        current[lastSegment] = _deepCopy(op.value!);
      } else if (current is List) {
        final idx = int.parse(lastSegment);
        current[idx] = _deepCopy(op.value!);
      }
    } else if (op.op == 'remove') {
      if (current is List) {
        final idx = int.parse(lastSegment);
        current.removeAt(idx);
      } else if (current is Map) {
        current.remove(lastSegment);
      }
    } else if (op.op == 'insert') {
      if (current is List) {
        final idx = int.parse(lastSegment);
        current.insert(idx, _deepCopy(op.value!));
      }
    }

    return rootCopy;
  }
}
