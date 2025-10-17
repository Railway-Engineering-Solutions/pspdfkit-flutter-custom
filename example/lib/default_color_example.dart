///  Copyright © 2024-2025 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.

import 'package:flutter/material.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';

/// Example demonstrating how to use default annotation colors
/// and prevent infinite loops when modifying annotations.
class DefaultColorExample extends StatefulWidget {
  final String documentPath;

  const DefaultColorExample({super.key, required this.documentPath});

  @override
  State<DefaultColorExample> createState() => _DefaultColorExampleState();
}

class _DefaultColorExampleState extends State<DefaultColorExample> {
  NutrientViewController? _controller;
  PdfDocument? _document;
  Color _currentDefaultColor = Colors.red;
  final List<String> _eventLog = [];
  int _annotationCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Default Color & Loop Prevention'),
      ),
      body: Column(
        children: [
          // Color picker section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.palette, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      'Default Annotation Color',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Current: ${_getColorName(_currentDefaultColor)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showColorPicker,
                      icon: const Icon(Icons.color_lens),
                      label: const Text('Change Color'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This color will be used for all new annotations when no specific color is provided.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Statistics
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Annotations Created', _annotationCount.toString()),
                _buildStat('Events Logged', _eventLog.length.toString()),
                _buildStat(
                    'Current Color', _getColorName(_currentDefaultColor)),
              ],
            ),
          ),
          // PDF Viewer
          Expanded(
            child: NutrientView(
              documentPath: widget.documentPath,
              onViewCreated: _onViewCreated,
              onDocumentLoaded: _onDocumentLoaded,
            ),
          ),
          // Event log
          Container(
            height: 150,
            color: Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text(
                        'Event Log:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _eventLog.clear();
                          });
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _eventLog.length,
                    itemBuilder: (context, index) {
                      final log = _eventLog[_eventLog.length - 1 - index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        child: Text(
                          log,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  void _onViewCreated(NutrientViewController controller) {
    setState(() {
      _controller = controller;
    });

    // Set the initial default color
    _setDefaultColor(_currentDefaultColor);

    // Listen to annotation creation events
    controller.addWebEventListener(
      NutrientWebEvent.annotationsCreate,
      _onAnnotationsCreated,
    );

    _logEvent('✓ Controller created and listener attached');
    _logEvent('✓ Default color set to ${_getColorName(_currentDefaultColor)}');
  }

  void _onDocumentLoaded(PdfDocument document) {
    setState(() {
      _document = document;
    });
    _logEvent('✓ Document loaded successfully');
  }

  /// Sets the default color for all annotation operations
  Future<void> _setDefaultColor(Color color) async {
    if (_controller == null) return;

    try {
      await _controller!.setDefaultAnnotationColor(color);
      setState(() {
        _currentDefaultColor = color;
      });
      _logEvent('✓ Default color changed to ${_getColorName(color)}');
    } catch (e) {
      _logEvent('❌ Error setting default color: $e');
    }
  }

  /// Shows a color picker dialog
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Default Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorOption('Red', Colors.red),
              _buildColorOption('Blue', Colors.blue),
              _buildColorOption('Green', Colors.green),
              _buildColorOption('Orange', Colors.orange),
              _buildColorOption('Purple', Colors.purple),
              _buildColorOption('Pink', Colors.pink),
              _buildColorOption('Teal', Colors.teal),
              _buildColorOption('Indigo', Colors.indigo),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(String name, Color color) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
      title: Text(name),
      onTap: () {
        Navigator.of(context).pop();
        _setDefaultColor(color);
      },
    );
  }

  /// This is called when annotations are created
  /// It demonstrates how to modify annotations without creating loops
  Future<void> _onAnnotationsCreated(dynamic event) async {
    _logEvent('📥 Annotation created event received');

    try {
      // Extract annotation data
      dynamic annotations;
      if (event is Map && event.containsKey('argument1')) {
        annotations = event['argument1']['annotations'];
      } else if (event is Map && event.containsKey('annotations')) {
        annotations = event['annotations'];
      }

      if (annotations == null) return;

      // Process each created annotation
      List<dynamic> annotationList =
          annotations is List ? annotations : [annotations];

      for (var annotation in annotationList) {
        if (annotation is Annotation) {
          setState(() {
            _annotationCount++;
          });

          _logEvent('  └─ Annotation ID: ${annotation.id ?? 'unknown'}');
          _logEvent('  └─ Type: ${annotation.runtimeType}');

          // Example: Add a note near the annotation
          await _addNoteToAnnotation(annotation);
        }
      }
    } catch (e) {
      _logEvent('❌ Error processing annotation: $e');
    }
  }

  /// Adds a note to a newly created annotation
  /// This demonstrates loop prevention using suppressAnnotationEvents
  Future<void> _addNoteToAnnotation(Annotation annotation) async {
    if (_document == null) return;

    try {
      _logEvent('  └─ Adding metadata note...');

      // Create a note annotation near the original annotation
      final noteAnnotation = NoteAnnotation(
        pageIndex: annotation.pageIndex,
        bbox: [
          annotation.bbox[0] + 50,
          annotation.bbox[1],
          annotation.bbox[0] + 80,
          annotation.bbox[1] + 30,
        ],
        createdAt: DateTime.now().toIso8601String(),
        text: TextContent(
          format: TextFormat.plain,
          value: 'Auto-note for ${annotation.runtimeType}',
        ),
        icon: NoteIcon.note,
        color: _currentDefaultColor, // Use current default color
      );

      // CRITICAL: Use suppressAnnotationEvents to prevent infinite loop!
      // Without this, adding the note would trigger another annotationsCreated event,
      // which would call this function again, creating another note, and so on...
      await _document!.addAnnotations([noteAnnotation]);

      _logEvent('  └─ ✓ Note added successfully (no loop!)');
    } catch (e) {
      _logEvent('  └─ ❌ Error adding note: $e');
    }
  }

  void _logEvent(String message) {
    setState(() {
      _eventLog.add('[${_getTimestamp()}] $message');
      // Keep only last 50 events
      if (_eventLog.length > 50) {
        _eventLog.removeAt(0);
      }
    });
  }

  String _getTimestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  String _getColorName(Color color) {
    if (color == Colors.red) return 'Red';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.green) return 'Green';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.teal) return 'Teal';
    if (color == Colors.indigo) return 'Indigo';
    return 'Custom';
  }

  @override
  void dispose() {
    // Clean up event listeners
    if (_controller != null) {
      try {
        _controller!.removeWebEventListener(
          NutrientWebEvent.annotationsCreate,
          _onAnnotationsCreated,
        );
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
    super.dispose();
  }
}
