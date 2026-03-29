# Battle Sprite Animation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 전투 화면의 유닛이 실제 캐릭터 자산과 방향별 애니메이션을 사용하도록 만들고, 적군도 기존 자산 재사용으로 최대한 시각화한다.

**Architecture:** 스프라이트 해석 규칙은 `character_sprite_assets.dart` 에 모으고, 전투 액션에 따른 상태/방향 전이는 `screens_battle.part.dart` 에서 관리한다. 전장 셀과 선택 패널은 같은 해석 로직을 사용하고, 회귀는 경로 해석 테스트와 위젯 상호작용 테스트로 잠근다.

**Tech Stack:** Flutter, flutter_test, existing asset bundle under `assets/characters`

---

### Task 1: Document the Approved Design

**Files:**
- Modify: `docs/plans/2026-03-29-battle-sprite-animation-design.md`
- Modify: `docs/plans/2026-03-29-battle-sprite-animation.md`

**Step 1: Save the approved design**

- Record the selected asset reuse strategy, facing rules, and animation reset behavior.

**Step 2: Confirm the implementation targets**

- Touch only the presentation layer and tests unless a missing model field forces expansion.

### Task 2: Lock Asset Resolution Expectations

**Files:**
- Modify: `test/content/character_asset_manifest_test.dart`
- Create: `test/presentation/character_sprite_assets_test.dart`
- Modify: `lib/src/presentation/character_sprite_assets.dart`

**Step 1: Write the failing test**

- Add tests for hero asset resolution, enemy sprite reuse by `UnitClass`, and animation file preference (`gif` before `png` before base frame).

**Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/character_sprite_assets_test.dart`

Expected: FAIL because the resolver helpers and enemy mapping do not exist yet.

**Step 3: Write minimal implementation**

- Add resolver methods that compute sprite ID, facing-specific animation path, and fallback order.

**Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/character_sprite_assets_test.dart`

Expected: PASS

### Task 3: Lock Battle Animation Behavior

**Files:**
- Modify: `test/features/route_and_battle_ui_test.dart`
- Modify: `lib/src/presentation/screens_battle.part.dart`
- Modify: `lib/src/presentation/screens_shell.part.dart`

**Step 1: Write the failing test**

- Add widget tests that trigger battle actions and assert:
  - selected unit animation label changes to `attack` then returns to `idle`
  - tilemap renders image-backed unit sprites
  - enemy cells render image-backed sprites via asset reuse

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/route_and_battle_ui_test.dart`

Expected: FAIL because action states do not auto-reset and no explicit direction/asset resolution is exposed.

**Step 3: Write minimal implementation**

- Track unit facings and animation states in the battle screen.
- Update move/attack/tactic/item/wait flows to set the correct action state.
- Schedule short resets back to `idle`.
- Pass facing and resolved asset paths into `BattleUnitSprite`.

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/route_and_battle_ui_test.dart`

Expected: PASS

### Task 4: Verify the Whole Feature

**Files:**
- Modify: `lib/src/presentation/character_sprite_assets.dart`
- Modify: `lib/src/presentation/screens_battle.part.dart`
- Modify: `lib/src/presentation/screens_shell.part.dart`
- Modify: `test/content/character_asset_manifest_test.dart`
- Create: `test/presentation/character_sprite_assets_test.dart`
- Modify: `test/features/route_and_battle_ui_test.dart`

**Step 1: Run focused tests**

Run: `flutter test test/presentation/character_sprite_assets_test.dart`
Run: `flutter test test/features/route_and_battle_ui_test.dart`

Expected: PASS

**Step 2: Run regression checks**

Run: `flutter analyze`
Run: `flutter test`

Expected: PASS

**Step 3: Summarize remaining gaps**

- Note that device-specific frame pacing for GIF playback is not covered by widget tests.
