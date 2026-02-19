import 'package:test/test.dart';
import 'package:neon_framework/neon.dart';
import 'package:neon_framework/src/widgets/widget_tree.dart';
import 'dart:convert';

void main() {
  test('NeonElement.toJson handles double.infinity', () {
    final context = NeonBuildContext(config: const NeonConfig());
    final container = Container(
      width: double.infinity,
      height: 100,
      child: const Text('Hello'),
    );

    final tree = NeonWidgetTree();
    tree.buildTree(container, context);

    final element = tree.root!;
    expect(() => jsonEncode(element.toJson()), returnsNormally);

    final json = element.toJson();
    expect(json['width'], equals(-1.0));
  });

  test('NeonElement.toJson handles Positioned infinity', () {
    final context = NeonBuildContext(config: const NeonConfig());
    final positioned = Positioned(
      left: double.infinity,
      child: const Text('Hello'),
    );

    final tree = NeonWidgetTree();
    tree.buildTree(positioned, context);

    final element = tree.root!;
    expect(() => jsonEncode(element.toJson()), returnsNormally);

    final json = element.toJson();
    expect(json['left'], equals(-1.0));
  });
}
