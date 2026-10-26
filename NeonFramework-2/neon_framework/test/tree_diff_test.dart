import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:neon_framework/neon.dart';

void main() {
  group('NeonWidgetTreeDiff - Pure Diff Engine', () {
    test('Identical trees produce no operations', () {
      final tree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 'c1', 'type': 'Text', 'text': 'Hello'},
          {'id': 'c2', 'type': 'Button', 'text': 'Submit'}
        ]
      };

      final patch = NeonWidgetTreeDiff.diff(
        tree,
        tree,
        revision: 2,
        baseRevision: 1,
      );

      expect(patch.operations, isEmpty);
      expect(patch.isEmpty, isTrue);
      expect(patch.revision, equals(2));
      expect(patch.baseRevision, equals(1));
    });

    test('Changed text produces a minimal update', () {
      final oldTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 't1', 'type': 'Text', 'text': 'Count: 0'}
        ]
      };

      final newTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 't1', 'type': 'Text', 'text': 'Count: 1'}
        ]
      };

      final patch = NeonWidgetTreeDiff.diff(
        oldTree,
        newTree,
        revision: 2,
        baseRevision: 1,
      );

      expect(patch.operations.length, equals(1));
      final op = patch.operations.first;
      expect(op.op, equals('update'));
      expect(op.path, equals('/children/0'));
      expect(op.properties, equals({'text': 'Count: 1'}));

      // Verify applying patch produces the exact new tree
      final applied = NeonWidgetTreeDiff.apply(oldTree, patch);
      expect(applied, equals(newTree));
    });

    test('Changed properties produce a property update', () {
      final oldTree = {
        'id': 'root',
        'type': 'Container',
        'color': 0xFF0000FF,
        'width': 100.0,
        'height': 50.0,
      };

      final newTree = {
        'id': 'root',
        'type': 'Container',
        'color': 0xFFFF0000,
        'width': 120.0,
        'height': 50.0,
      };

      final patch = NeonWidgetTreeDiff.diff(
        oldTree,
        newTree,
        revision: 3,
        baseRevision: 2,
      );

      expect(patch.operations.length, equals(1));
      final op = patch.operations.first;
      expect(op.op, equals('update'));
      expect(op.path, equals(''));
      expect(op.properties?['color'], equals(0xFFFF0000));
      expect(op.properties?['width'], equals(120.0));
      expect(op.properties?.containsKey('height'), isFalse);

      final applied = NeonWidgetTreeDiff.apply(oldTree, patch);
      expect(applied, equals(newTree));
    });

    test('Insertions at the end and in middle', () {
      final oldTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 'c0', 'type': 'Text', 'text': 'A'}
        ]
      };

      final newTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 'c0', 'type': 'Text', 'text': 'A'},
          {'id': 'c1', 'type': 'Text', 'text': 'B'},
          {'id': 'c2', 'type': 'Text', 'text': 'C'}
        ]
      };

      final patch = NeonWidgetTreeDiff.diff(
        oldTree,
        newTree,
        revision: 2,
        baseRevision: 1,
      );

      expect(patch.operations.length, equals(2));
      expect(patch.operations[0].op, equals('insert'));
      expect(patch.operations[0].path, equals('/children/1'));
      expect(patch.operations[0].value?['text'], equals('B'));

      expect(patch.operations[1].op, equals('insert'));
      expect(patch.operations[1].path, equals('/children/2'));
      expect(patch.operations[1].value?['text'], equals('C'));

      final applied = NeonWidgetTreeDiff.apply(oldTree, patch);
      expect(applied, equals(newTree));
    });

    test('Removals are ordered in descending index order', () {
      final oldTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 'c0', 'type': 'Text', 'text': 'A'},
          {'id': 'c1', 'type': 'Text', 'text': 'B'},
          {'id': 'c2', 'type': 'Text', 'text': 'C'},
          {'id': 'c3', 'type': 'Text', 'text': 'D'}
        ]
      };

      final newTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 'c0', 'type': 'Text', 'text': 'A'},
          {'id': 'c1', 'type': 'Text', 'text': 'B'}
        ]
      };

      final patch = NeonWidgetTreeDiff.diff(
        oldTree,
        newTree,
        revision: 2,
        baseRevision: 1,
      );

      expect(patch.operations.length, equals(2));
      // First remove index 3, then remove index 2
      expect(patch.operations[0].op, equals('remove'));
      expect(patch.operations[0].path, equals('/children/3'));

      expect(patch.operations[1].op, equals('remove'));
      expect(patch.operations[1].path, equals('/children/2'));

      final applied = NeonWidgetTreeDiff.apply(oldTree, patch);
      expect(applied, equals(newTree));
    });

    test('Widget replacement when the type changes', () {
      final oldTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 'c0', 'type': 'Text', 'text': 'Status'}
        ]
      };

      final newTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 'c0', 'type': 'CircularProgressIndicator', 'value': 0.5}
        ]
      };

      final patch = NeonWidgetTreeDiff.diff(
        oldTree,
        newTree,
        revision: 2,
        baseRevision: 1,
      );

      expect(patch.operations.length, equals(1));
      final op = patch.operations.first;
      expect(op.op, equals('replace'));
      expect(op.path, equals('/children/0'));
      expect(op.value?['type'], equals('CircularProgressIndicator'));

      final applied = NeonWidgetTreeDiff.apply(oldTree, patch);
      expect(applied, equals(newTree));
    });

    test('Widget replacement when the key changes', () {
      final oldTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 'item_1', 'key': 'item_1', 'type': 'Text', 'text': 'First'}
        ]
      };

      final newTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 'item_2', 'key': 'item_2', 'type': 'Text', 'text': 'Second'}
        ]
      };

      final patch = NeonWidgetTreeDiff.diff(
        oldTree,
        newTree,
        revision: 2,
        baseRevision: 1,
      );

      expect(patch.operations.length, equals(1));
      final op = patch.operations.first;
      expect(op.op, equals('replace'));
      expect(op.path, equals('/children/0'));
      expect(op.value?['key'], equals('item_2'));

      final applied = NeonWidgetTreeDiff.apply(oldTree, patch);
      expect(applied, equals(newTree));
    });

    test('Stable keyed widgets preserve identity', () {
      final oldTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 't1', 'key': 'stable_txt', 'type': 'Text', 'text': 'Old'},
          {'id': 'btn', 'key': 'stable_btn', 'type': 'Button', 'enabled': true}
        ]
      };

      final newTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 't1', 'key': 'stable_txt', 'type': 'Text', 'text': 'New'},
          {'id': 'btn', 'key': 'stable_btn', 'type': 'Button', 'enabled': true}
        ]
      };

      final patch = NeonWidgetTreeDiff.diff(
        oldTree,
        newTree,
        revision: 2,
        baseRevision: 1,
      );

      // Only text updated; button unchanged and not touched
      expect(patch.operations.length, equals(1));
      expect(patch.operations[0].op, equals('update'));
      expect(patch.operations[0].path, equals('/children/0'));
      expect(patch.operations[0].properties, equals({'text': 'New'}));

      final applied = NeonWidgetTreeDiff.apply(oldTree, patch);
      expect(applied, equals(newTree));
    });

    test('Keyed reordering detected safely', () {
      final oldTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': '1', 'key': 'k1', 'type': 'Text', 'text': 'Item 1'},
          {'id': '2', 'key': 'k2', 'type': 'Text', 'text': 'Item 2'}
        ]
      };

      final newTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': '2', 'key': 'k2', 'type': 'Text', 'text': 'Item 2'},
          {'id': '1', 'key': 'k1', 'type': 'Text', 'text': 'Item 1'}
        ]
      };

      final patch = NeonWidgetTreeDiff.diff(
        oldTree,
        newTree,
        revision: 2,
        baseRevision: 1,
      );

      expect(patch.operations.isNotEmpty, isTrue);
      final applied = NeonWidgetTreeDiff.apply(oldTree, patch);
      expect(applied, equals(newTree));
    });

    test('Unkeyed positional matching updates matching indexes', () {
      final oldTree = {
        'id': 'root',
        'type': 'Row',
        'children': [
          {'id': '0', 'type': 'Text', 'text': 'A'},
          {'id': '1', 'type': 'Text', 'text': 'B'}
        ]
      };

      final newTree = {
        'id': 'root',
        'type': 'Row',
        'children': [
          {'id': '0', 'type': 'Text', 'text': 'A'},
          {'id': '1', 'type': 'Text', 'text': 'B Modified'}
        ]
      };

      final patch = NeonWidgetTreeDiff.diff(
        oldTree,
        newTree,
        revision: 2,
        baseRevision: 1,
      );

      expect(patch.operations.length, equals(1));
      expect(patch.operations.first.op, equals('update'));
      expect(patch.operations.first.path, equals('/children/1'));

      final applied = NeonWidgetTreeDiff.apply(oldTree, patch);
      expect(applied, equals(newTree));
    });

    test('Nested changes generate deep JSON Pointer paths', () {
      final oldTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {
            'id': 'card',
            'type': 'Card',
            'children': [
              {
                'id': 'row',
                'type': 'Row',
                'children': [
                  {'id': 'lbl', 'type': 'Text', 'text': 'Deep Label'}
                ]
              }
            ]
          }
        ]
      };

      final newTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {
            'id': 'card',
            'type': 'Card',
            'children': [
              {
                'id': 'row',
                'type': 'Row',
                'children': [
                  {'id': 'lbl', 'type': 'Text', 'text': 'Deep Label Updated'}
                ]
              }
            ]
          }
        ]
      };

      final patch = NeonWidgetTreeDiff.diff(
        oldTree,
        newTree,
        revision: 5,
        baseRevision: 4,
      );

      expect(patch.operations.length, equals(1));
      final op = patch.operations.first;
      expect(op.op, equals('update'));
      expect(op.path, equals('/children/0/children/0/children/0'));
      expect(op.properties?['text'], equals('Deep Label Updated'));

      final applied = NeonWidgetTreeDiff.apply(oldTree, patch);
      expect(applied, equals(newTree));
    });

    test('Duplicate, missing, empty, and invalid keys handled safely', () {
      final oldTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': '1', 'key': '', 'type': 'Text', 'text': 'Empty Key'},
          {'id': '2', 'key': 'dup', 'type': 'Text', 'text': 'First Dup'},
          {'id': '3', 'key': 'dup', 'type': 'Text', 'text': 'Second Dup'},
          {'id': '4', 'type': 'Text', 'text': 'No Key'}
        ]
      };

      final newTree = {
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': '1', 'key': '', 'type': 'Text', 'text': 'Empty Key Updated'},
          {'id': '2', 'key': 'dup', 'type': 'Text', 'text': 'First Dup'},
          {'id': '3', 'key': 'dup', 'type': 'Text', 'text': 'Second Dup Modified'},
          {'id': '4', 'type': 'Text', 'text': 'No Key'}
        ]
      };

      final patch = NeonWidgetTreeDiff.diff(
        oldTree,
        newTree,
        revision: 2,
        baseRevision: 1,
      );

      expect(patch.operations.isNotEmpty, isTrue);
      final applied = NeonWidgetTreeDiff.apply(oldTree, patch);
      expect(applied, equals(newTree));
    });

    test('Patch JSON serialization and deserialization roundtrip', () {
      final originalPatch = WidgetTreePatch(
        version: 1,
        revision: 12,
        baseRevision: 11,
        operations: [
          PatchOperation.update('/children/0', {'text': 'Count: 5'}),
          PatchOperation.replace('/children/1', {'id': 'b1', 'type': 'Button'}),
          PatchOperation.remove('/children/2'),
          PatchOperation.insert('/children/3', {'id': 't2', 'type': 'Text'}),
        ],
      );

      final jsonMap = originalPatch.toJson();
      final deserialized = WidgetTreePatch.fromJson(jsonMap);

      expect(deserialized.version, equals(1));
      expect(deserialized.revision, equals(12));
      expect(deserialized.baseRevision, equals(11));
      expect(deserialized.operations.length, equals(4));

      expect(deserialized.operations[0].op, equals('update'));
      expect(deserialized.operations[0].path, equals('/children/0'));
      expect(deserialized.operations[0].properties?['text'], equals('Count: 5'));

      expect(deserialized.operations[1].op, equals('replace'));
      expect(deserialized.operations[1].path, equals('/children/1'));
      expect(deserialized.operations[1].value?['type'], equals('Button'));

      expect(deserialized.operations[2].op, equals('remove'));
      expect(deserialized.operations[2].path, equals('/children/2'));

      expect(deserialized.operations[3].op, equals('insert'));
      expect(deserialized.operations[3].path, equals('/children/3'));
      expect(deserialized.operations[3].value?['type'], equals('Text'));
    });

    test('Multiple sequential updates produce correct applied trees', () {
      Map<String, dynamic> currentTree = <String, dynamic>{
        'id': 'root',
        'type': 'Column',
        'children': [
          {'id': 'c0', 'type': 'Text', 'text': 'Step 0'}
        ]
      };

      for (int i = 1; i <= 5; i++) {
        final nextTree = {
          'id': 'root',
          'type': 'Column',
          'children': [
            {'id': 'c0', 'type': 'Text', 'text': 'Step $i'},
            if (i >= 3) {'id': 'badge_$i', 'type': 'Badge', 'label': '$i'}
          ]
        };

        final patch = NeonWidgetTreeDiff.diff(
          currentTree,
          nextTree,
          revision: i + 1,
          baseRevision: i,
        );

        currentTree = NeonWidgetTreeDiff.apply(currentTree, patch);
        expect(currentTree, equals(nextTree));
      }
    });
  });

  group('HTTP Bridge Diffing & Revision Integration', () {
    test('Bridge returns full tree initially, then patch on valid base revision', () async {
      NeonApp.reset();
      NeonApp.run(
        const _TestDiffApp(),
        config: const NeonConfig(port: 0, enableDiffing: true),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      final client = HttpClient();
      final port = NeonApp.instance.port;

      // 1. Initial GET /api/tree -> Returns Full Tree with revision: 1
      var req = await client.getUrl(Uri.parse('http://localhost:$port/api/tree'));
      var res = await req.close();
      var body = await res.transform(utf8.decoder).join();
      var json = jsonDecode(body) as Map<String, dynamic>;

      expect(json['type'], equals('full'));
      expect(json['revision'], equals(1));
      expect(json.containsKey('tree'), isTrue);

      // 2. Action with valid clientRevision (1) -> Returns patch
      req = await client.postUrl(Uri.parse('http://localhost:$port/action'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'id': 'btn_click',
        'clientRevision': 1,
        'patchVersion': 1,
      }));
      res = await req.close();
      body = await res.transform(utf8.decoder).join();
      json = jsonDecode(body) as Map<String, dynamic>;

      expect(json['type'], equals('patch'));
      expect(json['version'], equals(1));
      expect(json['revision'], equals(2));
      expect(json['baseRevision'], equals(1));
      expect(json['operations'], isA<List>());
      final ops = json['operations'] as List;
      expect(ops.any((o) => o['op'] == 'update'), isTrue);

      // 3. Stale revision (client sends 1 again instead of 2) -> Fallback to full tree
      req = await client.postUrl(Uri.parse('http://localhost:$port/action'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'id': 'btn_click',
        'clientRevision': 1, // Stale! Expected 2
        'patchVersion': 1,
      }));
      res = await req.close();
      body = await res.transform(utf8.decoder).join();
      json = jsonDecode(body) as Map<String, dynamic>;

      expect(json['type'], equals('full'));
      expect(json['revision'], equals(3));
      expect(json['fallbackReason'], equals('revision_mismatch'));
      expect(json.containsKey('tree'), isTrue);

      // 4. Recovery request -> Full tree returned
      req = await client.postUrl(Uri.parse('http://localhost:$port/action'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'id': 'btn_click',
        'clientRevision': 3,
        'recovery': true,
      }));
      res = await req.close();
      body = await res.transform(utf8.decoder).join();
      json = jsonDecode(body) as Map<String, dynamic>;

      expect(json['type'], equals('full'));
      expect(json['fallbackReason'], equals('recovery_requested'));

      NeonApp.reset();
    });

    test('Diffing disabled returns full tree every time', () async {
      NeonApp.reset();
      NeonApp.run(
        const _TestDiffApp(),
        config: const NeonConfig(port: 0, enableDiffing: false),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      final client = HttpClient();
      final port = NeonApp.instance.port;

      // Action with clientRevision sent, but diffing is disabled in config
      final req = await client.postUrl(Uri.parse('http://localhost:$port/action'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'id': 'btn_click',
        'clientRevision': 1,
      }));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;

      expect(json['type'], equals('full'));
      expect(json['fallbackReason'], equals('diffing_disabled'));

      NeonApp.reset();
    });
  });
}

class _TestDiffApp extends StatefulWidget {
  const _TestDiffApp();

  @override
  NeonState<_TestDiffApp> createState() => _TestDiffAppState();
}

class _TestDiffAppState extends NeonState<_TestDiffApp> {
  int clicks = 0;

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      children: [
        Text('Clicks: $clicks'),
        FilledButton(
          key: 'btn_click',
          onPressed: () => setState(() => clicks++),
          child: const Text('Tap Me'),
        ),
      ],
    );
  }
}
