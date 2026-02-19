import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

/// A widget that fetches its content from a remote URL.
class RemoteWidget extends NeonWidget {
  final String url;
  final NeonWidget placeholder;

  const RemoteWidget({
    super.key,
    required this.url,
    this.placeholder = const LeafWidget(type: 'LoadingIndicator'),
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    // The actual fetching happens on the client side (iOS/Android).
    // This widget serves as a marker in the tree.
    return LeafWidget(
      type: 'RemoteWidget',
      key: key,
    );
  }
}
