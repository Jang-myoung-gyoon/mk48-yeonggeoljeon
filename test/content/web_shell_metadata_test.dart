import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web shell metadata uses the game identity instead of scaffold defaults', () {
    final html = File('web/index.html').readAsStringSync();
    final manifest = File('web/manifest.json').readAsStringSync();

    expect(html, contains('<title>난세영걸전</title>'));
    expect(
      html,
      contains(
        '<meta name="description" content="삼국지 영걸전 감성의 Flutter 기반 SRPG 수직 슬라이스.">',
      ),
    );
    expect(html, contains('apple-mobile-web-app-title" content="난세영걸전"'));
    expect(html, isNot(contains('A new Flutter project.')));
    expect(html, isNot(contains('<title>ralphthon</title>')));

    expect(manifest, contains('"name": "난세영걸전"'));
    expect(manifest, contains('"short_name": "난세영걸전"'));
    expect(manifest, contains('"description": "삼국지 영걸전 감성의 Flutter 기반 SRPG 수직 슬라이스."'));
    expect(manifest, isNot(contains('"name": "ralphthon"')));
    expect(manifest, isNot(contains('"description": "A new Flutter project."')));
  });
}
