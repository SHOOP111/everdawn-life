# Everdawn Life

A complete, dependency-free **Godot 4** 2D world-life simulator with procedural high-resolution pixel art rendered entirely in-engine. No external art or plugins are required.

## Play
- **WASD / arrows** — move
- **Shift** — sprint (uses stamina)
- **Q** — cycle tools
- **Space** — use Hoe, Seeds, Watering Can, or Hands
- **E** — talk/interact
- **J / Tab** — journal
- **F5 / F9** — save/load
- **Mouse wheel** — camera zoom

The simulation includes 16 persistent citizens with schedules, jobs, needs, memories, affinity, and contextual dialogue; four seasons; weather; a day/night cycle; procedural biomes; crop growth based on moisture and fertility; quests; save/load; and deterministic world generation.

## Run and build
Requires Godot 4.4+:

```bash
godot --path .
godot --headless --path . --import
godot --headless --path . --export-release "Windows Desktop" artifacts/builds/EverdawnLife.exe
```

The repository's GitHub Actions workflow performs only meaningful checks: Godot import/parser validation, a focused simulation integration test, then Windows and Linux release exports. Godot and its export templates are installed only on GitHub-hosted runners; no local Godot install is required. Download playable builds from a successful workflow run's **Artifacts** section.

## Architecture
- `scripts/world/` deterministic world generation and procedural renderer
- `scripts/simulation/` citizens, farming, quests
- `scripts/core/` clock and versioned JSON persistence
- `scripts/ui/` responsive HUD and journal
- `tests/` headless integration smoke test

All visuals use a deliberately constrained 32-color-inspired palette, nearest-neighbor scaling, pixel snapping, layered silhouettes, animated weather, seasonal colors, and procedural environmental detail.
