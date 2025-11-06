import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../../core/utils/utility.dart';
import '../../core/utils/prompter.dart';

/// Manages local storage configuration for Flutter projects
class StorageConfigManager {
  /// Configure local storage for the Flutter project
  static Future<bool> configureStorage() async {
    try {
      Logger.header('💾 Local Storage Configuration Setup');

      // Check if we're in a Flutter project
      if (!_isFlutterProject()) {
        Logger.error(
            'Not a Flutter project. Please run this command from your Flutter project root.');
        return false;
      }

      // Step 1: Let user choose storage option
      Logger.step(1, 5, 'Selecting storage solution');
      final storageOption = await _selectStorageOption();
      if (storageOption == null) {
        Logger.warning('Storage configuration cancelled.');
        return false;
      }

      Logger.success('   Selected: $storageOption');

      // Step 2: Add dependencies
      Logger.step(2, 5, 'Adding dependencies');
      final dependenciesAdded = await _addDependencies(storageOption);
      if (!dependenciesAdded) {
        Logger.error('Failed to add dependencies. Please add them manually.');
        return false;
      }

      // Step 3: Create storage service file
      Logger.step(3, 5, 'Creating storage service');
      await _createStorageService(storageOption);
      Logger.success('   Storage service created');

      // Step 4: Create initialization file
      Logger.step(4, 5, 'Setting up initialization');
      await _setupInitialization(storageOption);
      Logger.success('   Initialization configured');

      // Step 5: Update main.dart or injection.dart
      Logger.step(5, 5, 'Updating project files');
      await _updateProjectFiles(storageOption);
      Logger.success('   Project files updated');

      // Summary
      Logger.summary('Storage Configuration Complete', [
        '${storageOption} dependencies added',
        'Storage service created',
        'Initialization code configured',
        'Project files updated',
      ]);

      return true;
    } catch (e) {
      Logger.error('Failed to configure storage: $e');
      return false;
    }
  }

  /// Check if we're in a Flutter project
  static bool _isFlutterProject() {
    final pubspecFile = File('pubspec.yaml');
    final libDir = Directory('lib');
    return pubspecFile.existsSync() && libDir.existsSync();
  }

  /// Let user select storage option
  static Future<String?> _selectStorageOption() async {
    final options = [
      'Hive',
      'SharedPreferences',
      'ObjectBox',
      'Isar',
      'Drift',
    ];

    final choice = Prompter.select<String>(
      message: '⚡ Choose a local storage solution',
      options: options,
      displayText: (option) => option,
      defaultValue: options[0],
      compact: true,
    );

    return choice;
  }

  /// Add dependencies based on storage option
  static Future<bool> _addDependencies(String storageOption) async {
    switch (storageOption.toLowerCase()) {
      case 'hive':
        final added = await Utility.addDependency('hive');
        if (added) {
          await Utility.addDependency('hive_flutter');
        }
        return added;

      case 'sharedpreferences':
        return await Utility.addDependency('shared_preferences');

      case 'objectbox':
        // Note: ObjectBox requires additional setup (code generation)
        final added = await Utility.addDependency('objectbox');
        if (added) {
          await Utility.addDependency('objectbox_flutter_libs');
        }
        return added;

      case 'isar':
        final added = await Utility.addDependency('isar');
        if (added) {
          await Utility.addDependency('isar_flutter_libs');
        }
        return added;

      case 'drift':
        final added = await Utility.addDependency('drift');
        if (added) {
          await Utility.addDependency('drift_native');
          await Utility.addDependency('sqlite3_flutter_libs');
          await Utility.addDependency('path_provider');
          await Utility.addDependency('path');
        }
        return added;

      default:
        return false;
    }
  }

  /// Create storage service file
  static Future<void> _createStorageService(String storageOption) async {
    final coreDir = Directory('lib/core');
    if (!coreDir.existsSync()) {
      await coreDir.create(recursive: true);
    }

    final storageDir = Directory('lib/core/storage');
    if (!storageDir.existsSync()) {
      await storageDir.create(recursive: true);
    }

    final serviceFilePath =
        path.join('lib', 'core', 'storage', 'storage_service.dart');
    final serviceFile = File(serviceFilePath);

    if (serviceFile.existsSync()) {
      Logger.warning('   Storage service already exists. Skipping creation.');
      return;
    }

    String serviceContent = '';
    switch (storageOption.toLowerCase()) {
      case 'hive':
        serviceContent = _createHiveService();
        break;
      case 'sharedpreferences':
        serviceContent = _createSharedPreferencesService();
        break;
      case 'objectbox':
        serviceContent = _createObjectBoxService();
        break;
      case 'isar':
        serviceContent = _createIsarService();
        break;
      case 'drift':
        serviceContent = _createDriftService();
        break;
    }

    await serviceFile.writeAsString(serviceContent);
  }

  /// Setup initialization code
  static Future<void> _setupInitialization(String storageOption) async {
    final initDir = Directory('lib/core/storage');
    if (!initDir.existsSync()) {
      await initDir.create(recursive: true);
    }

    final initFilePath =
        path.join('lib', 'core', 'storage', 'storage_init.dart');
    final initFile = File(initFilePath);

    if (initFile.existsSync()) {
      Logger.warning(
          '   Storage initialization already exists. Skipping creation.');
      return;
    }

    String initContent = '';
    switch (storageOption.toLowerCase()) {
      case 'hive':
        initContent = _createHiveInit();
        break;
      case 'sharedpreferences':
        initContent = _createSharedPreferencesInit();
        break;
      case 'objectbox':
        initContent = _createObjectBoxInit();
        break;
      case 'isar':
        initContent = _createIsarInit();
        break;
      case 'drift':
        initContent = _createDriftInit();
        break;
    }

    await initFile.writeAsString(initContent);
  }

  /// Update project files (main.dart or injection.dart)
  static Future<void> _updateProjectFiles(String storageOption) async {
    // Check if injection.dart exists
    final injectionFile = File('lib/injection.dart');
    if (injectionFile.existsSync()) {
      await _updateInjectionFile(injectionFile, storageOption);
    } else {
      // Update main.dart
      await _updateMainFile(storageOption);
    }
  }

  /// Update injection.dart file
  static Future<void> _updateInjectionFile(
      File injectionFile, String storageOption) async {
    String content = await injectionFile.readAsString();

    // Add import if not present
    final importLine = "import 'core/storage/storage_init.dart';";
    if (!content.contains(importLine)) {
      // Find the last import statement
      final importPattern = RegExp(r'^import\s+.*?;', multiLine: true);
      final matches = importPattern.allMatches(content);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        final insertIndex = lastMatch.end;
        content = content.substring(0, insertIndex) +
            '\n$importLine' +
            content.substring(insertIndex);
      } else {
        content = '$importLine\n$content';
      }
    }

    // Add initialization call in init() function
    final initCall = '  await initializeStorage();';
    if (!content.contains(initCall)) {
      // Find the init() function
      final initPattern = RegExp(r'Future<void>\s+init\(\)\s*async\s*\{');
      if (initPattern.hasMatch(content)) {
        content = content.replaceFirst(
          initPattern,
          'Future<void> init() async {\n$initCall',
        );
      } else {
        // If no init() function, add it
        if (content.contains('final sl = GetIt.instance;')) {
          content = content.replaceFirst(
            'final sl = GetIt.instance;',
            'final sl = GetIt.instance;\n\nFuture<void> init() async {\n$initCall\n}',
          );
        }
      }
    }

    await injectionFile.writeAsString(content);
  }

  /// Update main.dart file
  static Future<void> _updateMainFile(String storageOption) async {
    final mainFile = File('lib/main.dart');
    if (!mainFile.existsSync()) {
      Logger.warning(
          '   main.dart not found. Please initialize storage manually.');
      return;
    }

    String content = await mainFile.readAsString();

    // Add import if not present
    final importLine = "import 'core/storage/storage_init.dart';";
    if (!content.contains(importLine)) {
      // Find the last import statement
      final importPattern = RegExp(r'^import\s+.*?;', multiLine: true);
      final matches = importPattern.allMatches(content);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        final insertIndex = lastMatch.end;
        content = content.substring(0, insertIndex) +
            '\n$importLine' +
            content.substring(insertIndex);
      } else {
        content = '$importLine\n$content';
      }
    }

    // Add initialization call in main() function
    final initCall = '  await initializeStorage();';
    final initCallPattern = RegExp(r'await\s+initializeStorage\(\)\s*;');

    if (!initCallPattern.hasMatch(content)) {
      // Find main() function
      final mainPattern = RegExp(r'(Future<void>\s+)?main\(\)\s*(async\s*)?\{');
      if (mainPattern.hasMatch(content)) {
        // Check if main is async
        final match = mainPattern.firstMatch(content);
        if (match != null && match.group(1) == null) {
          // Make main async if it's not
          content = content.replaceFirst(
            RegExp(r'void\s+main\(\)'),
            'Future<void> main() async',
          );
        }

        // Ensure WidgetsFlutterBinding.ensureInitialized() is present
        final bindingCall = '  WidgetsFlutterBinding.ensureInitialized();';
        final bindingPattern =
            RegExp(r'WidgetsFlutterBinding\.ensureInitialized\(\)\s*;');

        if (!bindingPattern.hasMatch(content)) {
          // WidgetsFlutterBinding not found, add it before initializeStorage
          // Find where to insert it (before runApp or at start of main)
          if (content.contains('runApp(')) {
            // Insert before runApp
            final runAppIndex = content.indexOf('runApp(');
            // Find the start of the line before runApp
            int lineStart = runAppIndex;
            while (lineStart > 0 && content[lineStart - 1] != '\n') {
              lineStart--;
            }
            // Insert before the line containing runApp
            content = content.substring(0, lineStart) +
                '$bindingCall\n$initCall\n' +
                content.substring(lineStart);
          } else {
            // Insert at start of main function
            content = content.replaceFirst(
              RegExp(r'(Future<void>\s+)?main\(\)\s*async\s*\{'),
              'Future<void> main() async {\n$bindingCall\n$initCall',
            );
          }
        } else {
          // WidgetsFlutterBinding exists, add initializeStorage after it
          final bindingMatch = bindingPattern.firstMatch(content);
          if (bindingMatch != null) {
            final insertIndex = bindingMatch.end;
            // Check if there's already a newline after the binding call
            int afterIndex = insertIndex;
            while (afterIndex < content.length &&
                (content[afterIndex] == ' ' || content[afterIndex] == '\t')) {
              afterIndex++;
            }
            if (afterIndex < content.length && content[afterIndex] == '\n') {
              // Newline exists, insert after it
              afterIndex++;
              content = content.substring(0, afterIndex) +
                  '$initCall\n' +
                  content.substring(afterIndex);
            } else {
              // No newline, insert after the binding call
              content = content.substring(0, insertIndex) +
                  '\n$initCall' +
                  content.substring(insertIndex);
            }
          }
        }
      } else {
        // No main() function found, add it
        Logger.warning(
            '   main() function not found in main.dart. Please add initialization manually.');
      }
    }

    await mainFile.writeAsString(content);
  }

  // ==================== Service Content Generators ====================

  static String _createHiveService() {
    return '''import 'package:hive_flutter/hive_flutter.dart';

/// Hive storage service
/// Provides key-value storage functionality
class StorageService {
  static Box? _box;

  /// Initialize storage
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('app_storage');
  }

  /// Get value by key
  static T? get<T>(String key) {
    return _box?.get(key) as T?;
  }

  /// Set value by key
  static Future<void> set(String key, dynamic value) async {
    await _box?.put(key, value);
  }

  /// Delete value by key
  static Future<void> delete(String key) async {
    await _box?.delete(key);
  }

  /// Clear all data
  static Future<void> clear() async {
    await _box?.clear();
  }

  /// Check if key exists
  static bool containsKey(String key) {
    return _box?.containsKey(key) ?? false;
  }

  /// Get all keys
  static List<String> getAllKeys() {
    return _box?.keys.cast<String>().toList() ?? [];
  }

  /// Close storage
  static Future<void> close() async {
    await _box?.close();
  }
}
''';
  }

  static String _createSharedPreferencesService() {
    return '''import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences storage service
/// Provides key-value storage functionality using device preferences
class StorageService {
  static SharedPreferences? _prefs;

  /// Initialize storage
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get value by key
  static T? get<T>(String key) {
    if (_prefs == null) return null;

    switch (T) {
      case String:
        return _prefs!.getString(key) as T?;
      case int:
        return _prefs!.getInt(key) as T?;
      case double:
        return _prefs!.getDouble(key) as T?;
      case bool:
        return _prefs!.getBool(key) as T?;
      default:
        return null;
    }
  }

  /// Set string value
  static Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  /// Set int value
  static Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  /// Set double value
  static Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  /// Set bool value
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  /// Delete value by key
  static Future<bool> delete(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  /// Clear all data
  static Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  /// Check if key exists
  static bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  /// Get all keys
  static Set<String> getAllKeys() {
    return _prefs?.getKeys() ?? {};
  }
}
''';
  }

  static String _createObjectBoxService() {
    return '''import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

/// ObjectBox storage service
/// Provides object database functionality
/// 
/// Note: You need to:
/// 1. Add build_runner and objectbox_generator to dev_dependencies
/// 2. Run: flutter pub run build_runner build
/// 3. Create your entity classes with @Entity() annotation
class StorageService {
  static Store? _store;

  /// Initialize storage
  static Future<void> init() async {
    // Get application documents directory
    final directory = await getApplicationDocumentsDirectory();
    final objectboxDir = Directory(path.join(directory.path, 'objectbox'));
    if (!objectboxDir.existsSync()) {
      await objectboxDir.create(recursive: true);
    }
    
    // Note: Replace getObjectBoxModel() with your generated model
    // After running: flutter pub run build_runner build
    _store = Store(getObjectBoxModel(), directory: objectboxDir.path);
  }

  /// Get store instance
  static Store? get store {
    if (_store == null) {
      throw Exception('Storage not initialized. Call init() first.');
    }
    return _store!;
  }

  /// Close storage
  static Future<void> close() async {
    await _store?.close();
    _store = null;
  }

  /// Get a box for a specific entity type
  static Box<T> box<T>() {
    if (_store == null) {
      throw Exception('Storage not initialized. Call init() first.');
    }
    return _store!.box<T>();
  }
}

/// Placeholder for ObjectBox model
/// Replace this with your generated model after running build_runner
/// Example:
/// ```dart
/// import 'package:objectbox/objectbox.dart';
/// 
/// @Entity()
/// class User {
///   @Id()
///   int id = 0;
///   String name;
///   User({required this.name});
/// }
/// 
/// Store getObjectBoxModel() {
///   return openStore();
/// }
/// ```
Store getObjectBoxModel() {
  // This will be replaced with your generated model after running:
  // flutter pub run build_runner build
  throw UnimplementedError('Please run: flutter pub run build_runner build');
}
''';
  }

  static String _createIsarService() {
    return '''import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

/// Isar storage service
/// Provides NoSQL database functionality
/// 
/// Note: You need to:
/// 1. Add build_runner and isar_generator to dev_dependencies
/// 2. Run: flutter pub run build_runner build
/// 3. Create your collection classes with @collection annotation
class StorageService {
  static Isar? _isar;

  /// Initialize storage
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      schemas: [], // Add your collection schemas here after generation
      directory: dir.path,
    );
  }

  /// Get Isar instance
  static Isar get instance {
    if (_isar == null) {
      throw Exception('Storage not initialized. Call init() first.');
    }
    return _isar!;
  }

  /// Close storage
  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  /// Write transaction
  static Future<T> writeTxn<T>(Future<T> Function(Isar) callback) async {
    if (_isar == null) {
      throw Exception('Storage not initialized. Call init() first.');
    }
    return await _isar!.writeTxn(() => callback(_isar!));
  }

  /// Read transaction
  static Future<T> readTxn<T>(Future<T> Function(Isar) callback) async {
    if (_isar == null) {
      throw Exception('Storage not initialized. Call init() first.');
    }
    return await _isar!.readTxn(() => callback(_isar!));
  }
}
''';
  }

  static String _createDriftService() {
    return '''import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

/// Drift storage service
/// Provides SQL database functionality
/// 
/// Note: You need to:
/// 1. Add build_runner and drift_dev to dev_dependencies
/// 2. Create your database class extending GeneratedDatabase
/// 3. Run: flutter pub run build_runner build
class StorageService {
  static AppDatabase? _database;

  /// Initialize storage
  static Future<void> init() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, 'app.db'));
    _database = AppDatabase(NativeDatabase(file));
  }

  /// Get database instance
  static AppDatabase get database {
    if (_database == null) {
      throw Exception('Storage not initialized. Call init() first.');
    }
    return _database!;
  }

  /// Close storage
  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

/// Placeholder database class
/// Replace this with your generated database class after running build_runner
/// 
/// Example: Create a Users table class, then use @DriftDatabase annotation
/// on a class extending the generated database class
class AppDatabase extends GeneratedDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object>> get allTables => [];
  
  // TODO: Add your table definitions here
  // Example:
  // @override
  // List<TableInfo<Table, DataClass>> get allTables => [users];
}
''';
  }

  // ==================== Init Content Generators ====================

  static String _createHiveInit() {
    return '''import 'storage_service.dart';

/// Initialize Hive storage
Future<void> initializeStorage() async {
  await StorageService.init();
}
''';
  }

  static String _createSharedPreferencesInit() {
    return '''import 'storage_service.dart';

/// Initialize SharedPreferences storage
Future<void> initializeStorage() async {
  await StorageService.init();
}
''';
  }

  static String _createObjectBoxInit() {
    return '''import 'storage_service.dart';

/// Initialize ObjectBox storage
/// 
/// Important: Before using ObjectBox, you need to:
/// 1. Add to pubspec.yaml dev_dependencies:
///    - build_runner: ^2.4.0
///    - objectbox_generator: ^2.0.0
/// 2. Run: flutter pub get
/// 3. Create your entity classes with @Entity() annotation
/// 4. Run: flutter pub run build_runner build
Future<void> initializeStorage() async {
  await StorageService.init();
}
''';
  }

  static String _createIsarInit() {
    return '''import 'storage_service.dart';

/// Initialize Isar storage
/// 
/// Important: Before using Isar, you need to:
/// 1. Add to pubspec.yaml dev_dependencies:
///    - build_runner: ^2.4.0
///    - isar_generator: ^3.1.0
/// 2. Run: flutter pub get
/// 3. Create your collection classes with @collection annotation
/// 4. Run: flutter pub run build_runner build
Future<void> initializeStorage() async {
  await StorageService.init();
}
''';
  }

  static String _createDriftInit() {
    return '''import 'storage_service.dart';

/// Initialize Drift storage
/// 
/// Important: Before using Drift, you need to:
/// 1. Add to pubspec.yaml dev_dependencies:
///    - build_runner: ^2.4.0
///    - drift_dev: ^2.14.0
/// 2. Run: flutter pub get
/// 3. Create your database class extending GeneratedDatabase
/// 4. Run: flutter pub run build_runner build
Future<void> initializeStorage() async {
  await StorageService.init();
}
''';
  }
}
