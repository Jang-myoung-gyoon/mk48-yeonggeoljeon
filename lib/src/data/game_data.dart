import 'package:flutter/widgets.dart';

import '../domain/battle_engine.dart';
import '../domain/models.dart';

const List<RequiredScreen> requiredScreens = [
  RequiredScreen(code: 'SC-01', title: '난세영걸전', purpose: '게임 첫 진입과 시작점 제공'),
  RequiredScreen(code: 'SC-02', title: '메인 메뉴', purpose: '캠페인과 설정 진입 허브'),
  RequiredScreen(code: 'SC-03', title: '스테이지 선택', purpose: '캠페인 진행 선택'),
  RequiredScreen(code: 'SC-04', title: '스테이지 브리핑', purpose: '전투 전 정보 제공'),
  RequiredScreen(code: 'SC-05', title: '편성/준비 화면', purpose: '출전 장수 및 장비 설정'),
  RequiredScreen(
    code: 'SC-06',
    title: '전투 메인 HUD',
    purpose: '실제 SRPG 플레이 수동 조작',
  ),
  RequiredScreen(code: 'SC-07', title: '전투 상세 정보창', purpose: '유닛/타일/기술 정보 확인'),
  RequiredScreen(code: 'SC-08', title: '스토리 대화 화면', purpose: '전투 전후 서사 전달'),
  RequiredScreen(code: 'SC-09', title: '일기토 연출', purpose: '상징적 1:1 대결 강조'),
  RequiredScreen(code: 'SC-10', title: '결과 화면', purpose: '승리/패배 결과 정리'),
  RequiredScreen(code: 'SC-11', title: '장수 관리 화면', purpose: '장수 성장 상태 확인'),
  RequiredScreen(code: 'SC-12', title: '저장/불러오기', purpose: '진행 상태 관리'),
  RequiredScreen(code: 'SC-13', title: '설정 화면', purpose: '시스템 옵션 조정'),
  RequiredScreen(code: 'SC-14', title: '게임 오버 씬', purpose: '패배 후 재도전 흐름 제공'),
];

class GameDataRepository {
  GameDataRepository._();

  static final instance = GameDataRepository._();

  final List<OfficerProfile> roster = _buildRoster();
  late final List<StageDefinition> stages = _buildStages(roster);

  List<OfficerProfile> get heroes => roster
      .where((officer) => officer.faction == Faction.shu && !officer.isNpc)
      .toList(growable: false);

  List<RequiredScreen> get navigationScreens => requiredScreens;

  SimulationReport get sampleReport => BattleEngine.simulate(stages.first);

  OfficerProfile getOfficer(String id) =>
      roster.firstWhere((unit) => unit.id == id);
}

class InheritedGameData extends InheritedWidget {
  const InheritedGameData({
    super.key,
    required this.data,
    required super.child,
  });

  final GameDataRepository data;

  static GameDataRepository of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<InheritedGameData>();
    assert(
      inherited != null,
      'InheritedGameData is required above this widget.',
    );
    return inherited!.data;
  }

  @override
  bool updateShouldNotify(covariant InheritedGameData oldWidget) => false;
}

List<OfficerProfile> _buildRoster() {
  return const [
    OfficerProfile(
      id: 'liu-bei',
      name: '유비',
      unitClass: UnitClass.lord,
      faction: Faction.shu,
      title: '군주/지원형',
      signature: '회복 + 인접 아군 사기 상승',
      visual: '황백색 전포와 청록 망토, 한실 문양',
      maxHp: 24,
      attack: 8,
      defense: 7,
      mobility: 3,
      range: 1,
      level: 12,
      defaultEquipment: ['쌍검', '한실 인장'],
      defaultConsumables: ['붕대'],
      skillIds: ['benevolent-order'],
    ),
    OfficerProfile(
      id: 'guan-yu',
      name: '관우',
      unitClass: UnitClass.guardian,
      faction: Faction.shu,
      title: '돌파형 무장',
      signature: '강력한 단일 공격과 일기토 우위',
      visual: '녹포, 장수염, 청룡언월도 실루엣',
      maxHp: 28,
      attack: 11,
      defense: 9,
      mobility: 3,
      range: 1,
      level: 13,
      defaultEquipment: ['청룡언월도', '녹포'],
      defaultConsumables: ['전투주'],
      skillIds: ['duel-mastery'],
    ),
    OfficerProfile(
      id: 'zhang-fei',
      name: '장비',
      unitClass: UnitClass.lancer,
      faction: Faction.shu,
      title: '제압형 탱커',
      signature: '반격 + 위압 디버프',
      visual: '흑갑, 붉은 숄, 거친 창술',
      maxHp: 30,
      attack: 10,
      defense: 10,
      mobility: 3,
      range: 1,
      level: 13,
      defaultEquipment: ['장팔사모'],
      defaultConsumables: ['도발 북'],
      skillIds: ['intimidation'],
    ),
    OfficerProfile(
      id: 'zhao-yun',
      name: '조운',
      unitClass: UnitClass.cavalry,
      faction: Faction.shu,
      title: '기동형 에이스',
      signature: '측면 돌격 + 구조 지원',
      visual: '백은 갑주와 청색 포인트',
      maxHp: 25,
      attack: 10,
      defense: 8,
      mobility: 4,
      range: 1,
      level: 12,
      defaultEquipment: ['용담창'],
      defaultConsumables: ['구급초'],
      skillIds: ['rescue-charge'],
    ),
    OfficerProfile(
      id: 'zhuge-liang',
      name: '제갈량',
      unitClass: UnitClass.strategist,
      faction: Faction.shu,
      title: '책략형 컨트롤러',
      signature: '화계 + 버프/디버프',
      visual: '백도포, 우모관, 깃털 부채',
      maxHp: 20,
      attack: 7,
      defense: 6,
      mobility: 3,
      range: 2,
      level: 11,
      defaultEquipment: ['팔괘선'],
      defaultConsumables: ['화염 부적'],
      skillIds: ['fire-ambush'],
    ),
    OfficerProfile(
      id: 'xu-zhou-refugee',
      name: '서주 피난민',
      unitClass: UnitClass.archer,
      faction: Faction.shu,
      title: '호위 대상',
      signature: '보호가 필요한 민간인',
      visual: '피난 행렬과 짐수레',
      maxHp: 14,
      attack: 2,
      defense: 2,
      mobility: 2,
      range: 1,
      level: 1,
      isNpc: true,
      defaultEquipment: ['짐수레'],
    ),
    OfficerProfile(
      id: 'changban-refugee',
      name: '장판파 피난민',
      unitClass: UnitClass.archer,
      faction: Faction.shu,
      title: '대피 대상',
      signature: '조운 구조 이벤트의 핵심 생존자',
      visual: '아이를 안은 피난민',
      maxHp: 12,
      attack: 1,
      defense: 2,
      mobility: 2,
      range: 1,
      level: 1,
      isNpc: true,
      defaultEquipment: ['보급 상자'],
    ),
    OfficerProfile(
      id: 'hua-xiong',
      name: '화웅',
      unitClass: UnitClass.raider,
      faction: Faction.enemy,
      title: '초반 돌격 보스',
      signature: '높은 공격력, 정면 돌파',
      visual: '청동 흑철 갑주와 거대 도부',
      maxHp: 28,
      attack: 12,
      defense: 8,
      mobility: 3,
      range: 1,
      level: 15,
      isBoss: true,
    ),
    OfficerProfile(
      id: 'lu-bu',
      name: '여포',
      unitClass: UnitClass.raider,
      faction: Faction.enemy,
      title: '압도적 최강자',
      signature: '공포 효과 + 광역 제압',
      visual: '적흑 갑주와 방천화극',
      maxHp: 35,
      attack: 14,
      defense: 10,
      mobility: 4,
      range: 1,
      level: 18,
      isBoss: true,
    ),
    OfficerProfile(
      id: 'cao-cao',
      name: '조조',
      unitClass: UnitClass.strategist,
      faction: Faction.enemy,
      title: '전략형 총지휘관',
      signature: '버프 + 증원 운용',
      visual: '흑청 제왕복과 금장 투구',
      maxHp: 26,
      attack: 9,
      defense: 9,
      mobility: 3,
      range: 2,
      level: 16,
      isBoss: true,
    ),
    OfficerProfile(
      id: 'zhang-liao',
      name: '장료',
      unitClass: UnitClass.cavalry,
      faction: Faction.enemy,
      title: '기동 추격 보스',
      signature: '측후방 돌진과 탈출 저지',
      visual: '청회색 기병 갑주와 장창',
      maxHp: 27,
      attack: 11,
      defense: 8,
      mobility: 4,
      range: 1,
      level: 15,
      isBoss: true,
    ),
    OfficerProfile(
      id: 'xiahou-dun',
      name: '하후돈',
      unitClass: UnitClass.guardian,
      faction: Faction.enemy,
      title: '정면 압박 보스',
      signature: '강한 돌격과 방어 파괴',
      visual: '남청 갑주와 흉터',
      maxHp: 29,
      attack: 11,
      defense: 9,
      mobility: 3,
      range: 1,
      level: 16,
      isBoss: true,
    ),
    OfficerProfile(
      id: 'yellow-turban-vanguard',
      name: '황건 선봉대',
      unitClass: UnitClass.lancer,
      faction: Faction.enemy,
      title: '일반 창병',
      signature: '전열 유지와 측면 차단',
      visual: '황토색 두건과 목창, 누더기 갑옷',
      maxHp: 20,
      attack: 7,
      defense: 5,
      mobility: 3,
      range: 1,
      level: 8,
    ),
    OfficerProfile(
      id: 'allied-archer',
      name: '연합 궁수대',
      unitClass: UnitClass.archer,
      faction: Faction.enemy,
      title: '일반 궁병',
      signature: '원거리 견제와 관문 압박',
      visual: '흑갈 경장과 목궁, 관문 수비 깃발',
      maxHp: 18,
      attack: 6,
      defense: 4,
      mobility: 2,
      range: 2,
      level: 8,
    ),
    OfficerProfile(
      id: 'wei-raider',
      name: '위군 돌격병',
      unitClass: UnitClass.raider,
      faction: Faction.enemy,
      title: '일반 돌격병',
      signature: '단기 돌진과 협공 보조',
      visual: '남청 경갑과 환도, 조조군 군기',
      maxHp: 21,
      attack: 8,
      defense: 5,
      mobility: 3,
      range: 1,
      level: 9,
    ),
    OfficerProfile(
      id: 'wei-guard',
      name: '위군 방패병',
      unitClass: UnitClass.guardian,
      faction: Faction.enemy,
      title: '일반 중보병',
      signature: '방어선 유지와 거점 점거',
      visual: '암청 방패와 철갑, 성채 수비대',
      maxHp: 22,
      attack: 7,
      defense: 7,
      mobility: 2,
      range: 1,
      level: 9,
    ),
  ];
}

List<StageDefinition> _buildStages(List<OfficerProfile> roster) {
  OfficerProfile officer(String officerId) =>
      roster.firstWhere((unit) => unit.id == officerId);

  List<UnitPlacement> heroes({
    int offsetX = 1,
    int offsetY = 0,
    bool includeRefugee = false,
    bool includeChangbanRefugee = false,
  }) {
    final heroIds = [
      'liu-bei',
      'guan-yu',
      'zhang-fei',
      'zhao-yun',
      'zhuge-liang',
    ];
    final placements = <UnitPlacement>[
      for (var i = 0; i < heroIds.length; i++)
        UnitPlacement(
          profile: officer(heroIds[i]),
          x: offsetX + (i % 2),
          y: offsetY + i,
        ),
    ];
    if (includeRefugee) {
      placements.add(
        UnitPlacement(profile: officer('xu-zhou-refugee'), x: 0, y: 5),
      );
    }
    if (includeChangbanRefugee) {
      placements.add(
        UnitPlacement(profile: officer('changban-refugee'), x: 1, y: 5),
      );
    }
    return placements;
  }

  List<UnitPlacement> enemies({
    required String bossId,
    String supportA = 'yellow-turban-vanguard',
    String supportB = 'allied-archer',
    String supportC = 'wei-raider',
  }) {
    return [
      UnitPlacement(profile: officer(bossId), x: 7, y: 3),
      UnitPlacement(profile: officer(supportA), x: 6, y: 1),
      UnitPlacement(profile: officer(supportB), x: 6, y: 5),
      UnitPlacement(profile: officer(supportC), x: 5, y: 3),
    ];
  }

  StageDefinition stage({
    required int id,
    required String name,
    required String motif,
    required String objective,
    required StageObjectiveType objectiveType,
    required StageObjectiveRule objectiveRule,
    required String lossCondition,
    required List<StageLossRule> lossTriggers,
    required String gimmick,
    required int turnLimit,
    required double targetWinRate,
    required List<UnitPlacement> playerUnits,
    required List<UnitPlacement> enemyUnits,
    List<CapturePointDefinition> capturePoints = const [],
    List<EscapeZoneDefinition> escapeZones = const [],
  }) {
    return StageDefinition(
      id: id,
      name: name,
      motif: motif,
      objective: objective,
      objectiveType: objectiveType,
      objectiveRule: objectiveRule,
      lossCondition: lossCondition,
      lossTriggers: lossTriggers,
      eventTriggers: const <StageEventDefinition>[],
      gimmick: gimmick,
      turnLimit: turnLimit,
      width: 9,
      height: 7,
      tiles: _buildTerrain(width: 9, height: 7, stageId: id),
      playerUnits: playerUnits,
      enemyUnits: enemyUnits,
      targetWinRate: targetWinRate,
      capturePoints: capturePoints,
      escapeZones: escapeZones,
    );
  }

  return [
    stage(
      id: 1,
      name: '도원결의의 맹세',
      motif: '도원결의 / 의병 결성',
      objective: '황건 선봉을 물리치고 보스를 격파한다.',
      objectiveType: StageObjectiveType.bossDefeat,
      objectiveRule: const StageObjectiveRule(
        type: StageObjectiveType.bossDefeat,
        description: '화웅 격파',
        trackedUnitIds: ['hua-xiong'],
      ),
      lossCondition: '유비 격파 또는 8턴 초과',
      lossTriggers: const [
        StageLossRule(
          type: LossTriggerType.lordDead,
          description: '유비 격파',
          trackedUnitIds: ['liu-bei'],
        ),
        StageLossRule(
          type: LossTriggerType.turnLimit,
          description: '8턴 초과',
          turnDeadline: 8,
        ),
      ],
      gimmick: '이동·공격·상성 학습',
      turnLimit: 8,
      targetWinRate: 0.90,
      playerUnits: heroes(),
      enemyUnits: enemies(bossId: 'hua-xiong'),
    ),
    stage(
      id: 2,
      name: '사수관 돌파',
      motif: '반동탁 연합 / 화웅전',
      objective: '화웅을 격파하고 관문을 확보한다.',
      objectiveType: StageObjectiveType.bossDefeat,
      objectiveRule: const StageObjectiveRule(
        type: StageObjectiveType.bossDefeat,
        description: '화웅 격파',
        trackedUnitIds: ['hua-xiong'],
      ),
      lossCondition: '유비 격파 또는 12턴 초과',
      lossTriggers: const [
        StageLossRule(
          type: LossTriggerType.lordDead,
          description: '유비 격파',
          trackedUnitIds: ['liu-bei'],
        ),
        StageLossRule(
          type: LossTriggerType.turnLimit,
          description: '12턴 초과',
          turnDeadline: 12,
        ),
      ],
      gimmick: '관우 일기토 이벤트',
      turnLimit: 12,
      targetWinRate: 0.90,
      playerUnits: heroes(offsetY: 1),
      enemyUnits: enemies(
        bossId: 'hua-xiong',
        supportA: 'wei-guard',
        supportB: 'allied-archer',
        supportC: 'yellow-turban-vanguard',
      ),
    ),
    stage(
      id: 3,
      name: '호로관의 귀신',
      motif: '여포전',
      objective: '여포를 격퇴하고 전열을 유지한다.',
      objectiveType: StageObjectiveType.bossDefeat,
      objectiveRule: const StageObjectiveRule(
        type: StageObjectiveType.bossDefeat,
        description: '여포 격퇴',
        trackedUnitIds: ['lu-bu'],
      ),
      lossCondition: '유비 격파 또는 10턴 초과',
      lossTriggers: const [
        StageLossRule(
          type: LossTriggerType.lordDead,
          description: '유비 격파',
          trackedUnitIds: ['liu-bei'],
        ),
        StageLossRule(
          type: LossTriggerType.turnLimit,
          description: '10턴 초과',
          turnDeadline: 10,
        ),
      ],
      gimmick: '여포 광역 위협',
      turnLimit: 10,
      targetWinRate: 0.90,
      playerUnits: heroes(offsetX: 0),
      enemyUnits: enemies(
        bossId: 'lu-bu',
        supportA: 'allied-archer',
        supportB: 'wei-raider',
        supportC: 'wei-guard',
      ),
    ),
    stage(
      id: 4,
      name: '서주 구원',
      motif: '서주 원군전',
      objective: '서주 피난민을 마을 끝까지 호위한다.',
      objectiveType: StageObjectiveType.escort,
      objectiveRule: const StageObjectiveRule(
        type: StageObjectiveType.escort,
        description: '서주 피난민 호위',
        trackedUnitIds: ['xu-zhou-refugee'],
      ),
      lossCondition: '유비 격파, 피난민 전멸 또는 11턴 초과',
      lossTriggers: const [
        StageLossRule(
          type: LossTriggerType.lordDead,
          description: '유비 격파',
          trackedUnitIds: ['liu-bei'],
        ),
        StageLossRule(
          type: LossTriggerType.npcDead,
          description: '피난민 전멸',
          trackedUnitIds: ['xu-zhou-refugee'],
        ),
        StageLossRule(
          type: LossTriggerType.turnLimit,
          description: '11턴 초과',
          turnDeadline: 11,
        ),
      ],
      gimmick: '구호 목표',
      turnLimit: 11,
      targetWinRate: 0.30,
      playerUnits: heroes(includeRefugee: true),
      enemyUnits: enemies(
        bossId: 'cao-cao',
        supportA: 'wei-raider',
        supportB: 'allied-archer',
        supportC: 'wei-guard',
      ),
      escapeZones: const [
        EscapeZoneDefinition(
          id: 'xu-village-exit',
          label: '서주 피난로',
          eligibleUnitIds: ['xu-zhou-refugee'],
          tiles: [GridPoint(8, 6)],
        ),
      ],
    ),
    stage(
      id: 5,
      name: '하비 포위망',
      motif: '여포 세력 추격전',
      objective: '장료를 격퇴하고 성문 압박을 끝낸다.',
      objectiveType: StageObjectiveType.bossDefeat,
      objectiveRule: const StageObjectiveRule(
        type: StageObjectiveType.bossDefeat,
        description: '장료 격퇴',
        trackedUnitIds: ['zhang-liao'],
      ),
      lossCondition: '유비 격파 또는 11턴 초과',
      lossTriggers: const [
        StageLossRule(
          type: LossTriggerType.lordDead,
          description: '유비 격파',
          trackedUnitIds: ['liu-bei'],
        ),
        StageLossRule(
          type: LossTriggerType.turnLimit,
          description: '11턴 초과',
          turnDeadline: 11,
        ),
      ],
      gimmick: '투석기와 성문',
      turnLimit: 11,
      targetWinRate: 0.30,
      playerUnits: heroes(offsetY: 1),
      enemyUnits: enemies(
        bossId: 'zhang-liao',
        supportA: 'wei-guard',
        supportB: 'allied-archer',
        supportC: 'wei-raider',
      ),
    ),
    stage(
      id: 6,
      name: '여남의 추격',
      motif: '조조군 압박전',
      objective: '주력 4인을 탈출시켜 후퇴한다.',
      objectiveType: StageObjectiveType.escape,
      objectiveRule: const StageObjectiveRule(
        type: StageObjectiveType.escape,
        description: '주력 4기 탈출',
        trackedUnitIds: [
          'liu-bei',
          'guan-yu',
          'zhang-fei',
          'zhao-yun',
          'zhuge-liang',
        ],
        requiredCount: 4,
      ),
      lossCondition: '유비 격파 또는 탈출 실패',
      lossTriggers: const [
        StageLossRule(
          type: LossTriggerType.lordDead,
          description: '유비 격파',
          trackedUnitIds: ['liu-bei'],
        ),
        StageLossRule(
          type: LossTriggerType.escapeFailure,
          description: '주력 4기 탈출 실패',
          turnDeadline: 9,
          requiredCount: 4,
        ),
      ],
      gimmick: '후방 추격 AI',
      turnLimit: 9,
      targetWinRate: 0.30,
      playerUnits: heroes(offsetX: 0),
      enemyUnits: enemies(
        bossId: 'xiahou-dun',
        supportA: 'wei-raider',
        supportB: 'wei-guard',
        supportC: 'allied-archer',
      ),
      escapeZones: const [
        EscapeZoneDefinition(
          id: 'yunan-escape',
          label: '후퇴 경로',
          tiles: [
            GridPoint(8, 0),
            GridPoint(8, 1),
            GridPoint(8, 2),
            GridPoint(8, 3),
          ],
        ),
      ],
    ),
    stage(
      id: 7,
      name: '박망파 화계',
      motif: '제갈량 첫 책략전',
      objective: '하후돈을 유인 후 격퇴한다.',
      objectiveType: StageObjectiveType.bossDefeat,
      objectiveRule: const StageObjectiveRule(
        type: StageObjectiveType.bossDefeat,
        description: '하후돈 격퇴',
        trackedUnitIds: ['xiahou-dun'],
      ),
      lossCondition: '유비 격파 또는 10턴 초과',
      lossTriggers: const [
        StageLossRule(
          type: LossTriggerType.lordDead,
          description: '유비 격파',
          trackedUnitIds: ['liu-bei'],
        ),
        StageLossRule(
          type: LossTriggerType.turnLimit,
          description: '10턴 초과',
          turnDeadline: 10,
        ),
      ],
      gimmick: '숲/화계/매복',
      turnLimit: 10,
      targetWinRate: 0.30,
      playerUnits: heroes(offsetY: 1),
      enemyUnits: enemies(
        bossId: 'xiahou-dun',
        supportA: 'wei-raider',
        supportB: 'allied-archer',
        supportC: 'wei-guard',
      ),
    ),
    stage(
      id: 8,
      name: '장판파 혈로',
      motif: '조조 남하전',
      objective: '장판교를 2턴 버텨 유비와 피난민을 지킨다.',
      objectiveType: StageObjectiveType.holdPosition,
      objectiveRule: const StageObjectiveRule(
        type: StageObjectiveType.holdPosition,
        description: '장판교를 2턴 유지',
        targetPointIds: ['changban-bridge'],
        holdTurns: 2,
        controlFaction: Faction.shu,
      ),
      lossCondition: '유비 격파, 피난민 전멸 또는 10턴 초과',
      lossTriggers: const [
        StageLossRule(
          type: LossTriggerType.lordDead,
          description: '유비 격파',
          trackedUnitIds: ['liu-bei'],
        ),
        StageLossRule(
          type: LossTriggerType.npcDead,
          description: '피난민 전멸',
          trackedUnitIds: ['changban-refugee'],
        ),
        StageLossRule(
          type: LossTriggerType.turnLimit,
          description: '10턴 초과',
          turnDeadline: 10,
        ),
      ],
      gimmick: '조운 구조 이벤트',
      turnLimit: 10,
      targetWinRate: 0.30,
      playerUnits: heroes(includeChangbanRefugee: true),
      enemyUnits: enemies(
        bossId: 'cao-cao',
        supportA: 'wei-raider',
        supportB: 'wei-guard',
        supportC: 'allied-archer',
      ),
      capturePoints: const [
        CapturePointDefinition(
          id: 'changban-bridge',
          label: '장판교',
          position: GridPoint(4, 3),
        ),
      ],
    ),
    stage(
      id: 9,
      name: '적벽의 여파',
      motif: '조조 패주 이후',
      objective: '강가 잔당을 격퇴하고 강변을 확보한다.',
      objectiveType: StageObjectiveType.bossDefeat,
      objectiveRule: const StageObjectiveRule(
        type: StageObjectiveType.bossDefeat,
        description: '장료 격퇴',
        trackedUnitIds: ['zhang-liao'],
      ),
      lossCondition: '유비 격파 또는 10턴 초과',
      lossTriggers: const [
        StageLossRule(
          type: LossTriggerType.lordDead,
          description: '유비 격파',
          trackedUnitIds: ['liu-bei'],
        ),
        StageLossRule(
          type: LossTriggerType.turnLimit,
          description: '10턴 초과',
          turnDeadline: 10,
        ),
      ],
      gimmick: '강변 지형',
      turnLimit: 10,
      targetWinRate: 0.30,
      playerUnits: heroes(offsetY: 1),
      enemyUnits: enemies(
        bossId: 'zhang-liao',
        supportA: 'allied-archer',
        supportB: 'wei-guard',
        supportC: 'wei-raider',
      ),
    ),
    stage(
      id: 10,
      name: '형주 진입',
      motif: '형주 장악전',
      objective: '북문과 보급고를 점령해 형주 거점을 장악한다.',
      objectiveType: StageObjectiveType.capturePoints,
      objectiveRule: const StageObjectiveRule(
        type: StageObjectiveType.capturePoints,
        description: '북문과 보급고 점령',
        targetPointIds: ['jing-north-gate', 'jing-supply-depot'],
        requiredCount: 2,
        controlFaction: Faction.shu,
      ),
      lossCondition: '유비 격파 또는 12턴 초과',
      lossTriggers: const [
        StageLossRule(
          type: LossTriggerType.lordDead,
          description: '유비 격파',
          trackedUnitIds: ['liu-bei'],
        ),
        StageLossRule(
          type: LossTriggerType.turnLimit,
          description: '12턴 초과',
          turnDeadline: 12,
        ),
      ],
      gimmick: '다방향 증원',
      turnLimit: 12,
      targetWinRate: 0.30,
      playerUnits: heroes(offsetY: 1),
      enemyUnits: enemies(
        bossId: 'cao-cao',
        supportA: 'wei-guard',
        supportB: 'allied-archer',
        supportC: 'wei-raider',
      ),
      capturePoints: const [
        CapturePointDefinition(
          id: 'jing-north-gate',
          label: '형주 북문',
          position: GridPoint(7, 2),
        ),
        CapturePointDefinition(
          id: 'jing-supply-depot',
          label: '보급고',
          position: GridPoint(6, 5),
        ),
      ],
    ),
  ];
}

List<TerrainTile> _buildTerrain({
  required int width,
  required int height,
  required int stageId,
}) {
  final tiles = <TerrainTile>[];
  final forestBand = stageId % height;
  final riverColumn = (stageId + 2) % width;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      TerrainType type = TerrainType.plain;
      if (y == height ~/ 2) {
        type = TerrainType.road;
      }
      if (y == forestBand || (x == 2 && y.isOdd)) {
        type = TerrainType.forest;
      }
      if (x == riverColumn && y > 0 && y < height - 1) {
        type = TerrainType.river;
      }
      if (x == width - 1 && y == height ~/ 2) {
        type = TerrainType.gate;
      }
      if (x == 0 && y == height - 1) {
        type = TerrainType.village;
      }
      if (x == width - 1 && y != height ~/ 2) {
        type = TerrainType.wall;
      }
      tiles.add(TerrainTile(x: x, y: y, type: type));
    }
  }
  return tiles;
}
