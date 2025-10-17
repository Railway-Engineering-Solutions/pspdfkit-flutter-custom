///  Copyright © 2024-2025 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';

/// Example demonstrating the improved annotation features:
/// 1. Creating annotations with custom colors
/// 2. Using suppressAnnotationEvents to prevent loops
/// 3. Controlling user interaction (Web only)
class ImprovedAnnotationExample extends StatefulWidget {
  final String documentPath;

  const ImprovedAnnotationExample({super.key, required this.documentPath});

  @override
  State<ImprovedAnnotationExample> createState() =>
      _ImprovedAnnotationExampleState();
}

class _ImprovedAnnotationExampleState extends State<ImprovedAnnotationExample> {
  NutrientViewController? _controller;
  PdfDocument? _document;
  bool _isUserInteractionEnabled = true;
  final List<String> _eventLog = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Improved Annotation Features'),
      ),
      body: Column(
        children: [
          // Control panel
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Column(
              children: [
                const Text(
                  'Feature #1: Create Annotations with Colors',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _enterAnnotationMode(
                        AnnotationTool.inkPen,
                        Colors.red,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Red Pen'),
                    ),
                    ElevatedButton(
                      onPressed: () => _enterAnnotationMode(
                        AnnotationTool.inkPen,
                        Colors.blue,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Blue Pen'),
                    ),
                    ElevatedButton(
                      onPressed: () => _enterAnnotationMode(
                        AnnotationTool.highlight,
                        Colors.yellow,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Yellow Highlight'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Feature #3: Control User Interaction (Web Only)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        'User Interaction: ${_isUserInteractionEnabled ? "Enabled" : "Disabled"}'),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _toggleUserInteraction,
                      child: Text(
                          _isUserInteractionEnabled ? 'Disable' : 'Enable'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _showDialogOverPdf,
                      child: const Text('Show Dialog'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Feature #2: Add Annotation Programmatically',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _demonstrateLoopPrevention,
                  child: const Text('Add Green Ink Annotation'),
                ),
              ],
            ),
          ),
          // PDF Viewer
          Expanded(
            child: NutrientView(
              documentPath: widget.documentPath,
              onViewCreated: _onNutrientViewControllerCreated,
              onDocumentLoaded: _onDocumentLoaded,
            ),
          ),
          // Event log
          Container(
            height: 100,
            color: Colors.grey[300],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text(
                    'Event Log:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _eventLog.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Text(
                          _eventLog[_eventLog.length - 1 - index],
                          style: const TextStyle(fontSize: 12),
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

  void _onNutrientViewControllerCreated(NutrientViewController controller) {
    setState(() {
      _controller = controller;
    });

    // Listen to annotation events
    controller.addWebEventListener(
      NutrientWebEvent.annotationsCreate,
      _onAnnotationsCreated,
    );
  }

  void _onDocumentLoaded(PdfDocument document) {
    setState(() {
      _document = document;
    });
    _logEvent('Document loaded successfully');
  }

  /// Feature #1: Enter annotation creation mode with a specific color
  Future<void> _enterAnnotationMode(
    AnnotationTool tool,
    Color color,
  ) async {
    if (_controller == null) {
      _showMessage('Controller not initialized');
      return;
    }

    try {
      await _controller!.enterAnnotationCreationMode(tool, color);
      _logEvent('Entered ${tool.name} mode with color: ${_colorToHex(color)}');
      _showMessage('Ready to annotate with ${tool.name}');
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  /// Feature #2: Demonstrate loop prevention using annotation add
  Future<void> _demonstrateLoopPrevention() async {
    if (_document == null) {
      _showMessage('Document not loaded');
      return;
    }

    try {
      // Create an ink annotation programmatically
      final inkAnnotation = InkAnnotation(
        pageIndex: 0,
        lines: InkLines(
          intensities: [
            [1.0, 1.0, 1.0]
          ],
          points: [
            [
              [100, 100],
              [200, 200],
              [300, 100],
            ]
          ],
        ),
        lineWidth: 3.0,
        bbox: [95, 95, 305, 205],
        createdAt: DateTime.now().toIso8601String(),
        strokeColor: Colors.green,
      );

      _logEvent('Adding annotation programmatically');

      // Note: In a real scenario with annotationManager.suppressAnnotationEvents:
      // await document.annotationManager.suppressAnnotationEvents(() async {
      //   await document.annotationManager.addAnnotation(inkAnnotation);
      // });

      await _document!.addAnnotation(inkAnnotation);

      _logEvent('Annotation added successfully');
      _showMessage('Annotation added successfully');
    } catch (e) {
      _logEvent('Error adding annotation: $e');
      _showMessage('Error: $e');
    }
  }

  /// Feature #3: Toggle user interaction (Web only)
  Future<void> _toggleUserInteraction() async {
    if (_controller == null) {
      _showMessage('Controller not initialized');
      return;
    }

    try {
      final newState = !_isUserInteractionEnabled;
      await _controller!.setUserInteractionEnabled(newState);
      setState(() {
        _isUserInteractionEnabled = newState;
      });
      _logEvent('User interaction ${newState ? "enabled" : "disabled"}');
      _showMessage('User interaction ${newState ? "enabled" : "disabled"}');
    } catch (e) {
      _showMessage('Error (likely not on Web): $e');
    }
  }

  /// Demonstrate the dialog issue that setUserInteractionEnabled solves
  Future<void> _showDialogOverPdf() async {
    // First, disable user interaction to prevent click-through
    if (_controller != null) {
      try {
        await _controller!.setUserInteractionEnabled(false);
        _logEvent('Disabled interaction before showing dialog');
      } catch (e) {
        // Ignore if not on Web
      }
    }

    // Show the dialog
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Dialog Over PDF'),
            content: const Text(
              'With setUserInteractionEnabled(false), '
              'clicks on this dialog don\'t pass through to the PDF below! '
              'This prevents annotation mode from triggering when clicking the dialog.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }

    // Re-enable user interaction after dialog is closed
    if (_controller != null) {
      try {
        await _controller!.setUserInteractionEnabled(true);
        _logEvent('Re-enabled interaction after dialog closed');
      } catch (e) {
        // Ignore if not on Web
      }
    }
  }

  void _onAnnotationsCreated(dynamic event) {
    // This callback will NOT be triggered for annotations added using suppressAnnotationEvents
    if (event is Map && event.containsKey('argument1')) {
      final annotations = event['argument1']['annotations'];
      if (annotations is List && annotations.isNotEmpty) {
        _logEvent(
            'Annotation created event fired (${annotations.length} annotations)');
      }
    }
  }

  void _logEvent(String message) {
    setState(() {
      _eventLog
          .add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
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
