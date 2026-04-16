## Plan: Voice-to-Transaction Flow Integration

Implement a dedicated voice parsing pipeline around the current `HomePage` flow by separating speech capture, Wit.ai parsing, confidence routing, and transaction persistence. The project already has core transaction storage/UI (`IsarExpense`, add dialog, transaction list), but mic handling is only a placeholder and type naming is inconsistent in prior errors. This plan adds a thin orchestration layer so high-confidence results use quick confirmation, while low-confidence results open a full editable form.

### Steps
1. Normalize transaction typing to `IsarExpense` across [`lib/models/isarexpense.dart`](D:/TraXer/traxer/lib/models/isarexpense.dart), [`lib/pages/homepage.dart`](D:/TraXer/traxer/lib/pages/homepage.dart), and `onAddExpense` callback signatures.
2. Add voice/NLU contracts in new files like [`lib/models/voice_parse_result.dart`](D:/TraXer/traxer/lib/models/voice_parse_result.dart) and services for `speech_to_text` + Wit.ai request/response mapping.
3. Introduce a voice coordinator in [`lib/pages/homepage.dart`](D:/TraXer/traxer/lib/pages/homepage.dart) (`_handleMicTap`, `_processVoiceText`) and connect mic tap from [`lib/components/navbar.dart`](D:/TraXer/traxer/lib/components/navbar.dart).
4. Define confidence routing (`confidenceThreshold`, `categoryMap` fallback) in a dedicated config helper, then branch to confirm sheet (`showModalBottomSheet`) or full edit route.
5. Refactor [`lib/components/expensedialog.dart`](D:/TraXer/traxer/lib/components/expensedialog.dart) to accept optional draft values, so low-confidence flow opens complete editable expense/income form.
6. Add platform/runtime prerequisites: mic permissions in [`android/app/src/main/AndroidManifest.xml`](D:/TraXer/traxer/android/app/src/main/AndroidManifest.xml), speech keys in [`ios/Runner/Info.plist`](D:/TraXer/traxer/ios/Runner/Info.plist), and dependencies in [`pubspec.yaml`](D:/TraXer/traxer/pubspec.yaml).

### Further Considerations
1. Confidence threshold choice: conservative (`0.85`) / balanced (`0.75`) / aggressive (`0.65`)?
2. Full-edit UX: reuse `AddExpenseDialog` with prefill / create dedicated `EditTransactionPage` / hybrid (sheet then expand)?
3. Wit.ai token strategy: `--dart-define` only / secure backend proxy / Firebase Remote Config indirection?
