import 'package:flutter/widgets.dart';

import '../domain/battle_engine.dart';
import '../domain/models.dart';

const List<RequiredScreen> requiredScreens = [
  RequiredScreen(code: 'SC-01', title: '난세영걸전', purpose: '게임 첫 진입과 시작점 제공'),
  RequiredScreen(code: 'SC-02', title: '메인 메뉴', purpose: '캠페인과 설정 진입 허브'),
  RequiredScreen(code: 'SC-03', title: '스테이지 선택', purpose: '캠페인 진행 선택'),
  RequiredScreen(code: 'SC-04', title: '스테이지 브리핑', purpose: '전투 전 정보 제공'),
  RequiredScreen(code: 'SC-05', title: '편성/준비 화면', purpose: '출전 장수 및 장비 설정'),
  RequiredScreen(code: 'SC-06', title: '전투 메인 HUD', purpose: '실제 SRPG 플레이 수동 조작'),
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

  List<OfficerProfile> get heroes =>
      roster.where((officer) => officer.faction == Faction.shu).toList(growable: false);

  List<RequiredScreen> get navigationScreens => requiredScreens;

  SimulationReport get sampleReport => BattleEngine.simulate(stages.first);

  OfficerProfile getOfficer(String id) => roster.firstWhere((unit) => unit.id == id);
}

class InheritedGameData extends InheritedWidget {
  const InheritedGameData({super.key, required this.data, required super.child});

  final GameDataRepository data;

  static GameDataRepository of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<InheritedGameData>();
    assert(inherited != null, 'InheritedGameData is required above this widget.');
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
  OfficerProfile officer(String id) => roster.firstWhere((unit) => unit.id == id);

  final stageRows = [
    ('도원결의의 맹세', '도원결의 / 의병 결성', '튜토리얼 승리', '황건 도적을 제압하고 형제 결의를 맺는다.', '유비 격파', '이동·공격·상성 학습', 8, 0.90, 'hua-xiong'),
    ('사수관 돌파', '반동탁 연합 / 화웅전', '12턴 내 관문 돌파', '관우 일기토를 유도해 관문을 확보한다.', '유비 격파', '관우 일기토 이벤트', 12, 0.90, 'hua-xiong'),
    ('호로관의 귀신', '여포전', '생존 후 퇴각로 확보', '여포의 위협을 견디며 협공 타이밍을 만든다.', '핵심 장수 2인 이상 격파', '여포 광역 위협', 10, 0.90, 'lu-bu'),
    ('서주 구원', '서주 원군전', '민간인 호위', '난민 호송과 마을 화재 진압을 병행한다.', '민간인 전멸', '구호 목표', 11, 0.30, 'cao-cao'),
    ('하비 포위망', '여포 세력 추격전', '성문 2개 점령', '성문 압박과 궁병 대응을 동시에 수행한다.', '유비 격파', '투석기와 성문', 11, 0.30, 'zhang-liao'),
    ('여남의 추격', '조조군 압박전', '4기 이상 탈출', '후방 추격을 뿌리치며 보급품을 회수한다.', '탈출 실패', '후방 추격 AI', 9, 0.30, 'xiahou-dun'),
    ('박망파 화계', '제갈량 첫 책략전', '화공 유인 성공', '숲길에 적을 유인해 화계를 발동한다.', '유인 실패', '숲/화계/매복', 10, 0.30, 'xiahou-dun'),
    ('장판파 혈로', '조조 남하전', '유비 탈출 및 민간인 보호', '조운 구조 이벤트와 다중 탈출 지점을 운영한다.', '유비 사망', '조운 구조 이벤트', 10, 0.30, 'cao-cao'),
    ('적벽의 여파', '조조 패주 이후', '강 도하 후 잔당 제압', '수군 지원을 받으며 강변 잔당을 제압한다.', '턴 제한 초과', '강변 지형', 10, 0.30, 'zhang-liao'),
    ('형주 진입', '형주 장악전', '거점 점령 후 본진 방어', '다방향 증원을 막으며 형주 본진을 확보한다.', '유비 격파', '다방향 증원', 12, 0.30, 'cao-cao'),
  ];

  return [
    for (var index = 0; index < stageRows.length; index++)
      _stageFromRow(
        id: index + 1,
        name: stageRows[index].$1,
        motif: stageRows[index].$2,
        objective: stageRows[index].$3,
        gimmick: stageRows[index].$6,
        lossCondition: stageRows[index].$5,
        turnLimit: stageRows[index].$7,
        targetWinRate: stageRows[index].$8,
        boss: officer(stageRows[index].$9),
        roster: roster,
      ),
  ];
}

StageDefinition _stageFromRow({
  required int id,
  required String name,
  required String motif,
  required String objective,
  required String gimmick,
  required String lossCondition,
  required int turnLimit,
  required double targetWinRate,
  required OfficerProfile boss,
  required List<OfficerProfile> roster,
}) {
  OfficerProfile officer(String officerId) => roster.firstWhere((unit) => unit.id == officerId);

  final terrain = _buildTerrain(width: 8, height: 6, stageId: id);
  final heroIds = ['liu-bei', 'guan-yu', 'zhang-fei', 'zhao-yun', 'zhuge-liang'];
  final playerUnits = [
    for (var i = 0; i < heroIds.length; i++)
      UnitPlacement(
        profile: officer(heroIds[i]),
        x: 1 + (i % 2),
        y: i == heroIds.length - 1 ? 0 : 1 + i,
      ),
  ];
  final enemyUnits = [
    UnitPlacement(profile: boss, x: 6, y: 2),
    UnitPlacement(profile: _supportEnemy(id, roster), x: 5, y: 1),
    UnitPlacement(profile: _supportEnemy(id + 1, roster), x: 6, y: 4),
    UnitPlacement(profile: _supportEnemy(id + 2, roster), x: 4, y: 3),
  ];

  return StageDefinition(
    id: id,
    name: name,
    motif: motif,
    objective: objective,
    lossCondition: lossCondition,
    gimmick: gimmick,
    turnLimit: turnLimit,
    width: 8,
    height: 6,
    tiles: terrain,
    playerUnits: playerUnits,
    enemyUnits: enemyUnits,
    targetWinRate: targetWinRate,
  );
}

OfficerProfile _supportEnemy(int seed, List<OfficerProfile> roster) {
  final pool = roster.where((unit) => unit.faction == Faction.enemy && !unit.isBoss).toList(growable: false);
  return pool[seed % pool.length];
}

List<TerrainTile> _buildTerrain({required int width, required int height, required int stageId}) {
  final tiles = <TerrainTile>[];
  final forestBand = stageId % height;
  final riverColumn = stageId % width;

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
