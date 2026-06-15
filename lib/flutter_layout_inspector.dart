/// Flutter Layout Inspector
///
/// A zero-dependency debug tool. Wrap your root widget:
///
/// ```dart
/// void main() {
///   runApp(LayoutInspector(child: const MyApp()));
/// }
/// ```
///
/// Tap the 🔍 FAB to activate, then tap any widget to inspect it.
/// Automatically disabled in release builds — safe to leave in production.
library flutter_layout_inspector;

export 'src/layout_inspector.dart' show LayoutInspector;
