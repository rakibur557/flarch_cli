# Flarch CLI

[![pub package](https://img.shields.io/pub/v/flarch.svg)](https://pub.dev/packages/flarch)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Flarch** is a powerful command-line interface (CLI) tool designed to simplify and streamline Flutter project development. It automates the creation of clean architecture folder structures, manages features, and configures essential project components with ease.

## 🚀 Features

### Project Initialization
- **Interactive & Non-Interactive Modes**: Initialize Flutter projects with comprehensive setup
- **Automated Configuration**: Set up assets, themes, routing, networking, storage, and utilities in one command

### Architecture Support
- **Clean Architecture**: Full support for Clean Architecture patterns
- **MVC & MVVM**: Support for MVC and MVVM architectures
- **State Management**: Integration with Bloc, GetX, and Provider

### Feature Management
- **Create Features**: Generate complete feature structures with a single command
- **List Features**: View all features in your project
- **Remove Features**: Safely delete features with all associated files
- **Rename Features**: Rename features while maintaining structure

### Project Configuration
- **Assets Setup**: Configure assets folder structure
- **Theme Configuration**: Set up light/dark themes
- **Router Setup**: Configure GoRouter for navigation
- **Storage Setup**: Configure local storage (Hive, SharedPreferences, ObjectBox, Isar, Drift)
- **Network Setup**: Configure Dio client with connectivity checking
- **Utils Setup**: Create constants, API endpoints, and logger utilities

### Project Maintenance
- **Clean pubspec.yaml**: Remove unnecessary comments
- **Package ID Management**: Replace package IDs across the project
- **App Name Management**: Change app display names
- **Health Check**: Analyze project health and get recommendations

## 📦 Installation

```bash
dart pub global activate flarch
```

Make sure you have Dart SDK installed and `pub cache bin` is in your PATH.

## 🎯 Quick Start

### Initialize a New Project

```bash
# Interactive mode (asks questions)
flarch init

# Non-interactive mode (all options enabled)
flarch init my_app
```

### Create a Feature

```bash
# Interactive mode
flarch "FeatureName"

# With architecture
flarch "FeatureName" --clean
flarch "FeatureName" --mvc
flarch "FeatureName" --mvvm

# With state management
flarch "FeatureName" -sm "Name" -bloc
flarch "FeatureName" -sm "Name" -getx
```

### Configure Project

```bash
# Setup assets
flarch config assets

# Setup theme
flarch config theme

# Setup router
flarch config router

# Setup storage
flarch config storage

# Setup network (via init)
flarch init
```

## 📚 Usage Guide

### Project Initialization

```bash
flarch init                    # Interactive mode
flarch init my_app            # Non-interactive mode (all options enabled)
```

### Feature Management

```bash
flarch list                    # List all features
flarch tree                    # Show project directory tree
flarch rm FeatureName         # Remove a feature
flarch rename OldName NewName  # Rename a feature
```

### Project Configuration

```bash
flarch config assets           # Setup assets folder structure
flarch config main             # Clean main.dart and create app.dart
flarch config theme            # Setup theme configuration
flarch config router           # Setup GoRouter configuration
flarch config storage          # Setup local storage
flarch config package <id>     # Replace package ID
flarch config name "App Name"  # Change app display name
```

### Project Maintenance

```bash
flarch clean pubspec           # Clean comments from pubspec.yaml
flarch health                  # Check project health
```

## 🏗️ Architecture Support

### Clean Architecture

```bash
flarch "FeatureName" --clean
flarch "FeatureName" -u "UseCaseName"    # Create use case
flarch "FeatureName" -m "ModelName"      # Create model/entity
flarch "FeatureName" -r "RepositoryName" # Create repository
flarch "FeatureName" -d "DataSourceName"  # Create data source
```

### MVC Architecture

```bash
flarch "FeatureName" --mvc
```

### MVVM Architecture

```bash
flarch "FeatureName" --mvvm
```

## 🔧 State Management

```bash
flarch "FeatureName" -sm "Name" -bloc     # Bloc state management
flarch "FeatureName" -sm "Name" -getx     # GetX state management
flarch "FeatureName" -sm "Name" -provider # Provider state management
```

## 📖 Documentation

For detailed documentation, run:

```bash
flarch --help
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/NewFeature`)
3. Commit your changes (`git commit -m 'Add some NewFeature'`)
4. Push to the branch (`git push origin feature/NewFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Rakibur Rahman**

- GitHub: [rakibur557](https://github.com/rakibur557)
- Linked-in: [rakibur557](https://www.linkedin.com/in/rakibur557)
- Project: [flarch_cli](https://github.com/rakibur557/flarch_cli)

## 🙏 Acknowledgments

- Inspired by clean architecture principles
- Built with ❤️ for the Flutter community

## 📊 Project Health

Check your project's health and get recommendations:

```bash
flarch health
```

This will analyze your project structure, dependencies, configuration, and best practices, providing actionable recommendations.

---

**Made with ❤️ for Flutter developers**
