import 'package:isar/isar.dart';

part 'app_sync_state.g.dart';

@collection
class AppSyncState {
  Id id = 0;
  bool hasCompletedInitialSync = false;
  String? syncedUserId;
}
