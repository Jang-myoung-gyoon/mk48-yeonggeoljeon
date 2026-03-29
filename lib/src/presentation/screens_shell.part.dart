part of 'screens.dart';

class ChronicleShell extends StatelessWidget {
  const ChronicleShell({
    super.key,
    required this.current,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
  });

  final AppRoute current;
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  void _openRouteControlsSheet(
    BuildContext context,
    List<RouteSpec> specs,
    AppRoute current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('화면 컨트롤'),
                subtitle: Text('이동할 화면을 선택하세요.'),
              ),
              for (final spec in specs)
                ListTile(
                  selected: spec.route == current,
                  title: Text(spec.label),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    if (spec.route != current) {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(spec.route.path);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final specs = NanseHeroesApp.routeSpecs;
    final currentSpec = specs.firstWhere((spec) => spec.route == current);
    final appBarActions = <Widget>[
      TextButton.icon(
        onPressed: () => _openRouteControlsSheet(context, specs, current),
        icon: const Icon(Icons.tune),
        label: const Text('화면 컨트롤'),
      ),
      ...actions,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: appBarActions),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentSpec.label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PillarStrip extends StatelessWidget {
  const _PillarStrip();

  @override
  Widget build(BuildContext context) {
    final pillars = const [
      '유비 중심의 압축 서사',
      '미션형 SRPG 전장',
      '소수 정예 장수 육성',
      '삼국지 정체성이 분명한 아트/사운드',
    ];
    return SectionCard(
      title: '프로덕트 필러',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final item in pillars) Chip(label: Text(item))],
      ),
    );
  }
}

class _OfficerTile extends StatelessWidget {
  const _OfficerTile({
    required this.profile,
    required this.note,
    this.trailing,
    this.animationState = 'idle',
  });

  final OfficerProfile profile;
  final String note;
  final Widget? trailing;
  final String animationState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OfficerSprite(
              profile: profile,
              animationState: animationState,
              size: 72,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.name} · ${profile.title}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(note),
                  const SizedBox(height: 6),
                  Text(
                    profile.visual,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ?? Text('Lv.${profile.level}'),
          ],
        ),
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _BattleGrid extends StatelessWidget {
  const _BattleGrid({
    required this.state,
    required this.selectedUnitId,
    required this.animationStates,
    required this.unitFacings,
    required this.visualUnitPositions,
    required this.floatingTexts,
    required this.particles,
    required this.highlightedTiles,
    required this.interactiveTargetUnitIds,
    required this.onUnitSelected,
    required this.onTileSelected,
    required this.onTargetUnitSelected,
    required this.interactionLocked,
  });

  final BattleState state;
  final String selectedUnitId;
  final Map<String, String> animationStates;
  final Map<String, CharacterFacing> unitFacings;
  final Map<String, GridPoint> visualUnitPositions;
  final List<_BattleFloatingTextEntry> floatingTexts;
  final List<_BattleParticleEntry> particles;
  final Set<GridPoint> highlightedTiles;
  final Set<String> interactiveTargetUnitIds;
  final ValueChanged<String> onUnitSelected;
  final ValueChanged<GridPoint> onTileSelected;
  final ValueChanged<String> onTargetUnitSelected;
  final bool interactionLocked;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: state.stage.width / state.stage.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / state.stage.width;
          final cellHeight = constraints.maxHeight / state.stage.height;
          final displayUnits = {
            for (final unit in state.units.where(
              (candidate) => candidate.active,
            ))
              visualUnitPositions[unit.id] ?? unit.position: unit,
          };

          final cells = <Widget>[];
          for (var y = 0; y < state.stage.height; y++) {
            for (var x = 0; x < state.stage.width; x++) {
              final terrain = BattleEngine.terrainAt(state, x, y);
              final point = GridPoint(x, y);
              final unit = displayUnits[point];
              final isHighlighted = highlightedTiles.contains(point);
              final isSelected = unit?.id == selectedUnitId;
              final isInteractiveTarget =
                  unit != null && interactiveTargetUnitIds.contains(unit.id);
              cells.add(
                InkWell(
                  key: ValueKey('battle-cell-$x-$y'),
                  onTap: interactionLocked
                      ? null
                      : () {
                          if (unit != null && isInteractiveTarget) {
                            onTargetUnitSelected(unit.id);
                            return;
                          }
                          if (unit != null && unit.faction == Faction.shu) {
                            onUnitSelected(unit.id);
                            return;
                          }
                          if (isHighlighted) {
                            onTileSelected(point);
                          }
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Colors.amberAccent
                            : isInteractiveTarget
                            ? Colors.redAccent
                            : isHighlighted
                            ? Colors.white70
                            : Colors.black45,
                        width:
                            isSelected || isInteractiveTarget || isHighlighted
                            ? 2
                            : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: TerrainTileSprite(terrain: terrain),
                        ),
                        Positioned(
                          left: 4,
                          top: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                _leadingGlyph(terrain.label),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          }

          final floatingEntries = <Widget>[
            for (var index = 0; index < floatingTexts.length; index++)
              Positioned(
                left: floatingTexts[index].position.x * cellWidth,
                top: floatingTexts[index].position.y * cellHeight,
                width: cellWidth,
                height: cellHeight,
                child: IgnorePointer(
                  child: Center(
                    child: _BattleFloatingText(
                      entry: floatingTexts[index],
                      stackIndex: index,
                    ),
                  ),
                ),
              ),
          ];

          final particleEntries = <Widget>[
            for (final particle in particles)
              Positioned(
                left: particle.position.x * cellWidth,
                top: particle.position.y * cellHeight,
                width: cellWidth,
                height: cellHeight,
                child: IgnorePointer(
                  child: Center(child: _BattleParticle(entry: particle)),
                ),
              ),
          ];

          final unitEntries = <Widget>[
            for (final unit in state.units.where(
              (candidate) => candidate.active,
            ))
              _BattleUnitOverlay(
                key: ValueKey('battle-unit-${unit.id}'),
                unit: unit,
                position: visualUnitPositions[unit.id] ?? unit.position,
                animationState: animationStates[unit.id] ?? 'idle',
                facing:
                    unitFacings[unit.id] ?? CharacterSpriteAssets.defaultFacing,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
              ),
          ];

          return Stack(
            children: [
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: state.stage.width,
                childAspectRatio: 1,
                children: cells,
              ),
              IgnorePointer(
                child: Stack(
                  children: [
                    ...unitEntries,
                    ...particleEntries,
                    ...floatingEntries,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BattleUnitOverlay extends StatelessWidget {
  const _BattleUnitOverlay({
    super.key,
    required this.unit,
    required this.position,
    required this.animationState,
    required this.facing,
    required this.cellWidth,
    required this.cellHeight,
  });

  final BattleUnit unit;
  final GridPoint position;
  final String animationState;
  final CharacterFacing facing;
  final double cellWidth;
  final double cellHeight;

  @override
  Widget build(BuildContext context) {
    final spriteSize = cellWidth < 56
        ? (cellWidth * 0.62).clamp(16.0, 24.0)
        : 36.0;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 120),
      curve: Curves.linear,
      left: position.x * cellWidth,
      top: position.y * cellHeight,
      width: cellWidth,
      height: cellHeight,
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0, -0.15),
            child: BattleUnitSprite(
              unit: unit,
              animationState: animationState,
              facing: facing,
              size: spriteSize,
            ),
          ),
          Positioned(
            left: 4,
            right: 4,
            bottom: 3,
            child: _BattleUnitHealthBar(unit: unit),
          ),
        ],
      ),
    );
  }
}

class _BattleUnitHealthBar extends StatelessWidget {
  const _BattleUnitHealthBar({required this.unit});

  final BattleUnit unit;

  @override
  Widget build(BuildContext context) {
    final ratio = unit.maxHp == 0 ? 0.0 : unit.hp / unit.maxHp;
    final color = unit.faction == Faction.enemy
        ? const Color(0xFFE25555)
        : ratio > 0.6
        ? const Color(0xFF63E283)
        : ratio > 0.3
        ? const Color(0xFFFFC857)
        : const Color(0xFFFF6B6B);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black87),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            key: ValueKey('battle-hp-bar-${unit.id}'),
            value: ratio.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: const Color(0xFF2B1B1B),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
    );
  }
}

class _BattleFloatingText extends StatelessWidget {
  const _BattleFloatingText({required this.entry, required this.stackIndex});

  final _BattleFloatingTextEntry entry;
  final int stackIndex;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.tone) {
      _BattleFloatTone.damage => const Color(0xFFFFD0D0),
      _BattleFloatTone.heal => const Color(0xFFC8FFD2),
    };
    final shadowColor = switch (entry.tone) {
      _BattleFloatTone.damage => const Color(0xFF4A0000),
      _BattleFloatTone.heal => const Color(0xFF0F4A1E),
    };

    return TweenAnimationBuilder<double>(
      key: ValueKey(entry.id),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, progress, child) {
        final dy = (20 + stackIndex * 12) * progress;
        return Transform.translate(
          offset: Offset(0, -dy),
          child: Opacity(opacity: 1 - progress, child: child),
        );
      },
      child: Text(
        entry.text,
        key: ValueKey('battle-float-text-${entry.id}'),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: color,
          shadows: [
            Shadow(
              color: shadowColor,
              blurRadius: 0,
              offset: const Offset(1, 1),
            ),
            Shadow(
              color: shadowColor,
              blurRadius: 0,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleParticle extends StatelessWidget {
  const _BattleParticle({required this.entry});

  final _BattleParticleEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.kind) {
      _BattleParticleKind.attack => const Color(0xFFFFA84D),
      _BattleParticleKind.tactic => const Color(0xFF7FDBFF),
    };
    final keyName = switch (entry.kind) {
      _BattleParticleKind.attack => 'battle-particle-attack',
      _BattleParticleKind.tactic => 'battle-particle-tactic',
    };

    return TweenAnimationBuilder<double>(
      key: ValueKey(entry.id),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0.25, end: 1),
      builder: (context, progress, child) {
        return Transform.scale(
          scale: progress,
          child: Opacity(opacity: 1 - (progress * 0.65), child: child),
        );
      },
      child: Container(
        key: ValueKey(keyName),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.3),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _DuelPanel extends StatelessWidget {
  const _DuelPanel({
    required this.profile,
    required this.tag,
    required this.accent,
    this.animationState = 'idle',
    this.facing = CharacterFacing.south,
  });

  final OfficerProfile profile;
  final String tag;
  final Faction accent;
  final String animationState;
  final CharacterFacing facing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.color.withValues(alpha: 0.15),
                  border: Border.all(color: accent.color, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: OfficerSprite(
                    profile: profile,
                    animationState: animationState,
                    facing: facing,
                    size: 120,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                profile.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(tag),
              const SizedBox(height: 8),
              Text(
                animationState == 'idle'
                    ? '기세를 가다듬는다'
                    : animationState == 'attack'
                    ? '결정타를 날린다'
                    : '충격을 버텨낸다',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
