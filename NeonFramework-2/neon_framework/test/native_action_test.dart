import 'package:test/test.dart';
import 'package:neon_framework/neon.dart';
import 'package:neon_framework/src/core/neon_app.dart';
import 'dart:convert';
import 'dart:io';

class TestCounterApp extends StatefulWidget {
  const TestCounterApp({super.key});
  @override
  NeonState<TestCounterApp> createState() => TestCounterAppState();
}

class TestCounterAppState extends NeonState<TestCounterApp> {
  int count = 0;
  bool isToggled = false;

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      children: [
        Text('Count: $count'),
        FilledButton(
          key: 'btn_increment',
          onPressed: () => setState(() => count++),
          child: const Text('Increment'),
        ),
        Switch(
          key: 'sw_toggle',
          value: isToggled,
          onChanged: (val) => setState(() => isToggled = val),
        ),
      ],
    );
  }
}

void main() {
  test('Native Action Flow: Increment Counter', () async {
    // Start the app using the static run method
    NeonApp.run(
      const TestCounterApp(),
      config: const NeonConfig(),
    );

    // Give the server time to start
    await Future.delayed(const Duration(milliseconds: 500));

    final client = HttpClient();

    final port = NeonApp.instance.port;
    // 1. Get initial state
    var request =
        await client.getUrl(Uri.parse('http://localhost:$port/api/tree'));

    var response = await request.close();
    var body = await response.transform(utf8.decoder).join();
    var json = jsonDecode(body);

    // Initial count should be 0
    // The ID for the button will be 'btn_increment' (since I fixed the .u issue)
    // Wait, the FilledButton(key: 'btn_increment') builds a Button(key: 'btn_increment').
    // So ID is 'btn_increment'.

    // 2. Trigger Action
    request = await client.postUrl(Uri.parse('http://localhost:$port/action'));
    request.write(jsonEncode({
      'id': 'btn_increment',
    }));
    response = await request.close();
    body = await response.transform(utf8.decoder).join();
    json = jsonDecode(body);

    // 3. Verify Rebuild
    // The new JSON should have 'Count: 1'
    expect(body, contains('Count: 1'));

    // 4. Trigger Switch Action
    request = await client.postUrl(Uri.parse('http://localhost:$port/action'));

    request.write(jsonEncode({
      'id': 'sw_toggle',
      'value': true,
    }));
    response = await request.close();
    body = await response.transform(utf8.decoder).join();

    // Verify that the Switch state in JSON is true
    // Switch(key: 'sw_toggle') builds LeafWidget(type: 'Switch', key: 'sw_toggle')
    // and correctly has id: 'sw_toggle'
    expect(body, contains('"id":"sw_toggle"'));
    expect(body, contains('"value":true'));

    // Cleanup
    NeonApp.reset();
  });
}
