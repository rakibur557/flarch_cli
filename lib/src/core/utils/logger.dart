/// Centralizes logging and user feedback with consistent formatting
class Logger {
  // RGB Color helper
  static String rgb(int r, int g, int b, {bool bold = false}) {
    final boldCode = bold ? '1;' : '';
    return '\x1B[${boldCode}38;2;$r;$g;${b}m';
  }

  // Color scheme - matches project colors
  static final successColor = rgb(46, 204, 113); // Green for success
  static final errorColor = rgb(231, 76, 60); // Red for errors
  static final infoColor = rgb(52, 152, 219); // Blue for info
  static final warningColor = rgb(241, 196, 15); // Yellow for warnings
  static const reset = '\x1B[0m';

  /// Log a success message with consistent formatting
  /// Format: ✓ - [message]
  static void success(String message) {
    print('$successColor✓$reset $successColor$message$reset');
  }

  /// Log an error message with consistent formatting
  /// Format: ✗ Error: [message]
  static void error(String message) {
    print('$errorColor✗ Error:$reset $errorColor$message$reset');
  }

  /// Log an info message with consistent formatting
  /// Format: ℹ️ [message]
  static void info(String message) {
    print('$infoColorℹ️$reset  $infoColor$message$reset');
  }

  /// Log a warning message with consistent formatting
  /// Format: ⚠️ Warning: [message]
  static void warning(String message) {
    print('$warningColor⚠️  Warning:$reset $warningColor$message$reset');
  }

  /// Print a header with title
  static void header(String title) {
    final headerColor = rgb(135, 206, 250, bold: true);
    const width = 60;
    final padding = (width - title.length) ~/ 2;
    final leftPadding = padding;
    final rightPadding = width - title.length - leftPadding;
    print('');
    print('$headerColor${'=' * width}$reset');
    print('$headerColor${' ' * leftPadding}$title${' ' * rightPadding}$reset');
    print('$headerColor${'=' * width}$reset');
    print('');
  }

  /// Print a progress step
  static void step(int current, int total, String message) {
    final stepColor = rgb(135, 206, 250);
    print('$stepColor[$current/$total]$reset $stepColor$message$reset');
  }

  /// Print a section divider
  static void divider() {
    final dividerColor = rgb(100, 100, 100);
    print('$dividerColor${'─' * 60}$reset');
  }

  /// Print a summary box
  static void summary(String title, List<String> items) {
    final summaryColor = rgb(46, 204, 113);
    final boxColor = rgb(135, 206, 250);
    print('');
    print('$boxColor╔${'═' * 58}╗$reset');
    print(
        '$boxColor║$reset $summaryColor$title$reset${' ' * (56 - title.length)}$boxColor║$reset');
    print('$boxColor╠${'═' * 58}╣$reset');
    for (final item in items) {
      print(
          '$boxColor║$reset $summaryColor✓$reset $item${' ' * (56 - item.length - 2)}$boxColor║$reset');
    }
    print('$boxColor╚${'═' * 58}╝$reset');
    print('');
  }
}
