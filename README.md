# 난세영걸전

삼국지 영걸전 감성의 Flutter 기반 SRPG 수직 슬라이스입니다.  
유비 세력 5인의 성장, 10개 캠페인 스테이지, 헤드리스 전투 코어, 라우트 직접 진입 가능한 화면 셸을 한 코드베이스에 묶었습니다.

## 현재 포함 범위

- 10개 캠페인 스테이지 데이터
- 유비/관우/장비/조운/제갈량 5인 플레이어 로스터
- 보스/지형/턴 제한을 포함한 순수 Dart 전투 코어
- 수동 이동/공격/대기/턴 종료가 가능한 전투 HUD
- 타이틀, 메뉴, 스테이지 선택, 브리핑, 편성, 전투, 대화, 일기토, 결과, 장수 관리, 저장/불러오기, 설정, 게임 오버 화면
- Flutter test + analyze 기반 회귀 검증

## 실행

```bash
flutter pub get
flutter run
```

웹 확인:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 7357
```

## 검증

```bash
flutter analyze
flutter test
```
