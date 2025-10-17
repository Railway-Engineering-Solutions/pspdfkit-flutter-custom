# Initial Annotations Feature Guide

## Overview

The `initialAnnotations` feature allows you to automatically add annotations to a document when it first loads. This is useful for:

- **Pre-populating documents** with welcome messages or instructions
- **Highlighting important sections** automatically
- **Adding default annotations** for templates or forms
- **Creating annotated versions** of documents programmatically

## Basic Usage

Simply pass a list of `Annotation` objects to the `initialAnnotations` parameter when creating a `NutrientView`:

```dart
NutrientView(
  documentPath: 'path/to/document.pdf',
  initialAnnotations: [
    NoteAnnotation(
      pageIndex: 0,
      bbox: [50, 50, 80, 80],
      createdAt: DateTime.now().toIso8601String(),
      contents: 'Welcome! This is a pre-loaded note.',
      color: Colors.blue,
    ),
    HighlightAnnotation(
      pageIndex: 0,
      bbox: [100, 150, 300, 180],
      createdAt: DateTime.now().toIso8601String(),
      rects: [[100, 150, 300, 180]],
      color: Colors.yellow,
    ),
  ],
  onDocumentLoaded: (document) {
    print('Document loaded with initial annotations');
  },
);
```

## Supported Annotation Types

You can add any type of annotation as an initial annotation:

### 1. Note Annotations

```dart
NoteAnnotation(
  pageIndex: 0,
  bbox: [50, 50, 80, 80],
  createdAt: DateTime.now().toIso8601String(),
  contents: 'This is a note',
  iconName: 'Comment',
  color: Colors.blue,
)
```

### 2. Text Markup (Highlight, Underline, Strikeout, Squiggly)

```dart
HighlightAnnotation(
  pageIndex: 0,
  bbox: [100, 150, 300, 180],
  createdAt: DateTime.now().toIso8601String(),
  rects: [[100, 150, 300, 180]],
  color: Colors.yellow,
)

UnderlineAnnotation(
  pageIndex: 0,
  bbox: [100, 200, 300, 220],
  createdAt: DateTime.now().toIso8601String(),
  rects: [[100, 200, 300, 220]],
  color: Colors.red,
)
```

### 3. Ink Annotations (Hand-drawn)

```dart
InkAnnotation(
  pageIndex: 0,
  lines: InkLines(
    intensities: [[1.0, 1.0, 1.0]],
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
)
```

### 4. Free Text Annotations

```dart
FreeTextAnnotation(
  pageIndex: 0,
  bbox: [50, 450, 250, 500],
  createdAt: DateTime.now().toIso8601String(),
  contents: 'Important Text',
  fontSize: 16.0,
  fontName: 'Helvetica',
  color: Colors.purple,
  fillColor: Colors.yellow.withOpacity(0.3),
)
```

### 5. Shape Annotations (Square, Circle)

```dart
SquareAnnotation(
  pageIndex: 0,
  bbox: [300, 350, 450, 450],
  createdAt: DateTime.now().toIso8601String(),
  strokeColor: Colors.orange,
  fillColor: Colors.orange.withOpacity(0.2),
  lineWidth: 2.0,
)

CircleAnnotation(
  pageIndex: 0,
  bbox: [100, 500, 200, 600],
  createdAt: DateTime.now().toIso8601String(),
  strokeColor: Colors.blue,
  fillColor: Colors.blue.withOpacity(0.1),
  lineWidth: 2.0,
)
```

## Advanced Examples

### Example 1: Welcome Message on First Page

```dart
List<Annotation> createWelcomeAnnotations() {
  return [
    NoteAnnotation(
      pageIndex: 0,
      bbox: [50, 50, 80, 80],
      createdAt: DateTime.now().toIso8601String(),
      contents: '''
Welcome to this document!

Please review the highlighted sections.
Contact us if you have questions.
      ''',
      iconName: 'Note',
      color: Colors.blue,
    ),
  ];
}

// Usage
NutrientView(
  documentPath: documentPath,
  initialAnnotations: createWelcomeAnnotations(),
)
```

### Example 2: Auto-highlight Important Sections

```dart
List<Annotation> highlightImportantSections() {
  return [
    HighlightAnnotation(
      pageIndex: 0,
      bbox: [100, 100, 500, 130],
      createdAt: DateTime.now().toIso8601String(),
      rects: [[100, 100, 500, 130]],
      color: Colors.yellow,
    ),
    HighlightAnnotation(
      pageIndex: 0,
      bbox: [100, 200, 500, 230],
      createdAt: DateTime.now().toIso8601String(),
      rects: [[100, 200, 500, 230]],
      color: Colors.yellow,
    ),
    // Add more highlights...
  ];
}
```

### Example 3: Template with Instructions

```dart
List<Annotation> createFormInstructions() {
  return [
    FreeTextAnnotation(
      pageIndex: 0,
      bbox: [50, 50, 300, 100],
      createdAt: DateTime.now().toIso8601String(),
      contents: 'Please fill out all required fields',
      fontSize: 14.0,
      fontName: 'Helvetica-Bold',
      color: Colors.red,
    ),
    SquareAnnotation(
      pageIndex: 0,
      bbox: [50, 150, 300, 200],
      createdAt: DateTime.now().toIso8601String(),
      strokeColor: Colors.red,
      lineWidth: 2.0,
    ),
  ];
}
```

### Example 4: Dynamic Annotations from Data

```dart
List<Annotation> createAnnotationsFromData(List<HighlightData> highlights) {
  return highlights.map((highlight) {
    return HighlightAnnotation(
      pageIndex: highlight.pageIndex,
      bbox: highlight.bbox,
      createdAt: DateTime.now().toIso8601String(),
      rects: [highlight.bbox],
      color: highlight.color,
    );
  }).toList();
}

// Usage
final highlights = [
  HighlightData(pageIndex: 0, bbox: [100, 100, 300, 120], color: Colors.yellow),
  HighlightData(pageIndex: 1, bbox: [100, 200, 400, 220], color: Colors.green),
];

NutrientView(
  documentPath: documentPath,
  initialAnnotations: createAnnotationsFromData(highlights),
)
```

## Best Practices

### 1. Use Meaningful Coordinates

Make sure your `bbox` (bounding box) coordinates are appropriate for the page:
- **[left, top, right, bottom]** for most annotations
- Coordinates are in PDF points (1 point = 1/72 inch)
- Origin (0,0) is typically at bottom-left of the page

```dart
// Example: Top-left corner annotation
NoteAnnotation(
  bbox: [50, 50, 80, 80], // 50pts from left, 50pts from top
  // ...
)
```

### 2. Always Include Required Fields

Every annotation needs:
- `pageIndex` - The page to add the annotation to (0-based)
- `bbox` - The bounding box
- `createdAt` - Creation timestamp (ISO 8601 format)

```dart
InkAnnotation(
  pageIndex: 0,  // First page
  bbox: [100, 100, 200, 200],
  createdAt: DateTime.now().toIso8601String(), // Current time
  // ... other properties
)
```

### 3. Handle Errors Gracefully

```dart
NutrientView(
  documentPath: documentPath,
  initialAnnotations: _getInitialAnnotations(),
  onDocumentLoaded: (document) {
    print('Document loaded with annotations');
  },
  onDocumentError: (error) {
    print('Failed to load: $error');
    // Handle error - maybe show default document without annotations
  },
)
```

### 4. Consider Performance

For large numbers of initial annotations:
```dart
// Good: Process in chunks if needed
List<Annotation> _getInitialAnnotations() {
  // Load from cache or database
  final cached = _loadFromCache();
  if (cached != null) return cached;
  
  // Otherwise compute
  final annotations = _computeAnnotations();
  _saveToCache(annotations);
  return annotations;
}
```

### 5. Use Consistent Timestamps

```dart
// Good: Use a single timestamp for all initial annotations
final timestamp = DateTime.now().toIso8601String();

final annotations = [
  NoteAnnotation(
    createdAt: timestamp,
    // ...
  ),
  HighlightAnnotation(
    createdAt: timestamp,
    // ...
  ),
];
```

## Platform Support

| Platform | Support | Notes |
|----------|---------|-------|
| **Web** | ✅ Full | All annotation types supported |
| **iOS** | ✅ Full | All annotation types supported |
| **Android** | ✅ Full | All annotation types supported |

## Troubleshooting

### Annotations Not Appearing?

1. **Check coordinates**: Make sure `bbox` values are within page bounds
2. **Verify page index**: Ensure `pageIndex` is valid (0-based)
3. **Check required fields**: All required properties must be set
4. **Look at console**: Check for error messages in debug output

```dart
// Debug logging
NutrientView(
  documentPath: documentPath,
  initialAnnotations: myAnnotations,
  onDocumentLoaded: (document) {
    print('✓ Document loaded successfully');
    print('✓ ${myAnnotations.length} annotations should be visible');
  },
  onDocumentError: (error) {
    print('✗ Error: $error');
  },
)
```

### Annotations in Wrong Position?

PDF coordinates can be tricky:
- Different coordinate systems on different platforms
- Page rotation affects coordinates
- Zoom level doesn't affect stored coordinates

**Solution**: Test with simple, known coordinates first:

```dart
// Start with a simple top-left annotation
NoteAnnotation(
  pageIndex: 0,
  bbox: [50, 50, 80, 80], // Known good position
  // ...
)
```

### Performance Issues?

If adding many annotations causes slowness:

```dart
// Split into batches
Future<void> _addAnnotationsInBatches(
  PdfDocument document,
  List<Annotation> annotations,
) async {
  const batchSize = 50;
  for (var i = 0; i < annotations.length; i += batchSize) {
    final end = (i + batchSize < annotations.length) 
        ? i + batchSize 
        : annotations.length;
    final batch = annotations.sublist(i, end);
    await document.addAnnotations(batch);
  }
}
```

## Complete Example

See the complete working example at:
```
example/lib/initial_annotations_example.dart
```

This example includes:
- ✓ All major annotation types
- ✓ Proper error handling
- ✓ Info dialog explaining the feature
- ✓ Visual feedback

## API Reference

### NutrientView.initialAnnotations

```dart
final List<Annotation>? initialAnnotations;
```

**Description**: A list of annotations to automatically add when the document loads.

**Type**: `List<Annotation>?` (nullable)

**Default**: `null` (no initial annotations)

**Usage**:
```dart
NutrientView(
  documentPath: 'document.pdf',
  initialAnnotations: [
    // Your annotations here
  ],
)
```

**Timing**: Annotations are added after the document loads but before the `onDocumentLoaded` callback is called.

**Thread Safety**: The operation is performed asynchronously and safely.

## Summary

The `initialAnnotations` feature provides a simple, declarative way to pre-populate documents with annotations:

✓ **Easy to use** - Just pass a list of annotations  
✓ **Type-safe** - Full Dart type checking  
✓ **Automatic** - Annotations added on document load  
✓ **Flexible** - Supports all annotation types  
✓ **Cross-platform** - Works on Web, iOS, and Android  

Perfect for templates, instructions, highlights, and any pre-configured annotations!

