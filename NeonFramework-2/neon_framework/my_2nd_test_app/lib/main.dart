import 'package:neon_framework/neon.dart';
import 'screens/showcase.dart';

void main() {
  NeonApp.run(
    const ShowcaseApp(),
    config: const NeonConfig(
      environment: NeonEnvironment.development,
    ),
  );
}
