# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

This is a **fork** of the [Nutrient Flutter SDK](https://github.com/PSPDFKit/pspdfkit-flutter) (formerly PSPDFKit Flutter plugin), maintained for the **Trax** project by Railway Engineering Solutions. Trax is a railway delivery management app built with Flutter — see `~/repos/trax` and `trax.res.app` for the main application. This fork lives on the `feat/interaction` branch and is consumed by Trax as a git dependency.

The plugin provides PDF viewing, annotation, and editing across Android, iOS, and Web via native SDK wrappers.

## Common Commands

```bash
# Dependencies
flutter pub get

# Code generation (Pigeon — generates Dart/Kotlin/Swift API bindings)
dart run pigeon
# Outputs: lib/src/api/nutrient_api.g.dart, android/.../api/NutrientApi.g.kt, ios/Classes/api/NutrientApi.g.swift

# Analysis
flutter analyze

# Tests
flutter test                                    # all unit tests
flutter test test/annotation_models_test.dart   # single test

# Example app
cd example && flutter pub get && flutter run
```

## Architecture

### Cross-Platform API (Pigeon)

The API contract is defined in `pigeons/nutrient.dart`. Running `dart run pigeon` generates type-safe bindings for all three platforms. The generated file `lib/src/api/nutrient_api.g.dart` is excluded from lint analysis.

### Platform Layers

| Layer | Entry Point | Native SDK |
|-------|-------------|------------|
| **Dart** | `lib/nutrient_flutter.dart` → conditional exports | — |
| **Android** | `android/.../PspdfkitApiImpl.kt` | Nutrient 10.10.1 (Maven) |
| **iOS** | `ios/Classes/PspdfkitApiImpl.swift` | PSPDFKit 26.5.0 (CocoaPods) |
| **Web** | `lib/src/web/nutrient_web.dart` | Nutrient Web SDK (JS interop) |

### Conditional Imports Pattern

Platform-specific code uses conditional imports (`dart.library.io` / `dart.library.js_interop`) with stub files for unused platforms. Each feature typically has `*_native.dart`, `*_web.dart`, and `*_stub.dart` variants.

### Key Directories

- `lib/src/annotations/` — 20+ annotation model types with JSON serialization
- `lib/src/document/` — `PdfDocument`, `AnnotationManager`, `HeadlessDocumentNative`
- `lib/src/widgets/` — `NutrientView` (native) / `NutrientViewWeb`, controllers
- `lib/src/web/` — Web-specific implementation via JS interop
- `lib/src/adapters/` — Advanced native SDK access via JNI (Android) / FFI (iOS)
- `pigeons/` — Pigeon definition file and generation script

### Pigeon Workflow

When modifying the cross-platform API:
1. Edit `pigeons/nutrient.dart`
2. Run `dart run pigeon`
3. Implement the generated interface in `PspdfkitApiImpl.kt` (Android) and `PspdfkitApiImpl.swift` (iOS)

## Lint Rules

Uses `flutter_lints/flutter.yaml` with: `always_declare_return_types`, `prefer_single_quotes`, `sort_child_properties_last`, `unawaited_futures`, `use_full_hex_values_for_flutter_colors`.

## SDK Versions

- Flutter ≥3.27.0, Dart ≥3.0.0 <4.0.0
- Android: minSdk 24, compileSdk 36, Kotlin 2.1.20, JDK 17
- iOS: 16.0+, Swift 5.0
