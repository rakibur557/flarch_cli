import 'dart:io';
import '../../core/utils/logger.dart';

/// Health check result for a single check
class HealthCheck {
  final String name;
  final String description;
  final bool passed;
  final String? recommendation;
  final HealthSeverity severity;

  HealthCheck({
    required this.name,
    required this.description,
    required this.passed,
    this.recommendation,
    this.severity = HealthSeverity.info,
  });
}

enum HealthSeverity {
  success,
  warning,
  error,
  info,
}

/// Health check category
class HealthCategory {
  final String name;
  final List<HealthCheck> checks;
  final int passedCount;
  final int totalCount;

  HealthCategory({
    required this.name,
    required this.checks,
  })  : passedCount = checks.where((c) => c.passed).length,
        totalCount = checks.length;
}

/// Project health manager
class HealthManager {
  /// Run comprehensive health check
  static Future<void> checkHealth() async {
    Logger.header('🏥 Project Health Check');

    final categories = <HealthCategory>[];

    // 1. Project Structure
    categories.add(await _checkProjectStructure());

    // 2. Dependencies
    categories.add(await _checkDependencies());

    // 3. Configuration
    categories.add(await _checkConfiguration());

    // 4. Code Organization
    categories.add(await _checkCodeOrganization());

    // 5. Best Practices
    categories.add(await _checkBestPractices());

    // Display results with nice UI
    _displayHealthReport(categories);

    // Calculate and display overall score
    _displayOverallScore(categories);
  }

  /// Check project structure
  static Future<HealthCategory> _checkProjectStructure() async {
    final checks = <HealthCheck>[];

    // Check pubspec.yaml
    final pubspecExists = File('pubspec.yaml').existsSync();
    checks.add(HealthCheck(
      name: 'pubspec.yaml',
      description: 'Project configuration file',
      passed: pubspecExists,
      recommendation: pubspecExists ? null : 'Create pubspec.yaml in project root',
      severity: pubspecExists ? HealthSeverity.success : HealthSeverity.error,
    ));

    // Check lib directory
    final libExists = Directory('lib').existsSync();
    checks.add(HealthCheck(
      name: 'lib/ directory',
      description: 'Main source code directory',
      passed: libExists,
      recommendation: libExists ? null : 'Create lib/ directory for source code',
      severity: libExists ? HealthSeverity.success : HealthSeverity.error,
    ));

    // Check main.dart
    final mainExists = File('lib/main.dart').existsSync();
    checks.add(HealthCheck(
      name: 'lib/main.dart',
      description: 'Application entry point',
      passed: mainExists,
      recommendation: mainExists ? null : 'Create lib/main.dart as entry point',
      severity: mainExists ? HealthSeverity.success : HealthSeverity.error,
    ));

    // Check app.dart (optional but recommended)
    final appExists = File('lib/app.dart').existsSync();
    checks.add(HealthCheck(
      name: 'lib/app.dart',
      description: 'App widget configuration (recommended)',
      passed: appExists,
      recommendation: appExists
          ? null
          : 'Consider creating lib/app.dart for better code organization. Run: flarch config main',
      severity: appExists ? HealthSeverity.success : HealthSeverity.warning,
    ));

    // Check test directory
    final testExists = Directory('test').existsSync();
    checks.add(HealthCheck(
      name: 'test/ directory',
      description: 'Unit and widget tests',
      passed: testExists,
      recommendation: testExists
          ? null
          : 'Create test/ directory for writing tests',
      severity: testExists ? HealthSeverity.success : HealthSeverity.warning,
    ));

    return HealthCategory(name: '📁 Project Structure', checks: checks);
  }

  /// Check dependencies
  static Future<HealthCategory> _checkDependencies() async {
    final checks = <HealthCheck>[];

    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      return HealthCategory(name: '📦 Dependencies', checks: []);
    }

    final content = await pubspecFile.readAsString();

    // Check Flutter SDK version
    final hasFlutterSdk = content.contains('sdk: flutter') ||
        content.contains('flutter:') ||
        RegExp(r'sdk:\s*flutter').hasMatch(content);
    checks.add(HealthCheck(
      name: 'Flutter SDK',
      description: 'Flutter SDK dependency',
      passed: hasFlutterSdk,
      recommendation: hasFlutterSdk
          ? null
          : 'Ensure Flutter SDK is properly configured in pubspec.yaml',
      severity: hasFlutterSdk ? HealthSeverity.success : HealthSeverity.error,
    ));

    // Check for common state management
    final hasStateManagement = content.contains('flutter_bloc') ||
        content.contains('get:') ||
        content.contains('provider:') ||
        content.contains('riverpod:') ||
        content.contains('mobx:');
    checks.add(HealthCheck(
      name: 'State Management',
      description: 'State management solution',
      passed: hasStateManagement,
      recommendation: hasStateManagement
          ? null
          : 'Consider adding a state management solution (Bloc, GetX, Provider, Riverpod)',
      severity: hasStateManagement ? HealthSeverity.success : HealthSeverity.warning,
    ));

    // Check for dependency injection
    final hasDI = content.contains('get_it:') || content.contains('injectable:');
    checks.add(HealthCheck(
      name: 'Dependency Injection',
      description: 'DI solution (GetIt, Injectable)',
      passed: hasDI,
      recommendation: hasDI
          ? null
          : 'Consider using dependency injection. Run: flarch config di',
      severity: hasDI ? HealthSeverity.success : HealthSeverity.info,
    ));

    // Check for routing
    final hasRouter = content.contains('go_router:') ||
        content.contains('auto_route:') ||
        content.contains('fluro:');
    checks.add(HealthCheck(
      name: 'Routing',
      description: 'Navigation/routing solution',
      passed: hasRouter,
      recommendation: hasRouter
          ? null
          : 'Consider setting up routing. Run: flarch config router',
      severity: hasRouter ? HealthSeverity.success : HealthSeverity.info,
    ));

    // Check for local storage
    final hasStorage = content.contains('hive:') ||
        content.contains('shared_preferences:') ||
        content.contains('objectbox:') ||
        content.contains('isar:') ||
        content.contains('drift:');
    checks.add(HealthCheck(
      name: 'Local Storage',
      description: 'Local data persistence',
      passed: hasStorage,
      recommendation: hasStorage
          ? null
          : 'Consider adding local storage. Run: flarch config storage',
      severity: hasStorage ? HealthSeverity.success : HealthSeverity.info,
    ));

    // Check for HTTP client
    final hasHttp = content.contains('http:') ||
        content.contains('dio:') ||
        content.contains('chopper:');
    checks.add(HealthCheck(
      name: 'HTTP Client',
      description: 'Network/API client',
      passed: hasHttp,
      recommendation: hasHttp
          ? null
          : 'Consider adding an HTTP client (http, dio) for API calls',
      severity: hasHttp ? HealthSeverity.success : HealthSeverity.info,
    ));

    return HealthCategory(name: '📦 Dependencies', checks: checks);
  }

  /// Check configuration
  static Future<HealthCategory> _checkConfiguration() async {
    final checks = <HealthCheck>[];

    // Check for theme configuration
    final hasThemeConfig = File('lib/core/theme/app_theme.dart').existsSync() ||
        File('lib/core/theme/theme.dart').existsSync() ||
        File('lib/theme/app_theme.dart').existsSync();
    checks.add(HealthCheck(
      name: 'Theme Configuration',
      description: 'App theme setup',
      passed: hasThemeConfig,
      recommendation: hasThemeConfig
          ? null
          : 'Consider setting up theme configuration. Run: flarch config theme',
      severity: hasThemeConfig ? HealthSeverity.success : HealthSeverity.info,
    ));

    // Check for assets configuration
    final pubspecFile = File('pubspec.yaml');
    bool hasAssets = false;
    if (pubspecFile.existsSync()) {
      final content = await pubspecFile.readAsString();
      hasAssets = content.contains('assets:') || content.contains('flutter:');
    }
    checks.add(HealthCheck(
      name: 'Assets Configuration',
      description: 'Assets folder setup',
      passed: hasAssets,
      recommendation: hasAssets
          ? null
          : 'Consider setting up assets. Run: flarch config assets',
      severity: hasAssets ? HealthSeverity.success : HealthSeverity.info,
    ));

    // Check for .gitignore
    final hasGitignore = File('.gitignore').existsSync();
    checks.add(HealthCheck(
      name: '.gitignore',
      description: 'Git ignore file',
      passed: hasGitignore,
      recommendation: hasGitignore
          ? null
          : 'Create .gitignore to exclude build files and dependencies',
      severity: hasGitignore ? HealthSeverity.success : HealthSeverity.warning,
    ));

    // Check for analysis_options.yaml
    final hasAnalysisOptions = File('analysis_options.yaml').existsSync();
    checks.add(HealthCheck(
      name: 'analysis_options.yaml',
      description: 'Dart analyzer configuration',
      passed: hasAnalysisOptions,
      recommendation: hasAnalysisOptions
          ? null
          : 'Create analysis_options.yaml for code quality rules',
      severity: hasAnalysisOptions ? HealthSeverity.success : HealthSeverity.info,
    ));

    return HealthCategory(name: '⚙️  Configuration', checks: checks);
  }

  /// Check code organization
  static Future<HealthCategory> _checkCodeOrganization() async {
    final checks = <HealthCheck>[];

    // Check for features directory
    final hasFeaturesDir = Directory('lib/features').existsSync();
    checks.add(HealthCheck(
      name: 'lib/features/',
      description: 'Feature-based organization',
      passed: hasFeaturesDir,
      recommendation: hasFeaturesDir
          ? null
          : 'Consider organizing code by features. Create lib/features/ directory',
      severity: hasFeaturesDir ? HealthSeverity.success : HealthSeverity.info,
    ));

    // Check for core directory
    final hasCoreDir = Directory('lib/core').existsSync();
    checks.add(HealthCheck(
      name: 'lib/core/',
      description: 'Core/shared utilities',
      passed: hasCoreDir,
      recommendation: hasCoreDir
          ? null
          : 'Consider creating lib/core/ for shared utilities and configurations',
      severity: hasCoreDir ? HealthSeverity.success : HealthSeverity.info,
    ));

    // Count features
    int featureCount = 0;
    if (hasFeaturesDir) {
      final featuresDir = Directory('lib/features');
      if (featuresDir.existsSync()) {
        final entities = featuresDir.listSync();
        featureCount = entities.where((e) => e is Directory).length;
      }
    }
    checks.add(HealthCheck(
      name: 'Feature Count',
      description: 'Number of features: $featureCount',
      passed: featureCount > 0,
      recommendation: featureCount > 0
          ? null
          : 'Create features using: flarch "FeatureName"',
      severity: featureCount > 0 ? HealthSeverity.success : HealthSeverity.info,
    ));

    // Check for proper main.dart structure
    bool hasProperMain = false;
    final mainFile = File('lib/main.dart');
    if (mainFile.existsSync()) {
      final content = await mainFile.readAsString();
      hasProperMain = content.contains('runApp(') &&
          (content.contains('WidgetsFlutterBinding.ensureInitialized()') ||
              content.contains('main()'));
    }
    checks.add(HealthCheck(
      name: 'main.dart Structure',
      description: 'Proper main.dart setup',
      passed: hasProperMain,
      recommendation: hasProperMain
          ? null
          : 'Ensure main.dart has proper structure. Run: flarch config main',
      severity: hasProperMain ? HealthSeverity.success : HealthSeverity.warning,
    ));

    return HealthCategory(name: '📚 Code Organization', checks: checks);
  }

  /// Check best practices
  static Future<HealthCategory> _checkBestPractices() async {
    final checks = <HealthCheck>[];

    // Check pubspec.yaml for comments
    final pubspecFile = File('pubspec.yaml');
    bool hasComments = false;
    if (pubspecFile.existsSync()) {
      final content = await pubspecFile.readAsString();
      hasComments = content.contains('#') && RegExp(r'#\s*[A-Z]').hasMatch(content);
    }
    checks.add(HealthCheck(
      name: 'Clean pubspec.yaml',
      description: 'pubspec.yaml without unnecessary comments',
      passed: !hasComments,
      recommendation: hasComments
          ? 'Clean pubspec.yaml comments. Run: flarch clean pubspec'
          : null,
      severity: hasComments ? HealthSeverity.warning : HealthSeverity.success,
    ));

    // Check for README
    final hasReadme = File('README.md').existsSync();
    checks.add(HealthCheck(
      name: 'README.md',
      description: 'Project documentation',
      passed: hasReadme,
      recommendation: hasReadme
          ? null
          : 'Create README.md with project description and setup instructions',
      severity: hasReadme ? HealthSeverity.success : HealthSeverity.info,
    ));

    // Check for proper package name
    bool hasValidPackageName = false;
    if (pubspecFile.existsSync()) {
      final content = await pubspecFile.readAsString();
      final packageMatch = RegExp(r'^name:\s*([a-z0-9_]+)', multiLine: true).firstMatch(content);
      if (packageMatch != null) {
        final packageName = packageMatch.group(1)!;
        hasValidPackageName = RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(packageName);
      } else {
        hasValidPackageName = false;
      }
    }
    checks.add(HealthCheck(
      name: 'Package Name',
      description: 'Valid package naming (lowercase, underscores)',
      passed: hasValidPackageName,
      recommendation: hasValidPackageName
          ? null
          : 'Ensure package name follows Dart conventions (lowercase, underscores only)',
      severity: hasValidPackageName ? HealthSeverity.success : HealthSeverity.warning,
    ));

    return HealthCategory(name: '✨ Best Practices', checks: checks);
  }

  /// Display health report with nice UI
  static void _displayHealthReport(List<HealthCategory> categories) {
    print('');
    final headerColor = Logger.rgb(135, 206, 250, bold: true);
    
    print('$headerColor╔${'═' * 78}╗${Logger.reset}');
    print('$headerColor║${' ' * 20}📊 Health Check Report${' ' * 20}$headerColor║${Logger.reset}');
    print('$headerColor╚${'═' * 78}╝${Logger.reset}');
    print('');

    for (final category in categories) {
      // Category header with score
      final score = category.totalCount > 0
          ? ((category.passedCount / category.totalCount) * 100).round()
          : 0;
      
      final scoreColor = score >= 80
          ? Logger.successColor
          : score >= 50
              ? Logger.warningColor
              : Logger.errorColor;
      
      final scoreBar = _generateProgressBar(score);
      
      print('$headerColor┌${'─' * 76}┐${Logger.reset}');
      print('$headerColor│${Logger.reset} $headerColor${category.name}${Logger.reset}');
      print('$headerColor│${Logger.reset} $scoreBar');
      print('$headerColor│${Logger.reset} $scoreColor$score%${Logger.reset} ($scoreColor${category.passedCount}${Logger.reset}/${category.totalCount} checks passed)');
      print('$headerColor├${'─' * 76}┤${Logger.reset}');

      // Individual checks
      for (final check in category.checks) {
        String icon;
        String colorCode;
        switch (check.severity) {
          case HealthSeverity.success:
            icon = '✓';
            colorCode = Logger.successColor;
            break;
          case HealthSeverity.warning:
            icon = '⚠️';
            colorCode = Logger.warningColor;
            break;
          case HealthSeverity.error:
            icon = '✗';
            colorCode = Logger.errorColor;
            break;
          case HealthSeverity.info:
            icon = check.passed ? '✓' : 'ℹ️';
            colorCode = check.passed ? Logger.successColor : Logger.infoColor;
            break;
        }

        final status = check.passed ? 'PASS' : 'FAIL';
        final statusColor = check.passed ? Logger.successColor : Logger.errorColor;

        // Format check line
        final checkLine = '  $colorCode$icon${Logger.reset} [$statusColor$status${Logger.reset}] ${check.name}';
        print('$headerColor│${Logger.reset}$checkLine');
        
        // Description
        final descColor = Logger.rgb(200, 200, 200);
        print('$headerColor│${Logger.reset}    $descColor${check.description}${Logger.reset}');

        // Recommendation
        if (check.recommendation != null) {
          final recColor = Logger.rgb(241, 196, 15);
          print('$headerColor│${Logger.reset}    $recColor💡 ${check.recommendation}${Logger.reset}');
        }
        
        print('$headerColor│${Logger.reset}');
      }

      print('$headerColor└${'─' * 76}┘${Logger.reset}');
      print('');
    }
  }

  /// Generate progress bar
  static String _generateProgressBar(int percentage) {
    final barWidth = 50;
    final filled = (barWidth * percentage / 100).round();
    final empty = barWidth - filled;
    
    final filledColor = percentage >= 80
        ? Logger.successColor
        : percentage >= 50
            ? Logger.warningColor
            : Logger.errorColor;
    
    final filledBar = '$filledColor${'█' * filled}${Logger.reset}';
    final emptyBar = '${Logger.rgb(100, 100, 100)}${'░' * empty}${Logger.reset}';
    
    return '$filledBar$emptyBar';
  }

  /// Display overall health score with nice UI
  static void _displayOverallScore(List<HealthCategory> categories) {
    final totalChecks = categories.fold<int>(0, (sum, cat) => sum + cat.totalCount);
    final totalPassed = categories.fold<int>(0, (sum, cat) => sum + cat.passedCount);
    final overallScore = totalChecks > 0 ? ((totalPassed / totalChecks) * 100).round() : 0;

    print('');
    final boxColor = Logger.rgb(135, 206, 250);
    
    final scoreColor = overallScore >= 80
        ? Logger.successColor
        : overallScore >= 50
            ? Logger.warningColor
            : Logger.errorColor;

    final healthStatus = overallScore >= 80
        ? 'Excellent'
        : overallScore >= 50
            ? 'Good'
            : overallScore >= 30
                ? 'Needs Improvement'
                : 'Critical';

    final statusEmoji = overallScore >= 80
        ? '🎉'
        : overallScore >= 50
            ? '👍'
            : overallScore >= 30
                ? '⚠️'
                : '🚨';

    // Overall score box
    print('$boxColor╔${'═' * 78}╗${Logger.reset}');
    print('$boxColor║${' ' * 25}Overall Health Score${' ' * 25}$boxColor║${Logger.reset}');
    print('$boxColor╠${'═' * 78}╣${Logger.reset}');
    
    // Score bar
    final scoreBar = _generateProgressBar(overallScore);
    print('$boxColor║${Logger.reset} $scoreBar $boxColor║${Logger.reset}');
    
    // Status
    print('$boxColor║${Logger.reset}');
    print('$boxColor║${Logger.reset}  $statusEmoji $scoreColor$healthStatus${Logger.reset}');
    print('$boxColor║${Logger.reset}  $scoreColor$totalPassed/$totalChecks checks passed ($overallScore%)${Logger.reset}');
    print('$boxColor║${Logger.reset}');

    // Recommendations summary
    final recommendations = <String>[];
    for (final category in categories) {
      for (final check in category.checks) {
        if (check.recommendation != null && !check.passed) {
          recommendations.add(check.recommendation!);
        }
      }
    }

    if (recommendations.isNotEmpty) {
      print('$boxColor║${Logger.reset}');
      final recColor = Logger.rgb(241, 196, 15, bold: true);
      print('$boxColor║${Logger.reset}  $recColor💡 Quick Recommendations:${Logger.reset}');
      print('$boxColor║${Logger.reset}');
      
      for (var i = 0; i < recommendations.length && i < 5; i++) {
        final num = '${i + 1}.';
        print('$boxColor║${Logger.reset}    $num ${recommendations[i]}');
      }
      
      if (recommendations.length > 5) {
        print('$boxColor║${Logger.reset}    ... and ${recommendations.length - 5} more');
      }
    }

    print('$boxColor╚${'═' * 78}╝${Logger.reset}');
    print('');
  }
}

