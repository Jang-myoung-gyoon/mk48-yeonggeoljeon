import 'dart:convert';
import 'dart:io';

import '../domain/campaign_models.dart';
import 'save_slot_store.dart';

class _FileSaveSlotStore implements SaveSlotStore {
  Future<File> get _file async {
    final directory = Directory('.dart_tool');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return File('${directory.path}/ralphthon-save-slots.json');
  }

  @override
  Future<Map<SaveSlotId, SaveSlotRecord>> loadSlots() async {
    final file = await _file;
    if (!file.existsSync()) {
      return {};
    }
    final decoded = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    return {
      for (final entry in decoded.entries)
        SaveSlotId.values.byName(entry.key): SaveSlotRecord.fromJson(
          entry.value! as Map<String, Object?>,
        ),
    };
  }

  @override
  Future<void> writeSlot(SaveSlotRecord record) async {
    final existing = await loadSlots();
    existing[record.slotId] = record;
    final file = await _file;
    await file.writeAsString(
      jsonEncode({
        for (final entry in existing.entries) entry.key.name: entry.value.toJson(),
      }),
    );
  }
}

SaveSlotStore createPlatformSaveSlotStore() => _FileSaveSlotStore();
