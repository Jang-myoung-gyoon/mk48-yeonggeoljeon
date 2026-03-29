import '../src/data/game_data.dart';
import '../src/domain/models.dart';

class GameRepository {
  GameRepository._();

  static final instance = GameRepository._();

  GameDataRepository get _delegate => GameDataRepository.instance;

  List<StageDefinition> get stages => _delegate.stages;
  List<OfficerProfile> get heroes => _delegate.heroes;
  List<RequiredScreen> get requiredScreens => _delegate.navigationScreens;
}
