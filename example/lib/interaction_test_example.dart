///  Copyright © 2024-2025 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.

import 'package:flutter/material.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';

/// Simple test to verify that setUserInteractionEnabled works without errors
class InteractionTestExample extends StatefulWidget {
  final String documentPath;

  const InteractionTestExample({super.key, required this.documentPath});

  @override
  State<InteractionTestExample> createState() => _InteractionTestExampleState();
}

class _InteractionTestExampleState extends State<InteractionTestExample> {
  NutrientViewController? _controller;
  bool _interactionsEnabled = true;
  String _lastError = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interaction Test'),
      ),
      body: Column(
        children: [
          // Status
          Container(
            padding: const EdgeInsets.all(16),
            color: _interactionsEnabled
                ? Colors.green.shade50
                : Colors.red.shade50,
            child: Row(
              children: [
                Icon(
                  _interactionsEnabled ? Icons.check_circle : Icons.block,
                  color: _interactionsEnabled
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _interactionsEnabled
                        ? 'Interactions: ENABLED'
                        : 'Interactions: DISABLED',
                    style: TextStyle(
                      color: _interactionsEnabled
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Error display
          if (_lastError.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: $_lastError',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _interactionsEnabled ? null : _enableInteractions,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Enable'),
                ),
                ElevatedButton.icon(
                  onPressed: _interactionsEnabled ? _disableInteractions : null,
                  icon: const Icon(Icons.pause),
                  label: const Text('Disable'),
                ),
                ElevatedButton.icon(
                  onPressed: _testToggle,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Toggle'),
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
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Column(
              children: [
                Text(
                  'Test Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Click "Disable" to disable all interactions\n'
                  '2. Try clicking on annotations - they should be unresponsive\n'
                  '3. Click "Enable" to re-enable interactions\n'
                  '4. Click "Toggle" to quickly test enable/disable\n'
                  '5. Check for any error messages above',
                  style: TextStyle(fontSize: 13),
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
  }

  void _onDocumentLoaded(PdfDocument document) {
    // Document loaded successfully
  }

  Future<void> _enableInteractions() async {
    if (_controller == null) return;

    try {
      setState(() {
        _lastError = '';
      });

      final result = await _controller!.setUserInteractionEnabled(true);

      if (result == true) {
        setState(() {
          _interactionsEnabled = true;
        });
      } else {
        setState(() {
          _lastError = 'Failed to enable interactions (returned false)';
        });
      }
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
    }
  }

  Future<void> _disableInteractions() async {
    if (_controller == null) return;

    try {
      setState(() {
        _lastError = '';
      });

      final result = await _controller!.setUserInteractionEnabled(false);

      if (result == true) {
        setState(() {
          _interactionsEnabled = false;
        });
      } else {
        setState(() {
          _lastError = 'Failed to disable interactions (returned false)';
        });
      }
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
    }
  }

  Future<void> _testToggle() async {
    if (_controller == null) return;

    try {
      setState(() {
        _lastError = '';
      });

      // Toggle interactions
      final result =
          await _controller!.setUserInteractionEnabled(!_interactionsEnabled);

      if (result == true) {
        setState(() {
          _interactionsEnabled = !_interactionsEnabled;
        });
      } else {
        setState(() {
          _lastError = 'Failed to toggle interactions (returned false)';
        });
      }
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
    }
  }
}
