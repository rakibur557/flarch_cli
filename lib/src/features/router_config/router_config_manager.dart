import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../../core/utils/utility.dart';
import '../main_config/main_config_manager.dart';

/// Manages router configuration for Flutter projects
class RouterConfigManager {
  /// Configure router for the Flutter project
  static Future<bool> configureRouter() async {
    try {
      Logger.header('🚀 Router Configuration Setup');

      // Check if we're in a Flutter project
      if (!_isFlutterProject()) {
        Logger.error(
            'Not a Flutter project. Please run this command from your Flutter project root.');
        return false;
      }

      int totalSteps = 5;
      int currentStep = 0;

      // Step 1: Check if go_router dependency exists
      currentStep = 1;
      Logger.step(currentStep, totalSteps, 'Checking go_router dependency');
      final pubspecFile = File('pubspec.yaml');
      final pubspecContent = await pubspecFile.readAsString();
      final hasGoRouter = pubspecContent
              .contains(RegExp(r'^go_router:', multiLine: true)) ||
          pubspecContent.contains(RegExp(r'^  go_router:', multiLine: true));

      if (!hasGoRouter) {
        Logger.info('   go_router not found in dependencies');
        Logger.info('   Adding go_router package...');
        final added = await Utility.addDependency('go_router');
        if (!added) {
          Logger.error(
              'Failed to add go_router dependency. Please add it manually.');
          return false;
        }
        Logger.success('   go_router added successfully');
      } else {
        Logger.success('   go_router already in dependencies');
      }

      // Step 2: Check if app.dart exists and is properly configured
      currentStep = 2;
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
            !appContent.contains('MaterialApp')) {
          Logger.warning(
              '   app.dart exists but doesn\'t have expected structure');
          needsMainConfig = true;
        } else {
          Logger.success('   app.dart is properly configured');
        }
      }

      // Step 3: Configure main.dart if needed
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
      }

      // Step 4: Create router file
      currentStep = 3;
      Logger.step(currentStep, totalSteps, 'Creating router configuration');
      await _createRouterFile();
      Logger.success(
          '   Router file created at lib/core/router/app_router.dart');

      // Step 5: Update app.dart with router
      currentStep = 4;
      Logger.step(currentStep, totalSteps, 'Updating app.dart with router');
      final updateSuccess = await _updateAppWithRouter();
      if (updateSuccess) {
        Logger.success('   app.dart updated with MaterialApp.router');
      } else {
        Logger.warning(
            '   app.dart update may have issues. Please check manually.');
      }

      // Summary
      Logger.summary('Router Configuration Complete', [
        'go_router package added/verified',
        'AppRouter configured with professional setup',
        'MaterialApp.router configured',
        'All files updated successfully',
      ]);

      return true;
    } catch (e) {
      Logger.error('Failed to configure router: $e');
      return false;
    }
  }

  /// Check if we're in a Flutter project
  static bool _isFlutterProject() {
    final pubspecFile = File('pubspec.yaml');
    final libDir = Directory('lib');
    return pubspecFile.existsSync() && libDir.existsSync();
  }

  /// Create app_router.dart file with professional GoRouter setup
  static Future<void> _createRouterFile() async {
    final coreDir = Directory(path.join('lib', 'core'));
    if (!coreDir.existsSync()) {
      await coreDir.create(recursive: true);
    }

    final routerDir = Directory(path.join('lib', 'core', 'router'));
    if (!routerDir.existsSync()) {
      await routerDir.create(recursive: true);
    }

    final routerFilePath =
        path.join('lib', 'core', 'router', 'app_router.dart');
    final routerFile = File(routerFilePath);

    // Check if router file already exists
    if (routerFile.existsSync()) {
      Logger.warning('app_router.dart already exists. Skipping creation.');
      return;
    }

    final routerContent = '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App router configuration
/// Provides centralized routing with GoRouter
class AppRouter {
  AppRouter._(); // Private constructor to prevent instantiation

  /// Create and configure the router
  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      // Add your routes here
      // Example:
      // GoRoute(
      //   path: '/login',
      //   name: 'login',
      //   builder: (context, state) => const LoginPage(),
      // ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: \${state.error}'),
      ),
    ),
  );

  /// Navigate to a route by path
  static void go(String path) {
    _router.go(path);
  }

  /// Navigate to a route by name
  static void goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    _router.goNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Push a route
  static Future<T?> push<T extends Object?>(
    String path, {
    Object? extra,
  }) {
    return _router.push<T>(path, extra: extra);
  }

  /// Push a named route
  static Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    return _router.pushNamed<T>(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Pop the current route
  static void pop<T extends Object?>([T? result]) {
    _router.pop<T>(result);
  }

  /// Check if can pop
  static bool canPop() {
    return _router.canPop();
  }
}

/// Placeholder HomePage - replace with your actual home page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: const Center(
        child: Text('Home Page'),
      ),
    );
  }
}
''';

    await routerFile.writeAsString(routerContent);
  }

  /// Update app.dart to use MaterialApp.router
  static Future<bool> _updateAppWithRouter() async {
    try {
      // First try app.dart
      final appFilePath = path.join('lib', 'app.dart');
      final appFile = File(appFilePath);

      if (appFile.existsSync()) {
        return await _updateMaterialAppInFile(appFile);
      }

      // If app.dart doesn't exist, search for MaterialApp in lib directory
      final libDir = Directory('lib');
      if (libDir.existsSync()) {
        final materialAppFiles = await _findMaterialAppFiles(libDir);
        if (materialAppFiles.isNotEmpty) {
          // Update the first file found
          return await _updateMaterialAppInFile(materialAppFiles.first);
        }
      }

      Logger.error(
          'Could not find MaterialApp in the project. Please ensure app.dart exists.');
      return false;
    } catch (e) {
      Logger.error('Failed to update app with router: $e');
      return false;
    }
  }

  /// Find all Dart files containing MaterialApp
  static Future<List<File>> _findMaterialAppFiles(Directory dir) async {
    final files = <File>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        try {
          final content = await entity.readAsString();
          if (content.contains('MaterialApp(')) {
            files.add(entity);
          }
        } catch (e) {
          // Skip files that can't be read
        }
      }
    }
    return files;
  }

  /// Update MaterialApp in a file to use MaterialApp.router
  static Future<bool> _updateMaterialAppInFile(File file) async {
    try {
      String content = await file.readAsString();

      // Check if already configured
      if (content.contains('MaterialApp.router') &&
          content.contains('AppRouter.router')) {
        Logger.info('   MaterialApp.router already configured');
        return true;
      }

      // Add import if not present
      if (!content.contains("import 'core/router/app_router.dart';") &&
          !content.contains('import "core/router/app_router.dart";')) {
        // Find the last import statement
        final lines = content.split('\n');
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

        final routerImport = "import 'core/router/app_router.dart';";
        if (lastImportIndex != -1) {
          lines.insert(lastImportIndex + 1, routerImport);
        } else {
          // Add at the beginning
          lines.insert(0, routerImport);
        }
        content = lines.join('\n');
      }

      // Find MaterialApp and update to MaterialApp.router
      final materialAppStart = content.indexOf('MaterialApp(');
      if (materialAppStart == -1) {
        Logger.warning('   MaterialApp not found in ${file.path}');
        return false;
      }

      // Find the matching closing parenthesis for MaterialApp
      int parenCount = 1;
      int materialAppEnd = materialAppStart + 'MaterialApp('.length;
      for (int i = materialAppEnd; i < content.length; i++) {
        final char = content[i];
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
          content.substring(materialAppStart, materialAppEnd + 1);
      final beforeMaterialApp = content.substring(0, materialAppStart);
      final afterMaterialApp = content.substring(materialAppEnd + 1);

      // Update MaterialApp to MaterialApp.router
      String updatedMaterialApp = materialAppContent;

      // Remove home: property if it exists (not compatible with router)
      updatedMaterialApp = _removeHomeProperty(updatedMaterialApp);

      // Change MaterialApp( to MaterialApp.router(
      updatedMaterialApp = updatedMaterialApp.replaceFirst(
          'MaterialApp(', 'MaterialApp.router(');

      // Add routerConfig if not present
      if (!updatedMaterialApp.contains('routerConfig:')) {
        // Find where to add routerConfig - after MaterialApp.router(
        final routerStart = updatedMaterialApp.indexOf('MaterialApp.router(');
        if (routerStart != -1) {
          final afterRouter = updatedMaterialApp
              .substring(routerStart + 'MaterialApp.router('.length);
          // Skip whitespace and newlines
          int skipIndex = 0;
          while (skipIndex < afterRouter.length &&
              (afterRouter[skipIndex] == ' ' ||
                  afterRouter[skipIndex] == '\t' ||
                  afterRouter[skipIndex] == '\n')) {
            skipIndex++;
          }

          // Insert routerConfig after MaterialApp.router(
          updatedMaterialApp = updatedMaterialApp.replaceFirst(
            'MaterialApp.router(',
            'MaterialApp.router(\n      routerConfig: AppRouter.router,',
          );
        }
      }

      // Reconstruct the file
      content = beforeMaterialApp + updatedMaterialApp + afterMaterialApp;

      await file.writeAsString(content);
      return true;
    } catch (e) {
      Logger.error('Failed to update MaterialApp in file: $e');
      return false;
    }
  }

  /// Remove home: property from MaterialApp (not compatible with router)
  static String _removeHomeProperty(String content) {
    if (!content.contains('home:')) {
      return content;
    }

    // Find home: property
    int homeStart = content.indexOf('home:');
    if (homeStart == -1) {
      return content;
    }

    // Find where the home value starts (after 'home:')
    int homeValueStart = homeStart + 'home:'.length;
    int homeValueEnd = homeValueStart;

    // Skip whitespace
    while (homeValueEnd < content.length &&
        (content[homeValueEnd] == ' ' ||
            content[homeValueEnd] == '\t' ||
            content[homeValueEnd] == '\n')) {
      homeValueEnd++;
    }

    // Check if it's a simple value or a constructor call
    if (homeValueEnd < content.length && content[homeValueEnd] != '(') {
      // Simple value like 'home: Container(),' - find until comma
      while (homeValueEnd < content.length && content[homeValueEnd] != ',') {
        homeValueEnd++;
      }
      if (homeValueEnd < content.length && content[homeValueEnd] == ',') {
        homeValueEnd++; // Include the comma
      }
    } else {
      // Constructor call like 'home: Container(),' - find matching closing parenthesis
      if (homeValueEnd < content.length && content[homeValueEnd] == '(') {
        int parenCount = 1;
        homeValueEnd++; // Skip the opening '('
        while (homeValueEnd < content.length && parenCount > 0) {
          if (content[homeValueEnd] == '(') {
            parenCount++;
          } else if (content[homeValueEnd] == ')') {
            parenCount--;
            if (parenCount == 0) {
              homeValueEnd++; // Include the closing ')'
              break;
            }
          }
          homeValueEnd++;
        }

        // Skip whitespace after the closing ')'
        while (homeValueEnd < content.length &&
            (content[homeValueEnd] == ' ' ||
                content[homeValueEnd] == '\t' ||
                content[homeValueEnd] == '\n')) {
          homeValueEnd++;
        }

        // Include the comma if present
        if (homeValueEnd < content.length && content[homeValueEnd] == ',') {
          homeValueEnd++; // Include the comma
        }
      }
    }

    // Remove the home property
    final beforeHome = content.substring(0, homeStart);
    final afterHome = content.substring(homeValueEnd);

    // Remove any trailing newline before the next property
    final cleanedAfter = afterHome.replaceFirst(RegExp(r'^\s*\n+'), '\n');

    return beforeHome + cleanedAfter;
  }
}
