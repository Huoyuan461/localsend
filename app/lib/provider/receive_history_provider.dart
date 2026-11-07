import 'package:zhichuan_app/model/persistence/receive_history_entry.dart';
import 'package:zhichuan_app/provider/persistence_provider.dart';
import 'package:localsend_isolates/model/file_type.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Max stored history entries for free users.
const freeHistoryLimit = 30;

/// Max stored history entries for Pro users.
const proHistoryLimit = 200;

/// This provider stores the history of received files.
/// It automatically saves the history to the device's storage.
final receiveHistoryProvider = ReduxProvider<ReceiveHistoryService, List<ReceiveHistoryEntry>>((ref) {
  return ReceiveHistoryService(ref.read(persistenceProvider));
});

class ReceiveHistoryService extends ReduxNotifier<List<ReceiveHistoryEntry>> {
  final PersistenceService _persistence;

  ReceiveHistoryService(this._persistence);

  @override
  List<ReceiveHistoryEntry> init() => _persistence.getReceiveHistory();
}

/// Adds a history entry.
class AddHistoryEntryAction extends AsyncReduxAction<ReceiveHistoryService, List<ReceiveHistoryEntry>> {
  final String entryId;
  final String fileName;
  final FileType fileType;
  final String? path;
  final bool savedToGallery;
  final bool isMessage;
  final int fileSize;
  final String senderAlias;
  final DateTime timestamp;

  /// Max entries to keep. Callers pass the Pro limit for Pro users and the
  /// free limit otherwise (read via `purchaseProvider` at the dispatch site).
  /// Defaults to the Pro limit, which is also what FOSS builds use.
  final int maxEntries;

  AddHistoryEntryAction({
    required this.entryId,
    required this.fileName,
    required this.fileType,
    required this.path,
    required this.savedToGallery,
    required this.isMessage,
    required this.fileSize,
    required this.senderAlias,
    required this.timestamp,
    this.maxEntries = proHistoryLimit,
  });

  @override
  Future<List<ReceiveHistoryEntry>> reduce() async {
    if (!notifier._persistence.isSaveToHistory()) {
      return state;
    }

    final updated = [
      ReceiveHistoryEntry(
        id: entryId,
        fileName: fileName,
        fileType: fileType,
        path: path,
        savedToGallery: savedToGallery,
        isMessage: isMessage,
        fileSize: fileSize,
        senderAlias: senderAlias,
        timestamp: timestamp,
      ),
      ...state,
    ].take(maxEntries).toList();
    await notifier._persistence.setReceiveHistory(updated);
    return updated;
  }
}

/// Removes a history entry.
class RemoveHistoryEntryAction extends AsyncReduxAction<ReceiveHistoryService, List<ReceiveHistoryEntry>> {
  final String entryId;

  RemoveHistoryEntryAction(this.entryId);

  @override
  Future<List<ReceiveHistoryEntry>> reduce() async {
    final index = state.indexWhere((e) => e.id == entryId);
    if (index == -1) {
      return state;
    }
    final updated = [...state]..removeAt(index);
    await notifier._persistence.setReceiveHistory(updated);
    return updated;
  }
}

/// Removes all history entries.
class RemoveAllHistoryEntriesAction extends AsyncReduxAction<ReceiveHistoryService, List<ReceiveHistoryEntry>> {
  @override
  Future<List<ReceiveHistoryEntry>> reduce() async {
    await notifier._persistence.setReceiveHistory([]);
    return [];
  }
}
