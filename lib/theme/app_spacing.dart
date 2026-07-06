/// 4pt-based spacing scale for consistent layout across the app.
///
/// Usage: `SizedBox(height: AppSpacing.md)` instead of `SizedBox(height: 16)`.
abstract final class AppSpacing {
  /// 4pt
  static const double xs = 4;

  /// 8pt
  static const double sm = 8;

  /// 12pt
  static const double md12 = 12;

  /// 16pt
  static const double md = 16;

  /// 24pt
  static const double lg = 24;

  /// 32pt
  static const double xl = 32;

  /// 48pt
  static const double xxl = 48;

  /// Standard screen-edge horizontal padding.
  static const double screenPadding = md;

  /// Standard card internal padding.
  static const double cardPadding = md;
}
