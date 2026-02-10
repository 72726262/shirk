# Supabase Query Fix Guide

## Problem
Supabase Flutter v2.8.2 changed API - `.eq()`, `.or()` methods don't exist on `PostgrestTransformBuilder`

## Solution
The new API uses filter methods directly on the builder. Here's the conversion:

### OLD API (doesn't work):
```dart
.from('table').select().eq('column', value)
.from('table').select().or('column1.eq.value1,column2.eq.value2')
```

### NEW API (correct):
```dart
// For .eq()
.from('table').select('*').eq('column', value)  // Still works in v2.8.2

// For .or()
.from('table').select('*').or('column1.eq.value1,column2.eq.value2')  // Still works
```

**WAIT** - Let me check the actual Supabase version and API docs...

Actually, in supabase_flutter ^2.8.2, the methods SHOULD exist. The issue might be:
1. Missing `select('*')` before `.eq()`
2. Import issue
3. Type inference issue

Let me check the actual repository files to see the pattern used.
