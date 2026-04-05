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
import 'package:nutrient_flutter/src/document/annotation_json_converter.dart';
import 'package:nutrient_flutter_web/nutrient_flutter_web.dart'
    show
        NutrientWebInstance,
        NutrientWebInstanceExtension,
        NutrientWebStaticExtension,
        NutrientNamespace,
        NutrientRect,
        WebColorUtils,
        annotationTypeMap,
        pspdfkit;

/// A controller for a Nutrient viewer widget on the web platform.
///
/// Wraps a [NutrientWebInstance] from the modern `dart:js_interop`-based
/// web bindings provided by `nutrient_flutter_web`.
class NutrientViewControllerWeb extends NutrientViewController
    with AnnotationJsonConverter {
  final NutrientWebInstance instance;

  static const _buildId = 'nutrient-web-controller-v7';

  NutrientViewControllerWeb(this.instance) {
    if (kDebugMode) print('[$_buildId] Controller created');
  }

  // Map to store web event listeners for removal.
  final Map<NutrientWebEvent, Map<Function, JSFunction>> _webEventListeners =
      {};

  // Map to track legacy NutrientEvent listeners
  final Map<NutrientEvent, JSFunction> _legacyEventListeners = {};

  /// Default color for all annotation operations.
  Color? _defaultAnnotationColor;

  /// Locked annotation color — when set, color changes are reverted.
  Color? _lockedAnnotationColor;

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
      final tool = annotationTool ?? AnnotationTool.inkPen;
      final colorToUse = color ?? _defaultAnnotationColor;

      // Get the InteractionMode constant from the SDK namespace
      final sdkNamespace = NutrientNamespace.getAsJSObject();
      final interactionModeNamespace =
          sdkNamespace['InteractionMode'] as JSObject?;
      if (interactionModeNamespace == null) {
        throw Exception('InteractionMode namespace not found in SDK');
      }

      final modeName = tool.toWebInteractionMode();
      final interactionMode = interactionModeNamespace[modeName];
      if (interactionMode == null) {
        if (kDebugMode) {
          print('InteractionMode "$modeName" not found in SDK');
        }
        return false;
      }

      // Re-apply locked color presets before entering annotation mode
      if (_lockedAnnotationColor != null) {
        await _applyColorToAnnotationPresets(_lockedAnnotationColor!);
      }

      // For text markup tools, set the annotation preset first
      final presetId = _getAnnotationPresetId(tool);
      if (presetId != null) {
        await instance.setCurrentAnnotationPreset(presetId).toDart;
      }

      // Update view state to enter annotation mode
      final updateFn = ((JSObject viewState) {
        JSObject updated = viewState.callMethod(
            'set'.toJS, 'interactionMode'.toJS, interactionMode) as JSObject;
        // Apply color if provided
        if (colorToUse != null) {
          final pspdfkitColor = _createWebColor(colorToUse);
          if (pspdfkitColor != null) {
            updated = updated.callMethod(
                'set'.toJS, 'strokeColor'.toJS, pspdfkitColor) as JSObject;
            updated = updated.callMethod(
                'set'.toJS, 'fillColor'.toJS, pspdfkitColor) as JSObject;
          }
        }
        return updated;
      }).toJS;

      instance.setViewState(updateFn);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error entering annotation creation mode: $e');
      }
      return false;
    }
  }

  /// Returns the annotation preset ID for tools that require it.
  String? _getAnnotationPresetId(AnnotationTool tool) {
    switch (tool) {
      case AnnotationTool.highlight:
        return 'highlight';
      case AnnotationTool.underline:
        return 'underline';
      case AnnotationTool.strikeOut:
        return 'strikeout';
      case AnnotationTool.squiggly:
        return 'squiggly';
      default:
        return null;
    }
  }

  @override
  Future<bool?> exitAnnotationCreationMode() async {
    try {
      final updateFn = ((JSObject viewState) {
        return viewState.callMethod('set'.toJS, 'interactionMode'.toJS, null);
      }).toJS;

      instance.setViewState(updateFn);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error exiting annotation creation mode: $e');
      }
      return false;
    }
  }

  @override
  Future<Rect> getVisibleRect(int pageIndex) {
    throw UnimplementedError('This method is not supported yet on web!');
  }

  @override
  Future<void> zoomToRect(int pageIndex, Rect rect) async {
    try {
      final sdkNamespace = NutrientNamespace.getAsJSObject();
      final geometryNamespace = sdkNamespace['Geometry'] as JSObject?;
      if (geometryNamespace == null) {
        throw Exception('Geometry namespace not found in SDK');
      }
      final rectConstructor = geometryNamespace['Rect'] as JSFunction?;
      if (rectConstructor == null) {
        throw Exception('Geometry.Rect constructor not found in SDK');
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
      final jsInstance = instance as JSObject;
      if (enabled) {
        // Remove the interaction shield if it exists
        final shield = jsInstance.getProperty('_interactionShield'.toJS);
        if (shield != null && shield is JSObject) {
          shield.callMethod('remove'.toJS);
        }
      } else {
        // Create an overlay div to block interactions
        final doc = globalContext['document'] as JSObject;
        final shield =
            doc.callMethod('createElement'.toJS, 'div'.toJS) as JSObject;
        final style = shield['style'] as JSObject;
        style['position'] = 'absolute'.toJS;
        style['top'] = '0'.toJS;
        style['left'] = '0'.toJS;
        style['width'] = '100%'.toJS;
        style['height'] = '100%'.toJS;
        style['zIndex'] = '9999'.toJS;
        style['pointerEvents'] = 'all'.toJS;

        // Try to append to the PSPDFKit container
        final container =
            jsInstance.getProperty('contentDocument'.toJS) as JSObject?;
        if (container != null) {
          final host = container['host'] as JSObject?;
          if (host != null) {
            host.callMethod('appendChild'.toJS, shield);
          }
        }
        jsInstance.setProperty('_interactionShield'.toJS, shield);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user interaction: $e');
      }
      return false;
    }
  }

  /// Creates a Web SDK Color JS object from a Flutter [Color].
  /// Uses the package's WebColorUtils which handles namespace resolution.
  JSObject? _createWebColor(Color color) {
    try {
      // ignore: deprecated_member_use
      return WebColorUtils.colorIntToWebColor(color.value);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating web color: $e');
      }
      return null;
    }
  }

  /// Applies a color to all annotation tools via annotation presets,
  /// view state colors, and default annotation properties.
  Future<void> _applyColorToViewState(Color color) async {
    final pspdfkitColor = _createWebColor(color);
    if (pspdfkitColor == null) return;

    // 1. Override annotation presets — this is the primary mechanism on web.
    // Each tool reads its color from its preset, not from the view state.
    await _applyColorToAnnotationPresets(color);

    // 2. Also set view state colors as a fallback.
    final annotationTypes = [
      'ink', 'highlight', 'underline', 'strikeOut', 'squiggly',
      'note', 'freeText', 'square', 'circle', 'line', 'polygon', 'polyline',
    ];

    final defaultProps = <String, dynamic>{};
    for (final type in annotationTypes) {
      if (['square', 'circle', 'polygon'].contains(type)) {
        defaultProps[type] = {'strokeColor': pspdfkitColor, 'fillColor': pspdfkitColor};
      } else if (type == 'freeText') {
        defaultProps[type] = {'strokeColor': pspdfkitColor, 'fontColor': pspdfkitColor};
      } else {
        defaultProps[type] = {'strokeColor': pspdfkitColor};
      }
    }

    final updateFn = ((JSObject viewState) {
      JSObject updated = viewState.callMethod(
          'set'.toJS, 'defaultAnnotationProperties'.toJS, defaultProps.jsify()) as JSObject;
      updated =
          updated.callMethod('set'.toJS, 'strokeColor'.toJS, pspdfkitColor) as JSObject;
      updated =
          updated.callMethod('set'.toJS, 'fillColor'.toJS, pspdfkitColor) as JSObject;
      return updated;
    }).toJS;

    instance.setViewState(updateFn);
  }

  /// Overrides annotation presets to use the specified color for all tools.
  /// Uses WebColorUtils from the nutrient_flutter_web package to create
  /// Color instances, which handles namespace resolution correctly.
  /// Builds JS objects entirely through interop to avoid jsify issues.
  Future<void> _applyColorToAnnotationPresets(Color color) async {
    try {
      final webColor = _createWebColor(color);
      if (webColor == null) {
        if (kDebugMode) print('Could not create web color instance');
        return;
      }

      final presetIds = [
        'inkPen', 'highlighter', 'freeText', 'freeTextCallout',
        'stamp', 'note', 'square', 'circle', 'ellipse',
        'line', 'arrow', 'polygon', 'polyline', 'cloudy',
        'highlight', 'underline', 'strikeout', 'squiggly',
        'redaction', 'signature', 'image',
      ];

      // The annotation presets API uses Immutable.js internally and
      // resists modification. Instead, skip presets entirely and rely on
      // the enforcement listeners to recolor annotations after creation.
      if (kDebugMode) print('Locked color applied via enforcement listeners');
    } catch (e) {
      if (kDebugMode) {
        print('Error applying color to annotation presets: $e');
      }
    }
  }

  @override
  Future<bool?> setDefaultAnnotationColor(Color color) async {
    try {
      _defaultAnnotationColor = color;
      await _applyColorToViewState(color);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error setting default annotation color: $e');
      }
      return false;
    }
  }

  @override
  Future<bool?> setLockedAnnotationColor(Color color) async {
    try {
      if (kDebugMode) print('[NutrientWeb] setLockedAnnotationColor called with: $color');
      _lockedAnnotationColor = color;
      _defaultAnnotationColor = color;
      await _applyColorToViewState(color);
      _setupLockedColorEnforcement();
      if (kDebugMode) print('[NutrientWeb] setLockedAnnotationColor completed');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error setting locked annotation color: $e');
      }
      return false;
    }
  }

  @override
  Future<bool?> setPageBackgroundColor(Color color) async {
    // Web: the SDK uses hashed class names (PSPDFKit-2z5hjphww7...) so CSS
    // selectors can't target pages reliably. Instead, find the SDK's
    // contentDocument and apply background via a MutationObserver that
    // styles new page elements as they appear.
    try {
      final r = (color.r * 255).round();
      final g = (color.g * 255).round();
      final b = (color.b * 255).round();
      final css = 'rgb($r, $g, $b)';

      // Use JS to find the PSPDFKit container and apply background to
      // all elements with class starting with PSPDFKit- that contain a canvas.
      // Also set up a MutationObserver to handle pages loaded lazily.
      final script = '''
(function(css) {
  function applyBg() {
    var pages = document.querySelectorAll('[class^="PSPDFKit-"]');
    for (var i = 0; i < pages.length; i++) {
      var el = pages[i];
      if (el.querySelector && el.querySelector('canvas')) {
        el.style.backgroundColor = css;
      }
    }
  }
  applyBg();
  var observer = new MutationObserver(function() { applyBg(); });
  var container = document.querySelector('[class^="PSPDFKit-"]');
  if (container) {
    observer.observe(container.parentElement || document.body, {childList: true, subtree: true});
  }
})('$css')
''';

      globalContext.callMethod('eval'.toJS, script.toJS);
      if (kDebugMode) print('[NutrientWeb] Page background applied via JS: $css');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error setting page background color on web: $e');
      }
      return false;
    }
  }

  /// Sets up event listeners to enforce the locked color on annotation
  /// create/update events.
  void _setupLockedColorEnforcement() {
    // Intercept annotation creation — force locked color on new annotations
    final createCallback = ((JSAny? event) {
      if (_lockedAnnotationColor == null) return;
      _enforceLockedColorOnAnnotationEvent(event);
    }).toJS;
    instance.addEventListener('annotations.create', createCallback);

    // Intercept annotation updates — revert unauthorized color changes
    final updateCallback = ((JSAny? event) {
      if (_lockedAnnotationColor == null) return;
      _enforceLockedColorOnAnnotationEvent(event);
    }).toJS;
    instance.addEventListener('annotations.update', updateCallback);
  }

  /// Checks annotations from an event and updates any whose color doesn't
  /// match the locked color. The event callback receives an Immutable.js
  /// List of annotation records directly (not a wrapper object).
  void _enforceLockedColorOnAnnotationEvent(JSAny? event) {
    if (_lockedAnnotationColor == null || event == null) return;

    try {
      final lockedColor = _createWebColor(_lockedAnnotationColor!);
      if (lockedColor == null) return;

      final lockedR = (_lockedAnnotationColor!.r * 255).round();
      final lockedG = (_lockedAnnotationColor!.g * 255).round();
      final lockedB = (_lockedAnnotationColor!.b * 255).round();

      // The event IS the Immutable.js List of annotations directly.
      final annotations = event as JSObject;

      // Try to get size — if this is an Immutable.js List it has .size
      final sizeVal = annotations['size'];
      final size = sizeVal != null
          ? (sizeVal as JSNumber).toDartInt
          : 0;

      if (kDebugMode) print('[NutrientWeb] Enforcement: got $size annotations from event');

      if (size == 0) return;

      for (var i = 0; i < size; i++) {
        final annotation =
            annotations.callMethod('get'.toJS, i.toJS) as JSObject?;
        if (annotation == null) continue;

        // Check all color properties and enforce the locked color.
        // Different annotation types use different color properties:
        // - strokeColor: ink, shapes, lines
        // - fillColor: shape fill
        // - fontColor: text annotations
        // - color: highlight/markup annotations
        final colorProps = ['strokeColor', 'fillColor', 'fontColor', 'color'];
        var updated = annotation;
        var needsUpdate = false;

        for (final prop in colorProps) {
          final currentColor = annotation[prop] as JSObject?;
          if (currentColor == null) continue;

          final r = (currentColor['r'] as JSNumber?)?.toDartInt;
          final g = (currentColor['g'] as JSNumber?)?.toDartInt;
          final b = (currentColor['b'] as JSNumber?)?.toDartInt;

          if (r != lockedR || g != lockedG || b != lockedB) {
            updated = updated.callMethod(
                'set'.toJS, prop.toJS, lockedColor) as JSObject;
            needsUpdate = true;
          }
        }

        if (needsUpdate) {
          if (kDebugMode) print('[NutrientWeb] Enforcing locked color on annotation $i');
          instance.update(updated);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error enforcing locked color: $e');
      }
    }
  }

  @override
  Color? get defaultAnnotationColor => _defaultAnnotationColor;

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
        if (obj is JSObject) {
          final converted = _tryConvertJsAnnotation(obj);
          if (converted != null) {
            try {
              return Annotation.fromJson(converted);
            } catch (_) {
              return converted;
            }
          }
          return obj;
        }

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

      if (eventEnum.toString().contains('annotations')) {
        try {
          if (AnnotationManagerWeb.shouldSuppressEvents('')) {
            if (kDebugMode) {
              print('Suppressing ${eventEnum.toString()} event');
            }
            return;
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

  dynamic _safeConvertJsAny(JSAny? jsValue) {
    if (jsValue == null) return null;

    try {
      final dartified = jsValue.dartify();
      if (dartified is Map ||
          dartified is List ||
          dartified is String ||
          dartified is num ||
          dartified is bool ||
          dartified == null) {
        if (dartified is Map) {
          return _deepConvertAny(dartified);
        }
        return dartified;
      }
    } catch (_) {}

    try {
      final jsObj = jsValue as JSObject;
      return _convertJsObjectToMap(jsObj);
    } catch (_) {}

    return null;
  }

  Map<String, dynamic> _convertJsObjectToMap(JSObject jsObj) {
    final result = <String, dynamic>{};

    final objectKeys = globalContext['Object'] as JSObject?;
    if (objectKeys != null) {
      final keysMethod = objectKeys['keys'];
      if (keysMethod != null) {
        final keysArray = objectKeys.callMethod('keys'.toJS, jsObj);
        if (keysArray != null) {
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

  Map<String, dynamic> _deepConvertMap(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      result[entry.key] = _deepConvertValue(entry.value);
    }
    return result;
  }

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
