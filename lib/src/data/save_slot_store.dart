import '../domain/campaign_models.dart';

abstract class SaveSlotStore {
  Future<Map<SaveSlotId, SaveSlotRecord>> loadSlots();

  Future<void> writeSlot(SaveSlotRecord record);
}
