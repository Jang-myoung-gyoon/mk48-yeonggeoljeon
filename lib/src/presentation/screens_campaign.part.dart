part of 'screens.dart';

class StageSelectionScreen extends StatelessWidget {
  const StageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = InheritedGameData.of(context);
    final session = InheritedGameSession.of(context);
    return ChronicleShell(
      current: AppRoute.stageSelection,
      title: '스테이지 선택',
      subtitle: '캠페인 진행도와 무관하게 모든 전장 브리핑에 바로 접근할 수 있습니다.',
      child: ListView(
        children: [
          for (final stage in data.stages)
            Card(
              child: ListTile(
                selected: session.campaignState.selectedStageId == stage.id,
                title: Text('Stage ${stage.id}. ${stage.name}'),
                subtitle: Text(
                  '${stage.motif} · 목표 승률 ${(stage.targetWinRate * 100).round()}% · '
                  '${session.campaignState.unlockedStageIds.contains(stage.id) ? '진행도 해금됨' : '직접 접근 가능'}',
                ),
                trailing: FilledButton(
                  onPressed: () {
                    session.selectStage(stage.id);
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoute.stageBriefing.path);
                  },
                  child: const Text('브리핑'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StageBriefingScreen extends StatelessWidget {
  const StageBriefingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stage = InheritedGameSession.of(context).selectedStage;
    return ChronicleShell(
      current: AppRoute.stageBriefing,
      title: '스테이지 브리핑',
      subtitle: 'SC-04 — 승리 조건과 패배 조건, 기믹을 전투 전에 요약합니다.',
      child: ListView(
        children: [
          SectionCard(
            title: stage.name,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _FactChip(label: '목표', value: stage.objective),
                _FactChip(label: '패배 조건', value: stage.lossCondition),
                _FactChip(label: '턴 제한', value: '${stage.turnLimit}턴'),
                _FactChip(label: '기믹', value: stage.gimmick),
              ],
            ),
          ),
          SectionCard(
            title: '출전 장수',
            child: Column(
              children: [
                for (final unit in stage.playerUnits)
                  _OfficerTile(
                    profile: unit.profile,
                    note:
                        '${unit.profile.title} · ${unit.profile.signature}\n'
                        '배치 (${unit.x}, ${unit.y}) · 브리핑 대기',
                    animationState: 'idle',
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoute.formation.path),
              child: const Text('편성으로 이동'),
            ),
          ),
        ],
      ),
    );
  }
}

class FormationScreen extends StatelessWidget {
  const FormationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = InheritedGameSession.of(context);
    final stage = session.selectedStage;
    final progress = session.campaignState.officerProgress;
    final selectedIds = session.campaignState.selectedFormationIds.toSet();
    return ChronicleShell(
      current: AppRoute.formation,
      title: '편성/준비 화면',
      subtitle: '출전 편성, 성장 상태, 장비 슬롯을 실제 캠페인 데이터와 연결합니다.',
      child: ListView(
        children: [
          SectionCard(
            title: '출전 슬롯',
            child: Column(
              children: [
                for (final officer in session.availableOfficers)
                  _OfficerTile(
                    profile: officer,
                    note:
                        'Lv.${progress[officer.id]!.level} · EXP ${progress[officer.id]!.experience} · '
                        '장비 ${progress[officer.id]!.equipmentSlots.join(', ')}',
                    trailing: FilterChip(
                      label: Text(
                        selectedIds.contains(officer.id) ? '출전 중' : '대기',
                      ),
                      selected: selectedIds.contains(officer.id),
                      onSelected: (_) => session.toggleFormation(officer.id),
                    ),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: '예상 적 정보',
            child: Column(
              children: [
                for (final unit in stage.enemyUnits)
                  _OfficerTile(
                    profile: unit.profile,
                    note: '위협: ${unit.profile.signature}',
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                session.startSelectedStage();
                Navigator.of(context).pushNamed(AppRoute.battleHud.path);
              },
              child: const Text('전투 시작'),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = InheritedGameSession.of(context);
    final report = session.lastResult;
    return ChronicleShell(
      current: AppRoute.result,
      title: '결과 화면',
      subtitle: '경험치, 획득 아이템, 다음 스테이지 해금 상태를 실제 전투 정산으로 표시합니다.',
      child: ListView(
        children: [
          SectionCard(
            title: '전투 요약',
            child: report == null
                ? const Text('아직 정산할 전투 결과가 없습니다.')
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _FactChip(
                        label: '스테이지',
                        value: 'Stage ${report.stageId}',
                      ),
                      _FactChip(
                        label: '결과',
                        value: report.outcome == BattleOutcome.victory
                            ? '승리'
                            : '패배',
                      ),
                      _FactChip(label: '보상', value: '${report.items.length}개'),
                      _FactChip(
                        label: '해금',
                        value: report.unlockedStageIds.isEmpty
                            ? '없음'
                            : report.unlockedStageIds.join(', '),
                      ),
                    ],
                  ),
          ),
          SectionCard(
            title: '성장/보상',
            child: report == null
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      for (final entry in report.experienceAwards.entries)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: InheritedGameData.of(
                              context,
                            ).getOfficer(entry.key).faction.color,
                            child: Text(
                              _leadingGlyph(
                                InheritedGameData.of(
                                  context,
                                ).getOfficer(entry.key).name,
                              ),
                            ),
                          ),
                          title: Text(
                            InheritedGameData.of(
                              context,
                            ).getOfficer(entry.key).name,
                          ),
                          subtitle: Text('경험치 +${entry.value}'),
                        ),
                      if (report.items.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('획득 아이템: ${report.items.join(', ')}'),
                        ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: session.applyLastResult,
                        child: const Text('정산 적용'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class OfficerManagementScreen extends StatelessWidget {
  const OfficerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = InheritedGameSession.of(context);
    final roster = session.availableOfficers;
    final progress = session.campaignState.officerProgress;
    return ChronicleShell(
      current: AppRoute.officerManagement,
      title: '장수 관리 화면',
      subtitle: '레벨, 경험치, 장비/소모품 슬롯, 합류 시점을 실제 캠페인 상태에서 읽어옵니다.',
      child: ListView(
        children: [
          for (final officer in roster)
            _OfficerTile(
              profile: officer,
              note:
                  'Lv.${progress[officer.id]!.level} · EXP ${progress[officer.id]!.experience} · '
                  '합류 Stage ${progress[officer.id]!.availableFromStageId}\n'
                  '장비 ${progress[officer.id]!.equipmentSlots.join(', ')} · '
                  '소모품 ${progress[officer.id]!.consumableSlots.join(', ')}',
            ),
        ],
      ),
    );
  }
}

class SaveLoadScreen extends StatelessWidget {
  const SaveLoadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = InheritedGameSession.of(context);
    return ChronicleShell(
      current: AppRoute.saveLoad,
      title: '저장/불러오기',
      subtitle: '현재 스테이지, 턴, 편성, 성장, 인벤토리, 전투 상태를 슬롯으로 저장합니다.',
      child: ListView(
        children: [
          for (final slot in SaveSlotId.values)
            Card(
              child: ListTile(
                title: Text(
                  session.slots[slot]?.label ?? '${slot.name} · 빈 슬롯',
                ),
                subtitle: Text(
                  session.slots[slot]?.savedAtIso ??
                      '현재 캠페인 상태를 여기에 저장할 수 있습니다.',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => session.loadFromSlot(slot),
                      child: const Text('불러오기'),
                    ),
                    FilledButton(
                      onPressed: () => session.saveToSlot(slot),
                      child: const Text('저장'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
