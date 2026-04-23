import 'package:isar/isar.dart';

part 'isar_expense.g.dart';

enum TransactionType { expense, income }

@collection
class IsarExpense {
  IsarExpense();

  Id id = Isar.autoIncrement;

  late String title;
  late double amount;
  late String category;

  @Enumerated(EnumType.ordinal)
  late TransactionType type;

  @Index()
  late DateTime createdAt;

  @Index(unique: true)
  late String uuid;

  @Index()
  late DateTime updatedAt;

  @Index()
  bool isSynced = false;

  @Index()
  bool isDeleted = false;

  Map<String, dynamic> toSupabaseMap({required String userId}) {
    return {
      'user_id': userId,
      'uuid': uuid,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type.name,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_synced': isSynced,
      'is_deleted': isDeleted,
    };
  }

  factory IsarExpense.fromSupabaseMap(
    Map<String, dynamic> map, {
    String? fallbackUuid,
  }) {
    final expense = IsarExpense()
      ..uuid = (map['uuid'] as String?) ?? fallbackUuid ?? ''
      ..title = (map['title'] as String?) ?? ''
      ..amount = _readDouble(map['amount'])
      ..category = (map['category'] as String?) ?? ''
      ..type = _readTransactionType(map['type'])
      ..createdAt = _readDateTime(map['created_at']) ?? DateTime.now()
      ..updatedAt =
          _readDateTime(map['updated_at']) ??
          _readDateTime(map['created_at']) ??
          DateTime.now()
      ..isSynced = (map['is_synced'] as bool?) ?? true
      ..isDeleted = (map['is_deleted'] as bool?) ?? false;

    return expense;
  }

  static double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }

  static TransactionType _readTransactionType(Object? value) {
    if (value is String) {
      return TransactionType.values.firstWhere(
        (candidate) => candidate.name == value,
        orElse: () => TransactionType.expense,
      );
    }

    if (value is num) {
      final index = value.toInt();
      if (index >= 0 && index < TransactionType.values.length) {
        return TransactionType.values[index];
      }
    }

    return TransactionType.expense;
  }

  static DateTime? _readDateTime(Object? value) {

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
