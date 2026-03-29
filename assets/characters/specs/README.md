# PixelLab Character Asset Contract

This directory tracks the `난세영걸전` character-sprite production pipeline driven by PixelLab.

## Source-of-truth inputs

- `pixellab_character_brief.json` — per-character prompt/spec data derived from `tasks/prd-nanse-yeonggeoljeon.md`
- `pixellab_character_jobs.json` — PixelLab character IDs returned by `create_character`
- `pixellab_animation_plan.json` — local animation-state to PixelLab template mapping

## Local asset contract

Each finished sprite bundle is materialized to:

```text
assets/characters/<sprite-id>/
  base/<south|east|north|west>.png
  animations/<idle|walk|attack|hit>-<south|east|north|west>.gif
  icon/south-96.png
  manifest.json
```

## Materialization step

Use:

```bash
python3 tooling/pixellab/materialize_character_assets.py
```

The script will:

1. download the completed PixelLab export ZIP
2. copy 4-direction rotation PNGs into the local asset tree
3. convert animation frame sequences into GIFs for `idle`, `walk`, `attack`, `hit`
4. scale the `south` base frame from `48x48` to `96x96` with nearest-neighbor filtering
5. emit per-character and aggregate manifests

## Integer scaling rule

All generated battle sprites use `48x48` so the shared UI icon can be produced as an exact `2x` upscale to `96x96`, matching the PRD's integer-scaling requirement.
