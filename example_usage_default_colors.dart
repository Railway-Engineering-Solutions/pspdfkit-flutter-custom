///
/// Example: How to Use Default Annotation Colors
///
/// This example shows how to set custom default colors for annotations
/// during PSPDFKit initialization to override the hardcoded defaults.
///

import 'package:flutter/material.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Default Color Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PDFViewerWithCustomColors(),
    );
  }
}

class PDFViewerWithCustomColors extends StatefulWidget {
  @override
  _PDFViewerWithCustomColorsState createState() =>
      _PDFViewerWithCustomColorsState();
}

class _PDFViewerWithCustomColorsState extends State<PDFViewerWithCustomColors> {
  Color _selectedColor = Colors.red;
  Key _viewerKey = UniqueKey();

  final Map<String, Color> _colorPresets = {
    'Red': Colors.red,
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Orange': Colors.orange,
    'Purple': Colors.purple,
    'Pink': Colors.pink,
    'Teal': Colors.teal,
    'Brown': Colors.brown,
  };

  void _changeColor(Color newColor) {
    setState(() {
      _selectedColor = newColor;
      // Recreate the widget with new color
      _viewerKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Default Colors Demo'),
        actions: [
          // Color picker dropdown
          PopupMenuButton<Color>(
            icon: Icon(Icons.color_lens),
            tooltip: 'Select Default Color',
            onSelected: _changeColor,
            itemBuilder: (context) => _colorPresets.entries
                .map((entry) => PopupMenuItem<Color>(
                      value: entry.value,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: entry.value,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(entry.key),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: _selectedColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _selectedColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Default annotation color is set to ${_getColorName(_selectedColor)}. '
                    'All new annotations will use this color by default.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // PDF Viewer
          Expanded(
            child: NutrientView(
              key: _viewerKey,
              documentPath: 'assets/document.pdf', // Replace with your PDF path

              // ✨ THIS IS THE KEY PART - Set default colors during initialization
              configuration: PdfConfiguration(
                enableAnnotationEditing: true,
                webConfiguration: PdfWebConfiguration(
                  // Override PSPDFKit's default stroke color (#3A87FD)
                  defaultAnnotationStrokeColor: _selectedColor,

                  // Override PSPDFKit's default fill color (#AFFCFE)
                  defaultAnnotationFillColor: _selectedColor.withOpacity(0.3),

                  // Optional: Keep the selected tool active
                  keepSelectedTool: true,

                  // Optional: Enable history for undo/redo
                  enableHistory: true,
                ),
              ),

              onPdfDocumentLoaded: (document) {
                print(
                    '✅ PDF loaded with default color: ${_getColorName(_selectedColor)}');
                _showSnackBar('PDF loaded! Try creating an annotation.');
              },

              onPdfDocumentLoadFailure: (error) {
                print('❌ Failed to load PDF: $error');
                _showSnackBar('Failed to load PDF: $error');
              },
            ),
          ),

          // Instructions
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📝 Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('1. Select a color from the color picker (top right)'),
                Text('2. Click the pen/highlighter tool in the PDF toolbar'),
                Text('3. Draw or highlight - it will use your selected color!'),
                Text('4. Change colors and reload to see different defaults'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getColorName(Color color) {
    return _colorPresets.entries
        .firstWhere(
          (entry) => entry.value == color,
          orElse: () => MapEntry('Custom', color),
        )
        .key;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Alternative Example: Simple Static Color
class SimplePDFViewerWithRedColor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simple Red Default')),
      body: NutrientView(
        documentPath: 'assets/document.pdf',
        configuration: PdfConfiguration(
          webConfiguration: PdfWebConfiguration(
            // Set red as default - overrides PSPDFKit's blue default
            defaultAnnotationStrokeColor: Colors.red,
            defaultAnnotationFillColor: Colors.red.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}

/// Alternative Example: Brand Colors
class BrandColorPDFViewer extends StatelessWidget {
  // Your brand colors
  static const Color brandPrimary = Color(0xFF2C3E50);
  static const Color brandAccent = Color(0xFFE74C3C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Brand Color PDF'),
        backgroundColor: brandPrimary,
      ),
      body: NutrientView(
        documentPath: 'assets/document.pdf',
        configuration: PdfConfiguration(
          webConfiguration: PdfWebConfiguration(
            // Use brand colors for annotations
            defaultAnnotationStrokeColor: brandAccent,
            defaultAnnotationFillColor: brandAccent.withOpacity(0.15),
          ),
        ),
      ),
    );
  }
}
