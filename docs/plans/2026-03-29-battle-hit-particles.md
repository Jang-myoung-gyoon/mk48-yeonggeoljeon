# Battle Hit Particles Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add distinct target-side particle effects for physical attacks and tactics in the battle HUD.

**Architecture:** Extend the existing battle overlay system that already renders floating damage/heal text on target cells. Add a lightweight particle entry model plus a widget overlay that can render a red impact spark for attacks and a teal-purple magic pulse for tactics, then auto-clear them on a short timer.

**Tech Stack:** Flutter, widget tests, existing battle HUD presentation parts

---

### Task 1: Lock particle behavior in widget tests

**Files:**
- Modify: `test/features/route_and_battle_ui_test.dart`
- Test: `test/features/route_and_battle_ui_test.dart`

**Step 1: Write the failing test**

Add two widget tests:
- attack action spawns an attack impact particle on the target and clears it
- tactic action spawns a tactic impact particle on the target and clears it

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/route_and_battle_ui_test.dart`
Expected: FAIL because no particle overlay exists yet.

**Step 3: Write minimal implementation**

Add particle state and target-cell overlay rendering.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/route_and_battle_ui_test.dart`
Expected: PASS

### Task 2: Implement attack/tactic particle overlays

**Files:**
- Modify: `lib/src/presentation/screens_battle.part.dart`
- Modify: `lib/src/presentation/screens_shell.part.dart`
- Test: `test/features/route_and_battle_ui_test.dart`

**Step 1: Write the failing test**

Use the Task 1 tests as the specification.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/route_and_battle_ui_test.dart`
Expected: FAIL before overlay code is added.

**Step 3: Write minimal implementation**

Implement:
- particle entry type for impact location and effect kind
- red spark attack particle
- teal/purple magic pulse tactic particle
- auto-remove timer after short playback

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/route_and_battle_ui_test.dart`
Expected: PASS

### Task 3: Regression verification

**Files:**
- Verify only

**Step 1: Run focused battle UI regression**

Run: `flutter test test/features/route_and_battle_ui_test.dart`
Expected: PASS

**Step 2: Run broader verification**

Run: `flutter analyze`
Expected: PASS

Run: `flutter test`
Expected: PASS
