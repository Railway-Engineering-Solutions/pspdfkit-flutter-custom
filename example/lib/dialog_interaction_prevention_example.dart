///  Copyright © 2024-2025 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.

import 'package:flutter/material.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';

/// Example demonstrating complete dialog interaction prevention.
/// This shows how to completely disable ALL PDF interactions when dialogs are shown,
/// preventing click-through to annotations behind the dialog.
class DialogInteractionPreventionExample extends StatefulWidget {
  final String documentPath;

  const DialogInteractionPreventionExample(
      {super.key, required this.documentPath});

  @override
  State<DialogInteractionPreventionExample> createState() =>
      _DialogInteractionPreventionExampleState();
}

class _DialogInteractionPreventionExampleState
    extends State<DialogInteractionPreventionExample> {
  NutrientViewController? _controller;
  bool _isDialogOpen = false;
  final List<String> _interactionLog = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dialog Interaction Prevention'),
        actions: [
          IconButton(
            onPressed: _showTestDialog,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Show Test Dialog',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(16),
            color: _isDialogOpen ? Colors.red.shade50 : Colors.green.shade50,
            child: Row(
              children: [
                Icon(
                  _isDialogOpen ? Icons.block : Icons.check_circle,
                  color: _isDialogOpen
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isDialogOpen
                        ? 'Dialog is open - ALL PDF interactions are disabled'
                        : 'No dialog - PDF interactions are enabled',
                    style: TextStyle(
                      color: _isDialogOpen
                          ? Colors.red.shade900
                          : Colors.green.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                const Text(
                  'Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Click the info button to open a dialog\n'
                  '2. Try clicking on annotations behind the dialog\n'
                  '3. Notice that clicks are completely blocked\n'
                  '4. Close the dialog to re-enable interactions',
                  style: TextStyle(fontSize: 13),
                ),
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
          // Interaction log
          Container(
            height: 120,
            color: Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text(
                        'Interaction Log:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _interactionLog.clear();
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
                    itemCount: _interactionLog.length,
                    itemBuilder: (context, index) {
                      final log =
                          _interactionLog[_interactionLog.length - 1 - index];
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

  void _onViewCreated(NutrientViewController controller) {
    setState(() {
      _controller = controller;
    });

    // Listen to annotation events to demonstrate interaction blocking
    controller.addWebEventListener(
      NutrientWebEvent.annotationsCreate,
      _onAnnotationCreated,
    );

    controller.addWebEventListener(
      NutrientWebEvent.annotationSelectionChange,
      _onAnnotationSelectionChanged,
    );

    _logInteraction('✓ Controller created and listeners attached');
  }

  void _onDocumentLoaded(PdfDocument document) {
    _logInteraction('✓ Document loaded successfully');
  }

  /// Shows a test dialog and demonstrates interaction prevention
  void _showTestDialog() {
    _logInteraction('📱 Opening test dialog...');

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by clicking outside
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 8),
            Text('Interaction Prevention Test'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This dialog demonstrates complete interaction prevention:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('✓ Annotation creation is disabled'),
            const Text('✓ Annotation selection is disabled'),
            const Text('✓ Annotation editing is disabled'),
            const Text('✓ Text selection is disabled'),
            const Text('✓ Zoom and pan are disabled'),
            const Text('✓ Page navigation is disabled'),
            const Text('✓ CSS pointer-events are disabled'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Try clicking on annotations behind this dialog - '
                'they should be completely unresponsive!',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onDialogClosed();
            },
            child: const Text('Close Dialog'),
          ),
        ],
      ),
    ).then((_) {
      // This runs when dialog is closed
      _onDialogClosed();
    });

    // Disable PDF interactions when dialog opens
    _disablePDFInteractions();
  }

  /// Disables all PDF interactions
  Future<void> _disablePDFInteractions() async {
    if (_controller == null) return;

    try {
      await _controller!.setUserInteractionEnabled(false);
      setState(() {
        _isDialogOpen = true;
      });
      _logInteraction('🔒 PDF interactions DISABLED');
    } catch (e) {
      _logInteraction('❌ Error disabling interactions: $e');
    }
  }

  /// Re-enables all PDF interactions
  Future<void> _enablePDFInteractions() async {
    if (_controller == null) return;

    try {
      await _controller!.setUserInteractionEnabled(true);
      setState(() {
        _isDialogOpen = false;
      });
      _logInteraction('🔓 PDF interactions ENABLED');
    } catch (e) {
      _logInteraction('❌ Error enabling interactions: $e');
    }
  }

  /// Called when dialog is closed
  void _onDialogClosed() {
    _logInteraction('📱 Dialog closed');
    _enablePDFInteractions();
  }

  /// Logs annotation creation events
  Future<void> _onAnnotationCreated(dynamic event) async {
    _logInteraction('📝 Annotation created event received');

    // This should only happen when interactions are enabled
    if (_isDialogOpen) {
      _logInteraction('⚠️ WARNING: Annotation created while dialog is open!');
    }
  }

  /// Logs annotation selection change events
  Future<void> _onAnnotationSelectionChanged(dynamic event) async {
    _logInteraction('👆 Annotation selection changed');

    // This should only happen when interactions are enabled
    if (_isDialogOpen) {
      _logInteraction(
          '⚠️ WARNING: Annotation selection changed while dialog is open!');
    }
  }

  void _logInteraction(String message) {
    setState(() {
      _interactionLog.add('[${_getTimestamp()}] $message');
      // Keep only last 30 events
      if (_interactionLog.length > 30) {
        _interactionLog.removeAt(0);
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
          _onAnnotationCreated,
        );
        _controller!.removeWebEventListener(
          NutrientWebEvent.annotationSelectionChange,
          _onAnnotationSelectionChanged,
        );
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
    super.dispose();
  }
}
