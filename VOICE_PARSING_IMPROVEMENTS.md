# Voice Parsing Improvements - Homophone Handling

## Issue Fixed
The voice parser was having trouble with homophones that speech-to-text systems commonly misrecognize:
- "for" → "4" (sounds similar)
- "to" → "2" (sounds similar)
- Example: User says "add expense for 20 rupees for printing"
- STT converts to: "add expense 4 20 rupees 4 printing"
- **Result**: Parser was confused about amounts and subjects

## Solutions Implemented

### 1. **Homophone Normalization** (New Step 0)
Added intelligent homophone-to-word conversion at the very beginning of parsing:
```dart
"4 <verb/noun>" → "for <verb/noun>"  (when not quantity context)
"2 <verb/noun>" → "to <verb/noun>"   (when not quantity context)
```

**Smart Detection**: Only converts if the digit is NOT followed by quantity units:
- ✅ "4 printing" → "for printing" (correct conversion)
- ❌ "4 bottles" → stays as "4 bottles" (prevents wrong conversion)

### 2. **Improved Amount Detection**
Enhanced the bare number extraction logic to distinguish between:
- **Quantities**: Small numbers used for item counts (1-3 items)
- **Amounts**: Larger transaction values (≥ 5 rupees)

**Old behavior**: Just picks the last number regardless of context
**New behavior**: 
- First pass: Looks for larger numbers (≥ 5) in reverse order
- Fallback: Uses last number if all are small

This prevents parsing "2" from "2 books" as the transaction amount when "400" is the actual amount.

### 3. **Robust Subject Extraction**
Improved the subject extraction to handle:
- Multiple prepositions ("for X for Y" patterns)
- Leftover artifact numbers from failed homophone normalization
- Better context awareness using the preposition-matching strategies

**New Strategy 7**: Cleans out leftover numbers before extracting meaningful subject tokens, ensuring subjects like "printing" are properly captured even if "4"s are left in the text.

## Test Coverage
All 12 test cases pass, including:
- ✅ Homophone conversion: "4" → "for"
- ✅ Quantity vs Amount: "2 books for 400" correctly parses amount as 400
- ✅ Multiple prepositions: "for X for Y" patterns
- ✅ Brand detection: Subject properly extracted for brand lookup
- ✅ Category detection: Gym → Health, Domino's → Food, etc.
- ✅ Confidence scoring consistency

## Real-World Examples

### Before (Buggy)
```
Input:  "add expense 4 20 rupees 4 printing"
Amount: Incorrectly parsed (might pick wrong number)
Subject: Confused about what "printing" is
```

### After (Fixed)
```
Input:  "add expense 4 20 rupees 4 printing"
Amount: 20.0 ✓
Title:  "Printing" ✓
Type:   Expense ✓
```

## Performance Impact
- **Minimal overhead**: Regex matching only at parse start
- **Zero additional latency**: All operations remain on-device
- **Better accuracy**: Fewer manual corrections needed by users

## Files Modified
- `/home/samaksh/StudioProjects/TraXer/lib/services/voice_parse_service.dart`
  - Added `_normalizeHomophones()` method
  - Updated `parse()` to call normalization as Step 0
  - Improved `_extractSubject()` with new strategy
  - Enhanced bare number detection logic

## Testing
Run the test suite:
```bash
cd /home/samaksh/StudioProjects/TraXer
flutter test test_homophone_fixes.dart
```

All 12 tests pass successfully! ✅
