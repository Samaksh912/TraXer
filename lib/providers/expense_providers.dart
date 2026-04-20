import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/isar_expense.dart';
import '../repositories/expense_repository.dart';
import '../services/isar_service.dart';
import '../services/sync_service.dart';

final isarProvider = Provider<Isar>((ref) => isar);

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(isarProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    repository: ref.watch(expenseRepositoryProvider),
    firestore: FirebaseFirestore.instance,
  );
});

final expensesProvider = StreamProvider<List<IsarExpense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchActiveExpenses();
});

final totalExpenseProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesProvider).valueOrNull ?? [];
  return expenses
      .where((expense) => expense.type == TransactionType.expense && !expense.isDeleted)
      .fold(0.0, (sum, expense) => sum + expense.amount);
});

final totalIncomeProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesProvider).valueOrNull ?? [];
  return expenses
      .where((expense) => expense.type == TransactionType.income && !expense.isDeleted)
      .fold(0.0, (sum, expense) => sum + expense.amount);
});
