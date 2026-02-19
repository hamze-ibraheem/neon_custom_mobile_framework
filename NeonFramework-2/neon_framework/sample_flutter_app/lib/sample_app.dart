import 'package:neon_framework/neon.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({String? key}) : super(key: key);

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: NeonEdgeInsets.all(16),
          child: Text(
            'Hello from Flutter!',
            style: NeonTextStyle(fontSize: 24, fontWeight: NeonFontWeight.bold),
          ),
        ),
        SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            print('Button pressed');
          },
          child: Text('Click Me'),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {},
              icon: Text('⭐'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: Text('Outline'),
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
          child: Text('Increment'),
        ),
        Card(
          child: ListTile(
            leading: Text('📊'),
            title: Text('Statistics'),
            subtitle: Text('Tap for details'),
          ),
        ),
        LinearProgressIndicator(value: 0.5),
        CircularProgressIndicator(),
        Tooltip(
          message: 'This is a tooltip',
          child: Text('Hover me'),
        ),
      ],
    );
  }
}
