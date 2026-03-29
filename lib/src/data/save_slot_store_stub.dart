import '../domain/campaign_models.dart';
import 'save_slot_store.dart';

class _MemorySaveSlotStore implements SaveSlotStore {
  final Map<SaveSlotId, SaveSlotRecord> _records = {};

  @override
  Future<Map<SaveSlotId, SaveSlotRecord>> loadSlots() async => Map<SaveSlotId, SaveSlotRecord>.from(_records);

  @override
  Future<void> writeSlot(SaveSlotRecord record) async {
    _records[record.slotId] = record;
  }
}

SaveSlotStore createPlatformSaveSlotStore() => _MemorySaveSlotStore();
