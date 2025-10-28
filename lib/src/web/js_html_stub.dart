///
///  Copyright © 2023-2025 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.
///

// Minimal stubs to satisfy analyzer and mobile builds when web libraries are unavailable.

// ignore_for_file: unused_element, unnecessary_this, avoid_positional_boolean_parameters

/// Stub for dart:js's global context
dynamic context;

/// Stub for dart:html's Element
class Element {}

/// Very lightweight stub for dart:js JsObject
class JsObject {
  JsObject([dynamic a, List<dynamic>? args]);

  static dynamic jsify(Object? o) => o;

  dynamic callMethod(String method, [List<dynamic>? args]) => null;

  bool hasProperty(String name) => false;

  dynamic operator [](Object? key) => null;

  void operator []=(Object? key, Object? value) {}
}

/// Lightweight stub for dart:js JsArray
class JsArray {
  JsArray();
}
