# Everdawn Life

A large, dependency-free **Godot 4** 2D world-life simulator with procedural high-resolution pixel art rendered entirely in-engine. No external art packs or plugins are required.

## A living valley
- A deterministic **240×180 tile overworld** (3,840×2,880 world pixels) with coastlines, shallows, beaches, meadows, forests, highlands, a hand-formed village, and five distant named landmarks.
- Regrowing ecology with trees, ore, crystals, herbs, berries, and mushrooms; gathering quality, respawn calendars, and persistent depletion.
- Six deep skill tracks—Farming, Foraging, Fishing, Crafting, Social, and Exploration—with 30 levels each, XP curves, titles, crop-yield bonuses, and progression feedback.
- Farming with four crops, soil fertility, weather-driven moisture, watering, multi-stage growth, skill-scaled yields, and a persistent inventory.
- Seasonal fishing tables with weather bonuses, rarity tiers, collection tracking, and legendary catches.
- Eight craftable recipes spanning food, paths, fences, artisan machines, lanterns, and an ancient compass.
- A dynamic economy with daily supply/demand movement, market prices, 13 sellable goods, prosperity, currency, and lifetime trade statistics.
- Sixteen persistent citizens with names, jobs, traits, daily schedules, needs, mood, memories, birthdays, affinity, and five relationship stages.
- Eight story quests, community renown, discovery progression, market goals, fishing, crafting, and seasonal celebration objectives.
- Eight calendar festivals across four 28-day seasons, plus weather, day/night illumination, snow/rain effects, year rollover, and contextual events.
- Health, warmth, sprint stamina, exploration records, regional title reveals, versioned JSON saves, autosave, zoom, journal, workshop, and market interfaces.

## Controls
- **WASD / arrows** — move
- **Shift** — sprint
- **Q** — cycle six tools
- **R** — cycle seed variety
- **Space** — use tool
- **E** — talk, inspect landmarks, or join festivals
- **J / Tab** — journal, quests, skills, and calendar
- **C** — crafting workshop; arrows select, Enter crafts
- **M** — dynamic market; arrows select, Enter sells
- **F5 / F9** — save/load
- **Mouse wheel** — camera zoom

## CI builds—no local Godot required
Godot 4.4.1 and export templates are installed only on GitHub-hosted runners. `.github/workflows/build.yml` performs meaningful validation in dependency order:
1. Full Godot import and strict GDScript parser validation.
2. Focused integration simulation covering world generation, resource ecology, calendar, crops, relationships, skills, crafting, economy, festivals, quests, and persistence.
3. Optimized Windows and Linux release exports.
4. Upload of playable artifacts from successful workflow runs.

Download a build from the repository's **Actions → latest successful run → Artifacts** section.

## Architecture
- `scripts/world/` deterministic terrain, regions, landmarks, ecology, and layered procedural renderer
- `scripts/simulation/` citizens, farming, fishing, crafting, skills, economy, festivals, and quests
- `scripts/core/` calendar/weather clock and versioned JSON persistence
- `scripts/entities/` player movement, tools, survival, and discovery state
- `scripts/ui/` responsive HUD, dialogue, journal, workshop, market, and region presentation
- `tests/` meaningful headless integration smoke test

All visuals use a constrained pixel-art palette, nearest-neighbor scaling, pixel snapping, layered silhouettes, animated water and weather, seasonal colors, procedural environment detail, atmospheric day/night tinting, and hand-composed architecture.
