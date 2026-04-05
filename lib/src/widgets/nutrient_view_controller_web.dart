///
///  Copyright © 2018-2026 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.
///

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';
import 'package:nutrient_flutter/src/events/nutrient_events_extension.dart';
import '../document/annotation_json_converter.dart';
import '../document/annotation_manager_web.dart';
import '../web/nutrient_web.dart'
    if (dart.library.io) '../web/nutrient_web_stub.dart';
import '../web/nutrient_web_instance.dart'
    if (dart.library.io) '../web/nutrient_web_instance_stub.dart';
import 'package:nutrient_flutter/src/document/annotation_json_converter.dart';
import 'package:nutrient_flutter_web/nutrient_flutter_web.dart'
    show
        NutrientWebInstance,
        NutrientWebInstanceExtension,
        NutrientWebStaticExtension,
        NutrientNamespace,
        NutrientRect,
        annotationTypeMap,
        pspdfkit;

/// A controller for a Nutrient viewer widget on the web platform.
///
/// Wraps a [NutrientWebInstance] from the modern `dart:js_interop`-based
/// web bindings provided by `nutrient_flutter_web`.
class NutrientViewControllerWeb extends NutrientViewController
    with AnnotationJsonConverter {
  final NutrientWebInstance instance;

  NutrientViewControllerWeb(this.instance);

  // Map to store web event listeners for removal.
  final Map<NutrientWebEvent, Map<Function, JSFunction>> _webEventListeners =
      {};

  // Map to track legacy NutrientEvent listeners
  final Map<NutrientEvent, JSFunction> _legacyEventListeners = {};

  @override
  Future<bool?> importXfdf(String xfdfPath) async {
    await instance.importXFDF(xfdfPath).toDart;
    return true;
  }

  @override
  Future<bool?> processAnnotations(
    AnnotationType type,
    AnnotationProcessingMode processingMode,
    String destinationPath,
  ) {
    throw UnimplementedError('This method is not supported on the web!');
  }

  @override
  Future<bool?> save() async {
    await instance.save().toDart;
    return true;
  }

  @override
  Future<bool?> setAnnotationMenuConfiguration(
    AnnotationMenuConfiguration configuration,
  ) {
    if (kDebugMode) {
      print(
          'setAnnotationMenuConfiguration called on web - not yet implemented');
    }
    return Future.value(true);
  }

  @override
  Future<bool?> setAnnotationConfigurations(
      Map<AnnotationTool, AnnotationConfiguration> configurations) async {
    throw UnimplementedError('This method is not supported on the web!');
  }

  void dispose() {
    // Remove all web event listeners
    final eventsCopy = Map<NutrientWebEvent, Map<Function, JSFunction>>.from(
        _webEventListeners);
    for (final eventEntry in eventsCopy.entries) {
      final event = eventEntry.key;
      final callbacksCopy = Map<Function, JSFunction>.from(eventEntry.value);
      for (final callbackEntry in callbacksCopy.entries) {
        removeWebEventListener(event, callbackEntry.key as Function(dynamic));
      }
    }
    _webEventListeners.clear();

    // Remove all legacy event listeners
    final legacyEventsCopy =
        Map<NutrientEvent, JSFunction>.from(_legacyEventListeners);
    for (final eventEntry in legacyEventsCopy.entries) {
      removeEventListener(eventEntry.key);
    }
    _legacyEventListeners.clear();

    // Unload the instance
    try {
      pspdfkit.unload(instance);
    } catch (e) {
      if (kDebugMode) {
        print('Error unloading PSPDFKit instance: $e');
      }
    }
  }

  @override
  Future<void> addEventListener(
      NutrientEvent event, Function(dynamic) callback) async {
    if (!event.isWebSupported) {
      if (kDebugMode) {
        print(
            'Event ${event.name} is not supported on web, skipping listener registration');
      }
      return;
    }

    final JSFunction jsCallback = ((JSAny? data) {
      _processAndInvokeCallback(_safeConvertJsAny(data), callback, event);
    }).toJS;

    _legacyEventListeners[event] = jsCallback;
    instance.addEventListener(event.webName, jsCallback);
  }

  @override
  Future<void> removeEventListener(NutrientEvent event) async {
    if (!event.isWebSupported) return;

    final jsCallback = _legacyEventListeners[event];
    if (jsCallback != null) {
      try {
        instance.removeEventListener(event.webName, jsCallback);
        _legacyEventListeners.remove(event);
      } catch (e) {
        if (kDebugMode) {
          print('Error removing legacy event listener for $event: $e');
        }
      }
    }
  }

  @override
  void addWebEventListener(NutrientWebEvent event, Function(dynamic) callback) {
    final JSFunction jsCallback = ((JSAny? data) {
      _processAndInvokeCallback(_safeConvertJsAny(data), callback, event);
    }).toJS;

    _webEventListeners.putIfAbsent(event, () => {})[callback] = jsCallback;

    try {
      if (kDebugMode) {
        print('Adding event listener for: ${event.name}');
      }
      instance.addEventListener(event.name, jsCallback);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding web event listener for ${event.name}: $e');
      }
    }
  }

  @override
  void removeWebEventListener(
      NutrientWebEvent event, Function(dynamic) callback) {
    final eventCallbacks = _webEventListeners[event];
    if (eventCallbacks != null) {
      final jsCallback = eventCallbacks[callback];
      if (jsCallback != null) {
        try {
          instance.removeEventListener(event.name, jsCallback);
        } catch (e) {
          if (kDebugMode) {
            print('Error removing web event listener for $event: $e');
          }
        }
        eventCallbacks.remove(callback);
        if (eventCallbacks.isEmpty) {
          _webEventListeners.remove(event);
        }
      }
    }
  }

  @override
  Future<bool?> enterAnnotationCreationMode(
      [AnnotationTool? annotationTool, Color? color]) async {
    try {
      // Use provided color or fall back to default color
      final colorToUse = color ?? pspdfkitInstance.defaultAnnotationColor;

      if (annotationTool != null) {
        await pspdfkitInstance.setToolMode(annotationTool, colorToUse);
      } else {
        // Use a default annotation tool (ink) if none is specified
        // This is consistent with native implementations
        await pspdfkitInstance.setToolMode(AnnotationTool.inkPen, colorToUse);
      }
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        print('Error entering annotation creation mode: $e');
      }
      return Future.value(false);
    }
  }

  @override
  Future<bool?> exitAnnotationCreationMode() async {
    try {
      // Set tool mode to null to exit annotation creation mode
      // This will reset to the default interaction mode
      await pspdfkitInstance.setToolMode(null);
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        print('Error exiting annotation creation mode: $e');
      }
      return Future.value(false);
    }
  }

  @override
  Future<Rect> getVisibleRect(int pageIndex) {
    throw UnimplementedError('This method is not supported yet on web!');
  }

  @override
  Future<void> zoomToRect(int pageIndex, Rect rect) async {
    try {
      // Create a PSPDFKit.Geometry.Rect object using the SDK constructor
      final pspdfkitNamespace = globalContext['PSPDFKit'] as JSObject?;
      if (pspdfkitNamespace == null) {
        throw Exception('PSPDFKit namespace not found');
      }
      final geometryNamespace = pspdfkitNamespace['Geometry'] as JSObject?;
      if (geometryNamespace == null) {
        throw Exception('PSPDFKit.Geometry namespace not found');
      }
      final rectConstructor = geometryNamespace['Rect'] as JSFunction?;
      if (rectConstructor == null) {
        throw Exception('PSPDFKit.Geometry.Rect constructor not found');
      }

      final rectData = {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height,
      }.jsify();

      final webRect = rectConstructor.callAsConstructor(rectData);
      instance.jumpAndZoomToRect(pageIndex, webRect as NutrientRect);
    } catch (e) {
      throw Exception('Failed to zoom to rect: $e');
    }
  }

  @override
  Future<double> getZoomScale(int pageIndex) async {
    try {
      final scale = (instance as JSObject).getProperty('currentZoomLevel'.toJS);
      return (scale as JSNumber).toDartDouble;
    } catch (e) {
      throw Exception('Failed to get zoom scale: $e');
    }
  }

  @override
  Future<bool?> exportXfdf(String xfdfPath) async {
    final result = await instance.exportXFDF(null).toDart;
    if (result != null) {
      _downloadContent(
          (result as JSString).toDart, xfdfPath, 'application/vnd.adobe.xfdf');
    }
    return true;
  }

  /// Helper to trigger a file download in the browser.
  void _downloadContent(String content, String filename, String mimeType) {
    try {
      final urlObj = globalContext['URL'] as JSObject;
      final doc = globalContext['document'] as JSObject;

      final blob = globalContext.callMethod(
        'eval'.toJS,
        'new Blob([arguments[0]], {type: arguments[1]})'.toJS,
        content.toJS,
        mimeType.toJS,
      );
      final url = urlObj.callMethod('createObjectURL'.toJS, blob);
      final anchor = doc.callMethod('createElement'.toJS, 'a'.toJS) as JSObject;
      anchor['href'] = url;
      anchor['download'] = filename.toJS;
      anchor.callMethod('click'.toJS);
      urlObj.callMethod('revokeObjectURL'.toJS, url);
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading XFDF: $e');
      }
    }
  }

  /// Tries to convert a JS object (e.g. Immutable.js Record) to a Dart map
  /// using the Web SDK's `Annotations.toSerializableObject()`.
  ///
  /// Returns null if the object cannot be converted.
  Map<String, dynamic>? _tryConvertJsAnnotation(dynamic jsObj) {
    try {
      final ns = NutrientNamespace.getAsJSObject();
      final annotationsNs = ns['Annotations'] as JSObject?;
      if (annotationsNs == null) return null;

      final jsAnnotation = jsObj as JSObject;
      final jsJson = annotationsNs.callMethod(
        'toSerializableObject'.toJS,
        jsAnnotation,
      );
      if (jsJson == null) return null;

      final result = jsJson.dartify();
      Map<String, dynamic> typedMap;
      if (result is Map<String, dynamic>) {
        typedMap = _deepConvertMap(result);
      } else if (result is Map) {
        typedMap = _deepConvertMap(Map<String, dynamic>.from(result));
      } else {
        return null;
      }

      // Add type info via instanceof checks
      for (final entry in annotationTypeMap.entries) {
        final annotationClass = annotationsNs[entry.key];
        if (annotationClass == null) continue;
        if (jsAnnotation.instanceof(annotationClass as JSFunction)) {
          typedMap['type'] = entry.value;
          break;
        }
      }

      return typedMap;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool?> setUserInteractionEnabled(bool enabled) async {
    try {
      await pspdfkitInstance.setUserInteractionEnabled(enabled);
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user interaction: $e');
      }
      return Future.value(false);
    }
  }

  /// Sets the default color for all annotation operations.
  /// This color will be used when no specific color is provided to annotation methods.
  ///
  /// Example:
  /// ```dart
  /// await controller.setDefaultAnnotationColor(Colors.red);
  /// // Now all annotations will use red color by default
  /// await controller.enterAnnotationCreationMode(AnnotationTool.inkPen);
  /// // Ink pen will use red color
  /// ```
  Future<bool?> setDefaultAnnotationColor(Color color) async {
    try {
      await pspdfkitInstance.setDefaultAnnotationColor(color);
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting default annotation color: $e');
      }
      return Future.value(false);
    }
  }

  @override
  Future<bool?> setLockedAnnotationColor(Color color) async {
    // Web platform falls back to setting the default annotation color.
    return setDefaultAnnotationColor(color);
  }

  /// Gets the current default annotation color.
  Color? get defaultAnnotationColor => pspdfkitInstance.defaultAnnotationColor;

  // Helper method to process event data and invoke the user callback
  void _processAndInvokeCallback(
      dynamic data, Function(dynamic) userCallback, dynamic eventEnum) {
    try {
      bool isAnnotation(Map<String, dynamic> obj) {
        if (obj.containsKey('type') &&
            obj['type'] is String &&
            (obj['type'] as String).startsWith('pspdfkit/')) {
          return true;
        }

        if (obj.containsKey('id')) {
          final annotationProps = [
            'boundingBox',
            'pageIndex',
            'rects',
            'creatorName',
            'createdAt',
            'updatedAt'
          ];
          int matchCount = 0;
          for (final prop in annotationProps) {
            if (obj.containsKey(prop)) matchCount++;
          }
          if (matchCount >= 2) return true;
        }

        return false;
      }

      dynamic processObject(dynamic obj) {
        // Handle JS objects that dartify() couldn't convert (e.g. Immutable.js Records).
        // Try converting them as annotations via the Web SDK.
        if (obj is JSObject) {
          final converted = _tryConvertJsAnnotation(obj);
          if (converted != null) {
            try {
              return Annotation.fromJson(converted);
            } catch (_) {
              return converted;
            }
          }
          // Can't convert — return as-is
          return obj;
        }

        // dartify() may produce Map<Object?, Object?> instead of Map<String, dynamic>.
        // Normalize to Map<String, dynamic>.
        if (obj is Map && obj is! Map<String, dynamic>) {
          obj = Map<String, dynamic>.from(obj);
        }

        if (obj is Map<String, dynamic>) {
          if (isAnnotation(obj)) {
            try {
              return Annotation.fromJson(obj);
            } catch (e) {
              if (kDebugMode) {
                print('Failed to convert annotation to Dart object: $e');
              }
              return obj;
            }
          }

          final result = <String, dynamic>{};
          for (final entry in obj.entries) {
            result[entry.key] = processObject(entry.value);
          }
          return result;
        } else if (obj is List) {
          return obj.map((item) => processObject(item)).toList();
        }

        return obj;
      }

      dynamic finalData;

      // Normalize top-level map from dartify()
      if (data is Map && data is! Map<String, dynamic>) {
        data = Map<String, dynamic>.from(data);
      }

      if (data is Map<String, dynamic> &&
          data.containsKey('argument1') &&
          data.containsKey('argument2')) {
        finalData = {
          'argument1': processObject(data['argument1']),
          'argument2': processObject(data['argument2']),
        };
      } else {
        finalData = processObject(data);
      }

      if (kDebugMode && eventEnum.toString().contains('annotations')) {
        print('Processing ${eventEnum.toString()} event: $finalData');
      }

      // Check if annotation events should be suppressed
      // This prevents infinite loops when programmatically modifying annotations
      if (eventEnum.toString().contains('annotations')) {
        try {
          // Check if we should suppress annotation events
          if (AnnotationManagerWeb.shouldSuppressEvents('')) {
            if (kDebugMode) {
              print('Suppressing ${eventEnum.toString()} event');
            }
            return; // Don't call the user callback
          }
        } catch (e) {
          // If check fails, proceed with callback
        }
      }

      userCallback(finalData);
    } catch (e) {
      if (kDebugMode) {
        print('Error processing event listener data for $eventEnum: $e');
      }
      userCallback(data);
    }
  }

  /// Safely converts a JSAny to a Dart value, handling cases where dartify() fails.
  ///
  /// Some JS objects (like Immutable.js Records or certain event data) cannot
  /// be converted by dartify() and return LegacyJavaScriptObject instances.
  /// This method handles those cases by manually extracting properties.
  dynamic _safeConvertJsAny(JSAny? jsValue) {
    if (jsValue == null) return null;

    // Try dartify first
    try {
      final dartified = jsValue.dartify();
      // Check if dartify succeeded - if it returns the same type or a usable type
      if (dartified is Map ||
          dartified is List ||
          dartified is String ||
          dartified is num ||
          dartified is bool ||
          dartified == null) {
        // Deep convert to handle nested IdentityMap instances
        if (dartified is Map) {
          return _deepConvertAny(dartified);
        }
        return dartified;
      }
      // dartify returned something unusable (like LegacyJavaScriptObject)
      // Fall through to manual conversion
    } catch (_) {
      // dartify failed, fall through to manual conversion
    }

    // Manual conversion for JSObject using js_interop_unsafe
    try {
      final jsObj = jsValue as JSObject;
      return _convertJsObjectToMap(jsObj);
    } catch (_) {
      // Not a JSObject or conversion failed
    }

    // Return null for unconvertible values
    return null;
  }

  /// Converts a JSObject to a Map<String, dynamic> by extracting its properties.
  Map<String, dynamic> _convertJsObjectToMap(JSObject jsObj) {
    final result = <String, dynamic>{};

    // Get object keys using Object.keys() via globalContext
    final objectKeys = globalContext['Object'] as JSObject?;
    if (objectKeys != null) {
      final keysMethod = objectKeys['keys'];
      if (keysMethod != null) {
        final keysArray = objectKeys.callMethod('keys'.toJS, jsObj);
        if (keysArray != null) {
          // Convert JSArray to list
          final dartKeys = (keysArray as JSArray).toDart;
          for (final jsKey in dartKeys) {
            final key = (jsKey as JSString).toDart;
            final value = jsObj[key];
            result[key] = _safeConvertJsAny(value);
          }
        }
      }
    }

    return result;
  }

  /// Deep converts any value, handling nested maps and lists.
  dynamic _deepConvertAny(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _deepConvertMap(value);
    } else if (value is Map) {
      final converted = <String, dynamic>{};
      for (final entry in value.entries) {
        converted[entry.key.toString()] = _deepConvertAny(entry.value);
      }
      return converted;
    } else if (value is List) {
      return value.map(_deepConvertAny).toList();
    }
    return value;
  }

  /// Recursively converts a map and all nested maps/lists to proper Dart types.
  ///
  /// This is needed because `dartify()` may return `IdentityMap` instances
  /// for nested objects which don't behave like regular Dart maps.
  Map<String, dynamic> _deepConvertMap(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      result[entry.key] = _deepConvertValue(entry.value);
    }
    return result;
  }

  /// Recursively converts a value, handling maps and lists.
  dynamic _deepConvertValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _deepConvertMap(value);
    } else if (value is Map) {
      final converted = <String, dynamic>{};
      for (final entry in value.entries) {
        converted[entry.key.toString()] = _deepConvertValue(entry.value);
      }
      return converted;
    } else if (value is List) {
      return value.map(_deepConvertValue).toList();
    }
    return value;
  }
}
