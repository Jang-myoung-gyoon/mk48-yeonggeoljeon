# Battle HUD Action Popup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reduce the battle HUD height by replacing the always-visible inline command stack with a unit-triggered popup action menu.

**Architecture:** Keep the existing `BattleEngine` command flow and grid targeting model intact. Only the presentation layer changes: selecting a controllable unit opens a popup with `이동`, `공격`, `책략`, `도구`, `대기`, and the chosen mode continues on the battle grid instead of rendering a large inline target panel.

**Tech Stack:** Flutter, widget tests, existing `BattleEngine` and battle presentation parts

---

### Task 1: Lock the popup interaction in widget tests

**Files:**
- Modify: `test/features/route_and_battle_ui_test.dart`
- Test: `test/features/route_and_battle_ui_test.dart`

**Step 1: Write the failing test**

Add widget coverage for:
- tapping a Shu unit opens an action popup
- the popup exposes `이동`, `공격`, `책략`, `도구`, `대기`
- choosing a command closes the popup and keeps the HUD stable
- the old inline `커맨드 버튼` section is no longer required

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/route_and_battle_ui_test.dart`
Expected: FAIL because the current HUD still renders inline command sections and no popup exists.

**Step 3: Write minimal implementation**

Update the battle screen so unit selection opens a popup menu and command selection drives `commandMode`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/route_and_battle_ui_test.dart`
Expected: PASS

### Task 2: Replace the inline command stack with popup-driven controls

**Files:**
- Modify: `lib/src/presentation/screens_battle.part.dart`
- Modify: `lib/src/presentation/screens_shell.part.dart` if small grid/test hooks are needed
- Test: `test/features/route_and_battle_ui_test.dart`

**Step 1: Write the failing test**

Use the Task 1 test as the failing spec for popup rendering and mode switching.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/route_and_battle_ui_test.dart`
Expected: FAIL before UI changes.

**Step 3: Write minimal implementation**

Implement:
- popup menu on controllable unit tap
- `commandMode` helper text in the selected-unit card
- removal of tall inline action sections
- direct `대기` execution from popup

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/route_and_battle_ui_test.dart`
Expected: PASS

### Task 3: Regression verification

**Files:**
- Verify only

**Step 1: Run focused UI regression**

Run: `flutter test test/features/route_and_battle_ui_test.dart`
Expected: PASS

**Step 2: Run broader verification**

Run: `flutter analyze`
Expected: PASS

Run: `flutter test`
Expected: PASS
