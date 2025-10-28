///
///  Copyright © 2023-2025 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE REDISTRIED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.
///

/// Stub for Directory class on web platforms to avoid import errors.
/// This file is only used when building for web to provide a Directory type stub.
/// On non-web platforms, dart:io is imported instead.
// ignore: avoid_web_libraries_in_flutter

/// Stub Directory class for web platform.
class Directory {
  final String path;

  Directory(this.path);

  String get absolute => path;
}

/// Stub Registrar class to match flutter_web_plugins.dart
/// Only used when building for non-web platforms
class Registrar {
  // Stub implementation
}
