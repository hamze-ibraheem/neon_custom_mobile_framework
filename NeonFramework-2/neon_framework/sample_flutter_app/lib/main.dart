import 'package:neon_framework/neon.dart';
import 'sample_app.dart';
import 'screens/showcase.dart';

class AppLauncher extends StatefulWidget {
  const AppLauncher({String? key}) : super(key: key);

  @override
  NeonState<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends NeonState<AppLauncher> {
  bool showShowcase = false;

  @override
  NeonWidget build(NeonBuildContext context) {
    if (showShowcase) {
      return Column(
        children: [
          Container(
            padding: NeonEdgeInsets.all(8),
            color: NeonColor(0xFF1A1A2E),
            child: Row(
              children: [
                FilledButton(
                  key: 'btn_back_sample',
                  onPressed: () {
                    setState(() {
                      showShowcase = false;
                    });
                  },
                  child: Text('← Back to Sample App'),
                ),
                const Spacer(),
                Text('my_2nd_test_app', style: NeonTextStyle(color: NeonColor.white, fontWeight: NeonFontWeight.bold)),
              ],
            ),
          ),
          Expanded(child: const ShowcaseApp()),
        ],
      );
    }

    return Column(
      children: [
        Container(
          padding: NeonEdgeInsets.all(16),
          child: Text(
            'Sample App Preview',
            style: NeonTextStyle(fontSize: 28, fontWeight: NeonFontWeight.bold),
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: NeonEdgeInsets.symmetric(horizontal: 16),
          child: FilledButton(
            key: 'btn_load_showcase',
            onPressed: () {
              setState(() {
                showShowcase = true;
              });
            },
            child: Text('Load my_2nd_test_app Preview'),
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: NeonEdgeInsets.all(12),
          child: Text(
            'MyHomePage Widget',
            style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold),
          ),
        ),
        const MyHomePage(),
        SizedBox(height: 24),
        Container(
          padding: NeonEdgeInsets.all(12),
          child: Text(
            'CounterWidget (Stateful)',
            style: NeonTextStyle(fontSize: 18, fontWeight: NeonFontWeight.bold),
          ),
        ),
        CounterWidget(key: 'counter_widget'),
      ],
    );
  }
}

void main() {
  NeonApp.run(
    const AppLauncher(),
    config: const NeonConfig(
      environment: NeonEnvironment.development,
    ),
  );
}
