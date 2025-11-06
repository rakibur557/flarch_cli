import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';

/// Manages directory tree visualization
class TreeManager {
  /// Show directory tree structure
  static Future<void> showTree({String? rootPath, int maxDepth = 5}) async {
    try {
      final root = rootPath ?? Directory.current.path;
      final rootDir = Directory(root);

      if (!rootDir.existsSync()) {
        Logger.error('Directory not found: $root');
        return;
      }

      Logger.header('📁 Project Directory Tree');

      // Get the project name or use current directory name
      final projectName = path.basename(root);
      final projectColor = Logger.rgb(135, 206, 250, bold: true);
      final resetCode = Logger.reset;
      print('$projectColor$projectName$resetCode');

      // Print tree structure
      await _printTree(rootDir, '', '', maxDepth, 0);

      print('');
    } catch (e) {
      Logger.error('Failed to generate tree: $e');
    }
  }

  /// Recursively print directory tree
  static Future<void> _printTree(
    Directory dir,
    String prefix,
    String currentPrefix,
    int maxDepth,
    int currentDepth,
  ) async {
    if (currentDepth >= maxDepth) {
      final limitColor = Logger.rgb(100, 100, 100);
      final resetCode = Logger.reset;
      print('$currentPrefix$limitColor... (depth limit reached)$resetCode');
      return;
    }

    try {
      final entries = dir.listSync()
        ..sort((a, b) {
          // Sort: directories first, then files
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });

      // Filter out common ignored directories/files
      final filteredEntries = entries.where((entry) {
        final name = path.basename(entry.path);
        return !_shouldIgnore(name);
      }).toList();

      for (int i = 0; i < filteredEntries.length; i++) {
        final entry = filteredEntries[i];
        final isLast = i == filteredEntries.length - 1;
        final name = path.basename(entry.path);

        // Determine prefix characters
        final connector = isLast ? '└── ' : '├── ';
        final nextPrefix = isLast ? '    ' : '│   ';

        if (entry is Directory) {
          // Directory
          final dirColor = Logger.rgb(135, 206, 250);
          final resetCode = Logger.reset;
          print('$currentPrefix$connector$dirColor$name/$resetCode');

          if (currentDepth < maxDepth - 1) {
            await _printTree(
              entry,
              prefix,
              '$currentPrefix$nextPrefix',
              maxDepth,
              currentDepth + 1,
            );
          }
        } else if (entry is File) {
          // File
          final extension = path.extension(name);
          final color = _getFileColor(extension);
          final resetCode = Logger.reset;
          print('$currentPrefix$connector$color$name$resetCode');
        }
      }
    } catch (e) {
      // Skip directories that can't be accessed
    }
  }

  /// Check if a file/directory should be ignored
  static bool _shouldIgnore(String name) {
    // Common ignored files and directories
    final ignored = [
      '.dart_tool',
      '.git',
      '.idea',
      '.vscode',
      'build',
      'node_modules',
      '.packages',
      '.pub',
      'pubspec.lock',
      '.DS_Store',
      'Thumbs.db',
      '.gitignore',
      '.gitattributes',
    ];

    // Also ignore hidden files on Unix-like systems
    if (name.startsWith('.') && !ignored.contains(name)) {
      // Allow some common config files
      if (name == '.env' || name == '.env.example') {
        return false;
      }
      return true;
    }

    return ignored.contains(name);
  }

  /// Get color for file based on extension
  static String _getFileColor(String extension) {
    final colorMap = {
      '.dart': Logger.rgb(52, 152, 219), // Blue for Dart files
      '.yaml': Logger.rgb(46, 204, 113), // Green for YAML
      '.yml': Logger.rgb(46, 204, 113), // Green for YAML
      '.json': Logger.rgb(241, 196, 15), // Yellow for JSON
      '.md': Logger.rgb(52, 152, 219), // Blue for Markdown
      '.txt': Logger.rgb(200, 200, 200), // Gray for text
      '.png': Logger.rgb(241, 196, 15), // Yellow for images
      '.jpg': Logger.rgb(241, 196, 15),
      '.jpeg': Logger.rgb(241, 196, 15),
      '.gif': Logger.rgb(241, 196, 15),
      '.svg': Logger.rgb(241, 196, 15),
      '.xml': Logger.rgb(52, 152, 219), // Blue for XML
      '.gradle': Logger.rgb(52, 152, 219), // Blue for Gradle
      '.kt': Logger.rgb(52, 152, 219), // Blue for Kotlin
      '.java': Logger.rgb(52, 152, 219), // Blue for Java
      '.swift': Logger.rgb(52, 152, 219), // Blue for Swift
      '.m': Logger.rgb(52, 152, 219), // Blue for Objective-C
      '.plist': Logger.rgb(52, 152, 219), // Blue for plist
    };

    return colorMap[extension.toLowerCase()] ?? Logger.rgb(200, 200, 200);
  }
}
