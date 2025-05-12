import 'dart:math';

import 'package:flutter/material.dart';
import 'package:manifold_callibration/entities/bet.dart';
import 'package:manifold_callibration/entities/bet_outcome.dart';
import 'package:manifold_callibration/entities/outcome_bucket.dart';

class CalibrationChartWidget extends StatefulWidget {
  const CalibrationChartWidget({
    required this.buckets,
    super.key,
  });

  final List<OutcomeBucket> buckets;

  @override
  State<CalibrationChartWidget> createState() => _CalibrationChartWidgetState();
}

class _CalibrationChartWidgetState extends State<CalibrationChartWidget> {
  OverlayEntry? _overlayEntry;
  int? _hoveredBucketIndex;
  bool _hoveringYes = false;

  Rect? _getArrowHitbox(int bucketIndex, bool isYes, Size size) {
    const scaleDown = 0.9;
    // Account for arrow icon size and extra margin.
    const arrowIconSize = 16.0;
    const extraMargin = 4.0;
    const hitboxSize = arrowIconSize + extraMargin;
    
    final offsetX = size.width * (1 - scaleDown) * 0.5;
    final offsetY = size.height * (1 - scaleDown) * 0.5;
    final bucketWidth = size.width / widget.buckets.length;
    final originalX = bucketWidth * (bucketIndex + 0.5);
    final drawnX = originalX * scaleDown + offsetX;
    
    final bucket = widget.buckets[bucketIndex];
    final originalY = size.height * (1 - (isYes ? bucket.yesRatio : bucket.noRatio));
    final drawnY = originalY * scaleDown + offsetY;
    
    // Clamp center so that hitbox does not exceed canvas boundaries.
    final clampedX = drawnX.clamp(hitboxSize / 2, size.width - hitboxSize / 2);
    final clampedY = drawnY.clamp(hitboxSize / 2, size.height - hitboxSize / 2);
    
    return Rect.fromCenter(
      center: Offset(clampedX, clampedY),
      width: hitboxSize,
      height: hitboxSize,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showTooltip(BuildContext context, Offset position, List<Bet> bets) {
    _removeOverlay();
    
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final localPosition = box.localToGlobal(position);
    final screenSize = MediaQuery.of(context).size;
    
    const tooltipWidth = 300.0;
    final tooltipHeight = 56.0 + (bets.length * 44.0);
    
    var adjustedX = localPosition.dx + 20;
    var adjustedY = localPosition.dy;
    
    if (adjustedX + tooltipWidth > screenSize.width) {
      adjustedX = localPosition.dx - tooltipWidth - 20;
    }
    
    if (adjustedY + tooltipHeight > screenSize.height) {
      adjustedY = screenSize.height - tooltipHeight - 20;
    }
    if (adjustedY < 0) {
      adjustedY = 20;
    }
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: adjustedX,
        top: adjustedY,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(maxWidth: tooltipWidth),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final bet in bets)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${bet.amount.toStringAsFixed(0)} mana @ ${(bet.outcome as dynamic).probAfter.toStringAsFixed(2)} - ',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Expanded(
                          child: Text(
                            bet.market?.question ?? 'Unknown market',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(_overlayEntry!);
  }

  void _onHover(Offset position, Size size, {required bool isEnter}) {
    if (!isEnter) {
      setState(() {
        _hoveredBucketIndex = null;
        _removeOverlay();
      });
      return;
    }

    final bucketWidth = size.width / widget.buckets.length;
    final bucketIndex = position.dx ~/ bucketWidth;
    
    if (bucketIndex >= 0 && bucketIndex < widget.buckets.length) {
      final yesHitbox = _getArrowHitbox(bucketIndex, true, size);
      final noHitbox = _getArrowHitbox(bucketIndex, false, size);
      
      bool hitYes = yesHitbox?.contains(position) ?? false;
      bool hitNo = noHitbox?.contains(position) ?? false;
      
      if (hitYes || hitNo) {
        final isYes = hitYes;
        final bucket = widget.buckets[bucketIndex];
        
        setState(() {
          _hoveredBucketIndex = bucketIndex;
          _hoveringYes = isYes;
        });

        final bets = isYes ? bucket.getTopYesBets() : bucket.getTopNoBets();
        if (bets.isNotEmpty) {
          _showTooltip(context, position, bets);
        }
      } else {
        setState(() {
          _hoveredBucketIndex = null;
          _removeOverlay();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.of(context);
    return MouseRegion(
      onEnter: (event) => _onHover(event.localPosition, context.size ?? Size.zero, isEnter: true),
      onExit: (event) => _onHover(event.localPosition, context.size ?? Size.zero, isEnter: false),
      onHover: (event) => _onHover(event.localPosition, context.size ?? Size.zero, isEnter: true),
      child: CustomPaint(
        painter: _CalibrationChartPainter(
          buckets: widget.buckets,
          colors: colors,
          hoveredBucketIndex: _hoveredBucketIndex,
          hoveringYes: _hoveringYes,
        ),
      ),
    );
  }
}

class _CalibrationChartPainter extends CustomPainter {
  _CalibrationChartPainter({
    required this.buckets,
    required this.colors,
    this.hoveredBucketIndex,
    this.hoveringYes = false,
  });

  final List<OutcomeBucket> buckets;
  final ColorScheme colors;
  final int? hoveredBucketIndex;
  final bool hoveringYes;

  double flipY(Size size, double y) {
    return size.height - y;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const scaleDown = 0.9;
    canvas.translate(
      size.width * (1 - scaleDown) * 0.5,
      size.height * (1 - scaleDown) * 0.5,
    );
    canvas.scale(0.90, 0.90);

    canvas.drawLine(
      Offset(0, flipY(size, 0)),
      Offset(size.width, flipY(size, size.height)),
      Paint()..color = colors.secondary,
    );

    canvas.drawLine(
      Offset(0, flipY(size, 0)),
      Offset(size.width, flipY(size, 0)),
      Paint()..color = colors.secondary,
    );

    canvas.drawLine(
      Offset(0, flipY(size, 0)),
      Offset(0, flipY(size, size.height)),
      Paint()..color = colors.secondary,
    );

    final oneTenthWidth = size.width / 10;
    for (int i = 0; i <= 10; ++i) {
      final o = i * oneTenthWidth;
      canvas.drawLine(
        Offset(o, flipY(size, -4)),
        Offset(o, flipY(size, 4)),
        Paint()
          ..color = colors.secondary
          ..strokeWidth = 1.0,
      );

      canvas.drawLine(
        Offset(o, flipY(size, 0)),
        Offset(o, flipY(size, size.height)),
        Paint()
          ..color = colors.secondary
          ..strokeWidth = 0.5,
      );

      drawLabel(
        canvas,
        (i * 10).toString(),
        Offset(o, flipY(size, -15)),
      );
    }

    final oneTenthHeight = size.height / 10;
    for (int i = 0; i <= 10; ++i) {
      final y = i * oneTenthHeight;
      canvas.drawLine(
        Offset(-4, flipY(size, y)),
        Offset(4, flipY(size, y)),
        Paint()
          ..color = colors.secondary
          ..strokeWidth = 1.0,
      );
      canvas.drawLine(
        Offset(0, flipY(size, y)),
        Offset(size.width, flipY(size, y)),
        Paint()
          ..color = colors.secondary
          ..strokeWidth = 0.5,
      );

      drawLabel(
        canvas,
        (i * 10).toString(),
        Offset(-15, flipY(size, y)),
      );
    }

    for (int i = 0; i < buckets.length; ++i) {
      final bucket = buckets[i];
      final noY = size.height * bucket.noRatio;
      final yesY = size.height * bucket.yesRatio;

      final x = size.width * (i / buckets.length + 0.5 / buckets.length);      
      drawMarker(
        canvas: canvas,
        rotation: 0,
        offset: Offset(x, flipY(size, yesY)),
        color: Colors.green,
        isHovered: hoveredBucketIndex == i && hoveringYes,
      );

      drawMarker(
        canvas: canvas,
        rotation: pi,
        offset: Offset(x, flipY(size, noY)),
        color: Colors.red,
        isHovered: hoveredBucketIndex == i && !hoveringYes,
      );
    }
  }

  void drawLabel(Canvas canvas, String text, Offset offset) {
    final textStyle = TextStyle(
      color: colors.onPrimaryContainer,
      fontSize: 12,
    );
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: double.infinity,
    );
    textPainter.paint(
      canvas,
      offset - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void drawMarker({
    required Canvas canvas,
    required double rotation,
    required Offset offset,
    required Color color,
    bool isHovered = false,
  }) {
    final size = Size(isHovered ? 16 : 12, isHovered ? 16 : 12);
    var path = Path();
    path.moveTo(0, -size.height);
    path.relativeLineTo(size.width / 2, size.height);
    path.relativeLineTo(-size.width, 0);
    path.close();

    path = path.transform(Matrix4.rotationZ(rotation).storage);
    path = path.shift(offset);

    final paint = Paint()
      ..color = color.withOpacity(isHovered ? 1.0 : 0.8)
      ..style = PaintingStyle.fill;
    
    if (isHovered) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CalibrationChartPainter oldDelegate) {
    return buckets != oldDelegate.buckets ||
           hoveredBucketIndex != oldDelegate.hoveredBucketIndex ||
           hoveringYes != oldDelegate.hoveringYes;
  }
}
