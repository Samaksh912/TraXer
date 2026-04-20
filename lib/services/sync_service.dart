import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/isar_expense.dart';
import '../models/sync_queue_item.dart';
import '../repositories/expense_repository.dart';

class SyncService {
  SyncService({
    required this.repository,
    required this.firestore,
    FirebaseAuth? auth,
  }) : auth = auth ?? FirebaseAuth.instance;

  final ExpenseRepository repository;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  bool _isSyncing = false;

  Future<void> syncPendingItems() async {
    if (_isSyncing) {
      return;
    }

    final user = auth.currentUser;
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
    final user = auth.currentUser;
    if (user == null) {
      debugPrint('Skipping user document upsert: no authenticated user.');
      return;
    }

    final userDocRef = firestore.collection('users').doc(user.uid);
    final providers = user.providerData
        .map((entry) => entry.providerId)
        .where((providerId) => providerId.isNotEmpty)
        .toSet()
        .toList();

    await userDocRef.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'providerIds': providers,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> initialSync() async {
    final user = auth.currentUser;
    if (user == null) {
      debugPrint('Skipping initial sync: no authenticated user.');
      return;
    }

    final snapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .where('isDeleted', isEqualTo: false)
        .get();

    final remoteExpenses = snapshot.docs.map((doc) {
      final expense = IsarExpense.fromFirestoreMap(
        doc.data(),
        fallbackUuid: doc.id,
      );

      expense.isSynced = true;
      return expense;
    }).toList();

    await repository.applyRemoteExpenses(remoteExpenses);
  }

  Future<void> _processItem(SyncQueueItem item) async {
    final user = auth.currentUser;
    if (user == null) {
      throw StateError('Cannot sync without an authenticated user.');
    }

    final docRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .doc(item.entityUuid);

    switch (item.operation) {
      case ExpenseRepository.upsertOperation:
        final expense = await repository.getExpenseByUuid(item.entityUuid);
        if (expense == null) {
          throw StateError('Missing local expense for ${item.entityUuid}.');
        }

        await docRef.set(
          expense.toFirestoreMap(),
          SetOptions(merge: true),
        );
        return;
      case ExpenseRepository.deleteOperation:
        await docRef.delete();
        return;
      default:
        throw UnsupportedError('Unknown sync operation: ${item.operation}');
    }
  }
}
