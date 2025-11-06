import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../../core/utils/prompter.dart';

/// Manages package ID/namespace replacement for Flutter projects
class PackageIdManager {
  /// Replace package ID with various modes
  static Future<bool> replacePackageId({
    String? newPackageId,
    bool interactive = false,
    bool createBackup = false,
    bool dryRun = false,
  }) async {
    try {
      // Check if we're in a Flutter project
      if (!_isFlutterProject()) {
        Logger.error(
            'Not a Flutter project. Please run this command from your Flutter project root.');
        return false;
      }

      // Detect current package ID
      final currentPackageId = await _detectCurrentPackageId();
      if (currentPackageId == null) {
        Logger.error('Could not detect current package ID.');
        Logger.info(
            'Please ensure android/app/build.gradle or android/app/build.gradle.kts exists');
        Logger.info(
            '  - For build.gradle (Groovy DSL): ensure applicationId or namespace is set');
        Logger.info(
            '  - For build.gradle.kts (Kotlin DSL): ensure namespace is set');
        return false;
      }

      Logger.info('Current package ID: $currentPackageId');

      // Get new package ID
      String? targetPackageId = newPackageId;

      if (interactive || targetPackageId == null) {
        targetPackageId = await _getNewPackageIdInteractive(currentPackageId);
        if (targetPackageId == null || targetPackageId.isEmpty) {
          Logger.info('Operation cancelled.');
          return false;
        }
      }

      // Validate new package ID
      if (!_isValidPackageId(targetPackageId)) {
        Logger.error('Invalid package ID format: $targetPackageId');
        Logger.info(
            'Package ID should follow the pattern: com.example.appname');
        return false;
      }

      // Check if same as current
      if (currentPackageId == targetPackageId) {
        Logger.warning('New package ID is the same as current package ID.');
        return false;
      }

      // Show preview of changes
      await _previewChanges(currentPackageId, targetPackageId);

      // Ask for confirmation if not dry run
      if (!dryRun) {
        final confirmed = Prompter.confirm(
          message: '⚡ Do you want to proceed with these changes?',
          defaultValue: false,
          compact: true,
        );

        if (!confirmed) {
          Logger.info('Operation cancelled.');
          return false;
        }
      }

      // Create backup if requested
      String? backupPath;
      if (createBackup && !dryRun) {
        backupPath = await _createBackup();
        if (backupPath != null) {
          Logger.success('Backup created: $backupPath');
        }
      }

      // Perform replacement
      if (dryRun) {
        Logger.info('DRY RUN: No changes were made.');
        return true;
      }

      final success =
          await _performReplacement(currentPackageId, targetPackageId);

      if (success) {
        Logger.success('Package ID updated successfully!');
        Logger.info('Changed from: $currentPackageId');
        Logger.info('Changed to: $targetPackageId');
        if (backupPath != null) {
          Logger.info('Backup available at: $backupPath');
        }
        return true;
      } else {
        Logger.error('Failed to update package ID completely.');
        if (backupPath != null) {
          Logger.info('Use backup at: $backupPath to restore if needed.');
        }
        return false;
      }
    } catch (e) {
      Logger.error('Failed to replace package ID: $e');
      return false;
    }
  }

  /// Check if current directory is a Flutter project
  static bool _isFlutterProject() {
    final pubspecFile = File('pubspec.yaml');
    final androidDir = Directory('android');
    return pubspecFile.existsSync() && androidDir.existsSync();
  }

  /// Detect current package ID from Android build.gradle or build.gradle.kts
  static Future<String?> _detectCurrentPackageId() async {
    try {
      // Try build.gradle.kts first (Kotlin DSL)
      final buildGradleKtsPath = 'android/app/build.gradle.kts';
      final buildGradleKtsFile = File(buildGradleKtsPath);

      if (buildGradleKtsFile.existsSync()) {
        final content = await buildGradleKtsFile.readAsString();

        // Look for namespace = "..." (Kotlin DSL) - matches both single and double quotes
        // Try double quotes first
        var namespaceRegex = RegExp(r'namespace\s*=\s*"([^"]+)"');
        var namespaceMatch = namespaceRegex.firstMatch(content);
        if (namespaceMatch == null) {
          // Try single quotes
          namespaceRegex = RegExp(r"namespace\s*=\s*'([^']+)'");
          namespaceMatch = namespaceRegex.firstMatch(content);
        }
        if (namespaceMatch != null && namespaceMatch.groupCount > 0) {
          final group = namespaceMatch.group(1);
          return group?.trim();
        }

        // Fallback: look for applicationId = "..." (if present)
        var applicationIdRegex = RegExp(r'applicationId\s*=\s*"([^"]+)"');
        var appIdMatch = applicationIdRegex.firstMatch(content);
        if (appIdMatch == null) {
          applicationIdRegex = RegExp(r"applicationId\s*=\s*'([^']+)'");
          appIdMatch = applicationIdRegex.firstMatch(content);
        }
        if (appIdMatch != null && appIdMatch.groupCount > 0) {
          final group = appIdMatch.group(1);
          return group?.trim();
        }
      }

      // Try build.gradle (Groovy DSL)
      final buildGradlePath = 'android/app/build.gradle';
      final buildGradleFile = File(buildGradlePath);

      if (buildGradleFile.existsSync()) {
        final content = await buildGradleFile.readAsString();

        // Look for applicationId "..." or namespace "..." (Groovy DSL)
        final applicationIdRegex =
            RegExp(r"applicationId\s+['" "]([^'" "]+)['" "]");
        final match = applicationIdRegex.firstMatch(content);

        if (match != null && match.groupCount > 0) {
          final group = match.group(1);
          return group?.trim();
        }

        // Also check for namespace (Groovy DSL can have namespace too)
        final namespaceRegex = RegExp(r"namespace\s+['" "]([^'" "]+)['" "]");
        final namespaceMatch = namespaceRegex.firstMatch(content);
        if (namespaceMatch != null && namespaceMatch.groupCount > 0) {
          final group = namespaceMatch.group(1);
          return group?.trim();
        }
      }

      // Fallback to AndroidManifest.xml
      final manifestPath = 'android/app/src/main/AndroidManifest.xml';
      final manifestFile = File(manifestPath);

      if (manifestFile.existsSync()) {
        final content = await manifestFile.readAsString();

        final packageRegex = RegExp(r"package=['" "]([^'" "]+)['" "]");
        final match = packageRegex.firstMatch(content);

        if (match != null && match.groupCount > 0) {
          final group = match.group(1);
          return group?.trim();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get new package ID interactively
  static Future<String?> _getNewPackageIdInteractive(
      String currentPackageId) async {
    final input = Prompter.text(
      message: '⚡ Enter new package ID',
      defaultValue: currentPackageId,
      validate: (value) => value.isNotEmpty && _isValidPackageId(value),
      compact: true,
    );

    return input?.trim();
  }

  /// Validate package ID format
  static bool _isValidPackageId(String packageId) {
    // Package ID should match: com.example.appname or similar
    final packageIdRegex = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');
    return packageIdRegex.hasMatch(packageId);
  }

  /// Preview changes that will be made
  static Future<void> _previewChanges(
      String currentPackageId, String newPackageId) async {
    Logger.info('Changes to be made:');
    Logger.info('');

    final filesToUpdate =
        await _getFilesToUpdate(currentPackageId, newPackageId);

    for (final fileInfo in filesToUpdate) {
      Logger.info('  ✓ ${fileInfo['path']}');
      if (fileInfo['action'] != null) {
        Logger.info('    → ${fileInfo['action']}');
      }
    }

    Logger.info('');
  }

  /// Get list of files that will be updated
  static Future<List<Map<String, String>>> _getFilesToUpdate(
    String currentPackageId,
    String newPackageId,
  ) async {
    final files = <Map<String, String>>[];

    // Android build.gradle or build.gradle.kts
    final buildGradlePath = 'android/app/build.gradle';
    final buildGradleKtsPath = 'android/app/build.gradle.kts';

    if (File(buildGradleKtsPath).existsSync()) {
      files.add({
        'path': buildGradleKtsPath,
        'action': 'Update namespace/applicationId',
      });
    } else if (File(buildGradlePath).existsSync()) {
      files.add({
        'path': buildGradlePath,
        'action': 'Update applicationId/namespace',
      });
    }

    // AndroidManifest.xml
    final manifestPath = 'android/app/src/main/AndroidManifest.xml';
    if (File(manifestPath).existsSync()) {
      files.add({
        'path': manifestPath,
        'action': 'Update package attribute',
      });
    }

    // Kotlin/Java MainActivity files
    final kotlinPath = 'android/app/src/main/kotlin';
    final javaPath = 'android/app/src/main/java';

    final packageParts = currentPackageId.split('.');
    // Use path.joinAll for platform-specific separators
    final packageDir = path.joinAll(packageParts);

    if (Directory(kotlinPath).existsSync()) {
      final mainActivityPath =
          path.join(kotlinPath, packageDir, 'MainActivity.kt');
      if (File(mainActivityPath).existsSync()) {
        files.add({
          'path': mainActivityPath,
          'action': 'Update package declaration & move file',
        });
      }
    }

    if (Directory(javaPath).existsSync()) {
      final mainActivityPath =
          path.join(javaPath, packageDir, 'MainActivity.java');
      if (File(mainActivityPath).existsSync()) {
        files.add({
          'path': mainActivityPath,
          'action': 'Update package declaration & move file',
        });
      }
    }

    // iOS project.pbxproj
    final pbxprojPath = 'ios/Runner.xcodeproj/project.pbxproj';
    if (File(pbxprojPath).existsSync()) {
      files.add({
        'path': pbxprojPath,
        'action': 'Update PRODUCT_BUNDLE_IDENTIFIER',
      });
    }

    return files;
  }

  /// Create backup of project
  static Future<String?> _createBackup() async {
    try {
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final backupDir = Directory('backup_$timestamp');

      if (backupDir.existsSync()) {
        await backupDir.delete(recursive: true);
      }
      await backupDir.create(recursive: true);

      // Copy android directory
      final androidDir = Directory('android');
      if (androidDir.existsSync()) {
        await _copyDirectory(
            androidDir, Directory('${backupDir.path}/android'));
      }

      // Copy ios directory
      final iosDir = Directory('ios');
      if (iosDir.existsSync()) {
        await _copyDirectory(iosDir, Directory('${backupDir.path}/ios'));
      }

      return backupDir.path;
    } catch (e) {
      Logger.error('Failed to create backup: $e');
      return null;
    }
  }

  /// Copy directory recursively
  static Future<void> _copyDirectory(
      Directory source, Directory destination) async {
    await destination.create(recursive: true);

    await for (final entity in source.list(recursive: false)) {
      final entityName = path.basename(entity.path);

      if (entity is Directory) {
        await _copyDirectory(
            entity, Directory(path.join(destination.path, entityName)));
      } else if (entity is File) {
        await entity.copy(path.join(destination.path, entityName));
      }
    }
  }

  /// Perform the actual package ID replacement
  static Future<bool> _performReplacement(
      String currentPackageId, String newPackageId) async {
    try {
      bool allSuccess = true;

      // 1. Update Android build.gradle or build.gradle.kts
      final buildGradleSuccess =
          await _updateBuildGradle(currentPackageId, newPackageId);
      if (!buildGradleSuccess) {
        Logger.warning(
            'Failed to update build.gradle/build.gradle.kts, but continuing...');
        // Don't mark as failure, continue with other updates
      }

      // 2. Update AndroidManifest.xml
      final manifestSuccess =
          await _updateAndroidManifest(currentPackageId, newPackageId);
      if (!manifestSuccess) allSuccess = false;

      // 3. Update and move Kotlin/Java files
      final filesSuccess =
          await _updateAndMoveSourceFiles(currentPackageId, newPackageId);
      if (!filesSuccess) allSuccess = false;

      // 4. Update iOS project.pbxproj
      final iosSuccess =
          await _updateIosProject(currentPackageId, newPackageId);
      if (!iosSuccess) allSuccess = false;

      return allSuccess;
    } catch (e) {
      Logger.error('Error during replacement: $e');
      return false;
    }
  }

  /// Update Android build.gradle or build.gradle.kts
  static Future<bool> _updateBuildGradle(
      String currentPackageId, String newPackageId) async {
    try {
      // Try build.gradle.kts first (Kotlin DSL)
      final buildGradleKtsPath = 'android/app/build.gradle.kts';
      final buildGradleKtsFile = File(buildGradleKtsPath);

      if (buildGradleKtsFile.existsSync()) {
        var content = await buildGradleKtsFile.readAsString();

        // Replace namespace = "..." (Kotlin DSL) - try double quotes first
        var namespaceRegex = RegExp(r'(namespace\s*=\s*)"([^"]+)"');
        if (namespaceRegex.hasMatch(content)) {
          content = content.replaceAllMapped(
            namespaceRegex,
            (match) => '${match.group(1)}"$newPackageId"',
          );
        } else {
          // Try single quotes
          namespaceRegex = RegExp(r"(namespace\s*=\s*)'([^']+)'");
          if (namespaceRegex.hasMatch(content)) {
            content = content.replaceAllMapped(
              namespaceRegex,
              (match) => "${match.group(1)}'$newPackageId'",
            );
          } else {
            // If namespace doesn't exist, try to find applicationId = "..." (if present)
            var applicationIdRegex = RegExp(r'(applicationId\s*=\s*)"([^"]+)"');
            if (applicationIdRegex.hasMatch(content)) {
              content = content.replaceAllMapped(
                applicationIdRegex,
                (match) => '${match.group(1)}"$newPackageId"',
              );
            } else {
              applicationIdRegex = RegExp(r"(applicationId\s*=\s*)'([^']+)'");
              if (applicationIdRegex.hasMatch(content)) {
                content = content.replaceAllMapped(
                  applicationIdRegex,
                  (match) => "${match.group(1)}'$newPackageId'",
                );
              }
            }
          }
        }

        await buildGradleKtsFile.writeAsString(content);
        Logger.success('Updated $buildGradleKtsPath');
        return true;
      }

      // Try build.gradle (Groovy DSL)
      final buildGradlePath = 'android/app/build.gradle';
      final buildGradleFile = File(buildGradlePath);

      if (buildGradleFile.existsSync()) {
        var content = await buildGradleFile.readAsString();

        // Replace applicationId "..." (Groovy DSL)
        final applicationIdRegex =
            RegExp(r"(applicationId\s+)(['" "])([^'" "]+)(['" "])");
        if (applicationIdRegex.hasMatch(content)) {
          content = content.replaceAllMapped(
            applicationIdRegex,
            (match) {
              final prefix = match.group(1) ?? '';
              final quote1 = match.group(2) ?? '';
              final quote2 = match.group(4) ?? '';
              return '$prefix$quote1$newPackageId$quote2';
            },
          );
        } else {
          // Try namespace "..." (Groovy DSL can have namespace too)
          final namespaceRegex =
              RegExp(r"(namespace\s+)(['" "])([^'" "]+)(['" "])");
          if (namespaceRegex.hasMatch(content)) {
            content = content.replaceAllMapped(
              namespaceRegex,
              (match) {
                final prefix = match.group(1) ?? '';
                final quote1 = match.group(2) ?? '';
                final quote2 = match.group(4) ?? '';
                return '$prefix$quote1$newPackageId$quote2';
              },
            );
          } else {
            // Try without quotes
            final simpleRegex = RegExp(r'applicationId\s+([^\s]+)');
            content = content.replaceAllMapped(
              simpleRegex,
              (match) => 'applicationId $newPackageId',
            );
          }
        }

        await buildGradleFile.writeAsString(content);
        Logger.success('Updated $buildGradlePath');
        return true;
      }

      Logger.warning('Neither build.gradle nor build.gradle.kts found.');
      return false;
    } catch (e) {
      Logger.error('Failed to update build.gradle: $e');
      return false;
    }
  }

  /// Update AndroidManifest.xml
  static Future<bool> _updateAndroidManifest(
      String currentPackageId, String newPackageId) async {
    try {
      final manifestPath = 'android/app/src/main/AndroidManifest.xml';
      final file = File(manifestPath);

      if (!file.existsSync()) {
        Logger.warning('$manifestPath not found.');
        return false;
      }

      var content = await file.readAsString();

      // Replace package attribute
      final packageRegex = RegExp(r"(package=['" "])([^'" "]+)(['" "])");
      content = content.replaceAllMapped(
        packageRegex,
        (match) {
          final prefix = match.group(1) ?? '';
          final suffix = match.group(3) ?? '';
          return '$prefix$newPackageId$suffix';
        },
      );

      // Also replace any references in the manifest
      content = content.replaceAll(currentPackageId, newPackageId);

      await file.writeAsString(content);
      Logger.success('Updated $manifestPath');
      return true;
    } catch (e) {
      Logger.error('Failed to update AndroidManifest.xml: $e');
      return false;
    }
  }

  /// Update and move Kotlin/Java source files
  static Future<bool> _updateAndMoveSourceFiles(
      String currentPackageId, String newPackageId) async {
    try {
      bool success = true;

      // Try Kotlin first
      final kotlinPath = 'android/app/src/main/kotlin';
      if (Directory(kotlinPath).existsSync()) {
        final kotlinSuccess = await _updateSourceFilesInDirectory(
          kotlinPath,
          currentPackageId,
          newPackageId,
          'kt',
        );
        if (!kotlinSuccess) success = false;
      }

      // Try Java
      final javaPath = 'android/app/src/main/java';
      if (Directory(javaPath).existsSync()) {
        final javaSuccess = await _updateSourceFilesInDirectory(
          javaPath,
          currentPackageId,
          newPackageId,
          'java',
        );
        if (!javaSuccess) success = false;
      }

      return success;
    } catch (e) {
      Logger.error('Failed to update source files: $e');
      return false;
    }
  }

  /// Update source files in a directory (Kotlin or Java)
  static Future<bool> _updateSourceFilesInDirectory(
    String basePath,
    String currentPackageId,
    String newPackageId,
    String extension,
  ) async {
    try {
      // Build package directory paths using platform-specific separators
      final packageParts = currentPackageId.split('.');
      final oldPackageDir = path.joinAll(packageParts);
      final oldSourceDir = Directory(path.join(basePath, oldPackageDir));

      if (!oldSourceDir.existsSync()) {
        final oldPathDisplay = path.join(basePath, oldPackageDir);
        Logger.info('No $extension files found in $oldPathDisplay');
        return true; // Not an error if directory doesn't exist
      }

      // Create new directory structure
      final newPackageParts = newPackageId.split('.');
      final newPackageDir = path.joinAll(newPackageParts);
      final newSourceDir = Directory(path.join(basePath, newPackageDir));
      await newSourceDir.create(recursive: true);

      // Process all files in old directory
      await for (final entity in oldSourceDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.$extension')) {
          var content = await entity.readAsString();

          // Update package declaration
          final packageRegex = RegExp(r'^(package\s+)([^\s;]+)');
          content = content.replaceAllMapped(
            packageRegex,
            (match) => '${match.group(1)}$newPackageId',
          );

          // Replace any other references
          content = content.replaceAll(currentPackageId, newPackageId);

          // Calculate relative path from old directory using path package
          final oldDirPath = oldSourceDir.path;
          String relativePath;

          if (entity.path.startsWith(oldDirPath)) {
            // Get the path relative to old directory
            if (entity.path.length > oldDirPath.length) {
              // Remove old directory path and leading separator
              final remaining = entity.path.substring(oldDirPath.length);
              relativePath = remaining.startsWith(Platform.pathSeparator)
                  ? remaining.substring(1)
                  : remaining;
            } else {
              relativePath = path.basename(entity.path);
            }
          } else {
            relativePath = path.basename(entity.path);
          }

          // Build new file path using path.join for proper cross-platform handling
          final newFilePath = path.join(newSourceDir.path, relativePath);
          final newFile = File(newFilePath);

          // Ensure parent directory exists
          await newFile.parent.create(recursive: true);
          await newFile.writeAsString(content);

          final fileName = path.basename(entity.path);
          Logger.success('Updated $fileName');
        }
      }

      // Delete old directory after successful move
      try {
        await oldSourceDir.delete(recursive: true);
        Logger.info('Removed old directory structure: $oldPackageDir');

        // Clean up empty parent directories
        _cleanupEmptyParentDirectories(basePath, currentPackageId);
      } catch (e) {
        Logger.warning('Could not remove old directory: $e');
      }

      return true;
    } catch (e) {
      Logger.error('Failed to update $extension files: $e');
      return false;
    }
  }

  /// Clean up empty parent directories after removing old package directory
  static void _cleanupEmptyParentDirectories(
      String basePath, String oldPackageId) {
    try {
      final packageParts = oldPackageId.split('.');

      // Start from the parent directory of the old package directory
      // Work backwards to clean up empty directories
      for (int i = packageParts.length - 1; i > 0; i--) {
        // Build path to this parent directory level
        final parentParts = packageParts.sublist(0, i);
        final parentDirPath = path.join(basePath, path.joinAll(parentParts));
        final parentDir = Directory(parentDirPath);

        if (!parentDir.existsSync()) {
          continue; // Already deleted or doesn't exist
        }

        // Check if directory is empty
        final entities = parentDir.listSync();
        if (entities.isEmpty) {
          try {
            parentDir.deleteSync(recursive: false);
            Logger.info(
                'Removed empty parent directory: ${path.joinAll(parentParts)}');
          } catch (e) {
            // Stop if we can't delete (might have permissions issue or not empty)
            break;
          }
        } else {
          // Directory is not empty, stop cleaning up
          break;
        }
      }
    } catch (e) {
      // Silently fail - cleanup is not critical
      Logger.warning('Could not clean up empty parent directories: $e');
    }
  }

  /// Update iOS project.pbxproj
  static Future<bool> _updateIosProject(
      String currentPackageId, String newPackageId) async {
    try {
      final pbxprojPath = 'ios/Runner.xcodeproj/project.pbxproj';
      final file = File(pbxprojPath);

      if (!file.existsSync()) {
        Logger.info('iOS project file not found. Skipping iOS update.');
        return true; // Not an error if iOS project doesn't exist
      }

      var content = await file.readAsString();

      // Replace PRODUCT_BUNDLE_IDENTIFIER
      final bundleIdRegex =
          RegExp(r'(PRODUCT_BUNDLE_IDENTIFIER\s*=\s*)([^;]+)(\s*;)');
      content = content.replaceAllMapped(
        bundleIdRegex,
        (match) {
          final currentBundleId = match.group(2)?.trim() ?? '';
          if (currentBundleId.contains(currentPackageId)) {
            return '${match.group(1)}${currentBundleId.replaceAll(currentPackageId, newPackageId)}${match.group(3)}';
          }
          return match.group(0)!;
        },
      );

      await file.writeAsString(content);
      Logger.success('Updated $pbxprojPath');
      return true;
    } catch (e) {
      Logger.error('Failed to update iOS project: $e');
      return false;
    }
  }
}
