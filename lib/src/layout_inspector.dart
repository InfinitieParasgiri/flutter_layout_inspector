// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC API
// ─────────────────────────────────────────────────────────────────────────────

/// Wrap your root widget (or [MaterialApp]) with [LayoutInspector].
///
/// ```dart
/// void main() {
///   runApp(LayoutInspector(child: const MyApp()));
/// }
/// ```
///
/// - Tap the 🔍 FAB (bottom-right) to activate inspect mode.
/// - Tap any widget to see its type, screen, file, size, and position.
/// - Full details are also printed to the debug console.
/// - Completely disabled (zero overhead) in release builds.
class LayoutInspector extends StatefulWidget {
  /// The app (or widget subtree) to inspect.
  final Widget child;

  const LayoutInspector({super.key, required this.child});

  @override
  State<LayoutInspector> createState() => _LayoutInspectorState();
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _WidgetInfo {
  final String widgetType;
  final String screenName;
  final String filePath;
  final double width;
  final double height;
  final double x;
  final double y;
  final Offset tapPosition;

  const _WidgetInfo({
    required this.widgetType,
    required this.screenName,
    required this.filePath,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.tapPosition,
  });

  String get sizeLabel => '${width.toInt()} × ${height.toInt()} px';
  String get posLabel => '(${x.toInt()}, ${y.toInt()})';
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D1117);
const _kBgDeep = Color(0xFF080C10);
const _kBorder = Color(0xFF1E2D3D);
const _kCyan = Color(0xFF00E5FF);
const _kGreen = Color(0xFF4ADE80);
const _kYellow = Color(0xFFFFD54F);
const _kPink = Color(0xFFFF6B9D);
const _kPurple = Color(0xFFB39DDB);
const _kMuted = Color(0xFF4A5568);
const _kDimText = Color(0xFF2D3748);

// ─────────────────────────────────────────────────────────────────────────────
// SKIP LIST — noisy Flutter internals that clutter results
// ─────────────────────────────────────────────────────────────────────────────

const _kSkip = {
  'Semantics',
  '_RawGestureDetectorState',
  'MouseRegion',
  'Listener',
  'AbsorbPointer',
  'IgnorePointer',
  'RepaintBoundary',
  'FocusScope',
  '_FocusMarker',
  'Actions',
  'Shortcuts',
  'ScrollConfiguration',
  'DefaultTextStyle',
  'IconTheme',
  'AnimatedTheme',
  'Builder',
  '_ModalScope',
  'Overlay',
  '_Theater',
  '_LayoutInspectorState',
  '_InspectorFab',
  '_InspectorPanel',
  'GestureDetector',
  '_GestureDetector',
  'RawGestureDetector',
  'CustomPaint',
  'LayoutInspector',
};

// ─────────────────────────────────────────────────────────────────────────────
// MAIN STATE
// ─────────────────────────────────────────────────────────────────────────────

class _LayoutInspectorState extends State<LayoutInspector>
    with TickerProviderStateMixin {
  static const double _fabSize = 46;
  static const double _fabMargin = 16;
  static const double _fabDefaultBottomInset = 90;

  bool _active = false;
  _WidgetInfo? _info;
  Offset? _panelPos;
  Offset? _fabPos;

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeOut,
  );

  // ── Hit-test: walk the element tree, find the smallest hit widget ──────────

  void _onTap(TapDownDetails d) {
    if (!_active) return;
    final pos = d.globalPosition;
    _WidgetInfo? best;
    double bestArea = double.infinity;

    void walk(Element el) {
      final ro = el.renderObject;
      if (ro is RenderBox && ro.attached) {
        try {
          final origin = ro.localToGlobal(Offset.zero);
          final size = ro.size;
          final rect = origin & size;
          final type = el.widget.runtimeType.toString();

          if (rect.contains(pos) &&
              size.width > 2 &&
              size.height > 2 &&
              !_kSkip.contains(type)) {
            final area = size.width * size.height;
            if (area < bestArea) {
              bestArea = area;
              best = _WidgetInfo(
                widgetType: type,
                screenName: _screenName(el),
                filePath: _filePath(el),
                width: size.width,
                height: size.height,
                x: origin.dx,
                y: origin.dy,
                tapPosition: pos,
              );
            }
          }
        } catch (_) {}
      }
      el.visitChildren(walk);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(walk);

    if (best != null) {
      _logInfo(best!);
      setState(() {
        _info = best;
        _panelPos = _safePos(pos);
      });
      _fadeCtrl.forward(from: 0);
    }
  }

  // ── Walk ancestors to find the enclosing Screen / Page / View ─────────────

  String _screenName(Element el) {
    String found = 'Unknown Screen';
    el.visitAncestorElements((a) {
      final t = a.widget.runtimeType.toString();
      if (t.contains('Screen') ||
          t.contains('Page') ||
          t.contains('View') ||
          t.endsWith('Route')) {
        found = t;
        return false;
      }
      return true;
    });
    return found;
  }

  // ── Best-effort file path extraction ──────────────────────────────────────

  String _filePath(Element el) {
    // Method 1: diagnostics string may include file info
    try {
      final desc = el.toDiagnosticsNode().toStringDeep();
      final m = RegExp(r'([a-zA-Z0-9_/]+\.dart:\d+)').firstMatch(desc);
      if (m != null) return m.group(1)!;
    } catch (_) {}

    // Method 2: guess path from snake_cased class name
    final raw = el.widget.runtimeType.toString();
    final snake = raw
        .replaceAllMapped(
          RegExp(r'(?<=[a-z])([A-Z])'),
          (m) => '_${m.group(1)!.toLowerCase()}',
        )
        .toLowerCase();
    return 'lib/**/$snake.dart';
  }

  // ── Console log with filtered stack trace ─────────────────────────────────

  void _logInfo(_WidgetInfo info) {
    if (!kDebugMode) return;
    print('');
    print('┌─── 🔍 Layout Inspector ────────────────────────');
    print('│  Widget  : ${info.widgetType}');
    print('│  Screen  : ${info.screenName}');
    print('│  File    : ${info.filePath}');
    print('│  Size    : ${info.sizeLabel}');
    print('│  Position: ${info.posLabel}');
    print('└────────────────────────────────────────────────');
    print('  Stack trace (find your file below):');

    final frames = StackTrace.current.toString().split('\n');
    var count = 0;
    for (final frame in frames) {
      if (frame.contains('.dart') &&
          !frame.contains('package:flutter/') &&
          !frame.contains('layout_inspector.dart') &&
          !frame.contains('dart:') &&
          count < 6) {
        print('  $frame');
        count++;
      }
    }
    print('');
  }

  // ── Keep panel on screen ──────────────────────────────────────────────────

  Offset _safePos(Offset tap) {
    final s = MediaQuery.of(context).size;
    const w = 290.0, h = 240.0;
    double x = tap.dx + 14, y = tap.dy + 14;
    if (x + w > s.width) x = tap.dx - w - 14;
    if (y + h > s.height) y = tap.dy - h - 14;
    return Offset(x.clamp(8, s.width - w - 8), y.clamp(8, s.height - h - 8));
  }

  void _dismiss() => _fadeCtrl.reverse().then((_) {
    if (mounted) setState(() => _info = null);
  });

  void _toggle() => setState(() {
    _active = !_active;
    if (!_active) _dismiss();
  });

  Offset _clampFabPos(Offset pos, Size size) {
    final maxX = size.width - _fabSize - _fabMargin;
    final maxY = size.height - _fabSize - _fabMargin;
    return Offset(
      pos.dx.clamp(_fabMargin, maxX),
      pos.dy.clamp(_fabMargin, maxY),
    );
  }

  Offset _resolvedFabPos(Size size) {
    return _fabPos ??
        Offset(
          size.width - _fabSize - _fabMargin,
          size.height - _fabSize - _fabDefaultBottomInset,
        );
  }

  void _moveFab(Offset delta) {
    final size = MediaQuery.of(context).size;
    final next = _clampFabPos(_resolvedFabPos(size) + delta, size);
    setState(() => _fabPos = next);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Release mode: completely transparent, zero overhead
    if (kReleaseMode) return widget.child;

    final screenSize = MediaQuery.of(context).size;
    final fabPos = _clampFabPos(_resolvedFabPos(screenSize), screenSize);

    return Stack(
      children: [
        widget.child,

        // Tap interceptor — only when active
        if (_active)
          Positioned.fill(
            child: GestureDetector(
              onTapDown: _onTap,
              behavior: HitTestBehavior.translucent,
              child: CustomPaint(
                painter: _info == null ? null : _HighlightPainter(_info!),
                child: const SizedBox.expand(),
              ),
            ),
          ),

        // Info panel
        if (_info != null && _panelPos != null)
          Positioned(
            left: _panelPos!.dx,
            top: _panelPos!.dy,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _InspectorPanel(info: _info!, onClose: _dismiss),
            ),
          ),

        // FAB toggle
        Positioned(
          left: fabPos.dx,
          top: fabPos.dy,
          child: _InspectorFab(
            active: _active,
            onTap: _toggle,
            onDrag: _moveFab,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HIGHLIGHT PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _HighlightPainter extends CustomPainter {
  final _WidgetInfo info;
  _HighlightPainter(this.info);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(info.x, info.y, info.width, info.height);

    // Glow fill
    canvas.drawRect(rect.inflate(3), Paint()..color = _kCyan.withOpacity(0.08));

    // Dashed border
    _drawDashedRect(canvas, rect, _kCyan, 2.0);

    // Corner accents
    _drawCorners(canvas, rect);

    // Size badge
    _drawBadge(canvas, rect, info.sizeLabel);
  }

  void _drawDashedRect(Canvas c, Rect r, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    const dash = 6.0, gap = 4.0;

    void drawDashedLine(Offset a, Offset b) {
      final total = (b - a).distance;
      final dir = (b - a) / total;
      double pos = 0;
      while (pos < total) {
        final end = (pos + dash).clamp(0.0, total);
        c.drawLine(a + dir * pos, a + dir * end, paint);
        pos += dash + gap;
      }
    }

    drawDashedLine(r.topLeft, r.topRight);
    drawDashedLine(r.topRight, r.bottomRight);
    drawDashedLine(r.bottomRight, r.bottomLeft);
    drawDashedLine(r.bottomLeft, r.topLeft);
  }

  void _drawCorners(Canvas c, Rect r) {
    final p = Paint()
      ..color = _kCyan
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const len = 10.0;

    c.drawLine(r.topLeft, r.topLeft + const Offset(len, 0), p);
    c.drawLine(r.topLeft, r.topLeft + const Offset(0, len), p);
    c.drawLine(r.topRight, r.topRight + const Offset(-len, 0), p);
    c.drawLine(r.topRight, r.topRight + const Offset(0, len), p);
    c.drawLine(r.bottomLeft, r.bottomLeft + const Offset(len, 0), p);
    c.drawLine(r.bottomLeft, r.bottomLeft + const Offset(0, -len), p);
    c.drawLine(r.bottomRight, r.bottomRight + const Offset(-len, 0), p);
    c.drawLine(r.bottomRight, r.bottomRight + const Offset(0, -len), p);
  }

  void _drawBadge(Canvas c, Rect r, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: _kBg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const pad = 5.0;
    final bw = tp.width + pad * 2;
    final bh = tp.height + pad;
    final bx = r.left;
    final by = r.top - bh - 2;

    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, bw, bh),
        const Radius.circular(4),
      ),
      Paint()..color = _kCyan,
    );
    tp.paint(c, Offset(bx + pad, by + pad / 2));
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => old.info != info;
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _InspectorPanel extends StatelessWidget {
  final _WidgetInfo info;
  final VoidCallback onClose;

  const _InspectorPanel({required this.info, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 290,
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: _kCyan.withOpacity(0.12),
              blurRadius: 24,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Color(0xCC000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            const _Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Column(
                children: [
                  _row(
                    Icons.widgets_outlined,
                    'WIDGET',
                    info.widgetType,
                    _kCyan,
                  ),
                  _row(
                    Icons.phone_android_outlined,
                    'SCREEN',
                    info.screenName,
                    _kGreen,
                  ),
                  _row(
                    Icons.insert_drive_file_outlined,
                    'FILE',
                    info.filePath,
                    _kYellow,
                  ),
                  _row(
                    Icons.straighten_outlined,
                    'SIZE',
                    info.sizeLabel,
                    _kPink,
                  ),
                  _row(
                    Icons.place_outlined,
                    'POSITION',
                    info.posLabel,
                    _kPurple,
                  ),
                ],
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
    child: Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: _kCyan,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'LAYOUT INSPECTOR',
          style: TextStyle(
            color: _kCyan,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            fontFamily: 'monospace',
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _kDimText.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.close, color: _kMuted, size: 13),
          ),
        ),
      ],
    ),
  );

  Widget _row(IconData icon, String label, String value, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 13),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() => Container(
    decoration: const BoxDecoration(
      color: _kBgDeep,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(14),
        bottomRight: Radius.circular(14),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(
      children: const [
        Icon(Icons.terminal_outlined, color: _kMuted, size: 10),
        SizedBox(width: 5),
        Expanded(
          child: Text(
            'Full trace in console  •  debug only',
            style: TextStyle(
              color: _kMuted,
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(color: _kBorder, height: 1, thickness: 1);
}

// ─────────────────────────────────────────────────────────────────────────────
// FAB TOGGLE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _InspectorFab extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;
  final ValueChanged<Offset> onDrag;

  const _InspectorFab({
    required this.active,
    required this.onTap,
    required this.onDrag,
  });

  @override
  State<_InspectorFab> createState() => _InspectorFabState();
}

class _InspectorFabState extends State<_InspectorFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: (details) => widget.onDrag(details.delta),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.active ? _kCyan : _kBg,
            border: Border.all(
              color: widget.active ? _kCyan : _kBorder,
              width: 1.5,
            ),
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: Color.lerp(
                        _kCyan.withOpacity(0.3),
                        _kCyan.withOpacity(0.7),
                        _pulse.value,
                      )!,
                      blurRadius: 18 + _pulse.value * 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Icon(
            widget.active ? Icons.search_off_rounded : Icons.search_rounded,
            color: widget.active ? _kBgDeep : _kMuted,
            size: 20,
          ),
        ),
      ),
    );
  }
}
