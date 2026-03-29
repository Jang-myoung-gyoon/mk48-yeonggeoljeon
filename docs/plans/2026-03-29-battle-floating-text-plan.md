# Battle Floating Text Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 전투 액션 직후 피해/회복 수치가 타일 위에 떠오르다가 사라지도록 만든다.

**Architecture:** 전투 HUD 부모 상태에서 플로팅 텍스트 엔트리를 관리하고, `_BattleGrid` 가 셀별 오버레이로 렌더링한다. 값 계산은 액션 전후 `BattleState` 의 HP 차이만 사용한다.

**Tech Stack:** Flutter, flutter_test, existing battle HUD widgets

---

### Task 1: Lock the feedback behavior with tests

**Files:**
- Modify: `test/features/route_and_battle_ui_test.dart`

**Step 1: Write the failing tests**

- 공격 후 `-damage` 텍스트가 보였다가 사라지는 테스트를 추가한다.
- 도구 사용 후 `+heal` 텍스트가 보였다가 사라지는 테스트를 추가한다.

**Step 2: Run the focused widget test**

Run: `flutter test test/features/route_and_battle_ui_test.dart`

Expected: FAIL because no floating text overlay exists yet.

### Task 2: Implement floating text overlay state

**Files:**
- Modify: `lib/src/presentation/screens_battle.part.dart`
- Modify: `lib/src/presentation/screens_shell.part.dart`

**Step 1: Add structured overlay entries**

- Add a private entry model with id, position, text, and tone.
- Compare previous and next battle states after attack, tactic, and item actions.

**Step 2: Add render and lifecycle handling**

- Pass active overlay entries into `_BattleGrid`.
- Render them with upward motion and fade-out.
- Remove them with timers and clear them on reset/dispose.

### Task 3: Verify regressions

**Files:**
- Modify: `test/features/campaign_progress_ui_test.dart`
- Modify: `lib/src/presentation/screens_shell.part.dart`

**Step 1: Reconcile existing UI asset tests if they drift**

- Keep duel and campaign asset tests aligned with the current shared shell components.

**Step 2: Run the full suite**

Run: `flutter analyze`
Run: `flutter test`

Expected: PASS
