import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

enum ScrollDirection { vertical, horizontal }

class SingleChildScrollView extends NeonWidget {
  final NeonWidget child;
  final ScrollDirection scrollDirection;
  final NeonEdgeInsets padding;
  final bool reverse;

  const SingleChildScrollView({
    super.key,
    required this.child,
    this.scrollDirection = ScrollDirection.vertical,
    this.padding = NeonEdgeInsets.zero,
    this.reverse = false,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'SingleChildScrollView', key: key);
  }
}

class ListView extends NeonWidget {
  final List<NeonWidget> children;
  final ScrollDirection scrollDirection;
  final NeonEdgeInsets padding;
  final double? itemExtent;
  final bool shrinkWrap;
  final bool reverse;

  const ListView({
    super.key,
    required this.children,
    this.scrollDirection = ScrollDirection.vertical,
    this.padding = NeonEdgeInsets.zero,
    this.itemExtent,
    this.shrinkWrap = false,
    this.reverse = false,
  });

  ListView.builder({
    super.key,
    required int itemCount,
    required NeonWidget Function(int index) itemBuilder,
    this.scrollDirection = ScrollDirection.vertical,
    this.padding = NeonEdgeInsets.zero,
    this.itemExtent,
    this.shrinkWrap = false,
    this.reverse = false,
  }) : children = List.generate(itemCount, itemBuilder);

  ListView.separated({
    super.key,
    required int itemCount,
    required NeonWidget Function(int index) itemBuilder,
    required NeonWidget Function(int index) separatorBuilder,
    this.scrollDirection = ScrollDirection.vertical,
    this.padding = NeonEdgeInsets.zero,
    this.itemExtent,
    this.shrinkWrap = false,
    this.reverse = false,
  }) : children = List.generate(itemCount * 2 - 1, (i) {
         if (i.isEven) return itemBuilder(i ~/ 2);
         return separatorBuilder(i ~/ 2);
       });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'ListView', key: key);
  }
}

class CustomScrollView extends NeonWidget {
  final List<NeonWidget> slivers;
  final ScrollDirection scrollDirection;
  final bool reverse;

  const CustomScrollView({
    super.key,
    required this.slivers,
    this.scrollDirection = ScrollDirection.vertical,
    this.reverse = false,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'CustomScrollView', key: key);
  }
}

class SliverList extends NeonWidget {
  final List<NeonWidget> children;

  const SliverList({
    super.key,
    required this.children,
  });

  SliverList.builder({
    super.key,
    required int itemCount,
    required NeonWidget Function(int index) itemBuilder,
  }) : children = List.generate(itemCount, itemBuilder);

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'SliverList', key: key);
  }
}

class SliverAppBar extends NeonWidget {
  final NeonWidget? title;
  final bool floating;
  final bool pinned;
  final double expandedHeight;

  const SliverAppBar({
    super.key,
    this.title,
    this.floating = false,
    this.pinned = false,
    this.expandedHeight = 200.0,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'SliverAppBar', key: key);
  }
}
