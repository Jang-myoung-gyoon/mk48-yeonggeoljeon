# Character Asset Screen Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate the existing five `assets/characters` sprite sets more aggressively across stage briefing, formation, battle HUD, and duel presentation screens with visible animation states.

**Architecture:** Reuse the current `CharacterSpriteAssets`, `OfficerAvatar`, and `BattleUnitSprite` pipeline instead of introducing a new asset system. Add thin presentation widgets for animated officer cards and duel staging, then wire the affected screens to those widgets while preserving current battle logic and fallback sprite reuse for non-playable enemies.

**Tech Stack:** Flutter, widget tests, existing `CharacterSpriteAssets` asset helpers, battle and campaign presentation parts

---

### Task 1: Lock screen-level sprite usage in tests

**Files:**
- Modify: `test/features/campaign_progress_ui_test.dart`
- Modify: `test/features/route_and_battle_ui_test.dart`
- Test: `test/features/campaign_progress_ui_test.dart`

**Step 1: Write the failing test**

Add widget tests that prove:
- stage briefing renders animated or icon-based assets from `assets/characters` for the selected stage roster
- formation screen renders reused character assets for allied and enemy cards
- duel screen renders character sprite assets for both duel participants and advances animation state

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/campaign_progress_ui_test.dart`
Expected: FAIL because briefing/formation/duel screens do not yet expose the required asset-backed visuals and duel sequencing.

**Step 3: Write minimal implementation**

Add the presentation widgets and screen wiring needed for those tests.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/campaign_progress_ui_test.dart`
Expected: PASS

### Task 2: Add reusable animated character presentation widgets

**Files:**
- Modify: `lib/src/presentation/character_sprite_assets.dart`
- Test: `test/features/campaign_progress_ui_test.dart`

**Step 1: Write the failing test**

Use the Task 1 screen tests as the spec for larger animated card usage.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/campaign_progress_ui_test.dart`
Expected: FAIL before reusable widgets exist.

**Step 3: Write minimal implementation**

Add reusable widgets for:
- animated officer card/header visuals using existing five sprite sets
- optional title/tag lines for campaign and duel presentation

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/campaign_progress_ui_test.dart`
Expected: PASS

### Task 3: Wire briefing and formation screens to asset-heavy cards

**Files:**
- Modify: `lib/src/presentation/screens_campaign.part.dart`
- Test: `test/features/campaign_progress_ui_test.dart`

**Step 1: Write the failing test**

Use the briefing/formation tests from Task 1.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/campaign_progress_ui_test.dart`
Expected: FAIL before the screens are updated.

**Step 3: Write minimal implementation**

Replace plain list tiles with asset-driven cards that use:
- animated `idle` or `walk` states where appropriate
- existing `south` icon/base-frame reuse for compact info rows
- fallback sprite reuse for enemy information cards

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/campaign_progress_ui_test.dart`
Expected: PASS

### Task 4: Add duel animation staging with existing assets

**Files:**
- Modify: `lib/src/presentation/screens_story.part.dart`
- Test: `test/features/campaign_progress_ui_test.dart`

**Step 1: Write the failing test**

Use the duel animation test from Task 1.

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/campaign_progress_ui_test.dart`
Expected: FAIL before the duel screen uses animated sprites.

**Step 3: Write minimal implementation**

Build a small duel sequence that:
- shows both combatants with existing asset-backed sprites
- starts in `idle`
- advances to `attack` / `hit`
- returns to `idle` without needing a new asset format

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/campaign_progress_ui_test.dart`
Expected: PASS

### Task 5: Regression verification

**Files:**
- Verify only

**Step 1: Run focused screen tests**

Run: `flutter test test/features/campaign_progress_ui_test.dart`
Expected: PASS

Run: `flutter test test/features/route_and_battle_ui_test.dart`
Expected: PASS

**Step 2: Run broader verification**

Run: `flutter analyze`
Expected: PASS

Run: `flutter test`
Expected: PASS
