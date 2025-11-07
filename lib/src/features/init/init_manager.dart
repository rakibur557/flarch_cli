import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/utils/logger.dart';
import '../../core/utils/prompter.dart';
import '../../core/utils/utility.dart';
import '../asset_config/asset_config_manager.dart';
import '../theme_config/theme_config_manager.dart';
import '../router_config/router_config_manager.dart';
import '../main_config/main_config_manager.dart';
import '../clean_pub_comment/pubspec_cleaner.dart';

/// Configuration options for init command
class InitConfig {
  final String appName;
  final bool setupAssets;
  final bool setupTheme;
  final bool setupRouter;
  final bool setupNetwork;
  final bool setupStorage;
  final bool cleanPubspec;
  final bool setupUtils;

  InitConfig({
    required this.appName,
    this.setupAssets = false,
    this.setupTheme = false,
    this.setupRouter = false,
    this.setupNetwork = false,
    this.setupStorage = false,
    this.cleanPubspec = false,
    this.setupUtils = false,
  });
}

/// Manages project initialization
class InitManager {
  /// Initialize Flutter project with comprehensive setup
  /// If appName is provided, runs in non-interactive mode with all options enabled
  static Future<void> initialize({String? appName}) async {
    try {
      Logger.header('🚀 Flutter Project Initialization');

      // Check if we're in a Flutter project
      final pubspecFile = File('pubspec.yaml');
      bool isNewProject = !pubspecFile.existsSync();

      // Check if running in non-interactive mode (appName provided)
      final isNonInteractive = appName != null && appName.isNotEmpty;
      String finalAppName;
      String? projectPath;

      // If not in a Flutter project, create one first
      if (isNewProject) {
        if (isNonInteractive) {
          // appName is guaranteed to be non-null when isNonInteractive is true
          finalAppName = appName!; // ignore: unnecessary_non_null_assertion
          Logger.info('📋 Creating Flutter project: $finalAppName (non-interactive mode)');
        } else {
          Logger.info('📋 No Flutter project found. Let\'s create one first...');
          print('');

          // Step 1: Get app name first
          finalAppName = await _getAppName();
        }

        // Step 2: Create Flutter project
        Logger.info('Creating Flutter project: $finalAppName');
        final createSuccess = await _createFlutterProject(finalAppName);
        if (!createSuccess) {
          Logger.error('Failed to create Flutter project.');
          return;
        }

        // Change to project directory
        projectPath = finalAppName;
        final currentDir = Directory.current;
        final projectDir = Directory(path.join(currentDir.path, projectPath));
        if (projectDir.existsSync()) {
          // Change working directory to the new project
          Directory.current = projectDir;
          Logger.success('Created Flutter project and changed to project directory');
        } else {
          Logger.error('Project directory not found after creation: $projectPath');
          return;
        }
        print('');
      } else {
        // We're in an existing project
        if (isNonInteractive) {
          // appName is guaranteed to be non-null when isNonInteractive is true
          finalAppName = appName!; // ignore: unnecessary_non_null_assertion
          Logger.info('📋 Existing Flutter project detected. Configuring in non-interactive mode...');
        } else {
          Logger.info('📋 Existing Flutter project detected. Let\'s configure it...');
          print('');
          finalAppName = await _getAppNameFromPubspec() ?? await _getAppName();
        }
      }

      // Step 3: Collect preferences (or use defaults in non-interactive mode)
      final InitConfig config;
      if (isNonInteractive) {
        Logger.info('📋 Using default configuration (all options enabled)...');
        print('');
        config = InitConfig(
          appName: finalAppName,
          setupAssets: true,
          setupTheme: true,
          setupRouter: true,
          setupNetwork: true,
          setupStorage: true,
          cleanPubspec: true,
          setupUtils: true,
        );
        _displaySummary(config);
        print('');
        Logger.header('⚙️  Executing Configuration');
        await _executeConfigurations(config);
      } else {
        Logger.info('📋 Let\'s collect your preferences...');
        print('');

        config = await _collectUserPreferences(finalAppName);

        // Step 2: Display summary
        _displaySummary(config);

        // Step 3: Confirm before proceeding
        final proceed = Prompter.confirm(
          message: 'Proceed with initialization?',
          defaultValue: true,
        );

        if (!proceed) {
          Logger.info('Initialization cancelled.');
          return;
        }

        print('');
        Logger.header('⚙️  Executing Configuration');

        // Step 4: Execute configurations one by one
        await _executeConfigurations(config);
      }

      // Final summary
      print('');
      Logger.header('✅ Initialization Complete');
      Logger.success('Your Flutter project has been initialized successfully!');
      Logger.info('Next steps:');
      Logger.info('  1. Run: flutter pub get');
      if (config.setupNetwork) {
        Logger.info('  2. If using injectable, run: flutter pub run build_runner build');
      }
      Logger.info('  3. Start building your features with: flarch "FeatureName"');
      print('');
    } catch (e) {
      Logger.error('Initialization failed: $e');
    }
  }

  /// Get app name from user
  static Future<String> _getAppName() async {
    String? appName;
    while (appName == null || !_isValidAppName(appName)) {
      appName = Prompter.text(
        message: 'App name (lowercase, underscores only, no spaces or special characters)',
        validate: (value) => _isValidAppName(value),
      );

      if (appName == null || appName.isEmpty) {
        Logger.error('App name is required. Please enter a valid name.');
        continue;
      }

      if (!_isValidAppName(appName)) {
        Logger.error('Invalid app name. Use only lowercase letters and underscores.');
        appName = null;
      }
    }
    return appName;
  }

  /// Get app name from pubspec.yaml
  static Future<String?> _getAppNameFromPubspec() async {
    try {
      final pubspecFile = File('pubspec.yaml');
      if (!pubspecFile.existsSync()) {
        return null;
      }

      final content = await pubspecFile.readAsString();
      final match = RegExp(r'^name:\s*([a-z0-9_]+)', multiLine: true).firstMatch(content);
      if (match != null) {
        return match.group(1);
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  /// Create Flutter project
  static Future<bool> _createFlutterProject(String appName) async {
    try {
      Logger.step(1, 2, 'Creating Flutter project: $appName');

      // Use cmd /c on Windows, direct flutter command on other platforms
      final isWindows = Platform.isWindows;
      final process = await Process.run(
        isWindows ? 'cmd' : 'flutter',
        isWindows ? ['/c', 'flutter', 'create', appName] : ['create', appName],
        workingDirectory: Directory.current.path,
      );

      if (process.exitCode == 0) {
        Logger.success('   Flutter project created successfully');
        return true;
      } else {
        Logger.error('   Failed to create Flutter project: ${process.stderr}');
        if (process.stdout.toString().isNotEmpty) {
          Logger.info('   Output: ${process.stdout}');
        }
        return false;
      }
    } catch (e) {
      Logger.error('   Error creating Flutter project: $e');
      Logger.info('   Make sure Flutter is installed and in your PATH');
      return false;
    }
  }

  /// Collect user preferences
  static Future<InitConfig> _collectUserPreferences(String appName) async {
    print('');

    // Asset configurations
    final setupAssets = Prompter.confirm(
      message: 'Do you need asset configurations?',
      defaultValue: false,
    );

    // Theme configurations
    final setupTheme = Prompter.confirm(
      message: 'Do you need theme configurations?',
      defaultValue: false,
    );

    // Router configurations
    final setupRouter = Prompter.confirm(
      message: 'Do you need router configurations?',
      defaultValue: false,
    );

    // Network caller
    final setupNetwork = Prompter.confirm(
      message: 'Do you need network caller (Dio) setup?',
      defaultValue: false,
    );

    // Local storage configurations
    final setupStorage = Prompter.confirm(
      message: 'Do you need local storage configurations?',
      defaultValue: false,
    );

    // Clean pubspec
    final cleanPubspec = Prompter.confirm(
      message: 'Do you want to clean pubspec.yaml?',
      defaultValue: false,
    );

    // Utils configurations
    final setupUtils = Prompter.confirm(
      message: 'Do you need utils configurations?',
      defaultValue: false,
    );

    return InitConfig(
      appName: appName,
      setupAssets: setupAssets,
      setupTheme: setupTheme,
      setupRouter: setupRouter,
      setupNetwork: setupNetwork,
      setupStorage: setupStorage,
      cleanPubspec: cleanPubspec,
      setupUtils: setupUtils,
    );
  }

  /// Validate app name
  static bool _isValidAppName(String name) {
    // Only lowercase letters and underscores, must start with letter
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);
  }

  /// Display summary of configurations
  static void _displaySummary(InitConfig config) {
    print('');
    Logger.header('📊 Configuration Summary');
    print('');

    final summaryColor = Logger.rgb(135, 206, 250);
    final checkColor = Logger.successColor;
    final crossColor = Logger.rgb(200, 200, 200);

    print('  ${summaryColor}App Name:${Logger.reset} ${config.appName}');
    print('  ${config.setupAssets ? checkColor : crossColor}${config.setupAssets ? '✓' : '✗'}${Logger.reset} Asset configurations');
    print('  ${config.setupTheme ? checkColor : crossColor}${config.setupTheme ? '✓' : '✗'}${Logger.reset} Theme configurations');
    print('  ${config.setupRouter ? checkColor : crossColor}${config.setupRouter ? '✓' : '✗'}${Logger.reset} Router configurations');
    print('  ${config.setupNetwork ? checkColor : crossColor}${config.setupNetwork ? '✓' : '✗'}${Logger.reset} Network caller (Dio)');
    print('  ${config.setupStorage ? checkColor : crossColor}${config.setupStorage ? '✓' : '✗'}${Logger.reset} Local storage (Hive)');
    print('  ${config.cleanPubspec ? checkColor : crossColor}${config.cleanPubspec ? '✓' : '✗'}${Logger.reset} Clean pubspec.yaml');
    print('  ${config.setupUtils ? checkColor : crossColor}${config.setupUtils ? '✓' : '✗'}${Logger.reset} Utils configurations');
    print('');
  }

  /// Execute all configurations
  static Future<void> _executeConfigurations(InitConfig config) async {
    int step = 1;
    int totalSteps = _countSteps(config);

    // Ensure main.dart and app.dart exist
    await _ensureMainAndApp(step++, totalSteps);

    // Setup assets
    if (config.setupAssets) {
      await _setupAssets(step++, totalSteps);
    }

    // Setup theme
    if (config.setupTheme) {
      await _setupTheme(step++, totalSteps);
    }

    // Setup router
    if (config.setupRouter) {
      await _setupRouter(step++, totalSteps);
    }

    // Setup network
    if (config.setupNetwork) {
      await _setupNetwork(step++, totalSteps);
    }

    // Setup storage
    if (config.setupStorage) {
      await _setupStorage(step++, totalSteps);
    }

    // Clean pubspec
    if (config.cleanPubspec) {
      await _cleanPubspec(step++, totalSteps);
    }

    // Setup utils
    if (config.setupUtils) {
      await _setupUtils(step++, totalSteps);
    }
  }

  /// Count total steps
  static int _countSteps(InitConfig config) {
    int count = 1; // main.dart and app.dart
    if (config.setupAssets) count++;
    if (config.setupTheme) count++;
    if (config.setupRouter) count++;
    if (config.setupNetwork) count++;
    if (config.setupStorage) count++;
    if (config.cleanPubspec) count++;
    if (config.setupUtils) count++;
    return count;
  }

  /// Ensure main.dart and app.dart exist
  static Future<void> _ensureMainAndApp(int step, int totalSteps) async {
    Logger.step(step, totalSteps, 'Ensuring main.dart and app.dart exist');

    final mainFile = File('lib/main.dart');
    if (!mainFile.existsSync()) {
      Logger.error('main.dart not found. Please create it first.');
      return;
    }

    final appFile = File('lib/app.dart');
    if (!appFile.existsSync()) {
      Logger.info('   app.dart not found, creating it...');
      final success = await MainConfigManager.configureMain();
      if (success) {
        Logger.success('   main.dart and app.dart configured');
      } else {
        Logger.warning('   Failed to configure main.dart and app.dart');
      }
    } else {
      Logger.success('   main.dart and app.dart already exist');
    }
  }

  /// Setup assets
  static Future<void> _setupAssets(int step, int totalSteps) async {
    Logger.step(step, totalSteps, 'Setting up asset configurations');
    final success = await AssetConfigManager.setupAssets();
    if (success) {
      Logger.success('   Assets configured successfully');
    } else {
      Logger.warning('   Asset configuration failed');
    }
  }

  /// Setup theme
  static Future<void> _setupTheme(int step, int totalSteps) async {
    Logger.step(step, totalSteps, 'Setting up theme configurations');
    final success = await ThemeConfigManager.configureTheme();
    if (success) {
      Logger.success('   Theme configured successfully');
    } else {
      Logger.warning('   Theme configuration failed');
    }
  }

  /// Setup router
  static Future<void> _setupRouter(int step, int totalSteps) async {
    Logger.step(step, totalSteps, 'Setting up router configurations');
    final success = await RouterConfigManager.configureRouter();
    if (success) {
      Logger.success('   Router configured successfully');
    } else {
      Logger.warning('   Router configuration failed');
    }
  }

  /// Setup network (Dio, connectivity_plus, injectable)
  static Future<void> _setupNetwork(int step, int totalSteps) async {
    Logger.step(step, totalSteps, 'Setting up network caller (Dio)');

    try {
      // Add dependencies
      Logger.info('   Adding dependencies...');
      await Utility.addDependency('dio');
      await Utility.addDependency('connectivity_plus');
      await Utility.addDependency('injectable');
      await Utility.addDependency('pretty_dio_logger');

      // Create core/network directory
      await Utility.ensureDirectoryExists('lib/core/network');
      await Utility.ensureDirectoryExists('lib/core/error');

      // Create dio_client.dart
      await _createDioClient();

      // Create network_info.dart
      await _createNetworkInfo();

      // Create failures.dart
      await _createFailures();

      // Create exceptions.dart
      await _createExceptions();

      Logger.success('   Network setup completed');
    } catch (e) {
      Logger.error('   Network setup failed: $e');
    }
  }

  /// Create Dio client
  static Future<void> _createDioClient() async {
    final content = '''import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:injectable/injectable.dart';

/// Professional Dio client setup
/// Configured with interceptors, timeouts, and error handling
@lazySingleton
class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor (only in debug mode)
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    // Add error interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // Handle errors here
          return handler.next(error);
        },
      ),
    );
  }

  /// Get Dio instance
  Dio get dio => _dio;

  /// Set base URL
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer \$token';
  }

  /// Clear authentication token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }
}
''';

    Utility.writeFile('lib/core/network/dio_client.dart', content);
    Logger.success('   Created lib/core/network/dio_client.dart');
  }

  /// Create network info
  static Future<void> _createNetworkInfo() async {
    final content = '''import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfo(this._connectivity);

  /// Check if device is connected to internet
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }
}
''';

    Utility.writeFile('lib/core/network/network_info.dart', content);
    Logger.success('   Created lib/core/network/network_info.dart');
  }

  /// Create failures
  static Future<void> _createFailures() async {
    final content = '''/// Base class for all failures
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection']) : super(message);
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) : super(message);
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation error']) : super(message);
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed']) : super(message);
}

/// Permission failure
class PermissionFailure extends Failure {
  const PermissionFailure([String message = 'Permission denied']) : super(message);
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Unknown error occurred']) : super(message);
}
''';

    Utility.writeFile('lib/core/error/failures.dart', content);
    Logger.success('   Created lib/core/error/failures.dart');
  }

  /// Create exceptions
  static Future<void> _createExceptions() async {
    final content = '''import 'package:dio/dio.dart';

/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final dynamic originalError;

  const AppException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Server exception
class ServerException extends AppException {
  final int? statusCode;
  final dynamic data;

  const ServerException(
    String message, {
    this.statusCode,
    this.data,
    dynamic originalError,
  }) : super(message, originalError);
}

/// Network exception
class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection'])
      : super(message);
}

/// Timeout exception
class TimeoutException extends AppException {
  const TimeoutException([String message = 'Request timeout'])
      : super(message);
}

/// Cache exception
class CacheException extends AppException {
  const CacheException([String message = 'Cache error'])
      : super(message);
}

/// Validation exception
class ValidationException extends AppException {
  const ValidationException([String message = 'Validation error'])
      : super(message);
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException([String message = 'Authentication failed'])
      : super(message);
}

/// Exception handler utility
class ExceptionHandler {
  /// Convert DioException to AppException
  static AppException handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Request timeout');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ??
            error.response?.statusMessage ??
            'Server error';
        return ServerException(
          message,
          statusCode: statusCode,
          data: error.response?.data,
          originalError: error,
        );

      case DioExceptionType.cancel:
        return NetworkException('Request cancelled');

      case DioExceptionType.connectionError:
        return NetworkException('No internet connection');

      case DioExceptionType.badCertificate:
        return ServerException('Bad certificate');

      case DioExceptionType.unknown:
      default:
        return NetworkException('Unknown network error');
    }
  }

  /// Handle general exceptions
  static AppException handleException(dynamic error) {
    if (error is DioException) {
      return handleDioException(error);
    } else if (error is AppException) {
      return error;
    } else {
      return NetworkException('Unexpected error: \${error.toString()}');
    }
  }
}
''';

    Utility.writeFile('lib/core/error/exceptions.dart', content);
    Logger.success('   Created lib/core/error/exceptions.dart');
  }

  /// Setup storage (Hive)
  static Future<void> _setupStorage(int step, int totalSteps) async {
    Logger.step(step, totalSteps, 'Setting up local storage (Hive)');

    try {
      // Add dependencies
      Logger.info('   Adding Hive dependencies...');
      await Utility.addDependency('hive');
      await Utility.addDependency('hive_flutter');

      // Create core/storage directory
      await Utility.ensureDirectoryExists('lib/core/storage');

      // Create storage_service.dart
      await _createHiveService();

      // Create storage_init.dart
      await _createHiveInit();

      // Update main.dart with initialization
      await _updateMainFileForStorage();

      Logger.success('   Local storage (Hive) configured successfully');
    } catch (e) {
      Logger.error('   Storage setup failed: $e');
    }
  }

  /// Create Hive service file
  static Future<void> _createHiveService() async {
    final content = '''import 'package:hive_flutter/hive_flutter.dart';

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

    Utility.writeFile('lib/core/storage/storage_service.dart', content);
    Logger.success('   Created lib/core/storage/storage_service.dart');
  }

  /// Create Hive init file
  static Future<void> _createHiveInit() async {
    final content = '''import 'storage_service.dart';

/// Initialize Hive storage
Future<void> initializeStorage() async {
  await StorageService.init();
}
''';

    Utility.writeFile('lib/core/storage/storage_init.dart', content);
    Logger.success('   Created lib/core/storage/storage_init.dart');
  }

  /// Update main.dart with storage initialization
  static Future<void> _updateMainFileForStorage() async {
    final mainFile = File('lib/main.dart');
    if (!mainFile.existsSync()) {
      Logger.warning('   main.dart not found. Please initialize storage manually.');
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
        content = '${content.substring(0, insertIndex)}\n$importLine${content.substring(insertIndex)}';
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
        final bindingPattern = RegExp(r'WidgetsFlutterBinding\.ensureInitialized\(\)\s*;');

        if (!bindingPattern.hasMatch(content)) {
          // WidgetsFlutterBinding not found, add it before initializeStorage
          if (content.contains('runApp(')) {
            // Insert before runApp
            final runAppIndex = content.indexOf('runApp(');
            int lineStart = runAppIndex;
            while (lineStart > 0 && content[lineStart - 1] != '\n') {
              lineStart--;
            }
            content = '${content.substring(0, lineStart)}$bindingCall\n$initCall\n${content.substring(lineStart)}';
          } else {
            // Insert at start of main function
            content = content.replaceFirst(
              RegExp(r'(Future<void>\s+)?main\(\)\s*async\s*\{'),
              'Future<void> main() async {\n$bindingCall\n$initCall\n',
            );
          }
        } else {
          // WidgetsFlutterBinding exists, add initializeStorage after it
          final bindingMatch = bindingPattern.firstMatch(content);
          if (bindingMatch != null) {
            final insertIndex = bindingMatch.end;
            int afterIndex = insertIndex;
            while (afterIndex < content.length && (content[afterIndex] == ' ' || content[afterIndex] == '\t')) {
              afterIndex++;
            }
            if (afterIndex < content.length && content[afterIndex] == '\n') {
              afterIndex++;
              content = '${content.substring(0, afterIndex)}$initCall\n${content.substring(afterIndex)}';
            } else {
              content = '${content.substring(0, insertIndex)}\n$initCall${content.substring(insertIndex)}';
            }
          }
        }
      } else {
        Logger.warning('   main() function not found in main.dart. Please add initialization manually.');
      }
    }

    await mainFile.writeAsString(content);
    Logger.success('   Updated main.dart with storage initialization');
  }

  /// Clean pubspec
  static Future<void> _cleanPubspec(int step, int totalSteps) async {
    Logger.step(step, totalSteps, 'Cleaning pubspec.yaml');
    final success = await PubspecCleaner.cleanPubspec();
    if (success) {
      Logger.success('   pubspec.yaml cleaned successfully');
    } else {
      Logger.warning('   pubspec.yaml cleaning failed');
    }
  }

  /// Setup utils
  static Future<void> _setupUtils(int step, int totalSteps) async {
    Logger.step(step, totalSteps, 'Setting up utils configurations');

    try {
      // Create core/utils directory
      await Utility.ensureDirectoryExists('lib/core/utils');

      // Create constant.dart
      await _createConstants();

      // Create api_endpoint.dart
      await _createApiEndpoint();

      // Create app_logger.dart
      await _createAppLogger();

      Logger.success('   Utils configured successfully');
    } catch (e) {
      Logger.error('   Utils setup failed: $e');
    }
  }

  /// Create constants
  static Future<void> _createConstants() async {
    final content = '''/// Application constants
/// Use this class to store all constant values
class Constants {
  // Private constructor to prevent instantiation
  Constants._();

  // TODO: Add your app constants here
  // Example:
  // static const String appName = 'My App';
  // static const String apiBaseUrl = 'https://api.example.com';
  // static const int maxRetryAttempts = 3;
  // static const Duration connectionTimeout = Duration(seconds: 30);

  // App Info
  // static const String appVersion = '1.0.0';
  // static const String appBuildNumber = '1';

  // API Constants
  // static const String apiKey = 'your_api_key_here';
  // static const String apiSecret = 'your_api_secret_here';

  // Storage Keys
  // static const String keyUserId = 'user_id';
  // static const String keyAuthToken = 'auth_token';
  // static const String keyThemeMode = 'theme_mode';

  // UI Constants
  // static const double defaultPadding = 16.0;
  // static const double defaultBorderRadius = 8.0;
  // static const int maxCharacters = 255;

  // Network Constants
  // static const int connectTimeout = 30;
  // static const int receiveTimeout = 30;
  // static const int sendTimeout = 30;
}
''';

    Utility.writeFile('lib/core/utils/constant.dart', content);
    Logger.success('   Created lib/core/utils/constant.dart');
  }

  /// Create API endpoint
  static Future<void> _createApiEndpoint() async {
    final content = '''/// API endpoints configuration
/// Centralized location for all API endpoints
class ApiEndpoint {
  // Private constructor to prevent instantiation
  ApiEndpoint._();

  // Base URL
  // TODO: Replace with your actual base URL
  static const String baseUrl = 'https://api.example.com';

  // API Version
  static const String apiVersion = '/v1';

  // Full base URL with version
  static String get baseUrlWithVersion => '\$baseUrl\$apiVersion';

  // TODO: Add your API endpoints here
  // Example:
  // static const String login = '/auth/login';
  // static const String register = '/auth/register';
  // static const String logout = '/auth/logout';
  // static const String profile = '/user/profile';
  // static const String updateProfile = '/user/profile/update';

  // Auth endpoints
  // static const String login = '\$apiVersion/auth/login';
  // static const String register = '\$apiVersion/auth/register';
  // static const String refreshToken = '\$apiVersion/auth/refresh';
  // static const String logout = '\$apiVersion/auth/logout';

  // User endpoints
  // static const String getUserProfile = '\$apiVersion/user/profile';
  // static const String updateUserProfile = '\$apiVersion/user/profile';
  // static const String deleteUser = '\$apiVersion/user/delete';

  // Helper method to build full URL
  static String buildUrl(String endpoint) {
    return '\$baseUrl\$endpoint';
  }
}
''';

    Utility.writeFile('lib/core/utils/api_endpoint.dart', content);
    Logger.success('   Created lib/core/utils/api_endpoint.dart');
  }

  /// Create app logger
  static Future<void> _createAppLogger() async {
    final content = '''import 'package:flutter/foundation.dart';

/// Application logger utility
/// Provides consistent logging throughout the app
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  /// Log debug message
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[\$tag] ' : '';
      debugPrint('\$prefix\$message');
    }
  }

  /// Log info message
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[\$tag] ' : '';
      debugPrint('ℹ️  \$prefix\$message');
    }
  }

  /// Log warning message
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[\$tag] ' : '';
      debugPrint('⚠️  \$prefix\$message');
    }
  }

  /// Log error message
  static void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[\$tag] ' : '';
      debugPrint('❌ \$prefix\$message');
      if (error != null) {
        debugPrint('Error: \$error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: \$stackTrace');
      }
    }
  }

  /// Log success message
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[\$tag] ' : '';
      debugPrint('✅ \$prefix\$message');
    }
  }

  /// Log network request
  static void network(String method, String url, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('🌐 \$method \$url');
      if (data != null) {
        debugPrint('Data: \$data');
      }
    }
  }

  /// Log network response
  static void networkResponse(int statusCode, String url, {dynamic data}) {
    if (kDebugMode) {
      debugPrint('📡 Response \$statusCode: \$url');
      if (data != null) {
        debugPrint('Data: \$data');
      }
    }
  }
}
''';

    Utility.writeFile('lib/core/utils/app_logger.dart', content);
    Logger.success('   Created lib/core/utils/app_logger.dart');
  }
}
