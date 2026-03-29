import 'save_slot_store.dart';
import 'save_slot_store_stub.dart'
    if (dart.library.html) 'save_slot_store_web.dart'
    if (dart.library.io) 'save_slot_store_io.dart' as impl;

SaveSlotStore createPlatformSaveSlotStore() => impl.createPlatformSaveSlotStore();
