import 'package:flutter/material.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: Text(
            'Hello from Flutter!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
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
  const CounterWidget({Key? key}) : super(key: key);

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(
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
