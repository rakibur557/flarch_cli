import 'dart:io';
import 'logger.dart';

/// Custom prompt utility with full control over spacing and colors
class Prompter {
  // RGB Color helper
  static String rgb(int r, int g, int b, {bool bold = false}) {
    final boldCode = bold ? '1;' : '';
    return '\x1B[${boldCode}38;2;$r;$g;${b}m';
  }

  // Color scheme - matches flarch_commands.dart
  static final promptColor = rgb(135, 206, 250, bold: true); // Sky blue
  static final optionColor = rgb(255, 255, 255); // White
  static final selectedColor = rgb(46, 204, 113); // Green
  static final defaultColor = rgb(200, 200, 200); // Light gray
  static const reset = '\x1B[0m';

  /// Prompt for selection from a list of options
  /// Returns the selected option or null if cancelled
  static T? select<T>({
    required String message,
    required List<T> options,
    required String Function(T) displayText,
    T? defaultValue,
    bool compact = true, // Control spacing
  }) {
    // Display prompt message (no extra newlines)
    stdout.write('$promptColor$message$reset');
    if (defaultValue != null) {
      stdout
          .write(' $defaultColor(default: ${displayText(defaultValue)})$reset');
    }
    stdout.write(': ');
    stdout.writeln();

    // Display options with minimal spacing
    for (var i = 0; i < options.length; i++) {
      final option = options[i];
      final isDefault = defaultValue != null && option == defaultValue;
      final number = '${i + 1})';

      if (isDefault) {
        stdout.writeln(
            '  $optionColor$number$reset ${displayText(option)} $defaultColor[Default]$reset');
      } else {
        stdout.writeln('  $optionColor$number$reset ${displayText(option)}');
      }
    }

    if (!compact) {
      stdout.writeln();
    }

    // Get user input
    stdout.write('  $promptColor>$reset ');
    final input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) {
      return defaultValue;
    }

    // Try to parse as number
    final number = int.tryParse(input);
    if (number != null && number >= 1 && number <= options.length) {
      stdout.writeln(
          '$selectedColor✓$reset Selected: ${displayText(options[number - 1])}');
      return options[number - 1];
    }

    // Try to match by text
    for (var option in options) {
      if (displayText(option).toLowerCase() == input.toLowerCase()) {
        stdout
            .writeln('$selectedColor✓$reset Selected: ${displayText(option)}');
        return option;
      }
    }

    return defaultValue;
  }

  /// Prompt for text input
  static String? text({
    required String message,
    String? defaultValue,
    bool Function(String)? validate,
    bool compact = true,
  }) {
    stdout.write('$promptColor$message$reset');
    if (defaultValue != null && defaultValue.isNotEmpty) {
      stdout.write(' $defaultColor(default: $defaultValue)$reset');
    }
    stdout.write(': ');

    if (!compact) {
      stdout.writeln();
    }

    final input = stdin.readLineSync()?.trim() ?? '';

    if (input.isEmpty && defaultValue != null) {
      if (!compact) stdout.writeln();
      return defaultValue;
    }

    if (input.isEmpty) {
      if (!compact) stdout.writeln();
      return null;
    }

    if (validate != null && !validate(input)) {
      Logger.error('Invalid input. Please try again.');
      return text(
          message: message,
          defaultValue: defaultValue,
          validate: validate,
          compact: compact);
    }

    if (!compact) stdout.writeln();
    return input;
  }

  /// Prompt for yes/no confirmation
  static bool confirm({
    required String message,
    bool defaultValue = false,
    bool compact = true,
  }) {
    final defaultText = defaultValue ? 'Y' : 'y';
    final nonDefaultText = defaultValue ? 'n' : 'N';

    stdout.write(
        '$promptColor$message$reset $defaultColor($defaultText/$nonDefaultText)$reset: ');

    if (!compact) {
      stdout.writeln();
    }

    final input = stdin.readLineSync()?.trim().toLowerCase();

    if (input == null || input.isEmpty) {
      return defaultValue;
    }

    if (input.startsWith('y')) {
      if (!compact) stdout.writeln();
      return true;
    } else if (input.startsWith('n')) {
      if (!compact) stdout.writeln();
      return false;
    }

    return defaultValue;
  }
}
