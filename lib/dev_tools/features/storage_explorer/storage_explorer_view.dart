import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/dimensions.dart';
import '../../widgets/jump_to_bottom_fab.dart';
import '../../../network/managers/offline_sync_manager.dart';
import '../auth_tools/devtools_auth_controller.dart';
import 'storage_controller.dart';

class StorageExplorerView extends StatelessWidget {
  const StorageExplorerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = StorageController();
    final authController = DevToolsAuthController();
    final scrollController = ScrollController();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: JumpToBottomFAB(scrollController: scrollController),
      body: ValueListenableBuilder<String>(
        valueListenable: controller.selectedBox,
        builder: (context, currentBox, child) {
          return Column(
            children: [
              _buildSelector(context, currentBox, controller, authController),
              Expanded(
                child: _buildBoxContent(
                  context,
                  currentBox,
                  controller,
                  authController,
                  scrollController,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelector(
    BuildContext context,
    String currentBox,
    StorageController controller,
    DevToolsAuthController authController,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Dimen.w16, vertical: Dimen.h8),
      color: authController.isDeveloper
          ? const Color(0xFF0D1117)
          : const Color(0xFF1E1E1E),
      child: Row(
        children: [
          Text(
            'Box: ',
            style: TextStyle(color: Colors.white38, fontSize: Dimen.s13),
          ),
          SizedBox(width: Dimen.w8),
          ValueListenableBuilder<List<String>>(
            valueListenable: controller.boxes,
            builder: (context, boxes, child) {
              return DropdownButton<String>(
                value: currentBox,
                dropdownColor: const Color(0xFF2D2D2D),
                underline: const SizedBox(),
                items: boxes
                    .map(
                      (b) => DropdownMenuItem(
                        value: b,
                        child: Text(
                          b,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Dimen.s13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) controller.setSelectedBox(val);
                },
              );
            },
          ),
          const Spacer(),
          if (authController.isDeveloper) ...[
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.greenAccent,
                size: Dimen.h20,
              ),
              onPressed: () => _showAddDialog(context, currentBox),
              tooltip: 'Add Entry',
            ),
            if (currentBox == 'offline_queue')
              IconButton(
                icon: Icon(
                  Icons.sync,
                  color: Colors.blueAccent,
                  size: Dimen.h20,
                ),
                onPressed: () {
                  OfflineSyncManager().init();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sync triggered')),
                  );
                },
                tooltip: 'Force Sync',
              ),
            IconButton(
              icon: Icon(
                Icons.delete_sweep,
                color: Colors.redAccent,
                size: Dimen.h20,
              ),
              onPressed: () => controller.clearBox(currentBox),
              tooltip: 'Clear Box',
            ),
          ],
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, String boxName) {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: Dimen.w280,
          padding: EdgeInsets.all(Dimen.w20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(Dimen.r16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Entry',
                style: TextStyle(color: Colors.white, fontSize: Dimen.s16),
              ),
              SizedBox(height: Dimen.h20),
              TextField(
                controller: keyController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Key',
                  labelStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
              SizedBox(height: Dimen.h16),
              TextField(
                controller: valueController,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Value (JSON or String)',
                  labelStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
              SizedBox(height: Dimen.h24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                  SizedBox(width: Dimen.w8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                    ),
                    onPressed: () {
                      final key = keyController.text.trim();
                      final valueStr = valueController.text.trim();
                      if (key.isEmpty) return;

                      dynamic value;
                      try {
                        value = jsonDecode(valueStr);
                      } catch (_) {
                        value = valueStr;
                      }

                      Hive.box(boxName).put(key, value);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Add',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoxContent(
    BuildContext context,
    String boxName,
    StorageController controller,
    DevToolsAuthController authController,
    ScrollController scrollController,
  ) {
    if (!Hive.isBoxOpen(boxName)) {
      return const Center(
        child: Text('Box not open', style: TextStyle(color: Colors.redAccent)),
      );
    }

    return ValueListenableBuilder(
      valueListenable: Hive.box(boxName).listenable(),
      builder: (context, Box box, child) {
        final keys = box.keys.toList();
        if (keys.isEmpty) {
          return const Center(
            child: Text('Empty Box', style: TextStyle(color: Colors.white24)),
          );
        }

        return ListView.separated(
          controller: scrollController,
          itemCount: keys.length,
          padding: EdgeInsets.all(Dimen.w8),
          separatorBuilder: (_, _) =>
              Divider(height: Dimen.h1, color: Colors.white10),
          itemBuilder: (context, index) {
            final reversedKeys = keys.reversed.toList();
            final key = reversedKeys[index];
            final value = box.get(key);
            return _StorageTile(
              boxName: boxName,
              itemKey: key.toString(),
              value: value,
              onDelete: authController.isDeveloper
                  ? () => controller.deleteKey(boxName, key)
                  : null,
              onEdit: authController.isDeveloper
                  ? () =>
                        _showEditDialog(context, boxName, key.toString(), value)
                  : null,
            );
          },
        );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    String boxName,
    String key,
    dynamic currentValue,
  ) {
    String displayValue;
    try {
      if (currentValue is Map || currentValue is List) {
        displayValue = const JsonEncoder.withIndent('  ').convert(currentValue);
      } else {
        displayValue = currentValue.toString();
      }
    } catch (_) {
      displayValue = currentValue.toString();
    }

    final valueController = TextEditingController(text: displayValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Edit: $key',
          style: TextStyle(color: Colors.white, fontSize: Dimen.s14),
        ),
        content: SizedBox(
          width: Dimen.w300,
          child: TextField(
            controller: valueController,
            style: TextStyle(
              color: Colors.greenAccent,
              fontFamily: 'monospace',
              fontSize: Dimen.s12,
            ),
            maxLines: 10,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              final valueStr = valueController.text.trim();
              dynamic value;
              try {
                value = jsonDecode(valueStr);
              } catch (_) {
                value = valueStr;
              }

              Hive.box(boxName).put(key, value);
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StorageTile extends StatelessWidget {
  final String boxName;
  final String itemKey;
  final dynamic value;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _StorageTile({
    required this.boxName,
    required this.itemKey,
    required this.value,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    dynamic displayValue = value;
    String? timestamp;

    if (boxName == 'api_cache' && value is Map && value['timestamp'] != null) {
      displayValue = value['data'];
      timestamp = _formatTimestamp(value['timestamp']);
    }

    return ListTile(
      onTap: () => _showDetails(context, displayValue, timestamp),
      title: Text(
        itemKey,
        style: TextStyle(
          color: Colors.greenAccent,
          fontSize: Dimen.s13,
          fontFamily: 'monospace',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (timestamp != null)
            Padding(
              padding: EdgeInsets.only(bottom: Dimen.h2),
              child: Text(
                timestamp,
                style: TextStyle(color: Colors.blueAccent, fontSize: Dimen.s10),
              ),
            ),
          Text(
            displayValue.toString(),
            style: TextStyle(color: Colors.white38, fontSize: Dimen.s11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  void _showDetails(
    BuildContext context,
    dynamic displayValue,
    String? timestamp,
  ) {
    final authController = DevToolsAuthController();
    String prettyValue;
    try {
      if (displayValue is Map || displayValue is List) {
        prettyValue = const JsonEncoder.withIndent('  ').convert(displayValue);
      } else {
        prettyValue = displayValue.toString();
      }
    } catch (_) {
      prettyValue = displayValue.toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: authController.isDeveloper
          ? const Color(0xFF0D1117)
          : const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimen.r16)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: EdgeInsets.all(Dimen.w16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KEY',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: Dimen.s11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: Colors.blueAccent,
                              size: Dimen.h18,
                            ),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              onEdit!();
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            color: Colors.greenAccent,
                            size: Dimen.h18,
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: prettyValue));
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(content: Text('Copied')),
                            );
                          },
                        ),
                        if (onDelete != null)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: Dimen.h18,
                            ),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              onDelete!();
                            },
                          ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: Dimen.h4),
              SelectableText(
                itemKey,
                style: TextStyle(color: Colors.white, fontSize: Dimen.s14),
              ),
              if (timestamp != null) ...[
                SizedBox(height: Dimen.h8),
                Text(
                  'Cached: $timestamp',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: Dimen.s12,
                  ),
                ),
              ],
              SizedBox(height: Dimen.h24),
              Text(
                'VALUE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: Dimen.s11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Dimen.h8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Dimen.w12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(Dimen.r8),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: SelectableText(
                      prettyValue,
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: Dimen.s12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
