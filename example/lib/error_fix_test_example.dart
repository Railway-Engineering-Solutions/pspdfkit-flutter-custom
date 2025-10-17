///  Copyright © 2024-2025 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.

import 'package:flutter/material.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';

/// Test to verify that the TypeError fixes work correctly
class ErrorFixTestExample extends StatefulWidget {
  final String documentPath;

  const ErrorFixTestExample({super.key, required this.documentPath});

  @override
  State<ErrorFixTestExample> createState() => _ErrorFixTestExampleState();
}

class _ErrorFixTestExampleState extends State<ErrorFixTestExample> {
  NutrientViewController? _controller;
  Color _currentColor = Colors.red;
  bool _interactionsEnabled = true;
  final List<String> _testLog = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Fix Test'),
      ),
      body: Column(
        children: [
          // Status
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      'Testing Error Fixes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Default Color: ${_getColorName(_currentColor)} | '
                  'Interactions: ${_interactionsEnabled ? "Enabled" : "Disabled"}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          // Test buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testDefaultColor,
                  icon: const Icon(Icons.palette),
                  label: const Text('Test Default Color'),
                ),
                ElevatedButton.icon(
                  onPressed: _testInteractionToggle,
                  icon: const Icon(Icons.touch_app),
                  label: const Text('Test Interaction Toggle'),
                ),
                ElevatedButton.icon(
                  onPressed: _testAnnotationMode,
                  icon: const Icon(Icons.edit),
                  label: const Text('Test Annotation Mode'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearLog,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Log'),
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
          // Test log
          Container(
            height: 150,
            color: Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Test Log:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _testLog.length,
                    itemBuilder: (context, index) {
                      final log = _testLog[_testLog.length - 1 - index];
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
    _logTest('✓ Controller created');
  }

  void _onDocumentLoaded(PdfDocument document) {
    _logTest('✓ Document loaded');
  }

  Future<void> _testDefaultColor() async {
    if (_controller == null) return;

    try {
      _logTest('🎨 Testing default color setting...');

      // Cycle through different colors
      final colors = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple
      ];
      final currentIndex = colors.indexOf(_currentColor);
      final nextIndex = (currentIndex + 1) % colors.length;
      final nextColor = colors[nextIndex];

      await _controller!.setDefaultAnnotationColor(nextColor);

      setState(() {
        _currentColor = nextColor;
      });

      _logTest('✓ Default color set to ${_getColorName(nextColor)}');
    } catch (e) {
      _logTest('❌ Error setting default color: $e');
    }
  }

  Future<void> _testInteractionToggle() async {
    if (_controller == null) return;

    try {
      _logTest('🔄 Testing interaction toggle...');

      final newState = !_interactionsEnabled;
      await _controller!.setUserInteractionEnabled(newState);

      setState(() {
        _interactionsEnabled = newState;
      });

      _logTest('✓ Interactions ${newState ? "enabled" : "disabled"}');
    } catch (e) {
      _logTest('❌ Error toggling interactions: $e');
    }
  }

  Future<void> _testAnnotationMode() async {
    if (_controller == null) return;

    try {
      _logTest('✏️ Testing annotation mode...');

      // Test entering annotation mode with current default color
      await _controller!.enterAnnotationCreationMode(AnnotationTool.inkPen);
      _logTest('✓ Entered ink pen mode with default color');

      // Wait a bit then exit
      await Future.delayed(const Duration(seconds: 2));
      await _controller!.exitAnnotationCreationMode();
      _logTest('✓ Exited annotation mode');
    } catch (e) {
      _logTest('❌ Error testing annotation mode: $e');
    }
  }

  void _clearLog() {
    setState(() {
      _testLog.clear();
    });
  }

  void _logTest(String message) {
    setState(() {
      _testLog.add('[${_getTimestamp()}] $message');
      // Keep only last 50 events
      if (_testLog.length > 50) {
        _testLog.removeAt(0);
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
    return 'Custom';
  }
}
