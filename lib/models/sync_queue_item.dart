import 'package:isar/isar.dart';

part 'sync_queue_item.g.dart';

@collection
class SyncQueueItem {
  Id id = Isar.autoIncrement;

  late String entityUuid;
  late String entityType;
  late String operation;
  late DateTime queuedAt;
  int retryCount = 0;
}
