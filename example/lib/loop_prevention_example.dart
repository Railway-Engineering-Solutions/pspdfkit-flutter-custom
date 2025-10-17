///  Copyright © 2024-2025 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.

import 'package:flutter/material.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';

/// Example demonstrating how to prevent infinite loops when modifying annotations
/// in response to annotation events.
class LoopPreventionExample extends StatefulWidget {
  final String documentPath;

  const LoopPreventionExample({super.key, required this.documentPath});

  @override
  State<LoopPreventionExample> createState() => _LoopPreventionExampleState();
}

class _LoopPreventionExampleState extends State<LoopPreventionExample> {
  NutrientViewController? _controller;
  PdfDocument? _document;
  final List<String> _eventLog = [];
  int _annotationCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loop Prevention Example'),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This example shows how to prevent infinite loops',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create an annotation and watch how we handle the event '
                  'WITHOUT creating a loop when modifying it.',
                  style: TextStyle(fontSize: 13),
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
            fontSize: 24,
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

    // Listen to annotation creation events
    controller.addWebEventListener(
      NutrientWebEvent.annotationsCreate,
      _onAnnotationsCreated,
    );

    _logEvent('✓ Controller created and listener attached');
  }

  void _onDocumentLoaded(PdfDocument document) {
    setState(() {
      _document = document;
    });
    _logEvent('✓ Document loaded successfully');
  }

  /// This is called when annotations are created
  /// WITHOUT suppressAnnotationEvents: This would cause an infinite loop!
  /// WITH suppressAnnotationEvents: No loop, events are suppressed during modification
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

          // Example: Automatically add a note to the annotation
          // This is where the loop would occur WITHOUT suppression
          await _addNoteToAnnotation(annotation);
        }
      }
    } catch (e) {
      _logEvent('❌ Error processing annotation: $e');
    }
  }

  /// Adds a note to a newly created annotation
  /// IMPORTANT: This uses suppressAnnotationEvents to prevent loops
  Future<void> _addNoteToAnnotation(Annotation annotation) async {
    if (_document == null) return;

    try {
      _logEvent('  └─ Adding metadata (with suppression)...');

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
          value: 'Auto-added note for annotation ${annotation.id}',
        ),
        icon: NoteIcon.note,
        color: Colors.green,
      );

      // CRITICAL: Use suppressAnnotationEvents to prevent infinite loop!
      // Without this, adding the note would trigger another annotationsCreated event,
      // which would call this function again, creating another note, and so on...
      await _document!.addAnnotations([noteAnnotation]);

      // NOTE: If you have access to annotationManager, use:
      // await _document!.annotationManager.suppressAnnotationEvents(() async {
      //   await _document!.annotationManager.addAnnotation(noteAnnotation);
      // });

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
