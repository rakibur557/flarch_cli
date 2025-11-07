# Flarch CLI Example

This example demonstrates how to use the Flarch CLI tool to create and manage Flutter projects with Clean Architecture.

## Installation

First, install the Flarch CLI tool globally:

```bash
dart pub global activate flarch
```

Or add it to your project:

```bash
dart pub add flarch
```

## Basic Usage

### 1. Initialize a Flutter Project

Initialize a new Flutter project with all configurations:

```bash
flarch init my_app
```

Or use interactive mode:

```bash
flarch init
```

### 2. Create a Feature

Create a new feature with Clean Architecture:

```bash
flarch "UserProfile"
```

This will create a feature with the following structure:
- `lib/features/user_profile/`
  - `domain/` (entities, repositories, use cases)
  - `data/` (data sources, models)
  - `presentation/` (pages, widgets)

### 3. Create a Feature with State Management

Create a feature with Bloc state management:

```bash
flarch "UserProfile" -sm "UserProfile" -bloc
```

### 4. Create Use Cases, Models, and Repositories

```bash
# Create a use case
flarch "UserProfile" -u "GetUserProfile"

# Create a model
flarch "UserProfile" -m "User"

# Create a repository
flarch "UserProfile" -r "UserRepository"

# Create a data source
flarch "UserProfile" -d "UserRemoteDataSource"
```

### 5. Configure Project

```bash
# Setup assets
flarch config assets

# Setup theme
flarch config theme

# Setup router
flarch config router

# Setup storage (Hive, SharedPreferences, ObjectBox, Isar, Drift)
flarch config storage
```

### 6. Project Management

```bash
# List all features
flarch list

# Show project tree
flarch tree

# Remove a feature
flarch rm UserProfile

# Rename a feature
flarch rename UserProfile UserAccount

# Check project health
flarch health
```

## Example Project Structure

After running `flarch init my_app`, your project will have:

```
my_app/
├── lib/
│   ├── core/
│   │   ├── network/
│   │   ├── storage/
│   │   ├── theme/
│   │   └── router/
│   ├── features/
│   │   └── user_profile/
│   │       ├── domain/
│   │       ├── data/
│   │       └── presentation/
│   ├── app.dart
│   └── main.dart
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
└── pubspec.yaml
```

## More Examples

See the [main README](../README.md) for more detailed examples and documentation.

