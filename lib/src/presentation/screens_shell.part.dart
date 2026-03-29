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

  @override
  Widget build(BuildContext context) {
    final specs = NanseHeroesApp.routeSpecs;
    final currentSpec = specs.firstWhere((spec) => spec.route == current);
    final navItems = [
      for (final spec in specs)
        ListTile(
          selected: spec.route == current,
          title: Text(spec.label),
          onTap: () {
            Navigator.of(context).pushReplacementNamed(spec.route.path);
          },
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: Drawer(
        child: SafeArea(child: ListView(children: navItems)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1080;
          return Row(
            children: [
              if (wide)
                SizedBox(
                  width: 280,
                  child: Card(child: ListView(children: navItems)),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSpec.label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
  });

  final OfficerProfile profile;
  final String note;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: OfficerAvatar(profile: profile),
        title: Text('${profile.name} · ${profile.title}'),
        subtitle: Text('$note\n${profile.visual}'),
        isThreeLine: true,
        trailing: trailing ?? Text('Lv.${profile.level}'),
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
    required this.selectedAnimationState,
    required this.highlightedTiles,
    required this.attackableUnitIds,
    required this.onUnitSelected,
    required this.onTileSelected,
  });

  final BattleState state;
  final String selectedUnitId;
  final String selectedAnimationState;
  final Set<GridPoint> highlightedTiles;
  final Set<String> attackableUnitIds;
  final ValueChanged<String> onUnitSelected;
  final ValueChanged<GridPoint> onTileSelected;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (var y = 0; y < state.stage.height; y++) {
      for (var x = 0; x < state.stage.width; x++) {
        final terrain = BattleEngine.terrainAt(state, x, y);
        final unit = state.units
            .where(
              (candidate) =>
                  candidate.alive && candidate.x == x && candidate.y == y,
            )
            .cast<BattleUnit?>()
            .firstOrNull;
        final point = GridPoint(x, y);
        final isHighlighted = highlightedTiles.contains(point);
        final isSelected = unit?.id == selectedUnitId;
        final isAttackable =
            unit != null && attackableUnitIds.contains(unit.id);
        cells.add(
          InkWell(
            key: ValueKey('battle-cell-$x-$y'),
            onTap: () {
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
                      : isAttackable
                      ? Colors.redAccent
                      : isHighlighted
                      ? Colors.white70
                      : Colors.black45,
                  width: isSelected || isAttackable || isHighlighted ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: TerrainTileSprite(terrain: terrain)),
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
                  if (unit != null)
                    Center(
                      child: BattleUnitSprite(
                        unit: unit,
                        animationState: unit.id == selectedUnitId
                            ? selectedAnimationState
                            : 'idle',
                        size: 36,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return AspectRatio(
      aspectRatio: state.stage.width / state.stage.height,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: state.stage.width,
        childAspectRatio: 1,
        children: cells,
      ),
    );
  }
}

class _DuelPanel extends StatelessWidget {
  const _DuelPanel({
    required this.name,
    required this.tag,
    required this.accent,
  });

  final String name;
  final String tag;
  final Faction accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: accent.color,
                child: Text(
                  _leadingGlyph(name),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(height: 16),
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(tag),
            ],
          ),
        ),
      ),
    );
  }
}
