#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, shutil, subprocess, tempfile, zipfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUTPUT_ROOT = ROOT / 'assets/characters'
JOBS_PATH = OUTPUT_ROOT / 'specs/pixellab_character_jobs.json'
BRIEF_PATH = OUTPUT_ROOT / 'specs/pixellab_character_brief.json'
PLAN_PATH = OUTPUT_ROOT / 'specs/pixellab_animation_plan.json'
FACINGS = ('south','east','north','west')


def load_json(path: Path):
    return json.loads(path.read_text(encoding='utf-8'))


def node_download(character_id: str, out_path: Path):
    url = f'https://api.pixellab.ai/mcp/characters/{character_id}/download'
    js = r'''
const fs = require('fs');
(async () => {
  const [url, outPath] = process.argv.slice(1);
  const res = await fetch(url);
  console.log(JSON.stringify({status: res.status, contentType: res.headers.get('content-type') || '', contentLength: res.headers.get('content-length') || ''}));
  const buf = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(outPath, buf);
})();
'''
    result = subprocess.run(['node','-e',js,url,str(out_path)], cwd=ROOT, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise RuntimeError(result.stderr or result.stdout)
    meta = None
    for line in result.stdout.splitlines():
        line = line.strip()
        if line.startswith('{'):
            meta = json.loads(line)
            break
    if meta is None:
        raise RuntimeError('missing download metadata')
    return int(meta['status']), meta.get('contentType','')


def copy_rotations(extracted: Path, dest: Path):
    base_dir = dest / 'base'
    base_dir.mkdir(parents=True, exist_ok=True)
    rotations = {}
    for facing in FACINGS:
        src = extracted / 'rotations' / f'{facing}.png'
        if not src.exists():
            raise FileNotFoundError(f'missing rotation {src}')
        target = base_dir / f'{facing}.png'
        shutil.copy2(src, target)
        rotations[facing] = str(target.relative_to(ROOT))
    return rotations


def create_icon(dest: Path):
    src = dest / 'base/south.png'
    icon_dir = dest / 'icon'
    icon_dir.mkdir(parents=True, exist_ok=True)
    target = icon_dir / 'south-96.png'
    with Image.open(src) as image:
        if image.size != (48, 48):
            raise ValueError(f'expected 48x48 south frame, got {image.size}')
        image.resize((96,96), resample=Image.Resampling.NEAREST).save(target)
    return str(target.relative_to(ROOT))


def materialize_animations(extracted: Path, dest: Path, sprite_id: str, default_map: dict, overrides: dict):
    resolved = {**default_map, **overrides.get(sprite_id, {})}
    out = {}
    animations_dir = dest / 'animations'
    animations_dir.mkdir(parents=True, exist_ok=True)
    for state_name, template_name in resolved.items():
        state_paths = {}
        for facing in FACINGS:
            frame_dir = extracted / 'animations' / template_name / facing
            frames = sorted(frame_dir.glob('frame_*.png'))
            if not frames:
                raise FileNotFoundError(f'missing frames for {sprite_id} {state_name} {facing}')
            images = [Image.open(frame).convert('RGBA') for frame in frames]
            target = animations_dir / f'{state_name}-{facing}.gif'
            images[0].save(target, save_all=True, append_images=images[1:], optimize=False, disposal=2, loop=0, duration=110, transparency=0)
            for image in images:
                image.close()
            state_paths[facing] = str(target.relative_to(ROOT))
        out[state_name] = state_paths
    return out


def write_manifest(dest: Path, payload: dict):
    (dest / 'manifest.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sprite-id', action='append')
    args = parser.parse_args()

    jobs = load_json(JOBS_PATH)
    briefs = {entry['id']: entry for entry in load_json(BRIEF_PATH)}
    plan = load_json(PLAN_PATH)
    default_map = plan['default']
    overrides = plan.get('overrides', {})
    selected = args.sprite_id or list(jobs.keys())

    existing_manifest_path = OUTPUT_ROOT / 'specs/generated_manifest.json'
    if existing_manifest_path.exists():
        existing = json.loads(existing_manifest_path.read_text(encoding='utf-8'))
        aggregate = dict(existing.get('characters', {}))
        failures = dict(existing.get('failures', {}))
    else:
        aggregate = {}
        failures = {}

    for sprite_id in selected:
        character_id = jobs.get(sprite_id)
        if not character_id:
            failures[sprite_id] = 'missing job mapping'
            continue
        with tempfile.TemporaryDirectory(prefix=f'pixellab-{sprite_id}-') as tmp:
            tmp_path = Path(tmp)
            archive = tmp_path / f'{sprite_id}.zip'
            try:
                status, content_type = node_download(character_id, archive)
                if status != 200 or 'zip' not in content_type:
                    failures[sprite_id] = f'download not ready (status={status}, content_type={content_type})'
                    continue
                extracted = tmp_path / 'extracted'
                with zipfile.ZipFile(archive) as zf:
                    zf.extractall(extracted)
                dest = OUTPUT_ROOT / sprite_id
                if dest.exists():
                    shutil.rmtree(dest)
                dest.mkdir(parents=True, exist_ok=True)
                rotations = copy_rotations(extracted, dest)
                icon = create_icon(dest)
                animations = materialize_animations(extracted, dest, sprite_id, default_map, overrides)
                manifest = {
                    'sprite_id': sprite_id,
                    'character_id': character_id,
                    'role': briefs.get(sprite_id, {}).get('role', 'unknown'),
                    'rotations': rotations,
                    'icon_96': icon,
                    'animations': animations,
                }
                write_manifest(dest, manifest)
                aggregate[sprite_id] = manifest
                failures.pop(sprite_id, None)
                print(f'OK {sprite_id}')
            except Exception as exc:
                failures[sprite_id] = str(exc)
                print(f'FAIL {sprite_id}: {exc}')

    specs_dir = OUTPUT_ROOT / 'specs'
    specs_dir.mkdir(parents=True, exist_ok=True)
    (specs_dir / 'generated_manifest.json').write_text(json.dumps({'characters': aggregate, 'failures': failures}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    if failures:
        print(json.dumps({'failures': failures}, ensure_ascii=False, indent=2))
        return 1
    print(json.dumps({'characters': list(aggregate)}, ensure_ascii=False, indent=2))
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
