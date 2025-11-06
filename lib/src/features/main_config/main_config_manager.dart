import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';

/// Manages main.dart cleanup and app.dart creation
class MainConfigManager {
  /// Clean up main.dart and create app.dart
  static Future<bool> configureMain() async {
    try {
      // Check if we're in a Flutter project
      if (!_isFlutterProject()) {
        Logger.error(
            'Not a Flutter project. Please run this command from your Flutter project root.');
        return false;
      }

      final mainFilePath = path.join('lib', 'main.dart');
      final mainFile = File(mainFilePath);

      if (!mainFile.existsSync()) {
        Logger.error('main.dart not found at $mainFilePath');
        return false;
      }

      // Read current main.dart
      final mainContent = await mainFile.readAsString();

      // Check if already configured
      if (mainContent.contains("import 'app.dart';") ||
          mainContent.contains('import "app.dart";')) {
        Logger.warning('main.dart appears to already be configured.');
        Logger.info(
            'If you want to reconfigure, please restore the original main.dart first.');
        return false;
      }

      // Create new simplified main.dart
      final newMainContent = _createNewMainContent(mainContent);

      // Create app.dart
      await _createAppFile();

      // Update main.dart
      await mainFile.writeAsString(newMainContent);
      Logger.success('Updated main.dart');
      Logger.success('Created app.dart');

      // Update widget_test.dart if it exists
      await _updateWidgetTest();

      return true;
    } catch (e) {
      Logger.error('Failed to configure main: $e');
      return false;
    }
  }

  /// Check if we're in a Flutter project
  static bool _isFlutterProject() {
    final pubspecFile = File('pubspec.yaml');
    final libDir = Directory('lib');
    return pubspecFile.existsSync() && libDir.existsSync();
  }

  /// Create new simplified main.dart content
  /// Preserves existing imports and initialization code, only removes default classes
  static String _createNewMainContent(String oldContent) {
    String newContent = oldContent;

    // Remove MyApp class completely (handles nested braces)
    newContent = _removeClass(newContent, 'MyApp');

    // Remove MyHomePage class completely
    newContent = _removeClass(newContent, 'MyHomePage');

    // Remove _MyHomePageState class completely
    newContent = _removeClass(newContent, '_MyHomePageState');

    // Clean up extra blank lines (but preserve structure)
    newContent = newContent.replaceAll(RegExp(r'\n\s*\n\s*\n\s*\n+'), '\n\n');

    // Extract all imports (preserve existing imports)
    final lines = newContent.split('\n');
    final imports = <String>[];
    final codeBeforeMain = <String>[];
    int mainFunctionStartIndex = -1;
    int mainFunctionEndIndex = -1;
    bool foundMainFunction = false;

    // Collect all imports and find main function
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Collect all imports
      if (line.startsWith('import')) {
        imports.add(lines[i]); // Keep original formatting
      } else if (!foundMainFunction && line.isNotEmpty) {
        // Find main function start
        if (line.startsWith('Future<void> main') ||
            line.startsWith('void main')) {
          mainFunctionStartIndex = i;
          foundMainFunction = true;
        } else if (!line.startsWith('//') && imports.isNotEmpty) {
          // Collect any code between imports and main function (like top-level declarations)
          // But skip comments
          codeBeforeMain.add(lines[i]);
        }
      }
    }

    // Find main function end by counting braces
    if (mainFunctionStartIndex != -1) {
      int braceCount = 0;
      bool foundOpeningBrace = false;

      // Start from the line with main function
      for (int i = mainFunctionStartIndex; i < lines.length; i++) {
        final currentLine = lines[i];

        // Count braces in this line
        for (int j = 0; j < currentLine.length; j++) {
          final char = currentLine[j];
          if (char == '{') {
            braceCount++;
            foundOpeningBrace = true;
          } else if (char == '}') {
            braceCount--;
            if (foundOpeningBrace && braceCount == 0) {
              mainFunctionEndIndex = i;
              break;
            }
          }
        }

        if (mainFunctionEndIndex != -1) break;
      }

      // Fallback: if we can't find the end, use the last line
      if (mainFunctionEndIndex == -1) {
        mainFunctionEndIndex = lines.length - 1;
      }
    }

    // Add app.dart import if not already present
    bool hasAppImport = false;
    for (final import in imports) {
      if (import.contains("app.dart") || import.contains('app.dart')) {
        hasAppImport = true;
        break;
      }
    }

    if (!hasAppImport) {
      imports.add("import 'app.dart';");
    }

    // Extract main function body (preserve existing code)
    String mainFunctionBody = '';
    if (mainFunctionStartIndex != -1 && mainFunctionEndIndex != -1) {
      // Extract the main function signature and body
      final mainFunctionLines =
          lines.sublist(mainFunctionStartIndex, mainFunctionEndIndex + 1);
      mainFunctionBody = mainFunctionLines.join('\n');

      // Update runApp call to use MyApp() from app.dart
      // Replace any existing runApp call with MyApp() from app.dart
      if (mainFunctionBody.contains('runApp(')) {
        // Find runApp( and match until the closing ) - handle nested parentheses
        int runAppStart = mainFunctionBody.indexOf('runApp(');
        if (runAppStart != -1) {
          int parenCount = 1; // We already found the opening '(' in 'runApp('
          int startPos = runAppStart + 'runApp('.length;
          int endPos = -1;

          // Find the matching closing parenthesis
          for (int i = startPos; i < mainFunctionBody.length; i++) {
            final char = mainFunctionBody[i];
            if (char == '(') {
              parenCount++;
            } else if (char == ')') {
              parenCount--;
              if (parenCount == 0) {
                endPos = i; // Position of the closing ')'
                break;
              }
            }
          }

          if (endPos != -1 && endPos >= startPos) {
            // Replace from runAppStart to endPos+1 (includes the closing parenthesis)
            // substring(0, runAppStart) = everything before runApp
            // substring(endPos + 1) = everything after the closing ')'
            final before = mainFunctionBody.substring(0, runAppStart);
            final after = mainFunctionBody
                .substring(endPos + 1); // Start after the closing ')'
            mainFunctionBody = '$before${'runApp(const MyApp())'}$after';
          }
        }
      } else {
        // Add runApp call if it doesn't exist
        // Insert before the closing brace
        final lastLine = mainFunctionLines.last;
        if (lastLine.trim() == '}') {
          // Remove the closing brace, add runApp, then add closing brace
          final withoutLastLine =
              mainFunctionLines.sublist(0, mainFunctionLines.length - 1);
          mainFunctionBody =
              '${withoutLastLine.join('\n')}\n  runApp(const MyApp());\n}';
        } else {
          // Append to the end
          mainFunctionBody = '$mainFunctionBody\n  runApp(const MyApp());';
        }
      }
    } else {
      // If main function not found, create a simple one
      mainFunctionBody = 'void main() {\n  runApp(const MyApp());\n}';
    }

    // Build the final content
    final parts = <String>[];

    // Add imports
    if (imports.isNotEmpty) {
      parts.add(imports.join('\n'));
    }

    // Add code before main function (if any)
    if (codeBeforeMain.isNotEmpty) {
      parts.add('');
      parts.add(codeBeforeMain.join('\n'));
    }

    // Add main function
    parts.add('');
    parts.add(mainFunctionBody);

    final result = parts.join('\n') + '\n';

    return result;
  }

  /// Remove a class declaration completely, handling nested braces
  static String _removeClass(String content, String className) {
    // Pattern to match class declaration
    final classPattern = RegExp(
      r'class\s+' + RegExp.escape(className) + r'[^{]*\{',
      multiLine: true,
    );

    final match = classPattern.firstMatch(content);
    if (match == null) return content;

    final startIndex = match.start;
    int braceCount = 0;
    bool inString = false;
    String? stringChar;
    int? endIndex;

    // Find the matching closing brace
    for (int i = startIndex; i < content.length; i++) {
      final char = content[i];

      // Handle string literals
      if (!inString && (char == '"' || char == "'")) {
        inString = true;
        stringChar = char;
        continue;
      } else if (inString &&
          char == stringChar &&
          (i == 0 || content[i - 1] != '\\')) {
        inString = false;
        stringChar = null;
        continue;
      }

      if (inString) continue;

      // Count braces
      if (char == '{') {
        braceCount++;
      } else if (char == '}') {
        braceCount--;
        if (braceCount == 0) {
          endIndex = i + 1;
          break;
        }
      }
    }

    if (endIndex == null) return content;

    // Remove the class including any trailing newlines
    final before = content.substring(0, startIndex);
    final after = content.substring(endIndex);

    // Remove leading newlines from after
    final afterCleaned = after.replaceFirst(RegExp(r'^\s*\n+'), '');

    return before + afterCleaned;
  }

  /// Create app.dart file
  static Future<void> _createAppFile() async {
    final appFilePath = path.join('lib', 'app.dart');
    final appFile = File(appFilePath);

    // Check if app.dart already exists
    if (appFile.existsSync()) {
      Logger.warning('app.dart already exists. Skipping creation.');
      return;
    }

    // Detect app name
    final appName = await _detectAppName();
    final appTitle = appName ?? '';
    // Escape single quotes in app name
    final escapedAppTitle = appTitle.replaceAll("'", "\\'");

    final appContent = '''import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove debug banner
      debugShowCheckedModeBanner: false,
      // App title (shows in task switcher)
      title: '$escapedAppTitle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Container(),
    );
  }
}
''';

    await appFile.writeAsString(appContent);
  }

  /// Detect app name from AndroidManifest.xml or strings.xml
  static Future<String?> _detectAppName() async {
    try {
      // First, try AndroidManifest.xml android:label
      final manifestPath =
          path.join('android', 'app', 'src', 'main', 'AndroidManifest.xml');
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
      final stringsXmlPath = path.join(
          'android', 'app', 'src', 'main', 'res', 'values', 'strings.xml');
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
      final stringsXmlPath = path.join(
          'android', 'app', 'src', 'main', 'res', 'values', 'strings.xml');
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

  /// Update widget_test.dart to import app.dart
  static Future<void> _updateWidgetTest() async {
    final testFilePath = path.join('test', 'widget_test.dart');
    final testFile = File(testFilePath);

    if (!testFile.existsSync()) {
      Logger.info('widget_test.dart not found, skipping test file update.');
      return;
    }

    try {
      String testContent = await testFile.readAsString();

      // Check if it already imports app.dart
      if (testContent.contains("import '../lib/app.dart';") ||
          testContent.contains('import "../lib/app.dart";') ||
          (testContent.contains("import 'package:") &&
              testContent.contains('app.dart'))) {
        Logger.info('widget_test.dart already imports app.dart.');
        return;
      }

      // Remove import from main.dart if exists (line by line)
      final contentLinesList = testContent.split('\n');
      final cleanedLines = <String>[];
      for (final line in contentLinesList) {
        final trimmedLine = line.trim();
        // Skip lines that import main.dart
        if (trimmedLine.startsWith('import') &&
            (trimmedLine.contains('../lib/main.dart') ||
                trimmedLine.contains('package:') &&
                    trimmedLine.contains('/main.dart'))) {
          continue; // Skip this import line
        }
        cleanedLines.add(line);
      }
      testContent = cleanedLines.join('\n');

      // Add import for app.dart
      // Check if there are any imports
      final hasImports =
          RegExp(r'^import\s+', multiLine: true).hasMatch(testContent);

      String appImport;
      // Try to determine package name from pubspec.yaml
      final pubspecFile = File('pubspec.yaml');
      String packageImport = "import '../lib/app.dart';";

      if (pubspecFile.existsSync()) {
        try {
          final pubspecContent = await pubspecFile.readAsString();
          final nameMatch = RegExp(r'^name:\s*(.+)$', multiLine: true)
              .firstMatch(pubspecContent);
          if (nameMatch != null) {
            final packageName = nameMatch.group(1)?.trim();
            if (packageName != null && packageName.isNotEmpty) {
              packageImport = "import 'package:$packageName/app.dart';";
            }
          }
        } catch (e) {
          // Fallback to relative import
        }
      }

      appImport = packageImport;

      // Add the import after existing imports or at the beginning
      if (hasImports) {
        // Find the last import line
        final contentLines = testContent.split('\n');
        int lastImportIndex = -1;
        for (int i = 0; i < contentLines.length; i++) {
          if (contentLines[i].trim().startsWith('import')) {
            lastImportIndex = i;
          } else if (lastImportIndex != -1 &&
              contentLines[i].trim().isNotEmpty) {
            break;
          }
        }

        if (lastImportIndex != -1) {
          // Insert after last import
          contentLines.insert(lastImportIndex + 1, appImport);
          testContent = contentLines.join('\n');
        } else {
          // Add at the beginning
          testContent = '$appImport\n$testContent';
        }
      } else {
        // Add at the beginning
        testContent = '$appImport\n$testContent';
      }

      // Ensure const MyApp() is used (remove const if needed, or keep it)
      // The test file should already have const MyApp(), so we just ensure it's correct

      await testFile.writeAsString(testContent);
      Logger.success('Updated widget_test.dart');
    } catch (e) {
      Logger.warning('Failed to update widget_test.dart: $e');
      Logger.info('Please manually update widget_test.dart to import app.dart');
    }
  }
}
