import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/writing.dart';

/// Series styles: a color, a marker and a dash pattern each, so lines are
/// told apart without relying on color.
const _seriesColors = [AppColors.primary, AppColors.text, AppColors.success];

enum _Marker { circle, square, triangle }

const _markers = [_Marker.circle, _Marker.square, _Marker.triangle];

/// Dash and gap lengths; null is a solid line.
const List<List<double>?> _dashes = [
  null,
  [6, 4],
  [2, 3],
];

/// A line graph with its title and legend, or the same data as a table.
class ChartView extends StatefulWidget {
  const ChartView({super.key, required this.data});

  final LineChartData data;

  @override
  State<ChartView> createState() => _ChartViewState();
}

class _ChartViewState extends State<ChartView> {
  var _table = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(data.title, style: AppTextStyles.labelLg),
        const SizedBox(height: AppSpacing.smd),
        if (_table)
          ChartTable(data: data)
        else ...[
          LineChartGraphic(data: data),
          const SizedBox(height: AppSpacing.sm),
          ChartLegend(data: data),
        ],
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('chartViewToggle'),
            onPressed: () => setState(() => _table = !_table),
            icon: Icon(
              _table ? Icons.show_chart_rounded : Icons.table_chart_outlined,
              size: 18,
            ),
            label: Text(_table ? 'View as chart' : 'View as table'),
          ),
        ),
      ],
    );
  }
}

/// The plotted lines. Years run left to right in every language.
class LineChartGraphic extends StatelessWidget {
  const LineChartGraphic({
    super.key,
    required this.data,
    this.aspectRatio = 1.5,
    this.semanticLabel,
  });

  final LineChartData data;
  final double aspectRatio;

  /// What screen readers hear; by default, the title and a pointer to the
  /// table view.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          semanticLabel ??
          'Line graph: ${data.title}. Use View as table to hear the '
              'values.',
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: CustomPaint(painter: _LineChartPainter(data)),
        ),
      ),
    );
  }
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.data});

  final LineChartData data;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final (i, s) in data.series.indexed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 14,
                child: CustomPaint(painter: _LegendPainter(i)),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(s.name, style: AppTextStyles.bodySm),
            ],
          ),
      ],
    );
  }
}

/// The chart's values as a table, for screen readers and anyone who
/// prefers numbers.
class ChartTable extends StatelessWidget {
  const ChartTable({super.key, required this.data});

  final LineChartData data;

  @override
  Widget build(BuildContext context) {
    final figures = AppTextStyles.tabular(AppTextStyles.bodySm);
    Widget cell(String text, {bool header = false, bool end = false}) =>
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            text,
            textAlign: end ? TextAlign.end : TextAlign.start,
            style: header
                ? AppTextStyles.labelMd
                : figures.copyWith(color: AppColors.text),
          ),
        );

    return Table(
      key: const ValueKey('chartTable'),
      border: const TableBorder(
        horizontalInside: BorderSide(color: AppColors.border),
        bottom: BorderSide(color: AppColors.border),
      ),
      columnWidths: const {0: IntrinsicColumnWidth()},
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.primaryTint),
          children: [
            cell('Year', header: true),
            for (final s in data.series) cell(s.name, header: true, end: true),
          ],
        ),
        for (final (i, x) in data.xLabels.indexed)
          TableRow(
            children: [
              cell(x),
              for (final s in data.series)
                cell('${s.values[i]}${data.unit}', end: true),
            ],
          ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.data);

  final LineChartData data;

  static const _axisStyle = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    fontSize: 11,
    color: AppColors.textMuted,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  TextPainter _label(String text) => TextPainter(
    text: TextSpan(text: text, style: _axisStyle),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final yLabels = [for (num v = 0; v <= data.yMax; v += data.yStep) v];
    final labelWidth = yLabels
        .map((v) => _label('$v${data.unit}').width)
        .reduce((a, b) => a > b ? a : b);
    final left = labelWidth + 8;
    const top = 8.0, right = 12.0;
    final bottom = _label('2000').height + 8;
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );

    double xAt(int i) => plot.left + plot.width * i / (data.xLabels.length - 1);
    double yAt(num v) => plot.bottom - plot.height * v / data.yMax;

    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (final v in yLabels) {
      final y = yAt(v);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      final label = _label('$v${data.unit}');
      label.paint(canvas, Offset(left - 8 - label.width, y - label.height / 2));
    }
    for (final (i, x) in data.xLabels.indexed) {
      final label = _label(x);
      label.paint(canvas, Offset(xAt(i) - label.width / 2, plot.bottom + 6));
    }

    for (final (s, series) in data.series.indexed) {
      final color = _seriesColors[s % _seriesColors.length];
      final points = [
        for (final (i, v) in series.values.indexed) Offset(xAt(i), yAt(v)),
      ];
      final line = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (var i = 1; i < points.length; i++) {
        _drawSegment(canvas, points[i - 1], points[i], line, _dashes[s % 3]);
      }
      for (final p in points) {
        _drawMarker(canvas, p, _markers[s % 3], color);
      }
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.data != data;
}

class _LegendPainter extends CustomPainter {
  _LegendPainter(this.index);

  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final color = _seriesColors[index % _seriesColors.length];
    final y = size.height / 2;
    _drawSegment(
      canvas,
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = color
        ..strokeWidth = 2.5,
      _dashes[index % 3],
    );
    _drawMarker(canvas, Offset(size.width / 2, y), _markers[index % 3], color);
  }

  @override
  bool shouldRepaint(_LegendPainter old) => old.index != index;
}

void _drawSegment(
  Canvas canvas,
  Offset a,
  Offset b,
  Paint paint,
  List<double>? dash,
) {
  if (dash == null) {
    canvas.drawLine(a, b, paint);
    return;
  }
  final length = (b - a).distance;
  final dir = (b - a) / length;
  var d = 0.0;
  var on = true;
  var k = 0;
  while (d < length) {
    final step = dash[k % dash.length];
    final end = (d + step).clamp(0.0, length);
    if (on) canvas.drawLine(a + dir * d, a + dir * end, paint);
    d = end;
    on = !on;
    k++;
  }
}

void _drawMarker(Canvas canvas, Offset c, _Marker marker, Color color) {
  final fill = Paint()..color = color;
  final ring = Paint()
    ..color = AppColors.card
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  switch (marker) {
    case _Marker.circle:
      canvas.drawCircle(c, 4.5, fill);
      canvas.drawCircle(c, 4.5, ring);
    case _Marker.square:
      final r = Rect.fromCenter(center: c, width: 8.5, height: 8.5);
      canvas.drawRect(r, fill);
      canvas.drawRect(r, ring);
    case _Marker.triangle:
      final path = Path()
        ..moveTo(c.dx, c.dy - 5.5)
        ..lineTo(c.dx + 5.5, c.dy + 4.5)
        ..lineTo(c.dx - 5.5, c.dy + 4.5)
        ..close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, ring);
  }
}

/// Opens [data] in a bottom sheet.
Future<void> showChartSheet(BuildContext context, LineChartData data) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: ChartView(data: data),
        ),
      ),
    );
