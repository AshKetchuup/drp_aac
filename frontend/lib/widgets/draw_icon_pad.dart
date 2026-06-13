import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_theme.dart';

/// Opens a square drawing pad as an overlay (a dialog floating over the
/// communication grid — it intentionally does NOT take up the whole screen).
///
/// Returns PNG-encoded bytes of the drawing, or `null` if the user cancelled
/// or drew nothing. The bytes are a white-background raster, so they render
/// through the same [Image.memory] path as photo/gallery icons.
Future<Uint8List?> showDrawIconDialog(BuildContext context) {
  return showDialog<Uint8List?>(
    context: context,
    builder: (_) => const _DrawIconDialog(),
  );
}

/// One continuous pen (or eraser) stroke.
class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;

  _Stroke(this.points, this.color, this.width);
}

class _DrawIconDialog extends StatefulWidget {
  const _DrawIconDialog();

  @override
  State<_DrawIconDialog> createState() => _DrawIconDialogState();
}

class _DrawIconDialogState extends State<_DrawIconDialog> {
  // Basic colour palette for the pen.
  static const List<Color> _palette = [
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.brown,
  ];

  final GlobalKey _canvasKey = GlobalKey();
  final List<_Stroke> _strokes = [];

  // Drives canvas repaints directly, without rebuilding the dialog tree.
  // Rebuilding on every pan move would churn the tooltip/MouseRegion widgets
  // and trip the framework's re-entrant mouse-tracker assertion when drawing
  // with a mouse (desktop/web).
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  Color _penColor = Colors.black;
  // Sensible preset width — visible without being chunky.
  double _penWidth = 6;
  bool _erasing = false;

  @override
  void dispose() {
    _repaint.dispose();
    super.dispose();
  }

  void _startStroke(Offset p) {
    _strokes.add(
      _Stroke(
        [p],
        _erasing ? Colors.white : _penColor,
        _erasing ? _penWidth * 2.5 : _penWidth,
      ),
    );
    _repaint.value++;
  }

  void _extendStroke(Offset p) {
    _strokes.last.points.add(p);
    _repaint.value++;
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    _repaint.value++;
  }

  void _clear() {
    _strokes.clear();
    _repaint.value++;
  }

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      Navigator.pop(context, null);
      return;
    }
    final boundary = _canvasKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      Navigator.pop(context, null);
      return;
    }
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted) return;
    Navigator.pop(context, byteData?.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.isHighContrast ? Colors.black : Colors.white;
    // Size the square from the screen width rather than a LayoutBuilder:
    // AlertDialog measures the intrinsic width of its content, and LayoutBuilder
    // cannot answer intrinsic queries (it throws, which collapses the whole
    // dialog to zero size — the pad then never renders). Leaving ~120px for the
    // dialog insets + content padding keeps the square inside the dialog.
    final side = (MediaQuery.sizeOf(context).width - 120).clamp(200.0, 320.0);
    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      title: const Text('Draw an icon'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Square drawing surface ──────────────────────────────────
            Center(
              child: SizedBox(
                width: side,
                height: side,
                child: RepaintBoundary(
                  key: _canvasKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black54, width: 2),
                    ),
                    child: GestureDetector(
                      onPanStart: (d) => _startStroke(d.localPosition),
                      onPanUpdate: (d) => _extendStroke(d.localPosition),
                      child: CustomPaint(
                        painter: _DrawPainter(_strokes, _repaint),
                        size: Size(side, side),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ─── Colour palette + pen/eraser toggle ──────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final color in _palette)
                  _Swatch(
                    color: color,
                    selected: !_erasing && _penColor == color,
                    onTap: () => setState(() {
                      _penColor = color;
                      _erasing = false;
                    }),
                  ),
                _ToolButton(
                  icon: Icons.brush,
                  tooltip: 'Pen',
                  selected: !_erasing,
                  onTap: () => setState(() => _erasing = false),
                ),
                _ToolButton(
                  icon: Icons.cleaning_services,
                  tooltip: 'Eraser',
                  selected: _erasing,
                  onTap: () => setState(() => _erasing = true),
                ),
                _ToolButton(
                  icon: Icons.undo,
                  tooltip: 'Undo',
                  selected: false,
                  onTap: _undo,
                ),
                _ToolButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Clear',
                  selected: false,
                  onTap: _clear,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ─── Pen width slider ────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.line_weight, size: 20),
                Expanded(
                  child: Slider(
                    value: _penWidth,
                    min: 1,
                    max: 30,
                    onChanged: (v) => setState(() => _penWidth = v),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    _penWidth.round().toString(),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Use Drawing'),
        ),
      ],
    );
  }
}

class _DrawPainter extends CustomPainter {
  final List<_Stroke> strokes;

  _DrawPainter(this.strokes, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // White background so the captured image isn't transparent.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white,
    );
    // Clip so strokes never bleed past the square edge.
    canvas.clipRect(Offset.zero & size);
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length == 1) {
        // A single tap renders as a dot.
        canvas.drawPoints(ui.PointMode.points, stroke.points, paint);
      } else {
        final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (final p in stroke.points.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  // Repaints are driven by the [Listenable] passed to super, so there's no
  // need to repaint on delegate swap.
  @override
  bool shouldRepaint(_DrawPainter oldDelegate) => false;
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppTheme.focusHighlight : Colors.black26,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // A plain Semantics label rather than a Tooltip: Tooltip is built on
    // OverlayPortal, which fails to lay out inside this dialog on the current
    // Flutter version (floods the log with semantics/hit-test assertions and
    // stops the pad rendering). The hover tooltip is non-essential on a
    // touch-first AAC app; the label keeps screen-reader accessibility.
    return Semantics(
      label: tooltip,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.secondary.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppTheme.secondary : Colors.black26,
              width: selected ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.isHighContrast ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
