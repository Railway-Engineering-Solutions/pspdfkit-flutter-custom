///
///  Copyright @2023-2025 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.
///

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';
import 'package:nutrient_flutter/src/document/document_save_options_extension.dart';
import 'nutrient_web_utils.dart';

/// This class is used to interact with a
/// [PSPDFKit.Instance](https://www.nutrient.io/api/web/PSPDFKit.Instance.html) in
/// PSPDFKit Web SDK.
/// It is returned by [PSPDFKit.load].
class NutrientWebInstance {
  final JsObject _nutrientInstance;

  /// Default color for all annotation operations
  /// This color will be used when no specific color is provided
  Color? _defaultAnnotationColor;

  NutrientWebInstance(this._nutrientInstance) {
    // Set up event listeners to monitor annotation creation mode changes
    _setupColorInterceptionListeners();
  }

  List<String> get availableDocumentInfoKeys {
    return _nutrientInstance.callMethod('getAvailableDocumentInfoKeys');
  }

  /// Returns the PSPDFKitInstance JsObject.
  JsObject get jsObject => _nutrientInstance;

  /// Sets the default color for all annotation operations.
  /// This color will be used when no specific color is provided to annotation methods.
  ///
  /// Example:
  /// ```dart
  /// await instance.setDefaultAnnotationColor(Colors.red);
  /// // Now all annotations will use red color by default
  /// ```
  Future<void> setDefaultAnnotationColor(Color color) async {
    _defaultAnnotationColor = color;

    // Apply the color to PSPDFKit using setViewState with defaultAnnotationProperties
    try {
      // Try multiple approaches to get the Color class
      var colorClass = _getPSPDFKitColorClass();
      if (colorClass == null) {
        if (kDebugMode) {
          print(
              'PSPDFKit Color class not available, trying alternative approach');
        }
        // Try alternative approach using direct color object creation
        await _setDefaultColorAlternative(color);
        return;
      }

      var pspdfkitColor = JsObject(colorClass, [
        JsObject.jsify({
          'r': (color.r * 255).round(),
          'g': (color.g * 255).round(),
          'b': (color.b * 255).round(),
        })
      ]);

      // Set default annotation properties using setViewState
      await promiseToFuture(_nutrientInstance.callMethod('setViewState', [
        allowInterop((viewState) {
          // Create default annotation properties with the color
          var defaultProps = JsObject.jsify({
            'ink': {
              'strokeColor': pspdfkitColor,
              'lineWidth': 2,
            },
            'highlight': {
              'strokeColor': pspdfkitColor,
            },
            'underline': {
              'strokeColor': pspdfkitColor,
            },
            'strikeOut': {
              'strokeColor': pspdfkitColor,
            },
            'squiggly': {
              'strokeColor': pspdfkitColor,
            },
            'note': {
              'strokeColor': pspdfkitColor,
            },
            'freeText': {
              'strokeColor': pspdfkitColor,
            },
            'square': {
              'strokeColor': pspdfkitColor,
              'fillColor': pspdfkitColor,
            },
            'circle': {
              'strokeColor': pspdfkitColor,
              'fillColor': pspdfkitColor,
            },
            'line': {
              'strokeColor': pspdfkitColor,
            },
            'polygon': {
              'strokeColor': pspdfkitColor,
              'fillColor': pspdfkitColor,
            },
            'polyline': {
              'strokeColor': pspdfkitColor,
            },
          });

          // Update the view state with default annotation properties
          return viewState
              .callMethod('set', ['defaultAnnotationProperties', defaultProps]);
        })
      ]));

      // Also set the current stroke and fill colors in the view state
      // This ensures the color is immediately available for the current tool mode
      await promiseToFuture(_nutrientInstance.callMethod('setViewState', [
        allowInterop((viewState) {
          var updatedState =
              viewState.callMethod('set', ['strokeColor', pspdfkitColor]);
          updatedState =
              updatedState.callMethod('set', ['fillColor', pspdfkitColor]);
          return updatedState;
        })
      ]));

      if (kDebugMode) {
        print('Default annotation color set to: $color');
        print(
            'Applied to PSPDFKit using defaultAnnotationProperties and current colors');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error applying default color to PSPDFKit: $e');
      }
      // Still store the color even if PSPDFKit application fails
    }
  }

  /// Gets the current default annotation color.
  Color? get defaultAnnotationColor => _defaultAnnotationColor;

  /// Tries multiple approaches to get the NutrientViewer Color class
  dynamic _getPSPDFKitColorClass() {
    try {
      // Approach 1: Try to get Color class from the NutrientViewer instance
      var instanceColorClass = _nutrientInstance['Color'];
      if (instanceColorClass != null) {
        if (kDebugMode) {
          print('Found NutrientViewer Color class from instance');
        }
        return instanceColorClass;
      }

      // Approach 2: Try to get Color class from global NutrientViewer (correct global object)
      var globalColorClass = context['NutrientViewer']?['Color'];
      if (globalColorClass != null) {
        if (kDebugMode) {
          print('Found NutrientViewer Color class from global context');
        }
        return globalColorClass;
      }

      // Approach 3: Try to get Color class from global PSPDFKit (fallback)
      var pspdfkitColorClass = context['PSPDFKit']?['Color'];
      if (pspdfkitColorClass != null) {
        if (kDebugMode) {
          print('Found PSPDFKit Color class from global context');
        }
        return pspdfkitColorClass;
      }

      // Approach 4: Try to access Color class through the instance's constructor
      var instanceConstructor = _nutrientInstance['constructor'];
      if (instanceConstructor != null) {
        var constructorColorClass = instanceConstructor['Color'];
        if (constructorColorClass != null) {
          if (kDebugMode) {
            print('Found Color class from instance constructor');
          }
          return constructorColorClass;
        }
      }

      if (kDebugMode) {
        print('Color class not found in any location');
        print(
            'NutrientViewer object available: ${context['NutrientViewer'] != null}');
        print('PSPDFKit object available: ${context['PSPDFKit'] != null}');
        print('Instance object available: true');
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error accessing Color class: $e');
      }
      return null;
    }
  }

  /// Alternative approach to set default color when Color class is not available
  Future<void> _setDefaultColorAlternative(Color color) async {
    try {
      if (kDebugMode) {
        print('Using alternative color setting approach');
      }

      // Create a simple color object that PSPDFKit might accept
      var colorObject = JsObject.jsify({
        'r': (color.r * 255).round(),
        'g': (color.g * 255).round(),
        'b': (color.b * 255).round(),
        'a': 1.0,
      });

      // Try to set the color using the instance's setViewState method
      await promiseToFuture(_nutrientInstance.callMethod('setViewState', [
        allowInterop((viewState) {
          var updatedState =
              viewState.callMethod('set', ['strokeColor', colorObject]);
          updatedState =
              updatedState.callMethod('set', ['fillColor', colorObject]);
          return updatedState;
        })
      ]));

      if (kDebugMode) {
        print('Alternative color setting completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Alternative color setting failed: $e');
      }
    }
  }

  /// Sets up event listeners to intercept annotation creation mode changes
  /// and automatically apply the default color
  void _setupColorInterceptionListeners() {
    try {
      // Listen for view state changes to detect when annotation creation mode is entered
      _nutrientInstance.callMethod('addEventListener', [
        'viewStateChange',
        allowInterop((dynamic event) {
          try {
            // Check if we have a default color and if annotation creation mode is active
            if (_defaultAnnotationColor != null && event != null) {
              var viewState = event['viewState'];
              if (viewState != null) {
                var interactionMode = viewState['interactionMode'];

                // Check if we're in an annotation creation mode
                if (interactionMode != null &&
                    interactionMode.toString().contains('Annotation')) {
                  // Apply the default color to the current tool
                  _applyDefaultColorToCurrentTool();
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error in viewStateChange listener: $e');
            }
          }
        })
      ]);

      // Also listen for annotation creation events to ensure color is applied
      _nutrientInstance.callMethod('addEventListener', [
        'annotations.create',
        allowInterop((dynamic event) {
          try {
            // When an annotation is created, ensure the default color is applied
            if (_defaultAnnotationColor != null) {
              _ensureDefaultColorApplied();
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error in annotations.create listener: $e');
            }
          }
        })
      ]);

      if (kDebugMode) {
        print('Color interception listeners set up successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Could not set up color interception listeners: $e');
      }
    }
  }

  /// Applies the default color to the current annotation tool
  void _applyDefaultColorToCurrentTool() {
    try {
      if (_defaultAnnotationColor == null) return;

      // Get the current view state
      var currentViewState = _nutrientInstance['viewState'];
      if (currentViewState != null) {
        var interactionMode = currentViewState['interactionMode'];

        if (interactionMode != null) {
          // Convert PSPDFKit interaction mode back to Flutter AnnotationTool
          var toolMode = _getAnnotationToolFromInteractionMode(interactionMode);
          if (toolMode != null) {
            // Apply the default color
            _applyColorToTool(toolMode, _defaultAnnotationColor!);

            if (kDebugMode) {
              print('Applied default color to current tool: $toolMode');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error applying default color to current tool: $e');
      }
    }
  }

  /// Ensures the default color is applied to the current annotation tool
  void _ensureDefaultColorApplied() {
    try {
      if (_defaultAnnotationColor == null) return;

      // Force apply the default color using the ViewState API
      promiseToFuture(_nutrientInstance.callMethod('setViewState', [
        allowInterop((viewState) {
          var colorClass = _getPSPDFKitColorClass();
          if (colorClass != null) {
            var pspdfkitColor = JsObject(colorClass, [
              JsObject.jsify({
                'r': (_defaultAnnotationColor!.r * 255).round(),
                'g': (_defaultAnnotationColor!.g * 255).round(),
                'b': (_defaultAnnotationColor!.b * 255).round(),
              })
            ]);

            var updatedState =
                viewState.callMethod('set', ['strokeColor', pspdfkitColor]);
            updatedState =
                updatedState.callMethod('set', ['fillColor', pspdfkitColor]);

            return updatedState;
          } else {
            if (kDebugMode) {
              print(
                  'PSPDFKit Color class not available, skipping color application');
            }
            return viewState;
          }
        })
      ]));
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring default color applied: $e');
      }
    }
  }

  /// Converts PSPDFKit interaction mode to Flutter AnnotationTool
  AnnotationTool? _getAnnotationToolFromInteractionMode(
      dynamic interactionMode) {
    try {
      String modeString = interactionMode.toString();

      // Map PSPDFKit interaction modes to Flutter AnnotationTool
      if (modeString.contains('Ink')) return AnnotationTool.inkPen;
      if (modeString.contains('Highlight')) return AnnotationTool.highlight;
      if (modeString.contains('Underline')) return AnnotationTool.underline;
      if (modeString.contains('StrikeOut')) return AnnotationTool.strikeOut;
      if (modeString.contains('Squiggly')) return AnnotationTool.squiggly;
      if (modeString.contains('Note')) return AnnotationTool.note;
      if (modeString.contains('FreeText')) return AnnotationTool.freeText;
      if (modeString.contains('Square')) return AnnotationTool.square;
      if (modeString.contains('Circle')) return AnnotationTool.circle;
      if (modeString.contains('Line')) return AnnotationTool.line;
      if (modeString.contains('Polygon')) return AnnotationTool.polygon;
      if (modeString.contains('Polyline')) return AnnotationTool.polyline;

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error converting interaction mode: $e');
      }
      return null;
    }
  }

  /// Saves the current state of the PSPDFKit instance.
  /// Throws an error if the operation fails.
  Future<void> save() async {
    try {
      await promiseToFuture(_nutrientInstance.callMethod('save'));
    } catch (e) {
      throw Exception('Failed to save document: $e');
    }
  }

  /// Adds an annotation to the document.
  ///
  /// The annotation is passed as a [Map<String, dynamic>].
  /// The object structure should be the same as the one returned by
  /// `PSPDFKit.Annotations.toSerializableObject` in Nutrient Web SDK.
  ///
  ///Throws an error if the operation fails.
  Future<void> addAnnotation(Map<String, dynamic> jsonAnnotation,
      [Map<String, dynamic>? attachment]) async {
    try {
      var annotation = context['PSPDFKit']['Annotations'].callMethod(
          'fromSerializableObject', [JsObject.jsify(jsonAnnotation)]);
      await promiseToFuture(
          _nutrientInstance.callMethod('create', [annotation]));
    } catch (e) {
      throw Exception('Failed to add annotation: $e');
    }
  }

  /// Updates an annotation in the document.
  ///
  /// The annotation is passed as a [Map<String, dynamic>].
  /// The object structure should be the same as the one returned by
  /// `PSPDFKit.Annotations.toSerializableObject` in PSPDFKit for Web.
  ///
  /// Throws an error if the operation fails.
  ///
  /// @deprecated Use [updateAnnotationProperties] instead for safer updates
  /// that preserve attachment data and other properties.
  @Deprecated(
      'Use updateAnnotationProperties instead - this method may lose attachment data')
  Future<void> updateAnnotation(Map<String, dynamic> jsonAnnotation) async {
    try {
      await removeAnnotation(jsonAnnotation)
          .then((value) => addAnnotation(jsonAnnotation));
    } catch (e) {
      throw Exception('Failed to update annotation: $e');
    }
  }

  /// Updates specific properties of an annotation while preserving all other data.
  ///
  /// This method safely updates only the specified properties in [updatedProperties]
  /// while maintaining all other annotation data including attachments, custom data,
  /// and properties not included in the update.
  ///
  /// The [updatedProperties] map should contain the annotation's id and pageIndex
  /// along with any properties to update.
  ///
  /// Returns a [Future] that completes when the update is successful.
  /// Throws an error if the operation fails.
  Future<void> updateAnnotationProperties(
      Map<String, dynamic> updatedProperties) async {
    try {
      // Get the annotation id and page index
      final annotationId = updatedProperties['id'] ?? updatedProperties['name'];
      final pageIndex = updatedProperties['pageIndex'];

      if (annotationId == null || pageIndex == null) {
        throw ArgumentError('Annotation id and pageIndex are required');
      }

      // Get the existing annotation first
      var annotations = await _getRawAnnotations(pageIndex);
      JsObject? existingAnnotation;

      if (annotations != null && annotations['size'] != null) {
        for (var i = 0; i < annotations['size']; i++) {
          var annotation = annotations.callMethod('get', [i]);
          var annotationJson = webAnnotationToJSON(annotation);
          if (annotationJson['id'] == annotationId ||
              annotationJson['name'] == annotationId) {
            existingAnnotation = annotation;
            break;
          }
        }
      }

      if (existingAnnotation == null) {
        throw Exception('Annotation not found with id: $annotationId');
      }

      // Create an updated annotation by merging properties
      // The Nutrient Web SDK uses Immutable.js, so we need to chain set() calls
      // for each property we want to update
      var updatedAnnotation = existingAnnotation;

      // Update each property individually
      updatedProperties.forEach((key, value) {
        // Skip id and pageIndex as they shouldn't be changed
        if (key != 'id' && key != 'pageIndex' && key != 'name') {
          // Map property names to Web SDK expected names
          var webKey = key;
          if (key == 'lineWidth') {
            // The Web SDK uses 'strokeWidth' for line width
            webKey = 'strokeWidth';
          } else if (key == 'contents') {
            // The Web SDK uses 'text' for contents
            webKey = 'text';
          } else if (key == 'creator') {
            // The Web SDK uses 'creatorName' for creator
            webKey = 'creatorName';
          }

          // Handle color properties specially - they need to be PSPDFKit.Color instances
          if ((webKey == 'strokeColor' || webKey == 'fillColor') &&
              value is Map) {
            // Create a PSPDFKit.Color instance
            var colorClass = context['PSPDFKit']['Color'];
            value = JsObject(colorClass, [
              JsObject.jsify({
                'r': value['r'] ?? 0,
                'g': value['g'] ?? 0,
                'b': value['b'] ?? 0,
                'a': value['a'] ?? 255,
              })
            ]);
          }

          // Handle flags specially - convert to appropriate format
          if (key == 'flags' && value is List) {
            // The Web SDK expects flags as individual boolean properties
            // Map Flutter flag names to Web SDK property names
            final flagsList = List<String>.from(value);

            // Define all possible flags and their Web SDK property names
            final flagMappings = {
              'readOnly': 'readOnly',
              'locked': 'locked',
              'hidden': 'hidden',
              'invisible': 'invisible',
              'print': 'noPrint', // Note: inverted logic
              'noView': 'noView',
              'noZoom': 'noZoom',
              'noRotate': 'noRotate',
              'toggleNoView': 'toggleNoView',
              'lockedContents': 'lockedContents',
            };

            // Set or unset each flag based on whether it's in the list
            flagMappings.forEach((flutterFlag, webFlag) {
              if (flagsList.contains(flutterFlag)) {
                // Special handling for 'print' flag which has inverted logic
                if (flutterFlag == 'print') {
                  updatedAnnotation =
                      updatedAnnotation.callMethod('set', [webFlag, false]);
                } else {
                  updatedAnnotation =
                      updatedAnnotation.callMethod('set', [webFlag, true]);
                }
              } else {
                // Flag is not in the list, so it should be unset
                // Special handling for 'print' flag which has inverted logic
                if (flutterFlag == 'print') {
                  updatedAnnotation =
                      updatedAnnotation.callMethod('set', [webFlag, true]);
                } else {
                  updatedAnnotation =
                      updatedAnnotation.callMethod('set', [webFlag, false]);
                }
              }
            });
          } else if (key != 'flags') {
            // For non-flag properties, use the mapped key
            updatedAnnotation =
                updatedAnnotation.callMethod('set', [webKey, value]);
          }
        }
      });

      // Apply the update using the instance's update method
      await promiseToFuture(
          _nutrientInstance.callMethod('update', [updatedAnnotation]));
    } catch (e) {
      throw Exception('Failed to update annotation properties: $e');
    }
  }

  /// Returns a list of all annotations on the given page.
  /// The return annotations are in the [Instant JSON](https://www.nutrient.io/guides/web/json/) format.
  /// [pageIndex] is the index of the page to get the annotations from.
  /// Returns a [Future] that completes with the list of annotations.
  Future<dynamic> getAnnotations(int pageIndex,
      [String? annotationType]) async {
    var annotations = await _getRawAnnotations(pageIndex);
    var annotationJSON = <dynamic>[];

    // Check if annotations has a 'size' property (Immutable.js List)
    if (annotations != null && annotations['size'] != null) {
      for (var i = 0; i < annotations['size']; i++) {
        var annotation = annotations.callMethod('get', [i]);

        var ann = webAnnotationToJSON(annotation);

        if (annotationType != null) {
          if (ann['type'] == annotationType ||
              annotationType == 'pspdfkit/all') {
            annotationJSON.add(ann);
            continue;
          }
        } else {
          annotationJSON.add(ann);
        }
      }
    }
    return annotationJSON;
  }

  Future<dynamic> _getRawAnnotations(int pageIndex) async {
    var annotationPromise =
        await _nutrientInstance.callMethod('getAnnotations', [pageIndex]);
    return await promiseToFuture(annotationPromise);
  }

  /// Applies the given Instant JSON string to the document.
  /// Returns a Future that completes with a boolean indicating whether the operation was successful.
  /// The [annotationsJson] parameter is a String or Map containing the Instant JSON data to apply.
  /// Throws an error if the operation fails.
  ///
  Future<void> applyInstantJson(dynamic annotationsJson) async {
    Map<String, dynamic> instantJsonObject;
    if (annotationsJson is String) {
      instantJsonObject = jsonDecode(annotationsJson);
    } else if (annotationsJson is Map<String, dynamic>) {
      instantJsonObject = annotationsJson;
    } else {
      throw ArgumentError(
          'annotationsJson must be a String or a Map<String, dynamic>');
    }
    var operations = [
      {'type': 'applyInstantJson', 'instantJson': instantJsonObject}
    ];
    await applyOperations(operations);
  }

  /// Asynchronously exports the Instant JSON representation of the current document.
  /// Returns a [String] containing the Instant JSON data, or throws an exception if the export failed.
  Future<String?> exportInstantJson() async {
    var annotationsJsonPromise =
        await _nutrientInstance.callMethod('exportInstantJSON');
    JsObject instant = await promiseToFuture(annotationsJsonPromise);
    return jsonEncode(instant.toJson());
  }

  /// Imports XFDF annotations from a file path.
  /// Returns a Future that completes with a boolean value indicating whether the import was successful or not.
  /// The [xfdfPath] parameter is a String representing the file path of the XFDF file to import.
  /// The [ignorePageRotation] parameter is an optional boolean value indicating whether to ignore page rotation when importing annotations.
  /// Throws an error if the operation fails.
  Future<void> importXfdf(String xfdfPath, [bool? ignorePageRotation]) async {
    var operation = [
      {
        'type': 'applyXfdf',
        'xfdf': xfdfPath,
        'ignorePageRotation': ignorePageRotation ?? false,
      }
    ];
    try {
      await applyOperations(operation);
    } catch (e) {
      throw Exception('Failed to import XFDF: $e');
    }
  }

  /// Exports the current document as XFDF (XML Forms Data Format).
  ///
  /// The [xfdfPath] parameter is a String representing the file path of the XFDF file to export.
  /// Throws an error if the operation fails.
  Future<void> exportXfdf(
    String xfdfPath,
  ) async {
    try {
      var xfdf =
          await promiseToFuture(_nutrientInstance.callMethod('exportXFDF'));
      // Download the XFDF file to the provided path.
      var blob = Blob([xfdf], 'application/vnd.adobe.xfdf');
      var url = Url.createObjectUrlFromBlob(blob);
      var anchor = AnchorElement(href: url);
      anchor.download = xfdfPath;
      anchor.click();
    } catch (e) {
      throw Exception('Failed to export XFDF: $e');
    }
  }

  /// Retrieves all annotations in the document.
  /// Returns a [Future] that completes with a list of unsaved annotations.
  /// The annotations are retrieved asynchronously.
  Future<dynamic> getAllAnnotations() async {
    var json = await exportInstantJson();
    if (json == null) return {};
    var annotationsJson = jsonDecode(json);
    return annotationsJson;
  }

  /// Removes the specified annotation from the PDF document.
  ///
  /// The [jsonAnnotation] parameter should be a JSON representation of the annotation to be removed.
  /// Throws an error if the operation fails.
  Future<void> removeAnnotation(dynamic jsonAnnotation) async {
    try {
      if (jsonAnnotation is String) {
        jsonAnnotation = jsonDecode(jsonAnnotation);
      }
      var annotationId = jsonAnnotation['id'];
      var pageIndex = jsonAnnotation['pageIndex'];
      var name = jsonAnnotation['name'];

      JsObject rawAnnotations = await _getRawAnnotations(pageIndex);

      for (var i = 0; i < rawAnnotations['size']; i++) {
        var annotation = rawAnnotations.callMethod('get', [i]);

        if ((annotation['id'] == annotationId &&
                annotation['pageIndex'] == pageIndex) ||
            (annotation['name'] == name &&
                annotation['pageIndex'] == pageIndex)) {
          await _nutrientInstance.callMethod('delete', [annotation]);
        }
      }

      // Remove the annotation from the PDF document.
    } catch (e) {
      throw Exception('Failed to remove annotation: $e');
    }
  }

  /// Removes multiple annotations from the PDF document.
  Future<void> removeAnnotations(List<dynamic> jsonAnnotations) async {
    try {
      var ids = jsonAnnotations.map((e) => e['id']).toList();
      await _nutrientInstance.callMethod('delete', [ids]);
    } catch (e) {
      throw Exception('Failed to remove annotations: $e');
    }
  }

  /// Sets the value of a form field.
  ///
  /// This method allows you to programmatically set the value of a form field in the PSPDFKit Web instance.
  /// The form field is identified by its name or ID.
  ///
  /// Example usage:
  /// ```dart
  /// await setFormFieldValue('username', 'John Doe');
  /// ```
  ///
  /// Throws an Exception if an error occurs while setting the form field value.
  Future<void> setFormFieldValue(
      String value, String fullyQualifiedName) async {
    var formValues = {
      fullyQualifiedName: value,
    };
    return setFormFieldValues(formValues);
  }

  /// Sets the values of form fields in the PDF document.
  ///
  /// The [formValues] parameter is a map where the keys represent the field names
  /// and the values represent the new values to be set for each field.
  ///
  /// Throws an error if the operation fails.
  Future<void> setFormFieldValues(Map<String, String> formValues) async {
    try {
      await promiseToFuture(_nutrientInstance.callMethod('setFormFieldValues', [
        JsObject.jsify(formValues),
      ]));
    } catch (e) {
      throw Exception('Failed to set form field values: $e');
    }
  }

  /// Retrieves the value of a form field with the specified fully qualified name.
  /// The [fullyQualifiedName] parameter is the fully qualified name of the form field.
  /// Returns a [Future] that completes with the value of the form field, or `null` if the form field is not found.
  Future<String?> getFormFieldValue(String fullyQualifiedName) async {
    JsObject values = await _nutrientInstance.callMethod('getFormFieldValues');
    return values.toJson()[fullyQualifiedName];
  }

  /// Sets the measurement precision for the PSPDFKit Web instance.
  /// The [precision] parameter specifies the desired measurement precision.
  Future<void> setMeasurementPrecision(MeasurementPrecision precision) async {
    try {
      await promiseToFuture(
          _nutrientInstance.callMethod('setMeasurementPrecision', [
        precision.webName,
      ]));
    } catch (e) {
      throw Exception('Failed to set measurement precision: $e');
    }
  }

  /// Sets the measurement scale for the PSPDFKit Web instance.
  /// The [scale] parameter represents the measurement scale to be set.
  Future<void> setMeasurementScale(MeasurementScale scale) async {
    var webScale = {
      'unitFrom': scale.unitFrom,
      'unitTo': scale.unitTo,
      'fromValue': scale.valueFrom,
      'toValue': scale.valueTo,
    };

    try {
      await promiseToFuture(
          _nutrientInstance.callMethod('setMeasurementScale', [
        JsObject.jsify(webScale),
      ]));
    } catch (e) {
      throw Exception('Failed to set measurement scale: $e');
    }
  }

  /// Applies a list of operations to the PSPDFKit instance.
  /// Returns a Future that completes with the result of the operation.
  /// The operations are represented as a list of maps, where each map represents an operation.
  /// For a full list of supported operations, see the [PSPDFKit.DocumentOperation](https://www.nutrient.io/api/web/PSPDFKit.DocumentOperation.html) API reference.
  /// The operation names and arguments are specific to the PSPDFKit API.
  /// Throws an error if the operation fails.
  Future<dynamic> applyOperations(List<Map<String, dynamic>> operations) async {
    try {
      await promiseToFuture(_nutrientInstance.callMethod('applyOperations', [
        JsObject.jsify(operations),
      ]));
    } catch (e) {
      throw Exception('Failed to apply operations: $e');
    }
  }

  /// Sets the name of the annotation creator.
  ///
  /// The [name] parameter specifies the name of the annotation creator.
  /// This method is used to set the name of the user who is creating the annotations.
  /// The name will be associated with the annotations created by the user.
  /// Throws an error if the operation fails.
  Future<void> setAnnotationCreatorName(String name) async {
    try {
      await promiseToFuture(
          _nutrientInstance.callMethod('setAnnotationCreatorName', [name]));
    } catch (e) {
      throw Exception('Failed to set annotation creator name: $e');
    }
  }

  /// Sets the tool mode for the PSPDFKit Web instance using the ViewState API.
  ///
  /// The [toolMode] parameter specifies the interaction mode to set.
  /// This can be one of the PSPDFKit.InteractionMode values.
  /// If null is provided, it will reset to the default interaction mode (null).
  /// If [color] is provided, it will be set as the annotation color.
  ///
  /// Throws an error if the operation fails.
  Future<void> setToolMode(AnnotationTool? toolMode, [Color? color]) async {
    try {
      if (toolMode == null) {
        // Reset to default interaction mode (null)
        await promiseToFuture(_nutrientInstance.callMethod('setViewState', [
          allowInterop((viewState) {
            return viewState.callMethod('set', ['interactionMode', null]);
          })
        ]));
      } else {
        // Determine which color to use: provided color, default color, or none
        Color? colorToUse = color ?? _defaultAnnotationColor;

        if (kDebugMode) {
          print('Setting tool mode: ${toolMode.toWebInteractionMode()}');
          print('Using color: ${colorToUse?.toString() ?? "none"}');
          print(
              'Default color available: ${_defaultAnnotationColor?.toString() ?? "none"}');
        }

        // Set the interaction mode using ViewState API
        await promiseToFuture(_nutrientInstance.callMethod('setViewState', [
          allowInterop((viewState) {
            var updatedState = viewState.callMethod('set', [
              'interactionMode',
              context['PSPDFKit']['InteractionMode']
                  [toolMode.toWebInteractionMode()]
            ]);

            // If we have a color (either provided or default), set both stroke and fill colors
            if (colorToUse != null) {
              var colorClass = _getPSPDFKitColorClass();
              if (colorClass != null) {
                var pspdfkitColor = JsObject(colorClass, [
                  JsObject.jsify({
                    'r': (colorToUse.r * 255).round(),
                    'g': (colorToUse.g * 255).round(),
                    'b': (colorToUse.b * 255).round(),
                  })
                ]);

                // Set stroke color (for most annotations)
                updatedState = updatedState
                    .callMethod('set', ['strokeColor', pspdfkitColor]);
                // Also set fill color (for shapes like rectangle, circle, etc.)
                updatedState = updatedState
                    .callMethod('set', ['fillColor', pspdfkitColor]);

                if (kDebugMode) {
                  print(
                      'Applied color to PSPDFKit: strokeColor and fillColor set');
                }
              } else {
                if (kDebugMode) {
                  print(
                      'PSPDFKit Color class not available, skipping color application');
                }
              }
            }

            return updatedState;
          })
        ]));

        // Additional step: Force apply the color using PSPDFKit's style system
        if (colorToUse != null) {
          try {
            await _applyColorToTool(toolMode, colorToUse);
          } catch (e) {
            if (kDebugMode) {
              print(
                  'Warning: Could not apply color to tool via style system: $e');
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to set tool mode: $e');
    }
  }

  /// Applies color to a specific annotation tool using PSPDFKit's style system
  Future<void> _applyColorToTool(AnnotationTool toolMode, Color color) async {
    try {
      // Try to get PSPDFKit Color class using multiple approaches
      var colorClass = _getPSPDFKitColorClass();
      if (colorClass == null) {
        if (kDebugMode) {
          print(
              'PSPDFKit Color class not available, skipping tool color application');
        }
        return;
      }

      // Convert Flutter color to PSPDFKit color
      var pspdfkitColor = JsObject(colorClass, [
        JsObject.jsify({
          'r': (color.r * 255).round(),
          'g': (color.g * 255).round(),
          'b': (color.b * 255).round(),
        })
      ]);

      // Get the style manager if available
      var styleManager = _nutrientInstance['styleManager'];
      if (styleManager != null) {
        // Map Flutter annotation tools to PSPDFKit tool names
        String toolName = toolMode.toWebInteractionMode();

        // Apply color to the tool's style
        styleManager
            .callMethod('setLastUsedValue', [pspdfkitColor, 'color', toolName]);

        if (kDebugMode) {
          print('Applied color to tool $toolName via style manager');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error applying color to tool: $e');
      }
    }
  }

  /// Temporarily hides or shows all annotations in the document.
  ///
  /// This is a visual-only operation - annotations are not removed from the document
  /// and will reappear when [hidden] is set to false.
  ///
  /// [hidden] - true to hide annotations, false to show them
  /// Throws an error if the operation fails.
  Future<void> setAnnotationsHidden(bool hidden) async {
    try {
      await promiseToFuture(_nutrientInstance.callMethod('setViewState', [
        allowInterop((viewState) {
          // PSPDFKit Web requires read-only mode to hide annotations
          // Set both showAnnotations and readOnly
          var updatedState =
              viewState.callMethod('set', ['showAnnotations', !hidden]);

          if (hidden) {
            // When hiding annotations, enable read-only mode
            updatedState = updatedState.callMethod('set', ['readOnly', true]);
          } else {
            // When showing annotations, disable read-only mode
            updatedState = updatedState.callMethod('set', ['readOnly', false]);
          }

          return updatedState;
        })
      ]));
    } catch (e) {
      throw Exception('Failed to set annotations visibility: $e');
    }
  }

  /// Enables or disables user interaction with the PDF viewer.
  /// This completely prevents ALL interaction including clicking on existing annotations.
  /// This is useful for preventing click-through when dialogs are shown over the PDF widget.
  ///
  /// [enabled] - true to enable user interaction, false to disable it.
  /// Throws an error if the operation fails.
  Future<void> setUserInteractionEnabled(bool enabled) async {
    try {
      // Method 1: Use PSPDFKit ViewState API to disable interactions
      await promiseToFuture(_nutrientInstance.callMethod('setViewState', [
        allowInterop((viewState) {
          var updatedState = viewState;

          if (!enabled) {
            // Completely disable all interactions
            updatedState = updatedState.callMethod('set', ['readOnly', true]);
            updatedState =
                updatedState.callMethod('set', ['interactionMode', null]);

            // Disable annotation selection and interaction
            updatedState = updatedState
                .callMethod('set', ['allowAnnotationSelection', false]);
            updatedState = updatedState
                .callMethod('set', ['allowAnnotationEditing', false]);
            updatedState = updatedState
                .callMethod('set', ['allowAnnotationCreation', false]);

            // Disable text selection and other interactions
            updatedState =
                updatedState.callMethod('set', ['allowTextSelection', false]);
            updatedState = updatedState
                .callMethod('set', ['allowFormFieldEditing', false]);

            // Disable zoom and pan
            updatedState =
                updatedState.callMethod('set', ['allowZooming', false]);
            updatedState =
                updatedState.callMethod('set', ['allowPanning', false]);

            // Disable page navigation
            updatedState =
                updatedState.callMethod('set', ['allowPageNavigation', false]);

            // Additional interaction disabling
            updatedState = updatedState
                .callMethod('set', ['allowAnnotationMoving', false]);
            updatedState = updatedState
                .callMethod('set', ['allowAnnotationResizing', false]);
            updatedState = updatedState
                .callMethod('set', ['allowAnnotationDeletion', false]);
          } else {
            // Re-enable all interactions
            updatedState = updatedState.callMethod('set', ['readOnly', false]);
            updatedState = updatedState
                .callMethod('set', ['allowAnnotationSelection', true]);
            updatedState = updatedState
                .callMethod('set', ['allowAnnotationEditing', true]);
            updatedState = updatedState
                .callMethod('set', ['allowAnnotationCreation', true]);
            updatedState =
                updatedState.callMethod('set', ['allowTextSelection', true]);
            updatedState =
                updatedState.callMethod('set', ['allowFormFieldEditing', true]);
            updatedState =
                updatedState.callMethod('set', ['allowZooming', true]);
            updatedState =
                updatedState.callMethod('set', ['allowPanning', true]);
            updatedState =
                updatedState.callMethod('set', ['allowPageNavigation', true]);
            updatedState =
                updatedState.callMethod('set', ['allowAnnotationMoving', true]);
            updatedState = updatedState
                .callMethod('set', ['allowAnnotationResizing', true]);
            updatedState = updatedState
                .callMethod('set', ['allowAnnotationDeletion', true]);
          }

          return updatedState;
        })
      ]));

      // Method 2: Use CSS pointer-events as additional protection
      // This is optional - if it fails, PSPDFKit API should still work
      try {
        if (kDebugMode) {
          print(
              'Applying CSS pointer events blocking: ${enabled ? "enabled" : "disabled"}');
        }
        _setCSSPointerEvents(enabled);
        if (kDebugMode) {
          print('CSS pointer events blocking completed successfully');
        }
      } catch (e) {
        // CSS manipulation failed, but that's okay
        if (kDebugMode) {
          print('Warning: CSS pointer events manipulation failed: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to set user interaction: $e');
    }
  }

  /// Sets CSS pointer-events to completely prevent mouse interactions
  void _setCSSPointerEvents(bool enabled) {
    try {
      // Try multiple methods to find and disable PSPDFKit containers
      var document = context['document'];

      // Method 1: Query for common PSPDFKit container selectors
      var selectors = [
        '.pspdfkit-container',
        '[data-pspdfkit-container]',
        '.nutrient-container',
        '.pspdfkit-viewer',
        '[data-pspdfkit-viewer]',
        'iframe[src*="pspdfkit"]',
        'iframe[src*="nutrient"]'
      ];

      for (var selector in selectors) {
        try {
          var containers = document.callMethod('querySelectorAll', [selector]);
          if (containers != null && containers['length'] > 0) {
            for (int i = 0; i < containers['length']; i++) {
              var container = containers[i];
              if (container != null) {
                _applyCSSStyles(container, enabled);
              }
            }
          }
        } catch (e) {
          // Continue with next selector if this one fails
        }
      }

      // Method 2: Try to get container from PSPDFKit instance
      try {
        var container = _nutrientInstance.callMethod('getContainerElement');
        if (container != null && container is JsObject) {
          _applyCSSStyles(container, enabled);
        }
      } catch (e) {
        // If this fails, continue
      }

      // Method 3: Look for Flutter PDF widget containers (safer approach)
      try {
        // Look for Flutter's PDF widget containers specifically
        var flutterContainers = document.callMethod('querySelectorAll', [
          'div[data-flutter-view-type="platform-view"]',
          'div[data-flutter-view-type="html"]',
          'flt-glass-pane',
          'flt-scene-host'
        ]);

        if (flutterContainers != null && flutterContainers['length'] > 0) {
          for (int i = 0; i < flutterContainers['length']; i++) {
            var container = flutterContainers[i];
            if (container != null) {
              // Only apply if this container contains PSPDFKit elements
              var pspdfkitElements = container.callMethod('querySelectorAll', [
                '.pspdfkit-container, [data-pspdfkit-container], .nutrient-container'
              ]);
              if (pspdfkitElements != null && pspdfkitElements['length'] > 0) {
                _applyCSSStyles(container, enabled);
              }
            }
          }
        }
      } catch (e) {
        // If this fails, that's okay
      }
    } catch (e) {
      // If CSS manipulation fails, that's okay - PSPDFKit API should handle it
      if (kDebugMode) {
        print('Warning: Could not set CSS pointer events: $e');
      }
    }
  }

  /// Applies CSS styles to disable/enable pointer events on an element
  void _applyCSSStyles(dynamic element, bool enabled) {
    try {
      // Check if this element is part of a Flutter dialog or overlay
      if (_isFlutterDialogElement(element)) {
        if (kDebugMode) {
          print('Skipping Flutter dialog element to avoid interference');
        }
        return;
      }

      var style = element['style'];
      if (style != null && style is JsObject) {
        if (!enabled) {
          // Disable all pointer events
          style['pointerEvents'] = 'none';
          style['userSelect'] = 'none';
          style['touchAction'] = 'none';
          style['webkitUserSelect'] = 'none';
          style['mozUserSelect'] = 'none';
          style['msUserSelect'] = 'none';
        } else {
          // Re-enable pointer events
          style['pointerEvents'] = 'auto';
          style['userSelect'] = 'auto';
          style['touchAction'] = 'auto';
          style['webkitUserSelect'] = 'auto';
          style['mozUserSelect'] = 'auto';
          style['msUserSelect'] = 'auto';
        }
      }
    } catch (e) {
      // If applying styles fails, continue
    }
  }

  /// Checks if an element is part of a Flutter dialog or overlay
  bool _isFlutterDialogElement(dynamic element) {
    try {
      // Check if element has Flutter dialog/overlay classes
      var className = element['className'];
      if (className != null) {
        var classNameStr = className.toString().toLowerCase();
        if (classNameStr.contains('dialog') ||
            classNameStr.contains('overlay') ||
            classNameStr.contains('modal') ||
            classNameStr.contains('backdrop')) {
          return true;
        }
      }

      // Check if element is inside a Flutter dialog container
      var parent = element['parentElement'];
      while (parent != null) {
        var parentClass = parent['className'];
        if (parentClass != null) {
          var parentClassStr = parentClass.toString().toLowerCase();
          if (parentClassStr.contains('dialog') ||
              parentClassStr.contains('overlay') ||
              parentClassStr.contains('modal') ||
              parentClassStr.contains('backdrop')) {
            return true;
          }
        }
        parent = parent['parentElement'];
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Adds event listener to the PSPDFKit instance.
  /// The [eventName] parameter specifies the name of the event to listen to.
  /// The [callback] parameter specifies the callback function to be called when the event is triggered.
  /// The callback parameter function accepts varying number of arguments depending on the event.
  /// See the [PSPDFKit.Instance.addEventListener](https://www.nutrient.io/api/web/PSPDFKit.Instance.html#addEventListener) API reference for more information about the events and their arguments.
  void addEventListener(String eventName, Function(dynamic) callback) {
    try {
      _nutrientInstance.callMethod('addEventListener', [
        eventName,
        allowInterop(([dynamic event, dynamic event2]) {
          dynamic processedEvent1;
          dynamic processedEvent2;

          // --- Process event 1 ---
          if (event is JsObject) {
            // Convert JsObject to Map, handling annotations specifically
            final eventData = event.toJson();
            if (eventData is Map<String, dynamic>) {
              // Handle single annotation property
              if (eventData.containsKey('annotation') &&
                  event['annotation'] is JsObject) {
                eventData['annotation'] =
                    webAnnotationToJSON(event['annotation']);
              }
              // Handle annotations array property
              if (eventData.containsKey('annotations') &&
                  event['annotations'] is JsObject) {
                final jsAnnotationsArray = event['annotations'];
                // Check if it behaves like an array (has length property)
                if (jsAnnotationsArray.hasProperty('length')) {
                  final length = jsAnnotationsArray['length'] as int;
                  final convertedAnnotations = <dynamic>[];
                  for (var i = 0; i < length; i++) {
                    final annotation =
                        jsAnnotationsArray[i]; // Access array element
                    if (annotation is JsObject) {
                      convertedAnnotations.add(webAnnotationToJSON(annotation));
                    } else {
                      // Keep non-JsObject elements as they are
                      convertedAnnotations.add(annotation);
                    }
                  }
                  eventData['annotations'] =
                      convertedAnnotations; // Update the map
                }
              }
              processedEvent1 = eventData; // Use the processed map
            } else {
              processedEvent1 =
                  eventData; // Use the result of toJson directly if not map
            }
          } else {
            processedEvent1 = event; // Keep primitives/null as is
          }

          // --- Process event 2 ---
          if (event2 is JsObject) {
            // Check if event2 itself looks like an annotation before generic conversion
            // Use a heuristic: check for common annotation properties like 'id' and 'type'.
            final id = event2['id'];
            final type = event2['type'];
            if (id != null && type is String && type.startsWith('pspdfkit/')) {
              // Looks like an annotation, use the specific converter
              processedEvent2 = webAnnotationToJSON(event2);
            } else {
              // Not identified as an annotation, use generic conversion
              processedEvent2 = event2.toJson();
            }
          } else {
            processedEvent2 = event2; // Keep primitives/null as is
          }

          // --- Pass to callback ---
          if (event2 != null) {
            // Two arguments were passed from JS API. Package into a Map.
            callback({
              'argument1': processedEvent1,
              'argument2': processedEvent2,
            });
          } else {
            // Only one (or zero) argument was passed from JS API.
            callback(processedEvent1);
          }
        })
      ]);
    } catch (e) {
      throw Exception('Failed to add event listener for $eventName: $e');
    }
  }

  /// Removes event listener from the PSPDFKit instance.
  /// The [eventName] parameter specifies the name of the event to remove the listener from.
  /// The [jsCallback] parameter specifies the JavaScript function reference that was originally added.
  void removeEventListener(String eventName, Function jsCallback) {
    try {
      _nutrientInstance
          .callMethod('removeEventListener', [eventName, jsCallback]);
    } catch (e) {
      throw Exception('Failed to remove event listener for $eventName: $e');
    }
  }

  /// Sets the toolbar items to be displayed in the toolbar.
  /// The [items] parameter is a list of [NutrientWebToolbarItem] objects.
  void setToolbarItems(List<NutrientWebToolbarItem> items) {
    var jsItems = items.map((e) => e.toJsObject()).toList();
    _nutrientInstance.callMethod('setToolbarItems', [JsObject.jsify(jsItems)]);
  }

  /// Get the page info for the given page index.
  /// The [pageIndex] parameter is the index of the page to get the info for.
  /// Returns a [Future] that completes with the [PageInfo] object for the given page index.
  Future<PageInfo> getPageInfo(int pageIndex) async {
    var pageInfo =
        _nutrientInstance.callMethod('pageInfoForIndex', [pageIndex]);
    return PageInfo(
      pageIndex: pageInfo['pageIndex'],
      height: pageInfo['height'],
      width: pageInfo['width'],
      rotation: pageInfo['rotation'],
      label: pageInfo['label'],
    );
  }

  /// Exports the current document as a raw PDF file.
  /// The [options] parameter is an optional [DocumentSaveOptions] object that specifies the export options.
  /// Returns a [Future] that completes with a [Uint8List] containing the exported PDF data.
  Future<Uint8List> exportPdf({DocumentSaveOptions? options}) async {
    var webOptions = options?.toWebOptions();
    var arrayBuffer = await promiseToFuture(_nutrientInstance
        .callMethod('exportPDF', [JsObject.jsify(webOptions ?? {})]));

    var uintList = JsObject(context['Uint8Array'], [arrayBuffer]);
    JsArray jsArray = context['Array'].callMethod('from', [uintList]);
    Uint8List bytes = Uint8List.fromList(List<int>.from(jsArray));
    return bytes;
  }

  /// Get all form fields in the document.
  Future<List<PdfFormField>> getFormFields() async {
    JsObject formFields =
        await promiseToFuture(_nutrientInstance.callMethod('getFormFields'));

    // `getFormFields` returns a custom  (PSPDFKit.Immutable.List)[https://www.nutrient.io/api/web/PSPDFKit.Immutable.List.html]
    // whose value in an iterator. We need to convert this to a Dart list.
    var values = formFields.callMethod('values');

    List<dynamic> resultList = [];

    while (true) {
      JsObject nextItem = values.callMethod('next');
      // Check if the iterator is done.
      if (nextItem['done']) {
        break;
      }
      JsObject field = nextItem['value'];

      Map<String, dynamic> fieldMap = field.toJson();
      fieldMap['type'] = _getFormFieldType(field);
      resultList.add(fieldMap);
    }
    return resultList.map((field) => PdfFormField.fromMap(field)).toList();
  }

  /// Zooms to the specified rectangle on the given page.
  /// The [pageIndex] parameter is the index of the page to zoom to.
  /// The [rect] parameter is the rectangle to zoom to.
  /// Returns a [Future] that completes when the operation is complete.
  /// Throws an error if the operation fails.
  Future<void> zoomToRect(int pageIndex, Rect rect) async {
    try {
      JsObject webRect = JsObject(context['PSPDFKit']['Geometry']['Rect'], [
        JsObject.jsify({
          'left': rect.left,
          'top': rect.top,
          'width': rect.width,
          'height': rect.height
        })
      ]);
      _nutrientInstance.callMethod('jumpAndZoomToRect', [
        pageIndex,
        webRect,
      ]);
    } catch (e) {
      throw Exception('Failed to zoom to rect: $e');
    }
  }

  Future<double> getZoomScale(int pageIndex) async {
    try {
      var scale = _nutrientInstance['currentZoomLevel'];
      return scale.toDouble();
    } catch (e) {
      throw Exception('Failed to get zoom scale: $e');
    }
  }

  Future<int> getPageCount() async {
    try {
      var count = _nutrientInstance['totalPageCount'];
      return Future.value(count);
    } catch (e) {
      throw Exception('Failed to get document title: $e');
    }
  }

  String _getFormFieldType(JsObject field) {
    JsObject textClass = context['PSPDFKit']['FormFields']['TextFormField'];
    JsObject signatureClass =
        context['PSPDFKit']['FormFields']['SignatureFormField'];
    JsObject checkBoxClass =
        context['PSPDFKit']['FormFields']['CheckBoxFormField'];
    JsObject radioButtonClass =
        context['PSPDFKit']['FormFields']['RadioButtonFormField'];
    JsObject comboBoxClass =
        context['PSPDFKit']['FormFields']['ComboBoxFormField'];
    JsObject listBoxClass =
        context['PSPDFKit']['FormFields']['ListBoxFormField'];
    JsObject buttonClass = context['PSPDFKit']['FormFields']['ButtonFormField'];

    if (_instanceOf(field, textClass)) {
      return 'text';
    } else if (_instanceOf(field, signatureClass)) {
      return 'signature';
    } else if (_instanceOf(field, checkBoxClass)) {
      return 'checkbox';
    } else if (_instanceOf(field, radioButtonClass)) {
      return 'radioButton';
    } else if (_instanceOf(field, comboBoxClass)) {
      return 'comboBox';
    } else if (_instanceOf(field, listBoxClass)) {
      return 'listBox';
    } else if (_instanceOf(field, buttonClass)) {
      return 'button';
    } else {
      return 'unknown';
    }
  }

  bool _instanceOf(JsObject formField, JsObject formFieldClass) {
    String script = '''function instanceOf(formField, formFieldClass) {
      return formField instanceof formFieldClass;
    }''';
    context.callMethod('eval', [script]);
    var result = context.callMethod('instanceOf', [formField, formFieldClass]);
    return result;
  }

  /// Converts a Nutrient Web annotation to a JSON object.
  /// The [annotation] parameter is the PSPDFKit Web annotation to convert.
  /// Returns a JSON object representing the annotation.
  dynamic webAnnotationToJSON(JsObject annotation) {
    // Convert the annotation to a JSON object
    JsObject json = context['PSPDFKit']['Annotations']
        .callMethod('toSerializableObject', [annotation]);

    final result = json.toJson();

    // Add type information if result is a Map
    if (result is Map<String, dynamic>) {
      // Map of Nutrient Web annotation class names to their corresponding Nutrient type strings
      // as defined in annotation_type_extensions.dart
      final annotationTypeMap = {
        'TextAnnotation': 'pspdfkit/text',
        'NoteAnnotation': 'pspdfkit/note',
        'InkAnnotation': 'pspdfkit/ink',
        'HighlightAnnotation': 'pspdfkit/markup/highlight',
        'UnderlineAnnotation': 'pspdfkit/markup/underline',
        'SquiggleAnnotation': 'pspdfkit/markup/squiggly',
        'StrikeOutAnnotation': 'pspdfkit/markup/strikeout',
        'LineAnnotation': 'pspdfkit/shape/line',
        'RectangleAnnotation': 'pspdfkit/shape/rectangle',
        'EllipseAnnotation': 'pspdfkit/shape/ellipse',
        'PolygonAnnotation': 'pspdfkit/shape/polygon',
        'PolylineAnnotation': 'pspdfkit/shape/polyline',
        'LinkAnnotation': 'pspdfkit/link',
        'ImageAnnotation': 'pspdfkit/image',
        'RedactionAnnotation': 'pspdfkit/markup/redaction',
        'StampAnnotation': 'pspdfkit/stamp',
        'MediaAnnotation': 'pspdfkit/media',
        'WidgetAnnotation': 'pspdfkit/widget',
        'CommentMarkerAnnotation': 'pspdfkit/comment',
        'MarkupAnnotation': 'pspdfkit/markup'
      };

      // Check each annotation type
      for (final entry in annotationTypeMap.entries) {
        final className = entry.key;
        final typeString = entry.value;

        // Skip if the class doesn't exist
        if (!context['PSPDFKit']['Annotations'].hasProperty(className)) {
          continue;
        }

        // Get the annotation class
        final annotationClass = context['PSPDFKit']['Annotations'][className];

        // Check if the annotation is an instance of this class
        if (annotationClass != null &&
            _instanceOf(annotation, annotationClass)) {
          // Add the type to the result using the proper format
          result['type'] = typeString;
          break;
        }
      }
    }

    return result;
  }
}
