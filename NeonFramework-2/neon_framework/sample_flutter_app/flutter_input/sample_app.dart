import 'package:neon_framework/neon.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({String? key}) : super(key: key);

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Container(
          padding: NeonEdgeInsets.all(16),
          child: const Text(
            'Hello from Flutter!',
            style: NeonTextStyle(fontSize: 24, fontWeight: NeonFontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            print('Button pressed');
          },
          child: const Text('Click Me'),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Text('⭐'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Outline'),
            ),
          ],
        ),
      ],
    );
  }
}

class CounterWidget extends StatefulWidget {
  const CounterWidget({String? key}) : super(key: key);

  @override
  NeonState<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends NeonState<CounterWidget> {
  int count = 0;

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      children: [
        Text('Count: $count'),
        FilledButton(
          onPressed: () {
            setState(() {
              count++;
            });
          },
          child: const Text('Increment'),
        ),
        const Card(
          child: ListTile(
            leading: Text('📊'),
            title: Text('Statistics'),
            subtitle: Text('Tap for details'),
          ),
        ),
        const LinearProgressIndicator(value: 0.5),
        const CircularProgressIndicator(),
        const Tooltip(
          message: 'This is a tooltip',
          child: Text('Hover me'),
        ),
      ],
    );
  }
}
