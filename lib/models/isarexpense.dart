import 'package:isar/isar.dart';

part 'isarexpense.g.dart';

// 1. Define the Enum
enum TransactionType { expense, income }

@collection
class IsarExpense {
  Id id = Isar.autoIncrement;

  late String title;
  late double amount;
  late DateTime date;
  late String category;

  @Index()
  late DateTime createdDate;

  // 2. Add the type field with a default value
  @Enumerated(EnumType.ordinal) // Save as 0 or 1
  late TransactionType type;
}