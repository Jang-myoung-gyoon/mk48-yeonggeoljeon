# Battle Sprite Animation Design

## Goal

전투 화면에서 `assets/characters` 자산을 실제 전장 유닛 렌더링에 연결하고, 이동/공격/피격/대기 상태에 따라 보이는 애니메이션을 반영한다.

## Scope

- 아군 5명은 각자 보유한 `idle`, `walk`, `attack`, `hit` 애니메이션을 그대로 사용한다.
- 적군과 중립 유닛은 전용 자산이 없더라도 기존 영웅 스프라이트를 역할 기반으로 재사용한다.
- 전투 타일맵과 선택 유닛 패널 모두 같은 스프라이트 해석 규칙을 사용한다.
- 액션 직후 애니메이션이 잠깐 재생된 뒤 자동으로 `idle` 상태로 복귀한다.

## Approach

### Asset Resolution

- `CharacterSpriteAssets`에 유닛별 실제 스프라이트 ID를 해석하는 규칙을 둔다.
- 아군은 현재 유닛 ID를 그대로 사용한다.
- 적군/중립은 `UnitClass` 기반 기본 매핑을 사용한다.
  - `lord` -> `liu-bei`
  - `guardian` -> `guan-yu`
  - `lancer` -> `zhao-yun`
  - `cavalry`/`raider` -> `zhang-fei`
  - `strategist`/`archer` -> `zhuge-liang`
- 애니메이션 파일은 `gif` 우선, 없으면 `png`, 둘 다 없으면 base frame, 그것도 없으면 기존 fallback 아바타를 사용한다.

### Facing

- 스프라이트 방향은 남/동/북/서 4방향만 사용한다.
- 기본 방향은 남쪽이다.
- 유닛 이동 시 출발점과 도착점을 비교해 방향을 결정한다.
- 공격/책략은 공격자와 대상의 상대 위치를 기준으로 방향을 정한다.
- 정지 상태는 마지막으로 사용한 방향을 유지한다.

### Animation State

- 화면 상태로 유닛별 `animationState` 와 `facing` 을 관리한다.
- 이동 실행 시 `walk`, 공격/책략 시 공격자는 `attack`, 대상은 `hit`, 대기/리셋/턴 종료 후에는 `idle` 로 정리한다.
- 액션 상태는 짧은 지연 후 자동으로 `idle` 로 복귀한다.
- 상태 복귀는 `mounted` 확인 후 수행해 dispose 이후 setState를 피한다.

### Testing

- 자산 경로 해석 테스트를 추가해 적군/중립 대체 스프라이트 규칙과 애니메이션 파일 우선순위를 고정한다.
- 전투 HUD 위젯 테스트를 추가해:
  - 전장 타일맵에 실제 `Image` 위젯이 올라오는지
  - 공격 실행 뒤 선택 유닛 패널의 애니메이션 상태가 `attack` 으로 바뀌었다가 다시 `idle` 로 복귀하는지
  - 적군도 fallback 대신 실제 자산 경로를 받는지
    를 검증한다.

## Risks

- 테스트 환경에서 GIF 디코딩 타이밍 차이가 있을 수 있어, 경로 기반 검증과 상태 텍스트 검증을 같이 사용한다.
- 적군 자산 재사용은 연출상 완전히 고유하지 않다. 추후 전용 적군 세트가 생기면 매핑 테이블만 교체하면 된다.
