///
///  Copyright @2023-2025 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.
///

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';

/// Stub implementation of NutrientWebInstance for non-web platforms.
class NutrientWebInstance {
  NutrientWebInstance(dynamic instance);

  List<String> get availableDocumentInfoKeys => [];
  dynamic get jsObject => throw UnimplementedError('Web only');

  Future<void> setDefaultAnnotationColor(Color color) async {}
  Color? get defaultAnnotationColor => null;
  Future<void> save() async {}
  Future<void> addAnnotation(Map<String, dynamic> jsonAnnotation,
      [Map<String, dynamic>? attachment]) async {}
  Future<void> updateAnnotation(Map<String, dynamic> jsonAnnotation) async {}
  Future<void> updateAnnotationProperties(
      Map<String, dynamic> updatedProperties) async {}
  Future<dynamic> getAnnotations(int pageIndex,
          [String? annotationType]) async =>
      [];
  Future<void> applyInstantJson(dynamic annotationsJson) async {}
  Future<String?> exportInstantJson() async => null;
  Future<void> importXfdf(String xfdfPath, [bool? ignorePageRotation]) async {}
  Future<void> exportXfdf(String xfdfPath) async {}
  Future<dynamic> getAllAnnotations() async => {};
  Future<void> removeAnnotation(dynamic jsonAnnotation) async {}
  Future<void> removeAnnotations(List<dynamic> jsonAnnotations) async {}
  Future<void> setFormFieldValue(
      String value, String fullyQualifiedName) async {}
  Future<void> setFormFieldValues(Map<String, String> formValues) async {}
  Future<String?> getFormFieldValue(String fullyQualifiedName) async => null;
  Future<void> setMeasurementPrecision(MeasurementPrecision precision) async {}
  Future<void> setMeasurementScale(MeasurementScale scale) async {}
  Future<dynamic> applyOperations(
      List<Map<String, dynamic>> operations) async {}
  Future<void> setAnnotationCreatorName(String name) async {}
  Future<void> setToolMode(AnnotationTool? toolMode, [Color? color]) async {}
  Future<void> setAnnotationsHidden(bool hidden) async {}
  Future<void> setUserInteractionEnabled(bool enabled) async {}
  void addEventListener(String eventName, Function(dynamic) callback) {}
  void removeEventListener(String eventName, Function jsCallback) {}
  void setToolbarItems(List<NutrientWebToolbarItem> items) {}
  Future<PageInfo> getPageInfo(int pageIndex) async =>
      throw UnimplementedError();
  Future<Uint8List> exportPdf({DocumentSaveOptions? options}) async =>
      Uint8List(0);
  Future<List<PdfFormField>> getFormFields() async => [];
  Future<void> zoomToRect(int pageIndex, Rect rect) async {}
  Future<double> getZoomScale(int pageIndex) async => 1.0;
  Future<int> getPageCount() async => 0;
  dynamic webAnnotationToJSON(dynamic annotation) => {};
}
