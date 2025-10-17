# Improved Annotation Features

This document describes three major improvements to the Nutrient Flutter package for better annotation handling.

## Overview

The following features have been added:

1. **Color Parameter for Annotation Creation** - Pass a color when entering annotation creation mode
2. **Event Loop Prevention** - Suppress annotation events during programmatic operations
3. **User Interaction Control** - Enable/disable user interaction on the PDF viewer (Web only)

---

## Feature 1: Color Parameter for Annotation Creation

### Problem
Previously, when entering annotation creation mode, you couldn't specify the color for the annotation being created. Users had to manually change the color using the UI color picker, or set it via `setAnnotationConfigurations` which was not supported on Web.

### Solution
The `enterAnnotationCreationMode` method now accepts an optional `Color` parameter:

```dart
Future<bool?> enterAnnotationCreationMode([AnnotationTool? annotationTool, Color? color]);
```

### Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';

// Enter annotation mode with a specific color
await controller.enterAnnotationCreationMode(
  AnnotationTool.inkPen,
  Colors.red,
);

// Create a blue highlight
await controller.enterAnnotationCreationMode(
  AnnotationTool.highlight,
  Colors.blue.withOpacity(0.4),
);

// Create a green shape
await controller.enterAnnotationCreationMode(
  AnnotationTool.square,
  Colors.green,
);
```

### Platform Support

- ✅ **Web**: Fully supported using ViewState API
- ⚠️ **iOS/Android**: Partial support (tool mode works, color parameter planned for future implementation)

### Implementation Details

On Web, the color is applied by setting the `strokeColor` property in the ViewState:

```dart
// Internal implementation (Web)
await pspdfkitInstance.setToolMode(toolMode, color);
```

---

## Feature 2: Event Loop Prevention with `suppressAnnotationEvents`

### Problem
When listening to annotation events (`annotationsCreated`, `annotationsUpdated`, `annotationsDeleted`) and performing operations in those callbacks, you could easily create infinite loops:

```dart
// ❌ BAD: This creates an infinite loop!
controller.addWebEventListener(
  NutrientWebEvent.annotationsCreate,
  (event) async {
    // This triggers another annotationsCreate event, causing a loop!
    await document.annotationManager.addAnnotation(someAnnotation);
  },
);
```

### Solution
The `AnnotationManager` classes now provide a `suppressAnnotationEvents` method that temporarily disables event callbacks:

```dart
Future<T> suppressAnnotationEvents<T>(Future<T> Function() operation) async
```

### Usage Example

```dart
// ✅ GOOD: Using suppressAnnotationEvents prevents the loop
controller.addWebEventListener(
  NutrientWebEvent.annotationsCreate,
  (event) async {
    // Suppress events during programmatic operation
    await document.annotationManager.suppressAnnotationEvents(() async {
      await document.annotationManager.addAnnotation(someAnnotation);
    });
  },
);

// Example: Batch annotation operations without triggering events
await document.annotationManager.suppressAnnotationEvents(() async {
  for (final annotation in annotationsToAdd) {
    await document.annotationManager.addAnnotation(annotation);
  }
});
```

### How It Works

The `suppressAnnotationEvents` method:
1. Sets an internal flag to `true`
2. Executes your operation
3. Restores the previous flag state (supports nested calls)
4. Returns the result of your operation

```dart
bool _suppressAnnotationEvents = false;

Future<T> suppressAnnotationEvents<T>(Future<T> Function() operation) async {
  final previousState = _suppressAnnotationEvents;
  _suppressAnnotationEvents = true;
  try {
    return await operation();
  } finally {
    _suppressAnnotationEvents = previousState;
  }
}
```

### Platform Support

- ✅ **Web**: Fully supported
- ✅ **iOS/Android**: Fully supported

### Best Practices

1. **Always use when programmatically creating/updating/deleting annotations inside event callbacks**
2. **Keep the suppressed operation as short as possible**
3. **Nested calls are supported** - the flag is properly restored

---

## Feature 3: User Interaction Control (Web Only)

### Problem
On the Web platform, when a dialog or overlay is shown over the PDF widget, user clicks pass through to the PDF below. This causes unwanted behavior such as:
- Creating annotations when clicking on dialog buttons
- Selecting text when interacting with overlays
- General click-through issues

### Solution
A new method `setUserInteractionEnabled` allows you to temporarily disable user interaction with the PDF viewer:

```dart
Future<bool?> setUserInteractionEnabled(bool enabled);
```

### Usage Example

```dart
// Disable interaction before showing a dialog
await controller.setUserInteractionEnabled(false);

// Show your dialog
await showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Settings'),
    content: Text('Dialog content here'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Close'),
      ),
    ],
  ),
);

// Re-enable interaction after dialog is closed
await controller.setUserInteractionEnabled(true);
```

### Helper Widget Example

You can create a helper widget to automatically manage interaction state:

```dart
class PdfOverlayWidget extends StatefulWidget {
  final Widget child;
  final NutrientViewController? controller;
  
  const PdfOverlayWidget({
    super.key,
    required this.child,
    this.controller,
  });
  
  @override
  State<PdfOverlayWidget> createState() => _PdfOverlayWidgetState();
}

class _PdfOverlayWidgetState extends State<PdfOverlayWidget> {
  @override
  void initState() {
    super.initState();
    _disableInteraction();
  }
  
  @override
  void dispose() {
    _enableInteraction();
    super.dispose();
  }
  
  Future<void> _disableInteraction() async {
    try {
      await widget.controller?.setUserInteractionEnabled(false);
    } catch (e) {
      // Ignore errors (e.g., if controller is null or not on Web)
    }
  }
  
  Future<void> _enableInteraction() async {
    try {
      await widget.controller?.setUserInteractionEnabled(true);
    } catch (e) {
      // Ignore errors
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Usage:
showDialog(
  context: context,
  builder: (context) => PdfOverlayWidget(
    controller: _controller,
    child: AlertDialog(...),
  ),
);
```

### Implementation Details

On Web, this is implemented using the ViewState `readOnly` property:

```dart
await pspdfkitInstance.setViewState((viewState) {
  return viewState.set('readOnly', !enabled);
});
```

### Platform Support

- ✅ **Web**: Fully supported
- ❌ **iOS/Android**: Not supported (throws `UnimplementedError`)

The feature is Web-only because native platforms handle overlays differently and don't have the same click-through issues.

---

## Complete Example

See the complete working example at:
```
example/lib/improved_annotation_example.dart
```

This example demonstrates all three features working together:

```dart
class ImprovedAnnotationExample extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Controls for color annotation mode
          ElevatedButton(
            onPressed: () => controller.enterAnnotationCreationMode(
              AnnotationTool.inkPen,
              Colors.red,
            ),
            child: Text('Red Pen'),
          ),
          
          // Control for demonstrating loop prevention
          ElevatedButton(
            onPressed: () async {
              await document.annotationManager.suppressAnnotationEvents(() async {
                await document.annotationManager.addAnnotation(annotation);
              });
            },
            child: Text('Add Annotation (No Loop)'),
          ),
          
          // Control for user interaction
          ElevatedButton(
            onPressed: () async {
              await controller.setUserInteractionEnabled(false);
              // Show dialog
              await showDialog(...);
              await controller.setUserInteractionEnabled(true);
            },
            child: Text('Show Dialog'),
          ),
          
          // PDF Viewer
          Expanded(
            child: NutrientView(
              documentPath: documentPath,
              onNutrientViewControllerCreated: _onControllerCreated,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Migration Guide

### From Old API to New API

#### Color in Annotation Creation

**Before:**
```dart
// Old way: Couldn't specify color directly
await controller.enterAnnotationCreationMode(AnnotationTool.inkPen);
// User had to manually select color from UI
```

**After:**
```dart
// New way: Specify color directly
await controller.enterAnnotationCreationMode(
  AnnotationTool.inkPen,
  Colors.red,
);
```

#### Preventing Event Loops

**Before:**
```dart
// Old way: Manual flag management
bool _isProcessing = false;

controller.addWebEventListener(
  NutrientWebEvent.annotationsCreate,
  (event) async {
    if (_isProcessing) return; // Skip to prevent loop
    _isProcessing = true;
    try {
      await document.annotationManager.addAnnotation(annotation);
    } finally {
      _isProcessing = false;
    }
  },
);
```

**After:**
```dart
// New way: Built-in suppression
controller.addWebEventListener(
  NutrientWebEvent.annotationsCreate,
  (event) async {
    await document.annotationManager.suppressAnnotationEvents(() async {
      await document.annotationManager.addAnnotation(annotation);
    });
  },
);
```

#### Dialog Over PDF (Web)

**Before:**
```dart
// Old way: Clicks passed through to PDF
await showDialog(
  context: context,
  builder: (context) => AlertDialog(...),
);
// Problem: Clicking dialog buttons could trigger annotations below
```

**After:**
```dart
// New way: Disable interaction during dialog
await controller.setUserInteractionEnabled(false);
await showDialog(
  context: context,
  builder: (context) => AlertDialog(...),
);
await controller.setUserInteractionEnabled(true);
```

---

## API Reference

### NutrientViewController / PspdfkitWidgetController

#### `enterAnnotationCreationMode`

```dart
Future<bool?> enterAnnotationCreationMode([
  AnnotationTool? annotationTool,
  Color? color
]);
```

**Parameters:**
- `annotationTool` (optional): The annotation tool to activate
- `color` (optional): The color to use for the annotation

**Returns:** `Future<bool?>` indicating success

**Platform Support:**
- Web: ✅ Full support
- iOS/Android: ⚠️ Tool parameter supported, color parameter in development

---

#### `setUserInteractionEnabled`

```dart
Future<bool?> setUserInteractionEnabled(bool enabled);
```

**Parameters:**
- `enabled`: `true` to enable user interaction, `false` to disable

**Returns:** `Future<bool?>` indicating success

**Platform Support:**
- Web: ✅ Full support
- iOS/Android: ❌ Throws `UnimplementedError`

**Throws:** `UnimplementedError` on iOS/Android platforms

---

### AnnotationManager

#### `suppressAnnotationEvents`

```dart
Future<T> suppressAnnotationEvents<T>(Future<T> Function() operation);
```

**Parameters:**
- `operation`: The async function to execute with suppressed events

**Returns:** The result of the operation

**Platform Support:**
- Web: ✅ Full support
- iOS/Android: ✅ Full support

**Example:**
```dart
final result = await annotationManager.suppressAnnotationEvents(() async {
  await annotationManager.addAnnotation(annotation);
  return 'success';
});
print(result); // 'success'
```

---

#### `isSuppressingAnnotationEvents`

```dart
bool get isSuppressingAnnotationEvents;
```

**Returns:** `true` if events are currently being suppressed

**Platform Support:**
- Web: ✅ Full support
- iOS/Android: ✅ Full support

---

## Troubleshooting

### Issue: Color doesn't apply on native platforms

**Solution:** The color parameter is currently only fully supported on Web. On iOS/Android, the tool mode will work but the color needs to be set using `setAnnotationConfigurations` as a workaround until full support is implemented.

```dart
// Workaround for native platforms
await controller.setAnnotationConfigurations({
  AnnotationTool.inkPen: InkAnnotationConfiguration(
    color: Colors.red,
  ),
});
await controller.enterAnnotationCreationMode(AnnotationTool.inkPen);
```

### Issue: `setUserInteractionEnabled` throws error on iOS/Android

**Solution:** This feature is Web-only. Wrap calls in a try-catch or platform check:

```dart
if (kIsWeb) {
  await controller.setUserInteractionEnabled(false);
}

// Or with error handling:
try {
  await controller.setUserInteractionEnabled(false);
} catch (e) {
  // Ignore on non-Web platforms
}
```

### Issue: Events still firing despite using `suppressAnnotationEvents`

**Solution:** Make sure you're calling `suppressAnnotationEvents` on the AnnotationManager, not the controller:

```dart
// ❌ Wrong
await controller.suppressAnnotationEvents(...); // No such method

// ✅ Correct
await document.annotationManager.suppressAnnotationEvents(...);
```

---

## Performance Considerations

### `suppressAnnotationEvents`
- Minimal performance impact
- Flag check is O(1) operation
- Supports nested calls without degradation

### `setUserInteractionEnabled`
- Lightweight on Web (single ViewState update)
- No performance impact on native (throws immediately)

### Color in Annotation Mode
- No performance impact
- Color is set once when entering annotation mode
- Same performance as without color parameter

---

## Future Improvements

### Planned Features
1. **Native color support**: Full implementation of color parameter for iOS/Android
2. **Event filtering**: More granular control over which events to suppress
3. **Interaction regions**: Ability to disable interaction in specific regions only

### Feedback
If you have suggestions or encounter issues with these features, please file an issue on the GitHub repository.

---

## Summary

These three improvements significantly enhance annotation handling in the Nutrient Flutter package:

1. **✅ Color Parameter** - Directly specify annotation colors when entering creation mode
2. **✅ Loop Prevention** - Built-in mechanism to prevent infinite event loops
3. **✅ Interaction Control** - Prevent click-through issues on Web platform

All features are designed to be easy to use, performant, and follow Flutter best practices.

