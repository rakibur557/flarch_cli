import 'dart:io';
import '../../core/utils/logger.dart';

/// Cleans pubspec.yaml by removing unnecessary comments
class PubspecCleaner {
  /// Clean pubspec.yaml file
  static Future<bool> cleanPubspec() async {
    final pubspecPath = 'pubspec.yaml';

    if (!File(pubspecPath).existsSync()) {
      Logger.error('pubspec.yaml not found in the current directory.');
      return false;
    }

    try {
      final file = File(pubspecPath);
      final content = await file.readAsString();

      // Backup original content
      final originalContent = content;

      // Split into lines
      final lines = content.split('\n');
      final cleanedLines = <String>[];

      for (var line in lines) {
        // Skip lines that are only comments or whitespace + comments
        if (line.trim().startsWith('#')) {
          continue;
        }

        // Handle inline comments - keep the line but remove the comment part
        if (line.contains('#')) {
          // Check if # is inside a string (don't remove those)
          int quoteCount = 0;
          int commentPos = -1;

          for (int i = 0; i < line.length; i++) {
            final char = line[i];

            if (char == '"' || char == "'") {
              quoteCount++;
            } else if (char == '#' && quoteCount % 2 == 0) {
              // This is a comment, not inside a string
              commentPos = i;
              break;
            }
          }

          if (commentPos > 0) {
            // Remove comment part
            line = line.substring(0, commentPos).trimRight();
          }
        }

        // Only add non-empty lines, but preserve empty lines for structure
        if (line.isEmpty || line.trim().isNotEmpty) {
          cleanedLines.add(line);
        }
      }

      // Clean up excessive blank lines (more than 2 consecutive)
      final finalLines = <String>[];
      int blankLineCount = 0;

      for (var line in cleanedLines) {
        if (line.trim().isEmpty) {
          blankLineCount++;
          if (blankLineCount <= 2) {
            finalLines.add(line);
          }
        } else {
          blankLineCount = 0;
          finalLines.add(line);
        }
      }

      // Remove trailing blank lines
      while (finalLines.isNotEmpty && finalLines.last.trim().isEmpty) {
        finalLines.removeLast();
      }

      final cleanedContent = finalLines.join('\n');

      // Add a trailing newline if the original had one
      final finalContent =
          cleanedContent + (originalContent.endsWith('\n') ? '\n' : '');

      // Only write if content changed
      if (finalContent != originalContent) {
        await file.writeAsString(finalContent);
        Logger.success(
            'pubspec.yaml cleaned successfully. Removed all unnecessary comments.');
        return true;
      } else {
        Logger.info('pubspec.yaml is already clean. No comments to remove.');
        return true;
      }
    } catch (e) {
      Logger.error('Failed to clean pubspec.yaml: $e');
      return false;
    }
  }

  /// Show preview of what will be cleaned (dry run)
  static Future<void> previewClean() async {
    final pubspecPath = 'pubspec.yaml';

    if (!File(pubspecPath).existsSync()) {
      Logger.error('pubspec.yaml not found in the current directory.');
      return;
    }

    try {
      final file = File(pubspecPath);
      final content = await file.readAsString();
      final lines = content.split('\n');
      int commentCount = 0;
      int inlineCommentCount = 0;

      for (var line in lines) {
        if (line.trim().startsWith('#')) {
          commentCount++;
        } else if (line.contains('#') && !line.trim().startsWith('#')) {
          // Check if it's likely a comment (not in a string)
          final commentIndex = line.indexOf('#');
          final beforeComment = line.substring(0, commentIndex).trim();
          if (beforeComment.isNotEmpty &&
              !beforeComment.endsWith('"') &&
              !beforeComment.endsWith("'")) {
            inlineCommentCount++;
          }
        }
      }

      if (commentCount > 0 || inlineCommentCount > 0) {
        Logger.info(
            'Found $commentCount full comment lines and $inlineCommentCount inline comments.');
        Logger.info('Run "flarch clean pubspec" to remove them.');
      } else {
        Logger.info('No comments found in pubspec.yaml.');
      }
    } catch (e) {
      Logger.error('Failed to preview pubspec.yaml: $e');
    }
  }
}
