# Default Annotation Color System

## Overview

The default annotation color system allows you to set a **global default color** for all annotation operations. This color will be used automatically when no specific color is provided to annotation methods, making it easier to maintain consistent styling across your application.

## Key Features

✅ **Set a default color** that applies to all annotation operations  
✅ **Override on demand** by providing specific colors when needed  
✅ **Persistent across sessions** - the color stays set until changed  
✅ **Web platform support** - fully implemented for web  
✅ **Loop prevention** - prevents infinite loops when modifying annotations  

## How It Works

### 1. Set Default Color
```dart
// Set red as the default color for all annotations
await controller.setDefaultAnnotationColor(Colors.red);
```

### 2. Use Default Color
```dart
// This will use the default red color
await controller.enterAnnotationCreationMode(AnnotationTool.inkPen);

// This will use blue instead of the default
await controller.enterAnnotationCreationMode(AnnotationTool.inkPen, Colors.blue);
```

### 3. Check Current Default
```dart
Color? currentDefault = controller.defaultAnnotationColor;
print('Current default: $currentDefault');
```

## Complete Example

```dart
class MyPDFViewer extends StatefulWidget {
  @override
  _MyPDFViewerState createState() => _MyPDFViewerState();
}

class _MyPDFViewerState extends State<MyPDFViewer> {
  NutrientViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Color picker buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _setDefaultColor(Colors.red),
                child: Text('Red'),
              ),
              ElevatedButton(
                onPressed: () => _setDefaultColor(Colors.blue),
                child: Text('Blue'),
              ),
              ElevatedButton(
                onPressed: () => _setDefaultColor(Colors.green),
                child: Text('Green'),
              ),
            ],
          ),
          // PDF viewer
          Expanded(
            child: NutrientView(
              documentPath: 'path/to/document.pdf',
              onViewCreated: _onViewCreated,
            ),
          ),
        ],
      ),
    );
  }

  void _onViewCreated(NutrientViewController controller) {
    _controller = controller;
    
    // Set initial default color
    _setDefaultColor(Colors.red);
    
    // Listen to annotation events
    controller.addWebEventListener(
      NutrientWebEvent.annotationsCreate,
      _onAnnotationCreated,
    );
  }

  Future<void> _setDefaultColor(Color color) async {
    await _controller?.setDefaultAnnotationColor(color);
    print('Default color set to: $color');
  }

  Future<void> _onAnnotationCreated(dynamic event) async {
    // When annotations are created, they automatically use the default color
    print('New annotation created with default color');
    
    // You can still modify annotations without creating loops
    if (_document != null) {
      await _document!.addAnnotations([/* your annotations */]);
    }
  }
}
```

## API Reference

### Controller Methods

#### `setDefaultAnnotationColor(Color color)`
Sets the default color for all annotation operations.

**Parameters:**
- `color` - The color to use as default

**Returns:** `Future<bool?>` - true if successful, false if failed

**Example:**
```dart
await controller.setDefaultAnnotationColor(Colors.red);
```

#### `defaultAnnotationColor` (getter)
Gets the current default annotation color.

**Returns:** `Color?` - The current default color, or null if not set

**Example:**
```dart
Color? currentColor = controller.defaultAnnotationColor;
```

### How Default Color is Applied

The default color system works by:

1. **Storing the color** in the `NutrientWebInstance`
2. **Checking for override** when `enterAnnotationCreationMode` is called
3. **Using default if no override** is provided
4. **Applying to PSPDFKit context** via the Web SDK's ViewState API

```dart
// Internal logic (simplified)
Color? colorToUse = providedColor ?? defaultColor;
if (colorToUse != null) {
  // Apply color to PSPDFKit context
  viewState.set('strokeColor', pspdfkitColor);
}
```

## Use Cases

### Use Case 1: Brand Colors
```dart
// Set your brand color as default
await controller.setDefaultAnnotationColor(Colors.blue.shade700);

// All annotations will use brand blue
await controller.enterAnnotationCreationMode(AnnotationTool.highlight);
await controller.enterAnnotationCreationMode(AnnotationTool.inkPen);
```

### Use Case 2: User Preferences
```dart
// Load user's preferred color from settings
Color userColor = await loadUserPreferredColor();
await controller.setDefaultAnnotationColor(userColor);
```

### Use Case 3: Dynamic Color Themes
```dart
// Change color based on time of day
Color getTimeBasedColor() {
  final hour = DateTime.now().hour;
  if (hour < 12) return Colors.yellow; // Morning
  if (hour < 18) return Colors.orange; // Afternoon
  return Colors.purple; // Evening
}

await controller.setDefaultAnnotationColor(getTimeBasedColor());
```

### Use Case 4: Conditional Colors
```dart
// Set different colors based on document type
if (documentType == 'legal') {
  await controller.setDefaultAnnotationColor(Colors.red);
} else if (documentType == 'educational') {
  await controller.setDefaultAnnotationColor(Colors.green);
} else {
  await controller.setDefaultAnnotationColor(Colors.blue);
}
```

## Integration with Loop Prevention

The default color system works seamlessly with the loop prevention feature:

```dart
controller.addWebEventListener(
  NutrientWebEvent.annotationsCreate,
  (event) async {
    // Create annotations using the default color
    final note = NoteAnnotation(
      pageIndex: 0,
      bbox: [100, 100, 200, 150],
      createdAt: DateTime.now().toIso8601String(),
      text: TextContent(
        format: TextFormat.plain,
        value: 'Auto-generated note',
      ),
      color: controller.defaultAnnotationColor, // Use default color
    );
    
    // Add without creating loops
    await document.addAnnotations([note]);
  },
);
```

## Platform Support

| Platform | Default Color Support | Notes |
|----------|---------------------|-------|
| **Web** | ✅ Full | Complete implementation with PSPDFKit Web SDK |
| **iOS** | ⚠️ Limited | Throws UnimplementedError |
| **Android** | ⚠️ Limited | Throws UnimplementedError |

## Best Practices

### 1. Set Default Color Early
```dart
void _onViewCreated(NutrientViewController controller) {
  _controller = controller;
  
  // Set default color immediately after controller creation
  _setDefaultColor(Colors.blue);
}
```

### 2. Provide Override Options
```dart
// Allow users to override default color when needed
Future<void> createAnnotationWithColor(AnnotationTool tool, Color? color) async {
  await controller.enterAnnotationCreationMode(
    tool, 
    color ?? controller.defaultAnnotationColor,
  );
}
```

### 3. Handle Platform Differences
```dart
Future<void> setDefaultColorSafely(Color color) async {
  try {
    await controller.setDefaultAnnotationColor(color);
  } catch (e) {
    if (e is UnimplementedError) {
      print('Default color not supported on this platform');
    } else {
      print('Error setting default color: $e');
    }
  }
}
```

### 4. Store User Preferences
```dart
Future<void> saveUserColorPreference(Color color) async {
  // Save to local storage
  await SharedPreferences.getInstance().then((prefs) {
    prefs.setInt('default_annotation_color', color.value);
  });
  
  // Apply to controller
  await controller.setDefaultAnnotationColor(color);
}
```

## Troubleshooting

### Default Color Not Working?

**Check 1:** Are you on the Web platform?
```dart
if (kIsWeb) {
  // Default color works here
  await controller.setDefaultAnnotationColor(Colors.red);
} else {
  // Not supported on native platforms yet
  print('Default color not supported on this platform');
}
```

**Check 2:** Did you set the color after controller creation?
```dart
// ✅ Good
void _onViewCreated(NutrientViewController controller) {
  _controller = controller;
  _setDefaultColor(Colors.red); // Set after controller is ready
}

// ❌ Bad
void initState() {
  super.initState();
  _setDefaultColor(Colors.red); // Controller not ready yet
}
```

**Check 3:** Are you providing an override color?
```dart
// This will use blue, not the default red
await controller.enterAnnotationCreationMode(
  AnnotationTool.inkPen, 
  Colors.blue, // This overrides the default
);
```

### Color Not Persisting?

The default color persists for the lifetime of the controller instance. If you're creating new controller instances, you need to set the default color again:

```dart
void _onViewCreated(NutrientViewController controller) {
  _controller = controller;
  
  // Always set default color when controller is created
  _setDefaultColor(_currentDefaultColor);
}
```

## Migration Guide

### From Manual Color Management

**Before:**
```dart
// Had to specify color every time
await controller.enterAnnotationCreationMode(AnnotationTool.inkPen, Colors.red);
await controller.enterAnnotationCreationMode(AnnotationTool.highlight, Colors.red);
await controller.enterAnnotationCreationMode(AnnotationTool.note, Colors.red);
```

**After:**
```dart
// Set once, use everywhere
await controller.setDefaultAnnotationColor(Colors.red);
await controller.enterAnnotationCreationMode(AnnotationTool.inkPen);
await controller.enterAnnotationCreationMode(AnnotationTool.highlight);
await controller.enterAnnotationCreationMode(AnnotationTool.note);
```

### From Hardcoded Colors

**Before:**
```dart
const Color ANNOTATION_COLOR = Colors.red;

await controller.enterAnnotationCreationMode(AnnotationTool.inkPen, ANNOTATION_COLOR);
```

**After:**
```dart
await controller.setDefaultAnnotationColor(Colors.red);
await controller.enterAnnotationCreationMode(AnnotationTool.inkPen);
```

## Summary

The default annotation color system provides:

🎯 **Consistent styling** - One color for all annotations  
🎯 **Easy management** - Set once, use everywhere  
🎯 **Flexible overrides** - Override when needed  
🎯 **Loop prevention** - Safe annotation modification  
🎯 **Web optimization** - Full PSPDFKit Web SDK integration  

```dart
// Simple usage pattern:
await controller.setDefaultAnnotationColor(Colors.red);
await controller.enterAnnotationCreationMode(AnnotationTool.inkPen);
// Ink pen will use red color automatically!
```

This system makes annotation color management much simpler and more maintainable, especially for applications that need consistent branding or user preferences.

