import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../../core/utils/prompter.dart';
import '../../core/utils/utility.dart';

/// Safely renames a feature and updates all related files and registrations
class FeatureRenamer {
  /// Rename a feature safely
  static Future<bool> renameFeature(String oldFeatureName,
      {String? newFeatureName}) async {
    final oldFeaturePath = 'lib/features/$oldFeatureName';
    final oldFeatureDirectory = Directory(oldFeaturePath);

    // Check if feature exists
    if (!oldFeatureDirectory.existsSync()) {
      Logger.error('Feature "$oldFeatureName" does not exist.');
      return false;
    }

    // Get new feature name
    String? targetNewName = newFeatureName;

    if (targetNewName == null || targetNewName.isEmpty) {
      targetNewName = Prompter.text(
        message: '⚡ Enter new feature name',
        defaultValue: oldFeatureName,
        validate: (value) =>
            value.trim().isNotEmpty && _isValidFeatureName(value.trim()),
        compact: true,
      );

      if (targetNewName == null || targetNewName.isEmpty) {
        Logger.info('Renaming feature cancelled.');
        return false;
      }

      targetNewName = targetNewName.trim();
    }

    // Validate new feature name
    if (!_isValidFeatureName(targetNewName)) {
      Logger.error('Invalid feature name: "$targetNewName"');
      Logger.info(
          'Feature name should be lowercase with underscores (e.g., user_profile, auth)');
      return false;
    }

    // Check if new feature already exists
    final newFeaturePath = 'lib/features/$targetNewName';
    if (Directory(newFeaturePath).existsSync()) {
      Logger.error('Feature "$targetNewName" already exists.');
      return false;
    }

    // Confirm rename
    final confirmed = Prompter.confirm(
      message:
          '⚡ Rename feature "$oldFeatureName" to "$targetNewName"? This will update all references.',
      defaultValue: false,
      compact: true,
    );

    if (!confirmed) {
      Logger.info('Renaming feature cancelled.');
      return false;
    }

    try {
      // 1. Rename the directory
      await _renameDirectory(oldFeaturePath, newFeaturePath);

      // 2. Update GetIt registrations in injection.dart
      await _updateGetItRegistrations(oldFeatureName, targetNewName);

      // 3. Update all imports in the codebase
      await _updateAllImports(oldFeatureName, targetNewName);

      // 4. Update file contents (class names, etc.)
      await _updateFileContents(
          oldFeaturePath, newFeaturePath, oldFeatureName, targetNewName);

      // 5. Rename directories that match the feature name (e.g., bloc/auth/ -> bloc/login/)
      await _renameDirectoriesInFeature(
          newFeaturePath, oldFeatureName, targetNewName);

      // 6. Update imports again after directory renaming (to catch nested directory path changes)
      await _updateNestedDirectoryImports(oldFeatureName, targetNewName);

      Logger.success(
          'Feature "$oldFeatureName" renamed to "$targetNewName" successfully.');
      return true;
    } catch (e) {
      Logger.error('Failed to rename feature "$oldFeatureName": $e');
      return false;
    }
  }

  /// Validate feature name format
  static bool _isValidFeatureName(String name) {
    // Feature name should be lowercase, can contain underscores and numbers
    // Should start with a letter
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name) && name.length > 0;
  }

  /// Rename directory
  static Future<void> _renameDirectory(String oldPath, String newPath) async {
    try {
      final oldDir = Directory(oldPath);
      final newDir = Directory(newPath);

      if (newDir.existsSync()) {
        throw Exception('Target directory already exists: $newPath');
      }

      await oldDir.rename(newPath);
      Logger.success(
          'Renamed directory: ${path.basename(oldPath)} → ${path.basename(newPath)}');
    } catch (e) {
      Logger.error('Failed to rename directory: $e');
      rethrow;
    }
  }

  /// Update GetIt registrations
  static Future<void> _updateGetItRegistrations(
      String oldFeatureName, String newFeatureName) async {
    final injectionFilePath = 'lib/injection.dart';

    if (!File(injectionFilePath).existsSync()) {
      Logger.info('No injection.dart file found. Skipping GetIt updates.');
      return;
    }

    final injectionFile = File(injectionFilePath);
    String content = await injectionFile.readAsString();

    final oldClassName = Utility.convertCase(oldFeatureName, toCamelCase: true);
    final newClassName = Utility.convertCase(newFeatureName, toCamelCase: true);
    final oldMethodName = '_setUp$oldClassName';
    final newMethodName = '_setUp$newClassName';

    // Update method name
    content = content.replaceAll(oldMethodName, newMethodName);

    // Update imports with old feature name
    // Handle both relative imports: 'features/old_feature/...' and package imports
    // This pattern handles: features/old_feature/path/file.dart and replaces old_feature in both path and filename
    final oldImportPattern = RegExp(
        "import ['\"]([^'\"]*features/)$oldFeatureName(/[^'\"]*)['\"];",
        multiLine: true);
    content = content.replaceAllMapped(
      oldImportPattern,
      (match) {
        final prefix = match.group(1) ?? '';
        var suffix = match.group(2) ?? '';
        // Replace feature name in the suffix path as well (e.g., /data_sources/add_data_source.dart)
        suffix = suffix.replaceAll(oldFeatureName, newFeatureName);
        return "import '${prefix}$newFeatureName$suffix';";
      },
    );

    // Also update package imports: package:app/features/old_feature/...
    final packageImportPattern = RegExp(
        "import ['\"]package:([^'/]+)/features/$oldFeatureName(/[^'\"]*)['\"];",
        multiLine: true);
    content = content.replaceAllMapped(
      packageImportPattern,
      (match) {
        final packageName = match.group(1) ?? '';
        var suffix = match.group(2) ?? '';
        // Replace feature name in the suffix path as well
        suffix = suffix.replaceAll(oldFeatureName, newFeatureName);
        return "import 'package:$packageName/features/$newFeatureName$suffix';";
      },
    );

    // Handle export statements too
    final oldExportPattern = RegExp(
        "export ['\"]([^'\"]*features/)$oldFeatureName(/[^'\"]*)['\"];",
        multiLine: true);
    content = content.replaceAllMapped(
      oldExportPattern,
      (match) {
        final prefix = match.group(1) ?? '';
        var suffix = match.group(2) ?? '';
        suffix = suffix.replaceAll(oldFeatureName, newFeatureName);
        return "export '${prefix}$newFeatureName$suffix';";
      },
    );

    // Update class names in registrations
    // Pattern: ${oldClassName}Bloc, ${oldClassName}Repository, etc.
    // Order matters: longer patterns first
    final classPatterns = [
      'RepositoryImplement', // Must come before Repository
      'DataSourceImplement', // Must come before DataSource
      'ViewModel', // Must come before View and Model
      'Bloc',
      'Repository',
      'UseCase',
      'DataSource',
      'Controller',
      'Provider',
      'Model',
      'View',
    ];

    for (final suffix in classPatterns) {
      final oldPattern = RegExp('\\b$oldClassName$suffix\\b');
      content = content.replaceAll(oldPattern, '$newClassName$suffix');
    }

    // Also update class names in type annotations and generic types within injection.dart
    // Pattern: <${oldClassName}Repository>, ${oldClassName}RepositoryImplement(...)
    for (final suffix in classPatterns) {
      // Handle in generic types: <${oldClassName}Repository>
      final genericPattern = RegExp('<\\s*$oldClassName$suffix\\s*>');
      content = content.replaceAll(genericPattern, '<$newClassName$suffix>');

      // Handle in constructor calls: ${oldClassName}RepositoryImplement(...)
      final constructorPattern = RegExp('\\b$oldClassName$suffix\\s*\\(');
      content = content.replaceAll(constructorPattern, '$newClassName$suffix(');
    }

    // Update file path references in comments or strings (using old feature name)
    // But be careful not to replace in strings that are already updated
    content =
        content.replaceAll(RegExp('\\b$oldFeatureName\\b'), newFeatureName);

    await injectionFile.writeAsString(content);
    Logger.success('Updated GetIt registrations in injection.dart');
  }

  /// Update all imports in the codebase
  static Future<void> _updateAllImports(
      String oldFeatureName, String newFeatureName) async {
    final libDir = Directory('lib');
    if (!libDir.existsSync()) {
      return;
    }

    int updatedFiles = 0;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        try {
          var content = await entity.readAsString();
          final originalContent = content;

          // Update import statements
          final importPattern = RegExp(
              "import ['\"]([^'\"]*features/)$oldFeatureName(/[^'\"]*)['\"];",
              multiLine: true);
          content = content.replaceAllMapped(
            importPattern,
            (match) {
              final prefix = match.group(1) ?? '';
              final suffix = match.group(2) ?? '';
              return "import '${prefix}$newFeatureName$suffix';";
            },
          );

          // Update export statements
          final exportPattern = RegExp(
              "export ['\"]([^'\"]*features/)$oldFeatureName(/[^'\"]*)['\"];",
              multiLine: true);
          content = content.replaceAllMapped(
            exportPattern,
            (match) {
              final prefix = match.group(1) ?? '';
              final suffix = match.group(2) ?? '';
              return "export '${prefix}$newFeatureName$suffix';";
            },
          );

          // Update package references (for generated files)
          final packagePattern =
              RegExp("package:([^/]+)/features/$oldFeatureName");
          content = content.replaceAllMapped(
            packagePattern,
            (match) {
              final packageName = match.group(1) ?? '';
              return "package:$packageName/features/$newFeatureName";
            },
          );

          if (content != originalContent) {
            await entity.writeAsString(content);
            updatedFiles++;
          }
        } catch (e) {
          // Skip files that can't be read/written
          continue;
        }
      }
    }

    if (updatedFiles > 0) {
      Logger.success('Updated imports in $updatedFiles file(s)');
    }
  }

  /// Update file contents (class names, etc.)
  static Future<void> _updateFileContents(
    String oldFeaturePath,
    String newFeaturePath,
    String oldFeatureName,
    String newFeatureName,
  ) async {
    final newFeatureDir = Directory(newFeaturePath);
    if (!newFeatureDir.existsSync()) {
      return;
    }

    final oldClassName = Utility.convertCase(oldFeatureName, toCamelCase: true);
    final newClassName = Utility.convertCase(newFeatureName, toCamelCase: true);

    int updatedFiles = 0;

    await for (final entity in newFeatureDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        try {
          var content = await entity.readAsString();
          final originalContent = content;

          // Update class names that match the feature name pattern
          // Order matters: longer patterns first to avoid partial matches
          final classPatterns = [
            'RepositoryImplement', // MVVM repository implementation (check before Repository)
            'DataSourceImplement', // Clean architecture data source implementation (check before DataSource)
            'ViewModel', // MVVM (check before View and Model)
            'Repository',
            'UseCase',
            'DataSource',
            'Service', // MVVM
            'Controller',
            'Provider',
            'Bloc',
            'Model',
            'Entity',
            'View', // MVC/MVVM
            'Event', // BLoC
            'State', // BLoC
            'Initial', // BLoC initial state
          ];

          for (final suffix in classPatterns) {
            // Match whole word boundaries to avoid partial replacements
            final pattern = RegExp('\\b$oldClassName$suffix\\b');
            content = content.replaceAll(pattern, '$newClassName$suffix');
          }

          // Also handle type annotations, variable declarations, and generic types
          // Pattern: AddRepositoryImplement, AddService service, etc.
          for (final suffix in classPatterns) {
            // Handle as type: AddRepositoryImplement service
            final typePattern = RegExp('\\b$oldClassName$suffix\\s+\\w+\\b');
            content = content.replaceAllMapped(
              typePattern,
              (match) {
                final fullMatch = match.group(0)!;
                final rest =
                    fullMatch.substring(oldClassName.length + suffix.length);
                return '$newClassName$suffix$rest';
              },
            );

            // Handle in generic types: List<AddRepositoryImplement>
            final genericPattern = RegExp('<\\s*$oldClassName$suffix\\s*>');
            content =
                content.replaceAll(genericPattern, '<$newClassName$suffix>');

            // Handle in function parameters and return types
            // Pattern: AddRepositoryImplement method() or method(): AddRepositoryImplement
            final returnTypePattern =
                RegExp(':\\s+$oldClassName$suffix(\\s|,|\\)|\\{)');
            content = content.replaceAllMapped(
              returnTypePattern,
              (match) => ': $newClassName${suffix}${match.group(1)}',
            );

            final paramPattern =
                RegExp('\\b$oldClassName$suffix\\s+\\w+\\s*[,)]');
            content = content.replaceAllMapped(
              paramPattern,
              (match) {
                final fullMatch = match.group(0)!;
                final rest =
                    fullMatch.substring(oldClassName.length + suffix.length);
                return '$newClassName$suffix$rest';
              },
            );
          }

          // Handle class declarations that use the feature name directly
          // Pattern: class AddView extends ... or class AddService { ...
          final directClassPattern =
              RegExp('\\bclass\\s+$oldClassName(\\w+)?\\b');
          content = content.replaceAllMapped(
            directClassPattern,
            (match) {
              final suffix = match.group(1) ?? '';
              // Only replace if it's not already handled by the patterns above
              if (classPatterns.any((p) => suffix.contains(p))) {
                return match.group(0)!; // Already handled above
              }
              // For cases like "class AddView" where View might be in the suffix
              if (suffix.isNotEmpty) {
                // Check if it's a known suffix
                final knownSuffixes = [
                  'View',
                  'Controller',
                  'Service',
                  'Model',
                  'ViewModel',
                  'RepositoryImplement',
                  'DataSourceImplement'
                ];
                for (final knownSuffix in knownSuffixes) {
                  if (suffix.contains(knownSuffix)) {
                    return 'class $newClassName$suffix';
                  }
                }
              }
              return 'class $newClassName$suffix';
            },
          );

          // Update file name references in comments (simple replace for feature name patterns)
          final featureNamePattern = RegExp(
              '\\b$oldFeatureName(_[a-z0-9_]+)?\\b',
              caseSensitive: false);
          content = content.replaceAllMapped(
            featureNamePattern,
            (match) {
              final fullMatch = match.group(0)!;
              // Only replace if it's clearly a feature name reference
              return fullMatch.replaceFirst(
                  RegExp(oldFeatureName, caseSensitive: true), newFeatureName);
            },
          );

          // Update comments that reference the old feature name
          final commentPattern = RegExp('//.*$oldFeatureName');
          content = content.replaceAllMapped(
            commentPattern,
            (match) =>
                match.group(0)!.replaceAll(oldFeatureName, newFeatureName),
          );

          if (content != originalContent) {
            await entity.writeAsString(content);
            updatedFiles++;
          }
        } catch (e) {
          // Skip files that can't be read/written
          continue;
        }
      }
    }

    // Also update file names if they contain the feature name
    await _renameFilesInDirectory(
        newFeatureDir, oldFeatureName, newFeatureName);

    if (updatedFiles > 0) {
      Logger.success('Updated file contents in $updatedFiles file(s)');
    }
  }

  /// Rename files that contain the feature name
  static Future<void> _renameFilesInDirectory(
    Directory directory,
    String oldFeatureName,
    String newFeatureName,
  ) async {
    final filesToRename = <File>[];

    await for (final entity in directory.list(recursive: false)) {
      if (entity is File) {
        final fileName = path.basename(entity.path);
        if (fileName.contains(oldFeatureName)) {
          filesToRename.add(entity);
        }
      }
    }

    for (final file in filesToRename) {
      try {
        final oldFileName = path.basename(file.path);
        final newFileName =
            oldFileName.replaceAll(oldFeatureName, newFeatureName);
        final newPath = path.join(path.dirname(file.path), newFileName);

        if (file.path != newPath) {
          await file.rename(newPath);
          Logger.info('Renamed file: $oldFileName → $newFileName');
        }
      } catch (e) {
        Logger.warning('Could not rename file ${file.path}: $e');
      }
    }

    // Recursively handle subdirectories
    await for (final entity in directory.list(recursive: false)) {
      if (entity is Directory) {
        await _renameFilesInDirectory(entity, oldFeatureName, newFeatureName);
      }
    }
  }

  /// Rename directories within the feature that match the feature name
  /// This handles cases like: presentation/manager/bloc/auth/ -> presentation/manager/bloc/login/
  static Future<void> _renameDirectoriesInFeature(
    String featurePath,
    String oldFeatureName,
    String newFeatureName,
  ) async {
    final featureDir = Directory(featurePath);
    if (!featureDir.existsSync()) {
      return;
    }

    // Collect all directories that need to be renamed
    final directoriesToRename = <Directory>[];

    await for (final entity in featureDir.list(recursive: true)) {
      if (entity is Directory) {
        final dirName = path.basename(entity.path);
        // Check if directory name matches the old feature name (exact match or with pattern)
        if (dirName == oldFeatureName || dirName.contains(oldFeatureName)) {
          directoriesToRename.add(entity);
        }
      }
    }

    // Sort by depth (deepest first) to avoid renaming parent before child
    directoriesToRename.sort((a, b) {
      final aDepth = a.path.split(Platform.pathSeparator).length;
      final bDepth = b.path.split(Platform.pathSeparator).length;
      return bDepth.compareTo(aDepth); // Deeper first
    });

    // Rename directories
    for (final dir in directoriesToRename) {
      try {
        final oldDirName = path.basename(dir.path);
        final newDirName =
            oldDirName.replaceAll(oldFeatureName, newFeatureName);

        if (oldDirName != newDirName) {
          final newPath = path.join(path.dirname(dir.path), newDirName);

          // Check if target directory already exists
          if (Directory(newPath).existsSync()) {
            Logger.warning(
                'Target directory already exists: $newPath. Skipping rename of ${dir.path}');
            continue;
          }

          await dir.rename(newPath);
          Logger.success('Renamed directory: $oldDirName → $newDirName');
        }
      } catch (e) {
        Logger.warning('Could not rename directory ${dir.path}: $e');
      }
    }
  }

  /// Update imports that reference nested directories with the old feature name
  /// Handles cases like: features/auth/presentation/manager/bloc/auth/ -> features/login/presentation/manager/bloc/login/
  static Future<void> _updateNestedDirectoryImports(
      String oldFeatureName, String newFeatureName) async {
    final libDir = Directory('lib');
    if (!libDir.existsSync()) {
      return;
    }

    int updatedFiles = 0;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        try {
          var content = await entity.readAsString();
          final originalContent = content;

          // Update import/export paths that contain the old feature name in nested directories
          // Pattern: features/new_feature/.../old_feature/...
          final nestedPattern = RegExp(
            "import ['\"]([^'\"]*features/[^'/]*/)([^'\"]*)$oldFeatureName(/[^'\"]*)['\"];",
            multiLine: true,
          );
          content = content.replaceAllMapped(
            nestedPattern,
            (match) {
              final prefix = match.group(1) ?? '';
              final middle = match.group(2) ?? '';
              final suffix = match.group(3) ?? '';
              return "import '${prefix}${middle}$newFeatureName$suffix';";
            },
          );

          // Same for export statements
          final exportNestedPattern = RegExp(
            "export ['\"]([^'\"]*features/[^'/]*/)([^'\"]*)$oldFeatureName(/[^'\"]*)['\"];",
            multiLine: true,
          );
          content = content.replaceAllMapped(
            exportNestedPattern,
            (match) {
              final prefix = match.group(1) ?? '';
              final middle = match.group(2) ?? '';
              final suffix = match.group(3) ?? '';
              return "export '${prefix}${middle}$newFeatureName$suffix';";
            },
          );

          // Also update paths like: .../bloc/old_feature/... -> .../bloc/new_feature/...
          // This handles cases where the directory name matches the feature name
          final directoryPathPattern = RegExp(
            "(features/[^'/]+/[^'\"]*/)$oldFeatureName(/[^'\"]*)",
            multiLine: true,
          );
          content = content.replaceAllMapped(
            directoryPathPattern,
            (match) {
              final prefix = match.group(1) ?? '';
              final suffix = match.group(2) ?? '';
              return '${prefix}$newFeatureName$suffix';
            },
          );

          if (content != originalContent) {
            await entity.writeAsString(content);
            updatedFiles++;
          }
        } catch (e) {
          // Skip files that can't be read/written
          continue;
        }
      }
    }

    if (updatedFiles > 0) {
      Logger.success(
          'Updated nested directory imports in $updatedFiles file(s)');
    }
  }
}
