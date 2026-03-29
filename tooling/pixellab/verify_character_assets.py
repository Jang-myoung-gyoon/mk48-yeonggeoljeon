#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'assets/characters/specs/generated_manifest.json'
BRIEF = ROOT / 'assets/characters/specs/pixellab_character_brief.json'
STATES = ('idle','walk','attack','hit')
FACINGS = ('south','east','north','west')

def main():
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    briefs = json.loads(BRIEF.read_text(encoding='utf-8'))
    required = [entry['id'] for entry in briefs if entry.get('role') == 'hero']
    chars = manifest.get('characters', {})
    problems = []
    missing = [sprite_id for sprite_id in required if sprite_id not in chars]
    if missing:
        problems.append('missing bundles: ' + ', '.join(missing))
    for sprite_id, reason in manifest.get('failures', {}).items():
        problems.append(f'{sprite_id}: {reason}')
    for sprite_id, data in chars.items():
        for facing in FACINGS:
            if not (ROOT / data['rotations'][facing]).exists():
                problems.append(f'{sprite_id}: missing rotation {facing}')
        if not (ROOT / data['icon_96']).exists():
            problems.append(f'{sprite_id}: missing icon')
        for state in STATES:
            for facing in FACINGS:
                if not (ROOT / data['animations'][state][facing]).exists():
                    problems.append(f'{sprite_id}: missing {state}-{facing}')
    if problems:
        print(json.dumps({'ok': False, 'problems': problems}, ensure_ascii=False, indent=2))
        return 1
    print(json.dumps({'ok': True, 'count': len(required), 'sprites': required}, ensure_ascii=False, indent=2))
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
