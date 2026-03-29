import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app.dart';
import '../domain/campaign_models.dart';
import '../data/game_data.dart';
import '../domain/battle_engine.dart';
import '../domain/models.dart';
import 'character_sprite_assets.dart';
import 'ui_palette_extensions.dart';

part 'screens_shell.part.dart';
part 'screens_navigation.part.dart';
part 'screens_campaign.part.dart';
part 'screens_battle.part.dart';
part 'screens_story.part.dart';

String _leadingGlyph(String text) => text.isEmpty ? '?' : text.substring(0, 1);
