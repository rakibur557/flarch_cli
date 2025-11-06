import 'dart:io';
import '../../core/utils/logger.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Manages asset configuration for Flutter projects.
class AssetConfigManager {
  /// Creates assets folders and updates pubspec.yaml safely.
  static Future<bool> setupAssets() async {
    try {
      final pubspecFile = File('pubspec.yaml');
      if (!pubspecFile.existsSync()) {
        Logger.error('pubspec.yaml not found in current directory.');
        Logger.info('Please run this command from your Flutter project root.');
        return false;
      }

      await _createAssetsFolderStructure();
      await _updatePubspecYaml(pubspecFile);

      Logger.success('Assets configured successfully!');
      Logger.info('Folder structure created:');
      Logger.info('  - assets/images/');
      Logger.info('  - assets/icons/');
      Logger.info('  - assets/animations/');
      Logger.info('pubspec.yaml updated successfully.');
      return true;
    } catch (e) {
      Logger.error('Failed to setup assets: $e');
      return false;
    }
  }

  /// Create the assets folder structure
  static Future<void> _createAssetsFolderStructure() async {
    final dirs = [
      'assets',
      'assets/images',
      'assets/icons',
      'assets/animations'
    ];

    for (final dir in dirs) {
      final directory = Directory(dir);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
        Logger.success('Created $dir/ folder');
      }
    }
  }

  /// Helper to check if a YAML path exists
  static bool _pathExists(YamlEditor editor, List<Object> path) {
    try {
      editor.parseAt(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update pubspec.yaml properly under the `flutter:` section using YamlEditor
  static Future<void> _updatePubspecYaml(File pubspecFile) async {
    try {
      final content = await pubspecFile.readAsString();
      final editor = YamlEditor(content);

      // Ensure flutter section exists
      if (!_pathExists(editor, ['flutter'])) {
        editor.update(['flutter'], {});
      }

      // Ensure assets section exists under flutter
      if (!_pathExists(editor, ['flutter', 'assets'])) {
        editor.update(['flutter', 'assets'], []);
      }

      // Get current assets list
      final currentAssets = editor.parseAt(['flutter', 'assets']).value;
      final current = currentAssets is List ? currentAssets : <dynamic>[];

      // Convert to Set to avoid duplicates
      final assetSet = <String>{};

      // Add existing assets (convert to strings and clean them)
      for (final item in current) {
        if (item != null) {
          final asset = item.toString().trim();
          if (asset.isNotEmpty) {
            assetSet.add(asset);
          }
        }
      }

      // Add new assets
      final newAssets = [
        'assets/images/',
        'assets/icons/',
        'assets/animations/',
      ];

      for (final asset in newAssets) {
        assetSet.add(asset);
      }

      // Update with merged and sorted assets
      final sortedAssets = assetSet.toList()..sort();

      // Update the assets list
      editor.update(['flutter', 'assets'], sortedAssets);

      // Get the updated YAML string and write it
      final updatedContent = editor.toString();
      await pubspecFile.writeAsString(updatedContent);
      Logger.success('Updated pubspec.yaml (flutter.assets)');
    } catch (e) {
      Logger.error('Failed to update pubspec.yaml: $e');
      Logger.info('Please manually add the following under "flutter:"');
      Logger.info('  assets:');
      Logger.info('    - assets/images/');
      Logger.info('    - assets/icons/');
      Logger.info('    - assets/animations/');
      rethrow;
    }
  }
}
