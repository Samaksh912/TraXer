import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/isar_expense.dart';
import '../models/sync_queue_item.dart';
import '../repositories/expense_repository.dart';

class SyncService {
  SyncService({
    required this.repository,
    sb.SupabaseClient? supabaseClient,
  }) : supabase = supabaseClient ?? sb.Supabase.instance.client;

  final ExpenseRepository repository;
  final sb.SupabaseClient supabase;

  bool _isSyncing = false;

  Future<void> syncPendingItems() async {
    if (_isSyncing) {
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('Skipping sync: no authenticated user.');
      return;
    }

    _isSyncing = true;
    try {
      final items = await repository.getPendingQueueItems();
      for (final item in items) {
        try {
          await _processItem(item);
          await repository.completeQueueItem(item.id, item.entityUuid);
        } catch (error, stackTrace) {
          final retryCount = await repository.incrementQueueRetry(item.id);
          debugPrint(
            'Failed to sync ${item.entityType}:${item.entityUuid} '
            '(attempt $retryCount): $error\n$stackTrace',
          );

          if (retryCount >= 5) {
            debugPrint(
              'Giving up on ${item.entityType}:${item.entityUuid} '
              'after $retryCount attempts.',
            );
            continue;
          }

          final backoffSeconds = pow(2, max(retryCount - 1, 0)).toInt();
          await Future.delayed(Duration(seconds: backoffSeconds));
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> ensureUserDocument() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('Skipping user document upsert: no authenticated user.');
      return;
    }

    final providers =
        (user.appMetadata['providers'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .where((providerId) => providerId.isNotEmpty)
            .toSet()
            .toList();

    await supabase.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'display_name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
      'photo_url': user.userMetadata?['avatar_url'],
      'provider_ids': providers,
      'last_login_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'id');
  }

  Future<void> initialSync() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('Skipping initial sync: no authenticated user.');
      return;
    }

    final response = await supabase
        .from('expenses')
        .select()
        .eq('user_id', user.id)
        .eq('is_deleted', false);

    final remoteExpenses = (response as List<dynamic>).map((row) {
      final expense = IsarExpense.fromSupabaseMap(Map<String, dynamic>.from(row as Map));

      expense.isSynced = true;
      return expense;
    }).toList();

    await repository.applyRemoteExpenses(remoteExpenses);
  }

  Future<void> _processItem(SyncQueueItem item) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Cannot sync without an authenticated user.');
    }

    switch (item.operation) {
      case ExpenseRepository.upsertOperation:
        final expense = await repository.getExpenseByUuid(item.entityUuid);
        if (expense == null) {
          throw StateError('Missing local expense for ${item.entityUuid}.');
        }

        await supabase.from('expenses').upsert(
          expense.toSupabaseMap(userId: user.id),
          onConflict: 'user_id,uuid',
        );
        return;
      case ExpenseRepository.deleteOperation:
        await supabase
            .from('expenses')
            .delete()
            .eq('user_id', user.id)
            .eq('uuid', item.entityUuid);
        return;
      default:
        throw UnsupportedError('Unknown sync operation: ${item.operation}');
    }
  }
}
