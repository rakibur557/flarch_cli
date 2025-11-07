# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-01-17

### Fixed
- Fixed banner display issue where "m" characters were appearing around the banner
- Fixed ANSI escape code formatting in `rgb()` function

### Improved
- Improved pub points score from 120/160 to 160/160
- Fixed package description length (now within 60-180 character range)
- Added comprehensive dartdoc comments to all public API elements
- Fixed all 32 static analysis issues (type annotations, string interpolation, etc.)
- Created example directory with working example code

## [1.0.0] - 2025-11-07

### Added

#### Project Initialization
- `flarch init` command for interactive project initialization
- `flarch init <app_name>` for non-interactive project initialization with all options enabled
- Automatic Flutter project creation if not in a Flutter project
- Comprehensive project setup wizard

#### Feature Management
- `flarch "FeatureName"` - Create features with interactive prompts
- `flarch list` - List all features in the project
- `flarch tree` - Display project directory tree
- `flarch rm <FeatureName>` - Safely remove features
- `flarch rename <OldName> <NewName>` - Rename features

#### Architecture Support
- Clean Architecture support with use cases, repositories, data sources, and models
- MVC architecture support
- MVVM architecture support
- State management integration (Bloc, GetX, Provider)

#### Project Configuration
- `flarch config assets` - Setup assets folder structure
- `flarch config main` - Clean main.dart and create app.dart
- `flarch config theme` - Setup theme configuration with light/dark themes
- `flarch config router` - Setup GoRouter configuration
- `flarch config storage` - Setup local storage (Hive, SharedPreferences, ObjectBox, Isar, Drift)
- `flarch config package <id>` - Replace package ID across the project
- `flarch config name "App Name"` - Change app display name

#### Network Configuration
- Dio client setup with interceptors and error handling
- Connectivity checking with connectivity_plus
- Network info service
- Error handling with failures and exceptions

#### Storage Configuration
- Hive storage setup
- SharedPreferences support
- ObjectBox support
- Isar support
- Drift support

#### Utils Configuration
- Constants class setup
- API endpoints configuration
- App logger utility

#### Project Maintenance
- `flarch clean pubspec` - Clean unnecessary comments from pubspec.yaml
- `flarch health` - Check project health and get recommendations

#### Project Health Check
- Project structure analysis
- Dependencies analysis
- Configuration checks
- Code organization analysis
- Best practices recommendations
- Overall health score with actionable recommendations

### Features

- Interactive command-line interface with colored output
- Comprehensive error handling
- Cross-platform support (Windows, macOS, Linux)
- Case-insensitive command handling
- Reserved command protection (init, list, tree, etc. cannot be feature names)
- Automatic dependency management
- File backup support for critical operations
- Progress indicators for long-running operations

### Technical Details

- Built with Dart 3.0+
- Uses yaml_edit for safe pubspec.yaml manipulation
- Supports multiple architecture patterns
- Modular code structure for easy maintenance
- Comprehensive logging and user feedback

---

[1.0.1]: https://github.com/rakibur557/flarch_cli/releases/tag/v1.0.1
[1.0.0]: https://github.com/rakibur557/flarch_cli/releases/tag/v1.0.0
