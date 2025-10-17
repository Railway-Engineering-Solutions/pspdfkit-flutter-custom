///  Copyright © 2024-2025 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.

import 'package:flutter/material.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';

/// Example demonstrating how to add initial annotations when the document loads.
/// This is useful for pre-populating documents with annotations, highlights, or notes.
class InitialAnnotationsExample extends StatefulWidget {
  final String documentPath;

  const InitialAnnotationsExample({super.key, required this.documentPath});

  @override
  State<InitialAnnotationsExample> createState() =>
      _InitialAnnotationsExampleState();
}

class _InitialAnnotationsExampleState extends State<InitialAnnotationsExample> {
  // Define initial annotations that will be added when the document loads
  List<Annotation> get _initialAnnotations => [
        // 1. Welcome note annotation at the top of the page
        NoteAnnotation(
          pageIndex: 0,
          bbox: [50, 50, 80, 80],
          createdAt: DateTime.now().toIso8601String(),
          contents: 'Welcome! This is a pre-loaded note annotation.',
          iconName: 'Comment',
          color: Colors.blue,
        ),

        // 2. Highlight important text (approximate coordinates)
        HighlightAnnotation(
          pageIndex: 0,
          bbox: [100, 150, 300, 180],
          createdAt: DateTime.now().toIso8601String(),
          rects: [
            [100, 150, 300, 180],
          ],
          color: Colors.yellow,
        ),

        // 3. Red underline for emphasis
        UnderlineAnnotation(
          pageIndex: 0,
          bbox: [100, 250, 400, 270],
          createdAt: DateTime.now().toIso8601String(),
          rects: [
            [100, 250, 400, 270],
          ],
          color: Colors.red,
        ),

        // 4. Ink annotation (hand-drawn shape)
        InkAnnotation(
          pageIndex: 0,
          lines: InkLines(
            intensities: [
              [1.0, 1.0, 1.0, 1.0],
            ],
            points: [
              [
                [150, 350],
                [200, 300],
                [250, 350],
                [200, 400],
                [150, 350], // Close the shape
              ]
            ],
          ),
          lineWidth: 3.0,
          bbox: [145, 295, 255, 405],
          createdAt: DateTime.now().toIso8601String(),
          strokeColor: Colors.green,
        ),

        // 5. Free text annotation
        FreeTextAnnotation(
          pageIndex: 0,
          bbox: [50, 450, 250, 500],
          createdAt: DateTime.now().toIso8601String(),
          contents: 'Auto-loaded Text',
          fontSize: 16.0,
          fontName: 'Helvetica',
          color: Colors.purple,
          fillColor: Colors.yellow.withOpacity(0.3),
        ),

        // 6. Rectangle shape
        SquareAnnotation(
          pageIndex: 0,
          bbox: [300, 350, 450, 450],
          createdAt: DateTime.now().toIso8601String(),
          strokeColor: Colors.orange,
          fillColor: Colors.orange.withOpacity(0.2),
          lineWidth: 2.0,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initial Annotations Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This document has ${_initialAnnotations.length} annotations that were automatically added on load!',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // PDF Viewer with initial annotations
          Expanded(
            child: NutrientView(
              documentPath: widget.documentPath,
              initialAnnotations: _initialAnnotations,
              onDocumentLoaded: (document) {
                _showSnackBar(
                  'Document loaded with ${_initialAnnotations.length} initial annotations',
                );
              },
              onDocumentError: (error) {
                _showSnackBar('Error loading document: $error', isError: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initial Annotations Feature'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This example demonstrates the initialAnnotations feature, which allows you to:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                '✓',
                'Pre-populate documents with annotations',
              ),
              _buildInfoItem(
                '✓',
                'Add welcome messages or instructions',
              ),
              _buildInfoItem(
                '✓',
                'Highlight important sections automatically',
              ),
              _buildInfoItem(
                '✓',
                'Add any type of annotation (notes, shapes, text, etc.)',
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Annotations Added:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildAnnotationInfo('1', 'Blue Note', 'Comment icon'),
              _buildAnnotationInfo('2', 'Yellow Highlight', 'Text markup'),
              _buildAnnotationInfo('3', 'Red Underline', 'Text emphasis'),
              _buildAnnotationInfo('4', 'Green Ink Shape', 'Hand-drawn'),
              _buildAnnotationInfo('5', 'Purple Text Box', 'Free text'),
              _buildAnnotationInfo('6', 'Orange Rectangle', 'Shape'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildAnnotationInfo(String number, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title - $desc',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
