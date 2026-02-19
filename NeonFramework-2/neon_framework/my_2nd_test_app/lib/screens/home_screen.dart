import 'package:neon_framework/neon.dart';

class HomeScreen extends StatefulWidget {
  @override
  NeonState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends NeonState<HomeScreen> {
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  void _decrement() {
    setState(() {
      _counter--;
    });
  }

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(
        'Material 3 Buttons Showcase',
        style: NeonTextStyle(fontSize: 24.0),
      ),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton(
            onPressed: () {},
            child: Text('Filled', style: NeonTextStyle(color: NeonColor.white)),
          ),
          FilledTonalButton(
            onPressed: () {},
            child: Text('Tonal'),
          ),
        ],
      ),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {},
            child: Text('Elevated'),
          ),
          OutlinedButton(
            onPressed: () {},
            child: Text('Outlined'),
          ),
        ],
      ),

      TextButton(
        onPressed: () {},
        child: Text('Text Button'),
      ),

      IconButton(
        icon: Text('★'),
        variant: IconButtonVariant.filled,
        onPressed: () {},
      ),

      FloatingActionButton(
        child: Text('+'),
        onPressed: () {},
      ),

      Text(
        'Remote Widget Bridge',
        style: NeonTextStyle(fontSize: 20.0),
      ),

      // Simulating a bridge fetching UI from an external source
      RemoteWidget(
        url: 'http://localhost:8080/remote-demo',
      ),

      Container(height: 20, child: Text('')),

      Text('Counter: $_counter'),
      Button(onPressed: _increment, child: Text('Increment')),
    ]);
  }
}
