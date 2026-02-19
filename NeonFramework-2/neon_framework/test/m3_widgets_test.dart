import 'package:test/test.dart';
import 'package:neon_framework/neon.dart';

void main() {
  tearDown(() {
    NeonApp.reset();
  });

  group('Badge', () {
    test('Badge properties', () {
      const badge = Badge(
        backgroundColor: NeonColor.blue,
        label: Text('5'),
        child: Text('Icon'),
      );
      expect(badge.backgroundColor, equals(NeonColor.blue));
      expect(badge.label, isA<Text>());
      expect((badge.label as Text).data, equals('5'));
    });

    test('Badge builds Stack with child and Label', () {
      final context = NeonBuildContext(config: const NeonConfig());
      const badge = Badge(child: Text('A'));
      final built = badge.build(context);
      expect(built, isA<Stack>());
      final stack = built as Stack;
      expect(stack.children.length, equals(2));
      expect(stack.children[1], isA<LeafWidget>());
      expect((stack.children[1] as LeafWidget).type, equals('BadgeLabel'));
    });
  });

  group('Chips', () {
    test('ActionChip', () {
      var pressed = false;
      final chip = ActionChip(
        label: const Text('Action'),
        onPressed: () => pressed = true,
      );
      final context = NeonBuildContext(config: const NeonConfig());
      final built = chip.build(context) as LeafWidget;
      expect(built.type, equals('ActionChip'));
      // In a real scenario, the host would trigger this.
      // For now we just verify it exists.
    });

    test('FilterChip selection', () {
      var selectedValue = false;
      final chip = FilterChip(
        label: const Text('Filter'),
        selected: false,
        onSelected: (val) => selectedValue = val,
      );
      final context = NeonBuildContext(config: const NeonConfig());
      final built = chip.build(context) as LeafWidget;
      expect(built.type, equals('FilterChip'));
    });

    test('ChoiceChip', () {
      final chip = ChoiceChip(
        label: const Text('Choice'),
        selected: true,
      );
      final context = NeonBuildContext(config: const NeonConfig());
      final built = chip.build(context) as LeafWidget;
      expect(built.type, equals('ChoiceChip'));
    });

    test('InputChip', () {
      var deleted = false;
      final chip = InputChip(
        label: const Text('Input'),
        onDeleted: () => deleted = true,
      );
      final context = NeonBuildContext(config: const NeonConfig());
      final built = chip.build(context) as LeafWidget;
      expect(built.type, equals('InputChip'));
    });
  });

  group('Selection Controls', () {
    test('Switch', () {
      const sw = Switch(value: true);
      final context = NeonBuildContext(config: const NeonConfig());
      final built = sw.build(context) as LeafWidget;
      expect(built.type, equals('Switch'));
    });

    test('Checkbox', () {
      const cb = Checkbox(value: true);
      final context = NeonBuildContext(config: const NeonConfig());
      final built = cb.build(context) as LeafWidget;
      expect(built.type, equals('Checkbox'));
    });

    test('Radio', () {
      const rb = Radio<int>(value: 1, groupValue: 1);
      final context = NeonBuildContext(config: const NeonConfig());
      final built = rb.build(context) as LeafWidget;
      expect(built.type, equals('Radio'));
    });
  });

  group('Sliders', () {
    test('Slider', () {
      const s = Slider(value: 0.5, min: 0.0, max: 1.0);
      final context = NeonBuildContext(config: const NeonConfig());
      final built = s.build(context) as LeafWidget;
      expect(built.type, equals('Slider'));
    });

    test('RangeSlider', () {
      const rs = RangeSlider(values: NeonRangeValues(0.2, 0.8));
      final context = NeonBuildContext(config: const NeonConfig());
      final built = rs.build(context) as LeafWidget;
      expect(built.type, equals('RangeSlider'));
    });
  });
}
