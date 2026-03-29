// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import '../domain/campaign_models.dart';
import 'save_slot_store.dart';

class _WebSaveSlotStore implements SaveSlotStore {
  static const _storageKey = 'ralphthon-save-slots';

  @override
  Future<Map<SaveSlotId, SaveSlotRecord>> loadSlots() async {
    final raw = html.window.localStorage[_storageKey];
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw) as Map<String, Object?>;
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
    html.window.localStorage[_storageKey] = jsonEncode({
      for (final entry in existing.entries) entry.key.name: entry.value.toJson(),
    });
  }
}

SaveSlotStore createPlatformSaveSlotStore() => _WebSaveSlotStore();
