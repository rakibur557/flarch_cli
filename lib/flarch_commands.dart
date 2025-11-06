import 'dart:io';
import 'src/features/dependency_injection/get_it_manager.dart';
import 'src/features/architectures/clean_architecture/clean_architecture.dart';
import 'src/core/utils/logger.dart';
import 'src/core/utils/banner.dart';
import 'src/core/utils/prompter.dart';
import 'src/features/delete_feature/feature_remover.dart';
import 'src/features/rename_feature/feature_renamer.dart';
import 'src/features/clean_pub_comment/pubspec_cleaner.dart';
import 'src/features/asset_config/asset_config_manager.dart';
import 'src/features/package_config/package_id_manager.dart';
import 'src/features/app_name/app_name_manager.dart';
import 'src/features/main_config/main_config_manager.dart';
import 'src/features/theme_config/theme_config_manager.dart';
import 'src/features/router_config/router_config_manager.dart';
import 'src/features/storage_config/storage_config_manager.dart';
import 'src/features/tree/tree_manager.dart';
import 'src/features/init/init_manager.dart';
import 'src/features/health/health_manager.dart';
import 'src/core/factories/architecture_factory.dart';

class Flarch {
  // RGB Color helper
  static String rgb(int r, int g, int b, {bool bold = false}) {
    final boldCode = bold ? '1;' : '';
    return '\x1B[${boldCode}38;2;$r;$g;${b}m';
  }

  // Color scheme - Change these RGB values to customize colors
  static final gold = rgb(255, 215, 0, bold: true); // Border and header lines
  static final white = rgb(255, 255, 255); // Commands text
  static final skyBlue = rgb(135, 206, 250, bold: true); // Section titles
  static final successGreen = rgb(46, 204, 113); // Success messages
  static const reset = '\x1B[0m';

  void printUsage() {
    Banner.show();

    print('$skyBlue$reset');
    print('$skyBlue${' ' * 23}$skyBlue 🛠️   USAGE GUIDE 🛠️$reset${' ' * 23}$skyBlue$reset');
    print('$skyBlue$reset');
    print('');

    print('$skyBlue⚡ Creating Features:$reset');
    print('   $white flarch "FeatureName"$reset                               # Interactive mode');
    print('   $white flarch "FeatureName" --clean|--mvc|--mvvm$reset          # With architecture');
    print('');

    print('$skyBlue⚡  Clean Architecture Options:$reset');
    print('   $white flarch "FeatureName" -u "UseCaseName"$reset              # Create use case');
    print('   $white flarch "FeatureName" -m "ModelName"$reset                # Create model/entity');
    print('   $white flarch "FeatureName" -r "RepositoryName"$reset           # Create repository');
    print('   $white flarch "FeatureName" -d "DataSourceName"$reset           # Create data source');
    print('');

    print('$skyBlue⚡ State Management:$reset');
    print('   $white flarch "FeatureName" -sm "Name" -bloc$reset              # Bloc state management');
    print('   $white flarch "FeatureName" -sm "Name" -getx$reset              # GetX state management');
    print('   $white flarch "FeatureName" -sm "Name" -provider$reset          # Provider state management');
    print('');

    print('$skyBlue⚡ Project Initialization:$reset');
    print('   $white flarch init$reset                                        # Initialize Flutter project (interactive mode)');
    print('   $white flarch init <app_name>$reset                            # Initialize Flutter project (non-interactive, all options enabled)');
    print('');

    print('$skyBlue⚡ Feature Management:$reset');
    print('   $white flarch list$reset                                        # List all features');
    print('   $white flarch tree$reset                                        # Show project directory tree');
    print('   $white flarch rm <FeatureName>$reset                        # Remove a feature safely');
    print('   $white flarch rename <OldName> <NewName>$reset                # Rename a feature safely');
    print('   $white flarch rename <OldName>$reset                          # Interactive rename mode');
    print('');

    print('$skyBlue⚡  Project Configuration:$reset');
    print('   $white flarch config assets$reset                              # Setup assets folder structure');
    print('   $white flarch config main$reset                                # Clean main.dart and create app.dart');
    print('   $white flarch config theme$reset                               # Setup theme configuration');
    print('   $white flarch config router$reset                               # Setup GoRouter configuration');
    print(
        '   $white flarch config storage$reset                              # Setup local storage (Hive, SharedPreferences, ObjectBox, Isar, Drift)');
    print('');

    print('$skyBlue⚡ Project Settings:$reset');
    print('   $white flarch config package <new.id>$reset                    # Replace package ID (e.g., com.example.app)');
    print('   $white flarch config package --interactive$reset              # Interactive package ID replacement');
    print('   $white flarch config package <new.id> --backup$reset           # Replace with backup');
    print('   $white flarch config name "App Name"$reset                     # Change app display name');
    print('   $white flarch config name --interactive$reset                  # Interactive app name change');
    print('   $white flarch config name "App Name" --backup$reset             # Change app name with backup');
    print('');

    print('$skyBlue⚡ Project Maintenance:$reset');
    print('   $white flarch clean pubspec$reset                             # Clean comments from pubspec.yaml');
    print('');

    print('$skyBlue⚡ Project Health:$reset');
    print('   $white flarch health$reset                                    # Check project health and get recommendations');
    print('');

    print('$skyBlue⚡  Help & Information:$reset');
    print('   $white flarch --help$reset or $white flarch -h$reset                        # Show this help');
    print('   $white flarch --version$reset or $white flarch -v$reset                     # Show version');
    print('');

    print('$successGreen💡 Tip:$reset Run $white flarch "FeatureName"$reset without arguments for interactive prompts!');
    print('');
  }

  void printVersion() {
    Banner.show();
  }

  Future<void> run(List<String> arguments) async {
    // Handle help and version flags
    if (arguments.isNotEmpty) {
      final firstArg = arguments[0].toLowerCase();
      if (firstArg == '--help' || firstArg == '-h' || firstArg == 'help') {
        printUsage();
        return;
      }
      if (firstArg == '--version' || firstArg == '-v' || firstArg == 'version') {
        printVersion();
        return;
      }
    }

    if (arguments.isEmpty) {
      printUsage();
      return;
    }

    final firstArg = arguments[0];
    final firstArgLower = firstArg.toLowerCase();

    // Reserved commands that cannot be feature names
    final reservedCommands = [
      'list',
      'tree',
      'init',
      'remove',
      'delete',
      'del',
      'rm',
      'rename',
      'mv',
      'ren',
      'clean',
      'config',
      'setup',
      'health',
    ];

    // Check if it's a reserved command first (case-insensitive)
    if (reservedCommands.contains(firstArgLower)) {
      if (firstArgLower == 'list') {
        await _listFeatures();
        return;
      }

      if (firstArgLower == 'tree') {
        await TreeManager.showTree();
        return;
      }

      if (firstArgLower == 'health') {
        await HealthManager.checkHealth();
        return;
      }

      if (firstArgLower == 'init') {
        // Check if app name is provided as second argument
        String? appName;
        if (arguments.length > 1) {
          appName = arguments[1];
          // Validate app name (lowercase, underscores only, no spaces or special characters)
          if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(appName)) {
            Logger.error('Invalid app name: $appName');
            Logger.info('App name must be lowercase, with underscores only, no spaces or special characters.');
            return;
          }
        }
        await InitManager.initialize(appName: appName);
        return;
      }

      // For other reserved commands, continue to their specific handlers below
      // They will be handled with case-insensitive checks
    }

    // Continue with original case for feature name
    final featureName = firstArg;

    // Handle remove command (case-insensitive)
    if (firstArgLower == 'remove' || firstArgLower == 'delete' || firstArgLower == 'del' || firstArgLower == 'rm') {
      if (arguments.length < 2) {
        Logger.error('Please specify a feature name to delete.');
        Logger.info('Usage: flarch delete <FeatureName>');
        return;
      }
      final featureToRemove = arguments[1];
      await _removeFeature(featureToRemove);
      return;
    }

    // Handle rename command (case-insensitive)
    if (firstArgLower == 'rename' || firstArgLower == 'mv' || firstArgLower == 'ren') {
      if (arguments.length < 2) {
        Logger.error('Please specify a feature name to rename.');
        Logger.info('Usage: flarch rename <OldFeatureName> [NewFeatureName]');
        Logger.info('  Examples:');
        Logger.info('    flarch rename old_feature new_feature');
        Logger.info('    flarch rename old_feature  (interactive mode)');
        return;
      }
      final oldFeatureName = arguments[1];
      final newFeatureName = arguments.length > 2 ? arguments[2] : null;
      await FeatureRenamer.renameFeature(oldFeatureName, newFeatureName: newFeatureName);
      return;
    }

    // Handle clean command (case-insensitive)
    if (firstArgLower == 'clean') {
      if (arguments.length < 2) {
        Logger.error('Please specify what to clean.');
        Logger.info('Usage: flarch clean pubspec');
        Logger.info('Available options: pubspec (cleans pubspec.yaml comments)');
        return;
      }
      final cleanTarget = arguments[1].toLowerCase();
      if (cleanTarget == 'pubspec' || cleanTarget == 'pubspec.yaml') {
        await PubspecCleaner.cleanPubspec();
      } else {
        Logger.error('Unknown clean target: $cleanTarget');
        Logger.info('Available options: pubspec');
      }
      return;
    }

    // Handle config command (case-insensitive)
    if (firstArgLower == 'config') {
      if (arguments.length < 2) {
        Logger.error('Please specify what to configure.');
        Logger.info(
            'Usage: flarch config assets | flarch config main | flarch config theme | flarch config router | flarch config storage | flarch config package [id] | flarch config name [name]');
        Logger.info('Available options:');
        Logger.info('  assets - Setup assets folder structure');
        Logger.info('  main - Clean main.dart and create app.dart');
        Logger.info('  theme - Setup theme configuration with light/dark themes');
        Logger.info('  router - Setup GoRouter configuration');
        Logger.info('  storage - Setup local storage (Hive, SharedPreferences, ObjectBox, Isar, Drift)');
        Logger.info('  package [id] - Replace application package ID');
        Logger.info('    Examples:');
        Logger.info('      flarch config package com.newpackage.app');
        Logger.info('      flarch config package --interactive');
        Logger.info('      flarch config package com.newpackage.app --backup');
        Logger.info('  name [name] - Change app display name');
        Logger.info('    Examples:');
        Logger.info('      flarch config name "My New App"');
        Logger.info('      flarch config name --interactive');
        Logger.info('      flarch config name "My New App" --backup');
        return;
      }
      final configTarget = arguments[1].toLowerCase();

      if (configTarget == 'assets') {
        await AssetConfigManager.setupAssets();
      } else if (configTarget == 'main') {
        await MainConfigManager.configureMain();
      } else if (configTarget == 'theme') {
        await ThemeConfigManager.configureTheme();
      } else if (configTarget == 'router') {
        await RouterConfigManager.configureRouter();
      } else if (configTarget == 'storage' || configTarget == 'local storage') {
        await StorageConfigManager.configureStorage();
      } else if (configTarget == 'package') {
        // Parse package command options
        bool interactive = arguments.contains('--interactive') || arguments.contains('-i');
        bool createBackup = arguments.contains('--backup') || arguments.contains('-b');
        bool dryRun = arguments.contains('--dry-run') || arguments.contains('--preview');

        // Get package ID from arguments (skip flags)
        String? newPackageId;
        for (int i = 2; i < arguments.length; i++) {
          final arg = arguments[i];
          if (!arg.startsWith('--') && arg != '-i' && arg != '-b') {
            newPackageId = arg;
            break;
          }
        }

        await PackageIdManager.replacePackageId(
          newPackageId: newPackageId,
          interactive: interactive || newPackageId == null,
          createBackup: createBackup,
          dryRun: dryRun,
        );
      } else if (configTarget == 'name') {
        // Parse app name command options
        bool interactive = arguments.contains('--interactive') || arguments.contains('-i');
        bool createBackup = arguments.contains('--backup') || arguments.contains('-b');
        bool dryRun = arguments.contains('--dry-run') || arguments.contains('--preview');

        // Get app name from arguments (skip flags)
        // App name might have spaces, so we need to handle quoted strings
        String? newAppName;
        for (int i = 2; i < arguments.length; i++) {
          final arg = arguments[i];
          if (!arg.startsWith('--') && arg != '-i' && arg != '-b') {
            // If it starts with a quote, collect until we find the closing quote
            if (arg.startsWith('"') || arg.startsWith("'")) {
              final quote = arg[0];
              String collected = arg.substring(1); // Remove opening quote

              // If it ends with the same quote, we're done
              if (collected.endsWith(quote)) {
                newAppName = collected.substring(0, collected.length - 1);
                break;
              }

              // Otherwise, collect more arguments until we find the closing quote
              for (int j = i + 1; j < arguments.length; j++) {
                collected += ' ${arguments[j]}';
                if (arguments[j].endsWith(quote)) {
                  newAppName = collected.substring(0, collected.length - 1);
                  break;
                }
              }
              if (newAppName != null) break;
            } else {
              newAppName = arg;
              break;
            }
          }
        }

        await AppNameManager.replaceAppName(
          newAppName: newAppName,
          interactive: interactive || newAppName == null,
          createBackup: createBackup,
          dryRun: dryRun,
        );
      } else {
        Logger.error('Unknown config target: $configTarget');
        Logger.info('Available options: assets, main, theme, router, storage, package, name');
      }
      return;
    }

    // Handle setup command (alias for config, case-insensitive)
    if (firstArgLower == 'setup') {
      if (arguments.length < 2) {
        Logger.error('Please specify what to setup.');
        Logger.info('Usage: flarch setup assets | flarch setup package [new.package.id]');
        Logger.info('Available options:');
        Logger.info('  assets - Setup assets folder structure');
        Logger.info('  package [id] - Replace application package ID');
        return;
      }
      final setupTarget = arguments[1].toLowerCase();

      if (setupTarget == 'assets') {
        await AssetConfigManager.setupAssets();
      } else if (setupTarget == 'package') {
        // Parse package command options
        bool interactive = arguments.contains('--interactive') || arguments.contains('-i');
        bool createBackup = arguments.contains('--backup') || arguments.contains('-b');
        bool dryRun = arguments.contains('--dry-run') || arguments.contains('--preview');

        // Get package ID from arguments (skip flags)
        String? newPackageId;
        for (int i = 2; i < arguments.length; i++) {
          final arg = arguments[i];
          if (!arg.startsWith('--') && arg != '-i' && arg != '-b') {
            newPackageId = arg;
            break;
          }
        }

        await PackageIdManager.replacePackageId(
          newPackageId: newPackageId,
          interactive: interactive || newPackageId == null,
          createBackup: createBackup,
          dryRun: dryRun,
        );
      } else if (setupTarget == 'name') {
        // Parse app name command options
        bool interactive = arguments.contains('--interactive') || arguments.contains('-i');
        bool createBackup = arguments.contains('--backup') || arguments.contains('-b');
        bool dryRun = arguments.contains('--dry-run') || arguments.contains('--preview');

        // Get app name from arguments (skip flags)
        String? newAppName;
        for (int i = 2; i < arguments.length; i++) {
          final arg = arguments[i];
          if (!arg.startsWith('--') && arg != '-i' && arg != '-b') {
            // Handle quoted strings for app names with spaces
            if (arg.startsWith('"') || arg.startsWith("'")) {
              final quote = arg[0];
              String collected = arg.substring(1);
              if (collected.endsWith(quote)) {
                newAppName = collected.substring(0, collected.length - 1);
                break;
              }
              for (int j = i + 1; j < arguments.length; j++) {
                collected += ' ${arguments[j]}';
                if (arguments[j].endsWith(quote)) {
                  newAppName = collected.substring(0, collected.length - 1);
                  break;
                }
              }
              if (newAppName != null) break;
            } else {
              newAppName = arg;
              break;
            }
          }
        }

        await AppNameManager.replaceAppName(
          newAppName: newAppName,
          interactive: interactive || newAppName == null,
          createBackup: createBackup,
          dryRun: dryRun,
        );
      } else {
        Logger.error('Unknown setup target: $setupTarget');
        Logger.info('Available options: assets, package, name');
      }
      return;
    }

    if (arguments.length > 1) {
      if (arguments.contains('-sm')) {
        await _handleOption(arguments, featureName);
        return;
      }

      if (_featureExists(featureName)) {
        await _handleOption(arguments, featureName);
        return;
      }
    }

    if (_featureExists(featureName) && arguments.length == 1) {
      Logger.error('Feature "$featureName" already exists.');
      return;
    }

    if (arguments.length > 1 && ['-mvc', '-mvvm', '-clean'].contains(arguments[1])) {
      final architecture = arguments[1].substring(1);
      final stateManagement = await _promptForStateManagement();
      final customClassName = stateManagement != null ? _promptForCustomClassName() : null;

      await GetItManager.manageGetIt(featureName, stateManagement, architecture);
      _createFeatureStructure(featureName, stateManagement, customClassName, architecture);
      Logger.success('Feature "$featureName" created successfully with $architecture architecture');
      return;
    }

    await _createFeatureWithPrompt(featureName);
  }

  Future<void> _listFeatures() async {
    final featuresDirectory = Directory('lib/features');
    if (!featuresDirectory.existsSync()) {
      Logger.error('The "lib/features" directory does not exist.');
      return;
    }

    final features = featuresDirectory.listSync().whereType<Directory>();
    if (features.isEmpty) {
      Logger.info('No features found.');
      return;
    }

    print('${skyBlue}Available features:$reset');
    for (var feature in features) {
      print('$successGreen${feature.path.split('/').last}$reset');
    }
  }

  Future<void> _createFeatureWithPrompt(String featureName) async {
    final architecture = await _promptForArchitecture() ?? 'clean';
    final stateManagement = await _promptForStateManagement();
    final customClassName = stateManagement != null ? _promptForCustomClassName() : null;

    await GetItManager.manageGetIt(featureName, stateManagement, architecture);
    _createFeatureStructure(featureName, stateManagement, customClassName, architecture);
    Logger.success('Feature "$featureName" created successfully');
  }

  Future<void> _handleOption(List<String> arguments, String featureName) async {
    final architecture = await _getCurrentArchitecture(featureName);
    final architectureHandler = ArchitectureFactory().getArchitectureHandler(architecture);

    if (architectureHandler != null) {
      await architectureHandler.handleOption(arguments, featureName);
    } else {
      Logger.warning('  Unknown architecture. Using Clean Architecture as default.');
      await CleanArchitecture().handleOption(arguments, featureName);
    }
  }

  Future<String> _getCurrentArchitecture(String featureName) async {
    final paths = {'mvc': 'controllers', 'mvvm': 'viewmodels', 'clean': ''};

    for (var entry in paths.entries) {
      if (Directory('lib/features/$featureName/${entry.value}').existsSync()) {
        return entry.key;
      }
    }
    return 'clean';
  }

  Future<String?> _promptForArchitecture() async {
    final options = ['Clean Architecture', 'MVVM', 'MVC'];
    final choice = Prompter.select<String>(
      message: skyBlue + '⚡ Choose an architecture' + reset,
      options: options,
      displayText: (option) => option,
      defaultValue: options[0],
      compact: true, // Minimal spacing
    );

    if (choice == null) return 'clean';

    switch (choice.toLowerCase()) {
      case 'mvc':
        return 'mvc';
      case 'mvvm':
        return 'mvvm';
      case 'clean architecture':
        return 'clean';
      default:
        return 'clean';
    }
  }

  Future<String?> _promptForStateManagement() async {
    final options = ['Bloc', 'GetX', 'Provider', 'Skip'];
    final choice = Prompter.select<String>(
      message: skyBlue + '⚡ Choose a state management' + reset,
      options: options,
      displayText: (option) => option,
      defaultValue: options[3], // Skip by default
      compact: true, // Minimal spacing
    );

    if (choice == null) return null;

    switch (choice.toLowerCase()) {
      case 'bloc':
        return 'bloc';
      case 'getx':
        return 'getx';
      case 'provider':
        return 'provider';
      case 'skip':
      default:
        return null;
    }
  }

  String? _promptForCustomClassName() {
    final input = Prompter.text(
      message: skyBlue + '⚡ Custom class name for state management (optional)' + reset,
      defaultValue: '',
      validate: (s) => true, // Allow empty for optional field
      compact: true, // Minimal spacing
    );
    return input?.trim().isEmpty ?? true ? null : input!.trim();
  }

  void _createFeatureStructure(String featureName, String? stateManagement, String? customClassName, String architecture) {
    final architectureHandler = ArchitectureFactory().getArchitectureHandler(architecture);
    if (architectureHandler != null) {
      architectureHandler.createStructure(featureName, stateManagement, customClassName);
    } else {
      Logger.error('Failed to find architecture handler.');
    }
  }

  bool _featureExists(String featureName) => Directory('lib/features/$featureName').existsSync();

  Future<void> _removeFeature(String featureName) async {
    await FeatureRemover.removeFeature(featureName);
  }
}
