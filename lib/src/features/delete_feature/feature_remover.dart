import 'dart:io';

import 'package:flarch/src/core/utils/logger.dart';
import 'package:flarch/src/core/utils/prompter.dart';
import 'package:flarch/src/core/utils/utility.dart';

/// Safely removes a feature and cleans up all related files and registrations
class FeatureRemover {
  /// Remove a feature safely
  static Future<bool> removeFeature(String featureName) async {
    final featurePath = 'lib/features/$featureName';
    final featureDirectory = Directory(featurePath);

    // Check if feature exists
    if (!featureDirectory.existsSync()) {
      Logger.error('Feature "$featureName" does not exist.');
      return false;
    }

    // Confirm removal
    final confirmed = Prompter.confirm(
      message:
          '⚡ Are you sure you want to delete feature "$featureName"? This will delete all files and registrations.',
      defaultValue: false,
      compact: true,
    );

    if (!confirmed) {
      Logger.info('Deleting feature cancelled.');
      return false;
    }

    try {
      // 1. Clean up GetIt registrations in injection.dart
      await _removeGetItRegistrations(featureName);

      // 2. Remove the feature directory
      await _removeFeatureDirectory(featurePath);

      Logger.success('Feature "$featureName" deleted successfully.');
      return true;
    } catch (e) {
      Logger.error('Failed to delete feature "$featureName": $e');
      return false;
    }
  }

  /// Remove GetIt registrations for the feature
  static Future<void> _removeGetItRegistrations(String featureName) async {
    final injectionFilePath = 'lib/injection.dart';

    if (!File(injectionFilePath).existsSync()) {
      Logger.info('No injection.dart file found. Skipping GetIt cleanup.');
      return;
    }

    final injectionFile = File(injectionFilePath);
    String content = await injectionFile.readAsString();
    String originalContent = content;

    final className = Utility.convertCase(featureName, toCamelCase: true);
    final methodName = '_setUp$className';

    // Remove imports related to this feature (line by line)
    final lines = content.split('\n');
    final cleanedLines = <String>[];

    for (var line in lines) {
      // Check if line is an import for this feature
      if (line.trim().startsWith('import') &&
          (line.contains("'features/$featureName/") ||
              line.contains('"features/$featureName/'))) {
        continue; // Skip this import line
      }
      cleanedLines.add(line);
    }

    content = cleanedLines.join('\n');

    // Remove the setup method using proper brace matching
    final methodPattern = RegExp(
      '\\n?\\s*Future<void>\\s+$methodName\\s*\\(\\)\\s*async\\s*\\{',
      multiLine: true,
    );

    if (methodPattern.hasMatch(content)) {
      final match = methodPattern.firstMatch(content);
      if (match != null) {
        int start = match.start;
        int braceCount = 0;
        int end = start;

        // Find the matching closing brace
        for (int i = start; i < content.length; i++) {
          final char = content[i];

          if (char == '{') {
            braceCount++;
          } else if (char == '}') {
            braceCount--;
            if (braceCount == 0) {
              end = i + 1;
              // Include trailing newline if present
              if (end < content.length && content[end] == '\n') {
                end++;
              }
              break;
            }
          }
        }

        if (end > start) {
          // Remove the method
          content = content.substring(0, start) + content.substring(end);
        }
      }
    }

    // Remove the init() call - look for the await statement
    final initCallPattern = RegExp(
      '\\s*await\\s+$methodName\\(\\);?\\s*\\n',
      multiLine: true,
    );
    final initCallPattern2 = RegExp(
      '\\s*await\\s+$methodName\\(\\);?\\s*',
      multiLine: true,
    );

    if (initCallPattern.hasMatch(content)) {
      content = content.replaceAll(initCallPattern, '');
    } else if (initCallPattern2.hasMatch(content)) {
      content = content.replaceAll(initCallPattern2, '');
    }

    // Clean up extra blank lines (more than 2 consecutive)
    content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Trim trailing whitespace from each line
    final finalLines =
        content.split('\n').map((line) => line.trimRight()).join('\n');
    content = finalLines;

    // Only write if content changed
    if (content != originalContent) {
      await injectionFile.writeAsString(content);
      Logger.success('GetIt registrations deleted from injection.dart');
    } else {
      Logger.info('No GetIt registrations found for this feature.');
    }
  }

  /// Remove the feature directory
  static Future<void> _removeFeatureDirectory(String featurePath) async {
    final featureDirectory = Directory(featurePath);

    if (featureDirectory.existsSync()) {
      await featureDirectory.delete(recursive: true);
      Logger.success('Feature directory deleted: $featurePath');
    } else {
      Logger.warning('Feature directory not found: $featurePath');
    }
  }

  /// Get list of all features
  static List<String> getAvailableFeatures() {
    final featuresDirectory = Directory('lib/features');

    if (!featuresDirectory.existsSync()) {
      return [];
    }

    return featuresDirectory
        .listSync()
        .whereType<Directory>()
        .map((dir) => dir.path.split(Platform.pathSeparator).last)
        .toList();
  }
}
