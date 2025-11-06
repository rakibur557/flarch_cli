import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../main_config/main_config_manager.dart';

/// Manages theme configuration for Flutter projects
class ThemeConfigManager {
  /// Configure theme for the Flutter project
  static Future<bool> configureTheme() async {
    try {
      // Header
      // Logger.header('🎨 Theme Configuration Setup');

      // Check if we're in a Flutter project
      if (!_isFlutterProject()) {
        Logger.error(
            'Not a Flutter project. Please run this command from your Flutter project root.');
        return false;
      }

      final steps = <String>[];
      int totalSteps = 4;
      int currentStep = 0;

      // Step 1: Check if app.dart exists and is properly configured
      currentStep = 1;
      Logger.step(currentStep, totalSteps, 'Checking app.dart configuration');
      final appFilePath = path.join('lib', 'app.dart');
      final appFile = File(appFilePath);

      bool needsMainConfig = false;
      if (!appFile.existsSync()) {
        Logger.warning('   app.dart not found');
        needsMainConfig = true;
      } else {
        // Check if app.dart has the expected structure
        final appContent = await appFile.readAsString();
        if (!appContent.contains('class MyApp') ||
            (!appContent.contains('MaterialApp(') &&
                !appContent.contains('MaterialApp.router('))) {
          Logger.warning(
              '   app.dart exists but doesn\'t have expected structure');
          needsMainConfig = true;
        } else {
          Logger.success('   app.dart is properly configured');
          steps.add('app.dart verified');
        }
      }

      // Step 2: Configure main.dart if needed
      if (needsMainConfig) {
        currentStep = 2;
        Logger.step(currentStep, totalSteps, 'Configuring main.dart');
        Logger.info('   Setting up main.dart and app.dart...');
        final mainConfigSuccess = await MainConfigManager.configureMain();
        if (!mainConfigSuccess) {
          Logger.error(
              'Failed to configure main.dart. Please run "flarch config main" first.');
          return false;
        }
        Logger.success('   main.dart configured');
        Logger.success('   app.dart created');
        steps.add('main.dart configured');
        steps.add('app.dart created');
      }

      // Step 3: Create theme file
      currentStep = 3;
      Logger.step(currentStep, totalSteps, 'Creating theme configuration');
      await _createThemeFile();
      Logger.success('   Theme file created at lib/core/theme/app_theme.dart');
      steps.add('Theme file created');

      // Step 4: Update app.dart
      currentStep = 4;
      Logger.step(currentStep, totalSteps, 'Updating app.dart with theme');
      final updateSuccess = await _updateAppFile();
      if (updateSuccess) {
        Logger.success('   app.dart updated with theme configuration');
        steps.add('app.dart updated');
      } else {
        Logger.warning(
            '   app.dart update may have issues. Please check manually.');
      }

      // Summary
      // Logger.summary('Theme Configuration Complete', [
      //   'AppTheme.lightTheme and AppTheme.darkTheme configured',
      //   'Theme mode set to ThemeMode.system',
      //   'All files updated successfully',
      // ]);

      return true;
    } catch (e) {
      Logger.error('Failed to configure theme: $e');
      return false;
    }
  }

  /// Check if we're in a Flutter project
  static bool _isFlutterProject() {
    final pubspecFile = File('pubspec.yaml');
    final libDir = Directory('lib');
    return pubspecFile.existsSync() && libDir.existsSync();
  }

  /// Create app_theme.dart file
  static Future<void> _createThemeFile() async {
    final coreDir = Directory(path.join('lib', 'core'));
    if (!coreDir.existsSync()) {
      await coreDir.create(recursive: true);
    }

    final themeDir = Directory(path.join('lib', 'core', 'theme'));
    if (!themeDir.existsSync()) {
      await themeDir.create(recursive: true);
    }

    final themeFilePath = path.join('lib', 'core', 'theme', 'app_theme.dart');
    final themeFile = File(themeFilePath);

    // Check if theme file already exists
    if (themeFile.existsSync()) {
      Logger.warning('app_theme.dart already exists. Skipping creation.');
      return;
    }

    final themeContent = '''import 'package:flutter/material.dart';

/// App theme configuration
/// Provides light and dark themes with consistent styling and Material 3 support
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  // ============================================
  // Color Palette
  // ============================================
  
  /// Primary brand color - Main app color
  static const Color primaryColor = Color(0xFF6C63FF);
  
  /// Secondary color - Accent for highlights
  static const Color secondaryColor = Color(0xFFFF6584);
  
  /// Accent color - For special highlights
  static const Color accentColor = Color(0xFF00D9FF);
  
  /// Success color - For positive actions
  static const Color successColor = Color(0xFF4CAF50);
  
  /// Warning color - For warnings
  static const Color warningColor = Color(0xFFFF9800);
  
  /// Error color - For errors
  static const Color errorColor = Color(0xFFF44336);
  
  /// Info color - For informational messages
  static const Color infoColor = Color(0xFF2196F3);

  // ============================================
  // Dark Theme Colors
  // ============================================
  
  /// Dark background color
  static const Color darkBackground = Color(0xFF121212);
  
  /// Dark surface color
  static const Color darkSurface = Color(0xFF1E1E1E);
  
  /// Dark card color
  static const Color darkCard = Color(0xFF2C2C2C);
  
  /// Dark divider color
  static const Color darkDivider = Color(0xFF3A3A3A);

  // ============================================
  // Light Theme Configuration
  // ============================================
  
  /// Light theme configuration with Material 3
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        secondary: secondaryColor,
      ),
      
      // App bar theme
      appBarTheme: const AppBarThemeData(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        thickness: 1,
        space: 1,
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        size: 24,
      ),
    );
  }

  // ============================================
  // Dark Theme Configuration
  // ============================================
  
  /// Dark theme configuration with Material 3
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        secondary: secondaryColor,
        background: darkBackground,
        surface: darkSurface,
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: darkBackground,
      
      // App bar theme
      appBarTheme: AppBarThemeData(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: darkSurface,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Colors.white70),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white70,
      ),
      
      // Divider theme
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: darkDivider,
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        size: 24,
        color: Colors.white,
      ),
    );
  }
  
  // ============================================
  // Helper Methods
  // ============================================
  
  /// Get theme mode based on system preference
  static ThemeMode get systemThemeMode => ThemeMode.system;
  
  /// Get theme mode for light only
  static ThemeMode get lightThemeMode => ThemeMode.light;
  
  /// Get theme mode for dark only
  static ThemeMode get darkThemeMode => ThemeMode.dark;
}
''';

    await themeFile.writeAsString(themeContent);
  }

  /// Update app.dart to use the new theme
  static Future<bool> _updateAppFile() async {
    try {
      final appFilePath = path.join('lib', 'app.dart');
      final appFile = File(appFilePath);

      if (!appFile.existsSync()) {
        Logger.error(
            'app.dart not found. Please run "flarch config main" first.');
        return false;
      }

      String appContent = await appFile.readAsString();

      // Check if already fully configured
      if (appContent.contains("import 'core/theme/app_theme.dart';") ||
          appContent.contains('import "core/theme/app_theme.dart";')) {
        if (appContent.contains('AppTheme.lightTheme') &&
            appContent.contains('AppTheme.darkTheme') &&
            appContent.contains('themeMode:')) {
          Logger.info('app.dart already has theme configuration.');
          return true;
        }
      }

      // Add import if not present
      if (!appContent.contains("import 'core/theme/app_theme.dart';") &&
          !appContent.contains('import "core/theme/app_theme.dart";')) {
        // Find the last import statement
        final lines = appContent.split('\n');
        int lastImportIndex = -1;
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].trim().startsWith('import')) {
            lastImportIndex = i;
          } else if (lastImportIndex != -1 &&
              lines[i].trim().isNotEmpty &&
              !lines[i].trim().startsWith('//')) {
            break;
          }
        }

        final themeImport = "import 'core/theme/app_theme.dart';";
        if (lastImportIndex != -1) {
          lines.insert(lastImportIndex + 1, themeImport);
        } else {
          // Add at the beginning
          lines.insert(0, themeImport);
        }
        appContent = lines.join('\n');
      }

      // Find MaterialApp or MaterialApp.router and update theme configuration
      // Look for MaterialApp( or MaterialApp.router( and find the matching closing parenthesis
      int materialAppStart = appContent.indexOf('MaterialApp.router(');
      bool isRouter = false;
      if (materialAppStart == -1) {
        materialAppStart = appContent.indexOf('MaterialApp(');
        if (materialAppStart == -1) {
          Logger.warning(
              'MaterialApp or MaterialApp.router not found in app.dart. Please ensure MaterialApp exists.');
          return false;
        }
      } else {
        isRouter = true;
      }

      // Find the matching closing parenthesis for MaterialApp
      int parenCount = 1;
      final materialAppPattern =
          isRouter ? 'MaterialApp.router(' : 'MaterialApp(';
      int materialAppEnd = materialAppStart + materialAppPattern.length;
      for (int i = materialAppEnd; i < appContent.length; i++) {
        final char = appContent[i];
        if (char == '(') {
          parenCount++;
        } else if (char == ')') {
          parenCount--;
          if (parenCount == 0) {
            materialAppEnd = i;
            break;
          }
        }
      }

      // Extract MaterialApp content
      final materialAppContent =
          appContent.substring(materialAppStart, materialAppEnd + 1);
      final beforeMaterialApp = appContent.substring(0, materialAppStart);
      final afterMaterialApp = appContent.substring(materialAppEnd + 1);

      // Update theme configuration
      String updatedMaterialApp = materialAppContent;

      // Replace theme: ThemeData(...) or theme: ... with proper handling
      if (updatedMaterialApp.contains('theme:')) {
        // Find the theme property and replace it completely
        int themeStart = updatedMaterialApp.indexOf('theme:');
        if (themeStart != -1) {
          // Find where the theme value starts (after 'theme:')
          int themeValueStart = themeStart + 'theme:'.length;
          int themeValueEnd = themeValueStart;

          // Skip whitespace
          while (themeValueEnd < updatedMaterialApp.length &&
              (updatedMaterialApp[themeValueEnd] == ' ' ||
                  updatedMaterialApp[themeValueEnd] == '\t' ||
                  updatedMaterialApp[themeValueEnd] == '\n')) {
            themeValueEnd++;
          }

          // Check if it's ThemeData(...) or just a simple value
          if (themeValueEnd < updatedMaterialApp.length &&
              updatedMaterialApp[themeValueEnd] != '(') {
            // Simple value like 'AppTheme.lightTheme' - find until comma
            while (themeValueEnd < updatedMaterialApp.length &&
                updatedMaterialApp[themeValueEnd] != ',') {
              themeValueEnd++;
            }
            if (themeValueEnd < updatedMaterialApp.length &&
                updatedMaterialApp[themeValueEnd] == ',') {
              themeValueEnd++; // Include the comma
            }
          } else {
            // It's ThemeData(...) or similar - find matching closing parenthesis
            if (themeValueEnd < updatedMaterialApp.length &&
                updatedMaterialApp[themeValueEnd] == '(') {
              int parenCount = 1;
              themeValueEnd++; // Skip the opening '('

              // Find the matching closing ')'
              while (
                  themeValueEnd < updatedMaterialApp.length && parenCount > 0) {
                if (updatedMaterialApp[themeValueEnd] == '(') {
                  parenCount++;
                } else if (updatedMaterialApp[themeValueEnd] == ')') {
                  parenCount--;
                  if (parenCount == 0) {
                    themeValueEnd++; // Include the closing ')'
                    break;
                  }
                }
                themeValueEnd++;
              }

              // Skip whitespace after the closing ')'
              while (themeValueEnd < updatedMaterialApp.length &&
                  (updatedMaterialApp[themeValueEnd] == ' ' ||
                      updatedMaterialApp[themeValueEnd] == '\t' ||
                      updatedMaterialApp[themeValueEnd] == '\n')) {
                themeValueEnd++;
              }

              // Include the comma if present
              if (themeValueEnd < updatedMaterialApp.length &&
                  updatedMaterialApp[themeValueEnd] == ',') {
                themeValueEnd++; // Include the comma
              }
            }
          }

          // Replace everything from theme: to the end of the value (including comma)
          final beforeTheme = updatedMaterialApp.substring(0, themeStart);
          final afterTheme = updatedMaterialApp.substring(themeValueEnd);
          // Add proper spacing
          final spacing = '\n      ';
          updatedMaterialApp =
              '$beforeTheme${'$spacing${'theme: AppTheme.lightTheme,'}'}$afterTheme';
        }
      } else {
        // Add theme property after MaterialApp(
        updatedMaterialApp = updatedMaterialApp.replaceFirst(
          'MaterialApp(',
          'MaterialApp(\n      theme: AppTheme.lightTheme,',
        );
      }

      // Add darkTheme if not present
      if (!updatedMaterialApp.contains('darkTheme:')) {
        // Find theme: AppTheme.lightTheme, and add darkTheme after it
        final themeMatch =
            RegExp(r'theme:\s*AppTheme\.lightTheme,\s*', multiLine: true)
                .firstMatch(updatedMaterialApp);
        if (themeMatch != null) {
          final before = updatedMaterialApp.substring(0, themeMatch.end);
          final after = updatedMaterialApp.substring(themeMatch.end);

          // Check if after starts with closing parenthesis (MaterialApp closing)
          final trimmedAfter = after.trim();
          bool isClosingParen =
              trimmedAfter.startsWith(')') || trimmedAfter.startsWith('),');

          // Add proper spacing
          final spacing = after.startsWith('\n') ? '' : '\n      ';

          if (isClosingParen) {
            // If next is closing parenthesis ), skip it and find the actual next content
            int skipIndex = 0;
            while (skipIndex < after.length &&
                (after[skipIndex] == ' ' ||
                    after[skipIndex] == '\t' ||
                    after[skipIndex] == '\n')) {
              skipIndex++;
            }

            // Skip the closing ) and any comma after it
            if (skipIndex < after.length && after[skipIndex] == ')') {
              skipIndex++;
              // Skip comma if present
              if (skipIndex < after.length && after[skipIndex] == ',') {
                skipIndex++;
              }
              // Skip whitespace after ), or )
              while (skipIndex < after.length &&
                  (after[skipIndex] == ' ' ||
                      after[skipIndex] == '\t' ||
                      after[skipIndex] == '\n')) {
                skipIndex++;
              }
            }

            // Get the actual content after ), or )
            final actualAfter = after.substring(skipIndex);

            // Add darkTheme with newline, then the actual next content
            updatedMaterialApp =
                '$before${'$spacing${'darkTheme: AppTheme.darkTheme,'}'}$actualAfter';
          } else {
            // Normal case - add after theme
            updatedMaterialApp =
                '$before${'$spacing${'darkTheme: AppTheme.darkTheme,'}'}$after';
          }
        }
      }

      // Add themeMode if not present
      if (!updatedMaterialApp.contains('themeMode:')) {
        // Find darkTheme: AppTheme.darkTheme, and add themeMode after it
        final darkThemeMatch =
            RegExp(r'darkTheme:\s*AppTheme\.darkTheme,\s*', multiLine: true)
                .firstMatch(updatedMaterialApp);
        if (darkThemeMatch != null) {
          final before = updatedMaterialApp.substring(0, darkThemeMatch.end);
          final after = updatedMaterialApp.substring(darkThemeMatch.end);

          // Check if after starts with closing parenthesis (MaterialApp closing)
          final trimmedAfter = after.trim();
          bool isClosingParen =
              trimmedAfter.startsWith(')') || trimmedAfter.startsWith('),');

          // Add proper spacing and comment
          final spacing = after.startsWith('\n') ? '' : '\n      ';

          if (isClosingParen) {
            // If next is closing parenthesis ), remove it and find the actual next content
            // Find where ), ends (could be ), or just ) followed by newline)
            int skipIndex = 0;
            while (skipIndex < after.length &&
                (after[skipIndex] == ' ' ||
                    after[skipIndex] == '\t' ||
                    after[skipIndex] == '\n')) {
              skipIndex++;
            }

            // Skip the closing ) and any comma after it
            if (skipIndex < after.length && after[skipIndex] == ')') {
              skipIndex++;
              // Skip comma if present
              if (skipIndex < after.length && after[skipIndex] == ',') {
                skipIndex++;
              }
              // Skip whitespace after ), or )
              while (skipIndex < after.length &&
                  (after[skipIndex] == ' ' ||
                      after[skipIndex] == '\t' ||
                      after[skipIndex] == '\n')) {
                skipIndex++;
              }
            }

            // Get the actual content after ), or )
            final actualAfter = after.substring(skipIndex);

            // Add themeMode with newline, then the actual next content
            updatedMaterialApp =
                '''$before${'$spacing${'// Use system theme mode (light/dark based on device settings)'}'}
      ${'themeMode: ThemeMode.system,'}$actualAfter''';
          } else {
            // Normal case - add after darkTheme (there are more properties)
            updatedMaterialApp =
                '''$before${'$spacing${'// Use system theme mode (light/dark based on device settings)'}'}
      ${'themeMode: ThemeMode.system,'}$after''';
          }
        }
      }

      // Reconstruct the file
      appContent = beforeMaterialApp + updatedMaterialApp + afterMaterialApp;

      await appFile.writeAsString(appContent);
      return true;
    } catch (e) {
      Logger.error('Failed to update app.dart: $e');
      return false;
    }
  }
}
