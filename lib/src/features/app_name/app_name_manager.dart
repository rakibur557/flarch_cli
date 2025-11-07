import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../../core/utils/prompter.dart';

/// Manages app name/display name replacement for Flutter projects
class AppNameManager {
  /// Replace app name with various modes
  static Future<bool> replaceAppName({
    String? newAppName,
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

      // Detect current app name
      final currentAppName = await _detectCurrentAppName();
      if (currentAppName == null) {
        Logger.error('Could not detect current app name.');
        Logger.info(
            'Please ensure android/app/src/main/AndroidManifest.xml exists');
        return false;
      }

      Logger.info('Current app name: "$currentAppName"');

      // Get new app name
      String? targetAppName = newAppName;

      if (interactive || targetAppName == null) {
        targetAppName = _getNewAppNameInteractive(currentAppName);
        if (targetAppName == null || targetAppName.isEmpty) {
          Logger.info('Operation cancelled.');
          return false;
        }
      }

      // Validate new app name
      if (targetAppName.trim().isEmpty) {
        Logger.error('App name cannot be empty.');
        return false;
      }

      final trimmedAppName = targetAppName.trim();

      // Show what will be changed
      if (dryRun) {
        Logger.info('🔍 DRY RUN - No changes will be made');
        Logger.info(
            'Would change app name from "$currentAppName" to "$trimmedAppName"');
        return true;
      }

      // Create backup if requested
      String? backupPath;
      if (createBackup) {
        backupPath = await _createBackup();
        if (backupPath == null) {
          final shouldContinue = Prompter.confirm(
            message: 'Backup failed. Continue without backup?',
            defaultValue: false,
            compact: true,
          );
          if (!shouldContinue) {
            Logger.info('Operation cancelled.');
            return false;
          }
        } else {
          Logger.success('Backup created: $backupPath');
        }
      }

      // Confirm replacement
      final shouldProceed = Prompter.confirm(
        message: 'Replace app name "$currentAppName" with "$trimmedAppName"?',
        defaultValue: false,
        compact: true,
      );

      if (!shouldProceed) {
        Logger.info('Operation cancelled.');
        return false;
      }

      // Perform replacement
      final success = await _performReplacement(currentAppName, trimmedAppName);

      if (success) {
        Logger.success('✓ App name changed successfully to "$trimmedAppName"');
        Logger.info('You may need to restart your app to see the changes.');
      }

      return success;
    } catch (e) {
      Logger.error('Failed to replace app name: $e');
      return false;
    }
  }

  /// Check if current directory is a Flutter project
  static bool _isFlutterProject() {
    final pubspecFile = File('pubspec.yaml');
    final androidDir = Directory('android');
    return pubspecFile.existsSync() && androidDir.existsSync();
  }

  /// Detect current app name from AndroidManifest.xml or strings.xml
  static Future<String?> _detectCurrentAppName() async {
    try {
      // First, try AndroidManifest.xml android:label
      final manifestPath = 'android/app/src/main/AndroidManifest.xml';
      final manifestFile = File(manifestPath);

      if (manifestFile.existsSync()) {
        final content = await manifestFile.readAsString();

        // Look for android:label="@string/app_name" or android:label="App Name"
        var labelRegex = RegExp(r'android:label\s*=\s*"@string/(\w+)"');
        var match = labelRegex.firstMatch(content);

        if (match != null) {
          // It references a string resource, try to get it from strings.xml
          final stringResourceName = match.group(1);
          final appName =
              await _getStringResource(stringResourceName ?? 'app_name');
          if (appName != null) {
            return appName;
          }
        } else {
          // Direct label value
          labelRegex = RegExp(r'android:label\s*=\s*"([^"]+)"');
          match = labelRegex.firstMatch(content);
          if (match != null && match.groupCount > 0) {
            return match.group(1)?.trim();
          }
        }
      }

      // Fallback: Try strings.xml directly
      final stringsXmlPath = 'android/app/src/main/res/values/strings.xml';
      final stringsXmlFile = File(stringsXmlPath);
      if (stringsXmlFile.existsSync()) {
        final appName = await _getStringResource('app_name');
        if (appName != null) {
          return appName;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get string resource value from strings.xml
  static Future<String?> _getStringResource(String resourceName) async {
    try {
      final stringsXmlPath = 'android/app/src/main/res/values/strings.xml';
      final stringsXmlFile = File(stringsXmlPath);

      if (!stringsXmlFile.existsSync()) {
        return null;
      }

      final content = await stringsXmlFile.readAsString();
      final regex =
          RegExp('<string\\s+name=["\']$resourceName["\']>([^<]+)</string>');
      final match = regex.firstMatch(content);

      if (match != null && match.groupCount > 0) {
        return match.group(1)?.trim();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get new app name interactively
  static String? _getNewAppNameInteractive(String currentAppName) {
    final input = Prompter.text(
      message: '⚡ Enter new app name',
      defaultValue: currentAppName,
      validate: (value) => value.trim().isNotEmpty,
      compact: true,
    );

    return input?.trim();
  }

  /// Perform the actual app name replacement
  static Future<bool> _performReplacement(
      String currentAppName, String newAppName) async {
    try {
      var allSuccess = true;

      // Update AndroidManifest.xml
      final manifestSuccess =
          await _updateAndroidManifest(currentAppName, newAppName);
      allSuccess = allSuccess && manifestSuccess;

      // Update strings.xml (Android)
      final stringsSuccess = await _updateStringsXml(newAppName);
      allSuccess = allSuccess && stringsSuccess;

      // Update iOS Info.plist
      final iosSuccess = await _updateIosInfoPlist(currentAppName, newAppName);
      allSuccess = allSuccess && iosSuccess;

      return allSuccess;
    } catch (e) {
      Logger.error('Failed to perform app name replacement: $e');
      return false;
    }
  }

  /// Update AndroidManifest.xml
  static Future<bool> _updateAndroidManifest(
      String currentAppName, String newAppName) async {
    try {
      final manifestPath = 'android/app/src/main/AndroidManifest.xml';
      final file = File(manifestPath);

      if (!file.existsSync()) {
        Logger.warning(
            'AndroidManifest.xml not found. Skipping Android update.');
        return true; // Not an error if manifest doesn't exist
      }

      var content = await file.readAsString();

      // Replace android:label="@string/app_name" or direct label
      // If it references @string/app_name, we'll keep that reference and update strings.xml
      // If it's a direct value, we'll replace it

      var labelRegex = RegExp(r'android:label\s*=\s*"@string/(\w+)"');
      if (labelRegex.hasMatch(content)) {
        // It uses a string resource, so we'll update strings.xml instead
        // Keep the reference as is
        Logger.info(
            'AndroidManifest.xml uses string resource. Will update strings.xml.');
      } else {
        // Direct label value - replace it
        labelRegex = RegExp(r'(android:label\s*=\s*")([^"]+)(")');
        if (labelRegex.hasMatch(content)) {
          content = content.replaceAllMapped(
            labelRegex,
            (match) => '${match.group(1)}$newAppName${match.group(3)}',
          );
          await file.writeAsString(content);
          Logger.success('Updated $manifestPath');
        }
      }

      return true;
    } catch (e) {
      Logger.error('Failed to update AndroidManifest.xml: $e');
      return false;
    }
  }

  /// Update or create strings.xml for Android
  static Future<bool> _updateStringsXml(String newAppName) async {
    try {
      final stringsXmlPath = 'android/app/src/main/res/values/strings.xml';
      final file = File(stringsXmlPath);

      // Ensure values directory exists
      final valuesDir = file.parent;
      if (!valuesDir.existsSync()) {
        await valuesDir.create(recursive: true);
      }

      String content;
      if (file.existsSync()) {
        content = await file.readAsString();

        // Check if app_name string already exists
        final appNameRegex =
            RegExp('<string\\s+name=["\']app_name["\']>([^<]*)</string>');
        if (appNameRegex.hasMatch(content)) {
          // Replace existing app_name
          content = content.replaceAllMapped(
            appNameRegex,
            (match) => '<string name="app_name">$newAppName</string>',
          );
        } else {
          // Add app_name before </resources>
          final resourcesCloseRegex = RegExp(r'(\s*)</resources>');
          if (resourcesCloseRegex.hasMatch(content)) {
            content = content.replaceFirst(
              resourcesCloseRegex,
              '    <string name="app_name">$newAppName</string>\n\$1</resources>',
            );
          } else {
            // No </resources> tag found, append it
            content +=
                '\n    <string name="app_name">$newAppName</string>\n</resources>';
          }
        }
      } else {
        // Create new strings.xml
        content = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">$newAppName</string>
</resources>
''';
      }

      await file.writeAsString(content);
      Logger.success('Updated $stringsXmlPath');

      // Also ensure AndroidManifest.xml references @string/app_name
      await _ensureManifestUsesStringResource();

      return true;
    } catch (e) {
      Logger.error('Failed to update strings.xml: $e');
      return false;
    }
  }

  /// Ensure AndroidManifest.xml uses @string/app_name reference
  static Future<void> _ensureManifestUsesStringResource() async {
    try {
      final manifestPath = 'android/app/src/main/AndroidManifest.xml';
      final file = File(manifestPath);

      if (!file.existsSync()) {
        return;
      }

      var content = await file.readAsString();

      // Check if it already uses @string/app_name
      if (content.contains('android:label="@string/app_name"')) {
        return; // Already correct
      }

      // Replace direct label with string resource reference
      final labelRegex = RegExp(r'android:label\s*=\s*"[^"]*"');
      if (labelRegex.hasMatch(content)) {
        content = content.replaceAll(
          labelRegex,
          'android:label="@string/app_name"',
        );
        await file.writeAsString(content);
        Logger.info('Updated AndroidManifest.xml to use @string/app_name');
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Update iOS Info.plist
  static Future<bool> _updateIosInfoPlist(
      String currentAppName, String newAppName) async {
    try {
      final infoPlistPath = 'ios/Runner/Info.plist';
      final file = File(infoPlistPath);

      if (!file.existsSync()) {
        Logger.info('iOS Info.plist not found. Skipping iOS update.');
        return true; // Not an error if iOS project doesn't exist
      }

      var content = await file.readAsString();

      // Update CFBundleName and CFBundleDisplayName
      // These can be in different formats (XML plist or binary)

      // CFBundleName
      var bundleNameRegex = RegExp(
          r'<key>CFBundleName</key>\s*<string>([^<]*)</string>',
          caseSensitive: false);
      if (bundleNameRegex.hasMatch(content)) {
        content = content.replaceAllMapped(
          bundleNameRegex,
          (match) =>
              '<key>CFBundleName</key>\n\t<string>$newAppName</string>',
        );
      } else {
        // Try to add it if it doesn't exist (before </dict>)
        final dictCloseRegex = RegExp(r'(\s*)</dict>');
        if (dictCloseRegex.hasMatch(content) &&
            !content.contains('CFBundleName')) {
          content = content.replaceFirst(
            dictCloseRegex,
            '\t<key>CFBundleName</key>\n\t<string>$newAppName</string>\n\$1</dict>',
          );
        }
      }

      // CFBundleDisplayName
      var bundleDisplayNameRegex = RegExp(
          r'<key>CFBundleDisplayName</key>\s*<string>([^<]*)</string>',
          caseSensitive: false);
      if (bundleDisplayNameRegex.hasMatch(content)) {
        content = content.replaceAllMapped(
          bundleDisplayNameRegex,
          (match) =>
              '<key>CFBundleDisplayName</key>\n\t<string>$newAppName</string>',
        );
      } else {
        // Try to add it if it doesn't exist (before </dict>)
        final dictCloseRegex = RegExp(r'(\s*)</dict>');
        if (dictCloseRegex.hasMatch(content) &&
            !content.contains('CFBundleDisplayName')) {
          content = content.replaceFirst(
            dictCloseRegex,
            '\t<key>CFBundleDisplayName</key>\n\t<string>$newAppName</string>\n\$1</dict>',
          );
        }
      }

      await file.writeAsString(content);
      Logger.success('Updated $infoPlistPath');
      return true;
    } catch (e) {
      Logger.error('Failed to update iOS Info.plist: $e');
      return false;
    }
  }

  /// Create backup of android/ and ios/ directories
  static Future<String?> _createBackup() async {
    try {
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      final backupDir = Directory('backup_app_name_$timestamp');

      if (backupDir.existsSync()) {
        await backupDir.delete(recursive: true);
      }
      await backupDir.create(recursive: true);

      // Backup android directory
      final androidDir = Directory('android');
      if (androidDir.existsSync()) {
        await _copyDirectory(
            androidDir, Directory(path.join(backupDir.path, 'android')));
      }

      // Backup ios directory
      final iosDir = Directory('ios');
      if (iosDir.existsSync()) {
        await _copyDirectory(
            iosDir, Directory(path.join(backupDir.path, 'ios')));
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
}
