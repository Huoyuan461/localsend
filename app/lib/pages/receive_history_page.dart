import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zhichuan_app/config/theme.dart';
import 'package:zhichuan_app/gen/strings.g.dart';
import 'package:zhichuan_app/model/persistence/receive_history_entry.dart';
// [FOSS_REMOVE_START]
import 'package:zhichuan_app/pages/pro/pro_page.dart';
// [FOSS_REMOVE_END]
import 'package:zhichuan_app/pages/receive_page.dart';
// [FOSS_REMOVE_START]
import 'package:zhichuan_app/provider/purchase_provider.dart';
// [FOSS_REMOVE_END]
import 'package:zhichuan_app/provider/receive_history_provider.dart';
import 'package:zhichuan_app/provider/settings_provider.dart';
import 'package:zhichuan_app/util/native/directories.dart';
import 'package:zhichuan_app/util/native/open_file.dart';
import 'package:zhichuan_app/util/native/open_folder.dart';
import 'package:zhichuan_app/util/native/platform_check.dart';
import 'package:zhichuan_app/widget/dialogs/file_info_dialog.dart';
import 'package:zhichuan_app/widget/dialogs/history_clear_dialog.dart';
import 'package:zhichuan_app/widget/file_thumbnail.dart';
import 'package:zhichuan_app/widget/responsive_list_view.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:localsend_isolates/model/session_status.dart';
import 'package:localsend_isolates/util/file_size_helper.dart';
import 'package:path/path.dart' as path;
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

enum _EntryOption {
  open,
  showInFolder,
  info,
  delete
  ;

  String get label {
    return switch (this) {
      _EntryOption.open => t.receiveHistoryPage.entryActions.open,
      _EntryOption.showInFolder => t.receiveHistoryPage.entryActions.showInFolder,
      _EntryOption.info => t.receiveHistoryPage.entryActions.info,
      _EntryOption.delete => t.receiveHistoryPage.entryActions.deleteFromHistory,
    };
  }
}

const _optionsAll = _EntryOption.values;
final _optionsWithoutOpen = [_EntryOption.info, _EntryOption.delete];

class ReceiveHistoryPage extends StatefulWidget {
  const ReceiveHistoryPage({super.key});

  @override
  State<ReceiveHistoryPage> createState() => _ReceiveHistoryPageState();
}

class _ReceiveHistoryPageState extends State<ReceiveHistoryPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFile(
    BuildContext context,
    ReceiveHistoryEntry entry,
    Dispatcher<ReceiveHistoryService, List<ReceiveHistoryEntry>> dispatcher,
  ) async {
    if (entry.path != null) {
      await openFile(
        context,
        entry.fileType,
        entry.path!,
        onDeleteTap: () => dispatcher.dispatchAsync(RemoveHistoryEntryAction(entry.id)),
      );
    }
  }

  List<ReceiveHistoryEntry> _filterEntries(List<ReceiveHistoryEntry> entries) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return entries;
    }
    return entries.where((entry) {
      return entry.fileName.toLowerCase().contains(query) || entry.senderAlias.toLowerCase().contains(query);
    }).toList();
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _buildCsv(List<ReceiveHistoryEntry> entries) {
    final buffer = StringBuffer('fileName,fileType,senderAlias,timestamp,fileSize,path\n');
    for (final entry in entries) {
      buffer.writeln([
        _csvEscape(entry.fileName),
        entry.fileType.name,
        _csvEscape(entry.senderAlias),
        entry.timestamp.toLocal().toIso8601String(),
        entry.fileSize.toString(),
        _csvEscape(entry.path ?? ''),
      ].join(','));
    }
    return buffer.toString();
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Future<void> _exportCsv(BuildContext context, List<ReceiveHistoryEntry> entries) async {
    try {
      final destination = context.read(settingsProvider).destination ?? await getDefaultDestinationDirectory();
      final now = DateTime.now();
      final fileName =
          'zhichuan-history-${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}-${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}.csv';
      final file = File(path.join(destination, fileName));
      await file.writeAsString(_buildCsv(entries));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.receiveHistoryPage.exportSuccess(fileName: fileName)),
            action: SnackBarAction(
              label: t.receiveHistoryPage.openFolder,
              onPressed: () => openFolder(folderPath: destination),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.receiveHistoryPage.exportFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch(receiveHistoryProvider);
    // [FOSS_REMOVE_START]
    final isPro = context.watch(purchaseProvider).isPro;
    // [FOSS_REMOVE_END]
    final filteredEntries = _filterEntries(entries);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.receiveHistoryPage.title),
      ),
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: t.receiveHistoryPage.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainerIfDark,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainerIfDark,
                  ),
                  onPressed: checkPlatform([TargetPlatform.iOS])
                      ? null
                      : () async {
                          // ignore: use_build_context_synchronously
                          final destination = context.read(settingsProvider).destination ?? await getDefaultDestinationDirectory();
                          await openFolder(folderPath: destination);
                        },
                  icon: const Icon(Icons.folder),
                  label: Text(t.receiveHistoryPage.openFolder),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainerIfDark,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainerIfDark,
                  ),
                  onPressed: entries.isEmpty
                      ? null
                      : () async {
                          final result = await showDialog(
                            context: context,
                            builder: (_) => const HistoryClearDialog(),
                          );

                          if (context.mounted && result == true) {
                            await context.redux(receiveHistoryProvider).dispatchAsync(RemoveAllHistoryEntriesAction());
                          }
                        },
                  icon: const Icon(Icons.delete),
                  label: Text(t.receiveHistoryPage.deleteHistory),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainerIfDark,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainerIfDark,
                  ),
                  onPressed: filteredEntries.isEmpty ? null : () => _exportCsv(context, filteredEntries),
                  icon: const Icon(Icons.file_download),
                  label: Text(t.receiveHistoryPage.exportCsv),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Center(child: Text(t.receiveHistoryPage.empty, style: Theme.of(context).textTheme.headlineMedium)),
            )
          else if (filteredEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Center(child: Text(t.receiveHistoryPage.noResults, style: Theme.of(context).textTheme.headlineMedium)),
            )
          else
            ...filteredEntries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: InkWell(
                  splashColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onTap: entry.path != null || entry.isMessage
                      ? () async {
                          if (entry.isMessage) {
                            final vm = ViewProvider((ref) {
                              return ReceivePageVm(
                                status: SessionStatus.waiting,
                                sender: Device(
                                  signalingId: null,
                                  ip: '0.0.0.0',
                                  version: '1.0.0',
                                  port: 8080,
                                  https: false,
                                  fingerprint: 'fingerprint',
                                  alias: entry.senderAlias,
                                  deviceModel: 'deviceModel',
                                  deviceType: DeviceType.web,
                                  download: true,
                                  channels: const [],
                                ),
                                showSenderInfo: false,
                                files: [],
                                message: entry.fileName,
                                onAccept: () {},
                                onDecline: () {},
                                onClose: () {},
                              );
                            });

                            // ignore: unawaited_futures
                            context.push(() => ReceivePage(vm));
                            return;
                          }

                          await _openFile(context, entry, context.redux(receiveHistoryProvider));
                        }
                      : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilePathThumbnail(
                        path: entry.path,
                        fileType: entry.fileType,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 3),
                            Text(
                              entry.fileName,
                              style: const TextStyle(fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                            Text(
                              '${entry.timestampString(context)} - ${entry.fileSize.asReadableFileSize} - ${entry.senderAlias}',
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      PopupMenuButton<_EntryOption>(
                        onSelected: (_EntryOption item) async {
                          switch (item) {
                            case _EntryOption.open:
                              await _openFile(context, entry, context.redux(receiveHistoryProvider));
                              break;
                            case _EntryOption.showInFolder:
                              if (entry.path != null) {
                                await openFolder(
                                  folderPath: File(entry.path!).parent.path,
                                  fileName: path.basename(entry.path!),
                                );
                              }
                              break;
                            case _EntryOption.info:
                              // ignore: use_build_context_synchronously
                              await showDialog(
                                context: context,
                                builder: (_) => FileInfoDialog(entry: entry),
                              );
                              break;
                            case _EntryOption.delete:
                              // ignore: use_build_context_synchronously
                              await context.redux(receiveHistoryProvider).dispatchAsync(RemoveHistoryEntryAction(entry.id));
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return (entry.path != null ? _optionsAll : _optionsWithoutOpen).map((e) {
                            return PopupMenuItem<_EntryOption>(
                              value: e,
                              child: Text(e.label),
                            );
                          }).toList();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          // [FOSS_REMOVE_START]
          if (!isPro && entries.length >= freeHistoryLimit)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: InkWell(
                onTap: () async {
                  await context.push(() => const ProPage());
                },
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.receiveHistoryPage.proUpsell,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          // [FOSS_REMOVE_END]
        ],
      ),
    );
  }
}
