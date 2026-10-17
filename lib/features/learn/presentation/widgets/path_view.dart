import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/learning_path.dart';

const _nodeSize = 56.0;
const _currentNodeSize = 64.0;

/// Vertical learning path. Lessons alternate between the start and end
/// sides, with a connecting line drawn behind them; the checkpoint sits in
/// the middle at the end. Card text is start-aligned on both sides, and the
/// layout mirrors in RTL.
class PathView extends StatefulWidget {
  const PathView({super.key, required this.nodes, required this.onOpen});

  final List<LessonNode> nodes;
  final ValueChanged<LessonNode> onOpen;

  @override
  State<PathView> createState() => _PathViewState();
}

class _PathViewState extends State<PathView> {
  final _stackKey = GlobalKey();
  late List<GlobalKey> _nodeKeys;
  List<Offset> _centers = const [];

  @override
  void initState() {
    super.initState();
    _nodeKeys = _keysFor(widget.nodes);
  }

  @override
  void didUpdateWidget(PathView old) {
    super.didUpdateWidget(old);
    if (old.nodes.length != widget.nodes.length) {
      _nodeKeys = _keysFor(widget.nodes);
    }
  }

  static List<GlobalKey> _keysFor(List<LessonNode> nodes) => [
    for (final _ in nodes) GlobalKey(),
  ];

  /// Node centers depend on card heights, so they are measured after
  /// layout and the line is repainted if they moved.
  void _measure(Duration _) {
    if (!mounted) return;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || !stack.hasSize) return;
    final centers = <Offset>[];
    for (final key in _nodeKeys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      centers.add(
        box.localToGlobal(box.size.center(Offset.zero), ancestor: stack),
      );
    }
    if (!_sameOffsets(centers, _centers)) setState(() => _centers = centers);
  }

  static bool _sameOffsets(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).distance > 0.5) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_measure);
    final nodes = widget.nodes;
    final lastIsCheckpoint = nodes.isNotEmpty && nodes.last.lesson.isCheckpoint;

    return Stack(
      key: _stackKey,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _LinePainter(
              centers: _centers,
              done: [for (final n in nodes) _isDone(n.status)],
              reachable: [for (final n in nodes) !n.isLocked],
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < nodes.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.xl),
              if (i == nodes.length - 1 && lastIsCheckpoint)
                _CheckpointRow(
                  node: nodes[i],
                  nodeKey: _nodeKeys[i],
                  onOpen: () => widget.onOpen(nodes[i]),
                )
              else
                _LessonRow(
                  node: nodes[i],
                  nodeKey: _nodeKeys[i],
                  nodeAtEnd: i.isOdd,
                  onOpen: () => widget.onOpen(nodes[i]),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

bool _isDone(LessonStatus s) =>
    s == LessonStatus.completed || s == LessonStatus.reviewNeeded;

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.node,
    required this.nodeKey,
    required this.nodeAtEnd,
    required this.onOpen,
  });

  final LessonNode node;
  final GlobalKey nodeKey;

  /// Alternates the circle between the start and end side.
  final bool nodeAtEnd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final circle = _NodeCircle(key: nodeKey, node: node, onTap: onOpen);
    final card = Expanded(
      child: _LessonCard(node: node, onOpen: onOpen),
    );
    return Row(
      children: nodeAtEnd
          ? [card, const SizedBox(width: AppSpacing.smd), circle]
          : [circle, const SizedBox(width: AppSpacing.smd), card],
    );
  }
}

class _CheckpointRow extends StatelessWidget {
  const _CheckpointRow({
    required this.node,
    required this.nodeKey,
    required this.onOpen,
  });

  final LessonNode node;
  final GlobalKey nodeKey;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NodeCircle(key: nodeKey, node: node, onTap: onOpen),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: _LessonCard(node: node, onOpen: onOpen),
        ),
      ],
    );
  }
}

class _NodeCircle extends StatelessWidget {
  const _NodeCircle({super.key, required this.node, required this.onTap});

  final LessonNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = node.status == LessonStatus.current;
    final size = current ? _currentNodeSize : _nodeSize;
    final checkpoint = node.lesson.isCheckpoint;
    final (
      Color fill,
      Color iconColor,
      Border? border,
      IconData icon,
    ) = switch (node.status) {
      LessonStatus.completed => (
        AppColors.primary,
        AppColors.onPrimary,
        null,
        checkpoint ? Icons.emoji_events_rounded : Icons.check_rounded,
      ),
      LessonStatus.reviewNeeded => (
        AppColors.warningTint,
        AppColors.warning,
        Border.all(color: AppColors.warning, width: 3),
        Icons.refresh_rounded,
      ),
      LessonStatus.current => (
        AppColors.primary,
        AppColors.accent,
        Border.all(color: AppColors.accent, width: 4),
        Icons.play_arrow_rounded,
      ),
      LessonStatus.available => (
        AppColors.card,
        AppColors.primary,
        Border.all(color: AppColors.primary, width: 2),
        checkpoint ? Icons.emoji_events_rounded : Icons.menu_book_rounded,
      ),
      LessonStatus.locked => (
        AppColors.background,
        AppColors.textDisabled,
        Border.all(color: AppColors.border, width: 2),
        checkpoint ? Icons.emoji_events_outlined : Icons.lock_rounded,
      ),
    };

    // The card carries the semantics; the circle is a larger tap target.
    return ExcludeSemantics(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: border,
            boxShadow: node.isLocked ? null : AppShadows.card,
          ),
          child: Icon(icon, color: iconColor, size: current ? 32 : 26),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.node, required this.onOpen});

  final LessonNode node;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final lesson = node.lesson;
    final locked = node.isLocked;
    final result = node.result;

    final (
      String? tag,
      Color tagBg,
      IconData? tagIcon,
      Color tagIconColor,
    ) = switch (node.status) {
      LessonStatus.completed => (
        'Completed',
        AppColors.successTint,
        Icons.check_circle_rounded,
        AppColors.success,
      ),
      LessonStatus.reviewNeeded => (
        'Needs review',
        AppColors.warningTint,
        Icons.refresh_rounded,
        AppColors.warning,
      ),
      LessonStatus.current => (
        'Up next',
        AppColors.accent,
        null,
        AppColors.text,
      ),
      LessonStatus.available ||
      LessonStatus.locked => (null, AppColors.card, null, AppColors.text),
    };

    final detail = switch (node.status) {
      LessonStatus.locked => node.lockedReason!,
      LessonStatus.reviewNeeded =>
        '${node.mistakeCount} '
            '${node.mistakeCount == 1 ? 'mistake' : 'mistakes'} to review',
      LessonStatus.completed when result != null && result.total > 0 =>
        '${result.correct}/${result.total} correct',
      _ => '${lesson.estimatedMinutes} min',
    };

    final statusWord = switch (node.status) {
      LessonStatus.completed => 'completed',
      LessonStatus.reviewNeeded => 'needs review',
      LessonStatus.current => 'up next',
      LessonStatus.available => 'available',
      LessonStatus.locked => 'locked',
    };

    final card = AppCard(
      key: ValueKey('node-${lesson.id}'),
      color: locked ? AppColors.disabledFill : null,
      onTap: onOpen,
      semanticLabel: '${lesson.label}: ${lesson.title}, $statusWord. $detail',
      padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    lesson.label.toUpperCase(),
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                if (tag != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    flex: 2,
                    child: AppPill(
                      label: tag,
                      icon: tagIcon,
                      iconColor: tagIconColor,
                      background: tagBg,
                      foreground: AppColors.text,
                      size: AppPillSize.small,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              lesson.title,
              style: AppTextStyles.labelLg.copyWith(
                color: locked ? AppColors.textMuted : AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (locked) ...[
                  const Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                ],
                Flexible(
                  child: Text(
                    detail,
                    style: AppTextStyles.tabular(
                      AppTextStyles.bodySm,
                    ).copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!locked) return card;
    // The locked fill is translucent; back it so the path line stays hidden.
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadii.cardRadius,
      ),
      child: card,
    );
  }
}

/// The line through the node centers: S-curves between alternating sides.
/// Segments leading into finished lessons are drawn in the primary color.
class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.centers,
    required this.done,
    required this.reachable,
  });

  final List<Offset> centers;
  final List<bool> done;
  final List<bool> reachable;

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i + 1 < centers.length; i++) {
      final a = centers[i];
      final b = centers[i + 1];
      final midY = (a.dy + b.dy) / 2;
      final segment = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
      final active = done[i] && reachable[i + 1];
      canvas.drawPath(
        segment,
        paint..color = active ? AppColors.primary : AppColors.track,
      );
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.centers != centers || old.done != done || old.reachable != reachable;
}
