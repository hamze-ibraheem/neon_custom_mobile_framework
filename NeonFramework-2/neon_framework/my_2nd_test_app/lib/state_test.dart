import 'package:neon_framework/neon.dart';

/// Simple test app to verify state updates work correctly
class StateTestApp extends StatefulWidget {
  const StateTestApp({super.key});

  @override
  NeonState<StateTestApp> createState() => StateTestAppState();
}

class StateTestAppState extends NeonState<StateTestApp> {
  int counter = 0;
  bool isToggled = false;
  double sliderValue = 0.5;

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      children: [
        const AppBar(
          title: Text('State Test'),
          variant: AppBarVariant.medium,
        ),
        Container(
          padding: const NeonEdgeInsets.all(20),
          color: NeonColor.white,
          child: Column(
            children: [
              // Counter Test
              Text('Counter: $counter',
                  style: const NeonTextStyle(
                      fontSize: 24, fontWeight: NeonFontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    key: 'btn_increment',
                    onPressed: () {
                      setState(() {
                        counter++;
                      });
                    },
                    child: const Text('Increment'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    key: 'btn_decrement',
                    onPressed: () {
                      setState(() {
                        counter--;
                      });
                    },
                    child: const Text('Decrement'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Toggle Test
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Toggle: ${isToggled ? "ON" : "OFF"}'),
                  Switch(
                    key: 'switch_test',
                    value: isToggled,
                    onChanged: (val) {
                      setState(() {
                        isToggled = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Slider Test
              Text('Slider: ${(sliderValue * 100).toInt()}%'),
              Slider(
                key: 'slider_test',
                value: sliderValue,
                onChanged: (val) {
                  setState(() {
                    sliderValue = val;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void main() {
  NeonApp.run(
    const StateTestApp(),
    config: const NeonConfig(
      environment: NeonEnvironment.development,
    ),
  );
}
