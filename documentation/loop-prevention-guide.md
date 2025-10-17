# Preventing Infinite Loops with Annotation Events

## The Problem

When you listen to annotation events (create/update/delete) and then modify annotations in those event callbacks, you can easily create an **infinite loop**:

```dart
// ❌ BAD: This creates an infinite loop!
controller.addWebEventListener(
  NutrientWebEvent.annotationsCreate,
  (event) async {
    // When annotation is created, we update its color
    var annotation = event['argument1']['annotations'][0];
    annotation.color = Colors.red;
    
    // This triggers another annotationsCreate event!
    // Which calls this callback again!
    // Which updates the color again!
    // Which triggers another event!
    // INFINITE LOOP! 🔥
    await document.addAnnotation(annotation);
  },
);
```

## The Solution: suppressAnnotationEvents

Use the `suppressAnnotationEvents` method to temporarily disable event callbacks during programmatic operations:

```dart
// ✅ GOOD: No infinite loop!
controller.addWebEventListener(
  NutrientWebEvent.annotationsCreate,
  (event) async {
    var annotations = event['argument1']['annotations'];
    
    // Wrap annotation modifications in suppressAnnotationEvents
    await document.annotationManager.suppressAnnotationEvents(() async {
      for (var annotation in annotations) {
        // Modify and save - events are suppressed!
        annotation.color = Colors.red;
        await document.annotationManager.addAnnotation(annotation);
      }
    });
    // Events are automatically re-enabled after the function completes
  },
);
```

## How It Works

### 1. The suppression flag is set
```dart
await document.annotationManager.suppressAnnotationEvents(() async {
  // Inside this block:
  // - _suppressAnnotationEvents flag = true
  // - Any annotation operations won't trigger callbacks
  
  await document.annotationManager.addAnnotation(myAnnotation);
  await document.annotationManager.updateAnnotation(updated);
});
// After the block:
// - _suppressAnnotationEvents flag = false
// - Events work normally again
```

### 2. Event callbacks check the flag
Before invoking your callback, the controller checks:
```dart
if (AnnotationManagerWeb.shouldSuppressEvents()) {
  print('Suppressing event'); // Event is blocked
  return; // Your callback is NOT called
}
userCallback(data); // Your callback is called normally
```

### 3. The loop is prevented
```
User creates annotation
  ↓
annotationsCreate event fires
  ↓
Your callback is invoked
  ↓
suppressAnnotationEvents(() async {  ← FLAG SET TO TRUE
    ↓
    Modify annotation programmatically
    ↓
    annotationsCreate event fires... BUT SUPPRESSED! 🛡️
    ↓
    (Your callback is NOT invoked)
})  ← FLAG SET BACK TO FALSE
  ↓
Done! No loop!
```

## Common Use Cases

### Use Case 1: Auto-Adding Color to Annotations

```dart
controller.addWebEventListener(
  NutrientWebEvent.annotationsCreate,
  (event) async {
    final annotations = event['argument1']['annotations'];
    
    await document.annotationManager.suppressAnnotationEvents(() async {
      for (var annotation in annotations) {
        // Set color based on type
        if (annotation is InkAnnotation) {
          annotation.strokeColor = Colors.blue;
        } else if (annotation is HighlightAnnotation) {
          annotation.color = Colors.yellow;
        }
        
        // Update without triggering another event
        await document.annotationManager.updateAnnotation(annotation);
      }
    });
  },
);
```

### Use Case 2: Auto-Adding Metadata

```dart
controller.addWebEventListener(
  NutrientWebEvent.annotationsCreate,
  (event) async {
    final annotations = event['argument1']['annotations'];
    
    await document.annotationManager.suppressAnnotationEvents(() async {
      for (var annotation in annotations) {
        // Add metadata note near the annotation
        final note = NoteAnnotation(
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
            value: 'Created by ${currentUser.name}',
          ),
          color: Colors.green,
        );
        
        await document.annotationManager.addAnnotation(note);
      }
    });
  },
);
```

### Use Case 3: Validation and Modification

```dart
controller.addWebEventListener(
  NutrientWebEvent.annotationsCreate,
  (event) async {
    final annotations = event['argument1']['annotations'];
    
    await document.annotationManager.suppressAnnotationEvents(() async {
      for (var annotation in annotations) {
        // Validate and fix annotations
        if (annotation is FreeTextAnnotation) {
          // Ensure minimum font size
          if (annotation.fontSize < 12) {
            annotation.fontSize = 12;
            await document.annotationManager.updateAnnotation(annotation);
          }
        }
      }
    });
  },
);
```

### Use Case 4: Batch Operations

```dart
controller.addWebEventListener(
  NutrientWebEvent.annotationsCreate,
  (event) async {
    // When one annotation is created, create related annotations
    final annotation = event['argument1']['annotations'][0];
    
    await document.annotationManager.suppressAnnotationEvents(() async {
      // Create a border around the annotation
      final border = SquareAnnotation(
        pageIndex: annotation.pageIndex,
        bbox: [
          annotation.bbox[0] - 5,
          annotation.bbox[1] - 5,
          annotation.bbox[2] + 5,
          annotation.bbox[3] + 5,
        ],
        createdAt: DateTime.now().toIso8601String(),
        strokeColor: Colors.red,
        strokeWidth: 2.0,
      );
      
      // Add label
      final label = FreeTextAnnotation(
        pageIndex: annotation.pageIndex,
        bbox: [
          annotation.bbox[0],
          annotation.bbox[3] + 10,
          annotation.bbox[0] + 100,
          annotation.bbox[3] + 30,
        ],
        createdAt: DateTime.now().toIso8601String(),
        text: TextContent(
          format: TextFormat.plain,
          value: 'Important',
        ),
        fontSize: 10,
        fontColor: Colors.red,
      );
      
      // Add both without triggering more events
      await document.annotationManager.addAnnotations([border, label]);
    });
  },
);
```

## Best Practices

### 1. Always wrap programmatic modifications
```dart
// ✅ Good
controller.addWebEventListener(event, (data) async {
  await document.annotationManager.suppressAnnotationEvents(() async {
    // Your modifications here
  });
});

// ❌ Bad
controller.addWebEventListener(event, (data) async {
  // Direct modifications - will cause loops!
  await document.annotationManager.addAnnotation(annotation);
});
```

### 2. Keep suppression blocks short
```dart
// ✅ Good - suppress only what's needed
await document.annotationManager.suppressAnnotationEvents(() async {
  await document.annotationManager.addAnnotation(annotation);
});
// UI updates happen here normally

// ❌ Bad - suppresses too much
await document.annotationManager.suppressAnnotationEvents(() async {
  await document.annotationManager.addAnnotation(annotation);
  await Future.delayed(Duration(seconds: 2));
  setState(() { /* ... */ });
  // All these are unnecessarily suppressed
});
```

### 3. Handle errors properly
```dart
controller.addWebEventListener(event, (data) async {
  try {
    await document.annotationManager.suppressAnnotationEvents(() async {
      // Your operations
      await document.annotationManager.addAnnotation(annotation);
    });
  } catch (e) {
    print('Error modifying annotation: $e');
    // Events are automatically re-enabled even on error
  }
});
```

### 4. Nested calls are supported
```dart
await document.annotationManager.suppressAnnotationEvents(() async {
  await operation1();
  
  await document.annotationManager.suppressAnnotationEvents(() async {
    // Nested suppression is fine
    await operation2();
  });
  
  await operation3();
});
// Flag is properly restored to original state
```

## Debugging

### Enable debug logging
Set `kDebugMode` to see suppression in action:

```dart
// You'll see logs like:
// Processing NutrientWebEvent.annotationsCreate event: {...}
// Suppressing NutrientWebEvent.annotationsCreate event
```

### Check if events are being suppressed
```dart
if (document.annotationManager.isSuppressingAnnotationEvents) {
  print('Events are currently suppressed');
}
```

### Count events to detect loops
```dart
int eventCount = 0;

controller.addWebEventListener(event, (data) async {
  eventCount++;
  print('Event #$eventCount');
  
  if (eventCount > 10) {
    print('WARNING: Possible infinite loop detected!');
    return;
  }
  
  // Your code...
});
```

## Troubleshooting

### Events still looping?

**Check 1:** Are you using `suppressAnnotationEvents`?
```dart
// Make sure you're using this:
await document.annotationManager.suppressAnnotationEvents(() async {
  // Your modifications
});
```

**Check 2:** Are you modifying annotations inside the callback?
```dart
// If you're doing THIS inside an event callback:
await document.addAnnotation(...);
await document.updateAnnotation(...);
await document.removeAnnotation(...);

// You MUST wrap it in suppressAnnotationEvents!
```

**Check 3:** Are you on the Web platform?
```dart
// This feature is currently fully implemented for Web
// Native platforms have basic support
if (kIsWeb) {
  // Full suppression support
} else {
  // Limited support
}
```

### Events not firing at all?

**Check 1:** Did you forget to close the suppression block?
```dart
// ❌ Bad - events stay suppressed!
_suppressStart();
await document.addAnnotation(annotation);
// Forgot to call _suppressEnd()!

// ✅ Good - automatically closed
await document.annotationManager.suppressAnnotationEvents(() async {
  await document.addAnnotation(annotation);
}); // Events re-enabled here automatically
```

**Check 2:** Are you listening to the right events?
```dart
// Make sure your listener is registered:
controller.addWebEventListener(
  NutrientWebEvent.annotationsCreate, // Check event name
  yourCallback,
);
```

## Platform Support

| Platform | Suppression Support | Notes |
|----------|-------------------|-------|
| **Web** | ✅ Full | Complete implementation |
| **iOS** | ✅ Full | Complete implementation |
| **Android** | ✅ Full | Complete implementation |

## Complete Example

See the complete working example at:
```
example/lib/loop_prevention_example.dart
```

This example shows:
- ✓ Listening to annotation events
- ✓ Modifying annotations in callbacks
- ✓ Using suppressAnnotationEvents to prevent loops
- ✓ Event logging to see suppression in action
- ✓ Statistics to verify no loops occur

## Summary

**The Problem:** Modifying annotations in event callbacks creates infinite loops.

**The Solution:** Wrap modifications in `suppressAnnotationEvents()`.

**The Result:** No more loops! Events are temporarily suppressed during programmatic operations.

```dart
// Simple formula for success:
controller.addWebEventListener(event, (data) async {
  await document.annotationManager.suppressAnnotationEvents(() async {
    // Modify annotations here safely
  });
});
```

🎯 **Remember:** If you're modifying annotations in an annotation event callback, you MUST use `suppressAnnotationEvents` to prevent infinite loops!

