import '../models/isar_expense.dart';

/// Holds the result of parsing a voice transcript into a structured transaction.
class VoiceParseResult {
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final double confidence; // 0.0 – 1.0

  const VoiceParseResult({
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.confidence,
  });

  /// Converts to an IsarExpense draft (id = autoincrement, date = now)
  IsarExpense toIsarExpense() {
    return IsarExpense()
      ..title = title
      ..amount = amount
      ..createdAt = DateTime.now()
      ..category = category
      ..type = type;
  }
}
