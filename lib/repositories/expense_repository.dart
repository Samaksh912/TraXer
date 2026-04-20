import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../models/app_sync_state.dart';
import '../models/isar_expense.dart';
import '../models/sync_queue_item.dart';

class ExpenseRepository {
  ExpenseRepository(this._isar);

  static const String expenseEntityType = 'expense';
  static const String upsertOperation = 'upsert';
  static const String deleteOperation = 'delete';

  final Isar _isar;
  final Uuid _uuid = const Uuid();

  Future<void> addExpense(IsarExpense expense) async {
    final now = DateTime.now();

    expense
      ..uuid = _uuid.v4()
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..isDeleted = false;

    await _isar.writeTxn(() async {
      await _isar.isarExpenses.put(expense);
      await _upsertQueueItem(
        entityUuid: expense.uuid,
        operation: upsertOperation,
      );
    });
  }

  Future<void> updateExpense(IsarExpense expense) async {
    expense
      ..updatedAt = DateTime.now()
      ..isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.isarExpenses.put(expense);
      await _upsertQueueItem(
        entityUuid: expense.uuid,
        operation: upsertOperation,
      );
    });
  }

  Future<void> deleteExpense(String uuid) async {
    await _isar.writeTxn(() async {
      final expense = await _isar.isarExpenses.where().uuidEqualTo(uuid).findFirst();
      if (expense == null) {
        return;
      }

      expense
        ..isDeleted = true
        ..updatedAt = DateTime.now()
        ..isSynced = false;

      await _isar.isarExpenses.put(expense);
      await _upsertQueueItem(entityUuid: uuid, operation: deleteOperation);
    });
  }

  Stream<List<IsarExpense>> watchActiveExpenses() {
    return _isar.isarExpenses
        .filter()
        .isDeletedEqualTo(false)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<List<SyncQueueItem>> getPendingQueueItems() {
    return _isar.syncQueueItems
        .filter()
        .retryCountLessThan(5)
        .sortByQueuedAt()
        .findAll();
  }

  Future<IsarExpense?> getExpenseByUuid(String uuid) {
    return _isar.isarExpenses.where().uuidEqualTo(uuid).findFirst();
  }

  Future<void> completeQueueItem(Id queueItemId, String entityUuid) async {
    await _isar.writeTxn(() async {
      await _isar.syncQueueItems.delete(queueItemId);

      final expense = await _isar.isarExpenses.where().uuidEqualTo(entityUuid).findFirst();
      if (expense == null) {
        return;
      }

      expense.isSynced = true;
      await _isar.isarExpenses.put(expense);
    });
  }

  Future<int> incrementQueueRetry(Id queueItemId) async {
    var retryCount = 0;

    await _isar.writeTxn(() async {
      final item = await _isar.syncQueueItems.get(queueItemId);
      if (item == null) {
        return;
      }

      item.retryCount += 1;
      retryCount = item.retryCount;
      await _isar.syncQueueItems.put(item);
    });

    return retryCount;
  }

  Future<void> applyRemoteExpenses(List<IsarExpense> remoteExpenses) async {
    await _isar.writeTxn(() async {
      for (final remoteExpense in remoteExpenses) {
        final localExpense = await _isar.isarExpenses
            .where()
            .uuidEqualTo(remoteExpense.uuid)
            .findFirst();

        final shouldApply =
            localExpense == null || remoteExpense.updatedAt.isAfter(localExpense.updatedAt);
        if (!shouldApply) {
          continue;
        }

        if (localExpense != null) {
          remoteExpense.id = localExpense.id;
        }

        remoteExpense.isSynced = true;
        await _isar.isarExpenses.put(remoteExpense);
      }
    });
  }

  Future<bool> hasCompletedInitialSyncForUser(String userId) async {
    final state = await _isar.appSyncStates.get(0);
    return state?.hasCompletedInitialSync == true && state?.syncedUserId == userId;
  }

  Future<void> setInitialSyncCompletedForUser(String userId) async {
    await _isar.writeTxn(() async {
      final state = (await _isar.appSyncStates.get(0)) ?? AppSyncState();
      state
        ..id = 0
        ..hasCompletedInitialSync = true
        ..syncedUserId = userId;
      await _isar.appSyncStates.put(state);
    });
  }

  Future<void> resetInitialSyncState() async {
    await _isar.writeTxn(() async {
      final state = (await _isar.appSyncStates.get(0)) ?? AppSyncState();
      state
        ..id = 0
        ..hasCompletedInitialSync = false
        ..syncedUserId = null;
      await _isar.appSyncStates.put(state);
    });
  }

  Future<void> _upsertQueueItem({
    required String entityUuid,
    required String operation,
  }) async {
    final existing = await _isar.syncQueueItems
        .filter()
        .entityUuidEqualTo(entityUuid)
        .and()
        .entityTypeEqualTo(expenseEntityType)
        .findFirst();

    final queueItem = existing ??
        SyncQueueItem()
          ..entityUuid = entityUuid
          ..entityType = expenseEntityType;

    queueItem
      ..operation = operation
      ..queuedAt = DateTime.now()
      ..retryCount = 0;

    await _isar.syncQueueItems.put(queueItem);
  }

}
