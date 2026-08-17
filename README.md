# VOID

[![Flutter](https://img.shields.io/badge/Flutter-3.5+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/Storage-SQLite%20%2F%20Drift-003B57?logo=sqlite&logoColor=white)](https://drift.simonbinder.eu/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A local-first desktop application for cataloging and managing personal media collections.

## Features

- **Dynamic schema engine**: Built-in schemas for Movies, TV Shows, and Books, plus support for custom schemas with 12 typed field definitions (text, numbers, ratings, dates, select, multi-select, URLs, images, boolean).
- **Online metadata lookup**: Search and fetch metadata, artwork, release dates, and ratings from public APIs (Open Library for books, TVmaze for TV series, and media search providers).
- **Configurable view modes**: Toggle between a responsive grid (3 to 12 columns per row with automatic aspect ratio scaling) and a horizontal cover-shelf list view with carousel navigation.
- **Local-first SQLite storage**: Fully offline persistence using Drift and SQLite with reactive stream queries and schema migration synchronization.
- **Custom window chrome**: Frameless desktop shell with integrated title bar, window controls (Windows, macOS, Linux), search bar, and context menus.
- **State management**: Feature-first architecture powered by Riverpod with code generation.

## Project Structure

```
lib/
├── app/                  # Application entry, router, and root providers
├── core/                 # Shared utilities, database config, and theme definitions
│   ├── database/         # Drift SQLite database schema and migrations
│   ├── theme/            # Material 3 dark/light themes and typography
│   └── utils/            # Validators, serializers, and helpers
├── features/
│   ├── collections/      # Collection domains, repositories, and UI widgets
│   ├── items/            # Item CRUD, detail drawer, and dynamic field inputs
│   ├── media_search/     # External metadata search API clients and dialogs
│   ├── schemas/          # Schema definitions, field configs, and validators
│   ├── search/           # Global search state and filters
│   └── settings/         # Layout settings, view preferences, and persistence
└── shared/               # Reusable dialogs, popups, and layout shell
```

## Getting Started

### Prerequisites

- Flutter SDK `^3.5.0`
- Dart SDK `^3.5.0`
- Desktop build toolchains:
  - **Windows**: Visual Studio 2022 with "Desktop development with C++"
  - **macOS**: Xcode with Command Line Tools
  - **Linux**: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/muneebbug/void.git
   cd void
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generation (for Drift, Freezed, and Riverpod):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### Running the App

To start the desktop app in development mode:

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

## Running Tests

Run the test suite covering database operations, schema serialization, validators, and widget layouts:

```bash
flutter test
```

To run static analysis:

```bash
flutter analyze
```

## Building for Release

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

