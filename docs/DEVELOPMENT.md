# Development notes

## Code layout

| File | Responsibility |
| --- | --- |
| `scripts/game.gd` | Level layout, projectile sweeps, checkpoint, exit, camera, world rendering |
| `scripts/player.gd` | CharacterBody2D movement, jump timing, dash, damage, aiming |
| `scripts/controls.gd` | Keyboard and gamepad bindings; input and render timing setup |
| `scripts/art.gd` | Original pixel matrices, palette, simple player animation |
| `scripts/pixels.gd` | Remaining sprite cells, pixel collision, chipping and shattering |
| `scripts/enemy.gd` | Ground patrols, hovering enemies, enemy projectiles, damage |
| `scripts/breakable.gd` | Crates and the reactor; partial and complete destruction |
| `scripts/debris.gd` | Batched cosmetic fragments and sleeping / lifetime behavior |
| `scripts/hud.gd` | Health, dash readiness, pause, checkpoint messages, completion |
| `scripts/pixel_font.gd` | Original 5×7 bitmap alphabet |
| `scripts/sound.gd` | Cached procedural sound effects and a 12-voice pool |

## Feel tuning

Movement constants live in `player.gd`. Run speed is 185 logical pixels/s, jump speed 390, rising gravity 1250, falling gravity 1650, dash speed 380 for 130 ms, and dash cooldown 480 ms. Horizontal acceleration reaches full speed in roughly 75 ms. Release braking is faster. Press and release events are retained until the next physics update, including very short taps.

The 120 Hz physics step bounds the engine-side wait for an input edge to roughly 8.3 ms; it does not measure total display or device latency. Rendering is capped at 240 FPS and V-sync is off. Enable V-sync in Project Settings if screen tearing is undesirable on the target machine. Pixel snapping affects rendering, while physics keeps subpixel positions.

Damage feedback never pauses or globally slows the simulation. Stagger affects the enemy. Camera shake is small and brief, with no dependence between camera smoothing and input response. Changing physics tick rate should be followed by both integration suites and a physical play test.

## Destruction and performance

Sprite cells are authored as character matrices and map to two logical pixels each. A hit sorts remaining cells by distance to the impact, detaches a small number, and emits their original colors and positions. Enemy facing is included in both collision and detachment. Projectile sweeps check the earliest terrain or remaining-cell hit rather than only the destination position.

Enemies have 3–4 HP, crates 5 HP, and the reactor 12 HP. Small per-hit chip counts keep sustained horizontal fire able to finish targets before it drills a completely empty tunnel. The final hit shatters every remaining cell. Changing chip counts requires checking this property again.

The prototype uses coarse character / crate movement colliders and precise sprite-cell projectile collision. Missing cells do not change a character's movement collider. Fragments collide with platform and ground top surfaces; they do not collide with one another, enemies, or crate walls. This keeps debris cosmetic and movement predictable. A fully granular terrain / fragment simulation would be a separate feature.

Fragments are kept in one capped array and drawn by one node. Gravity and collision run only for active fragments. At rest they retain their position until they fade. Target broad-phase checks skip objects more than 100 pixels from the projectile segment's start, which comfortably exceeds one tick's travel at the supported speeds.

## Validation recorded for this prototype

- Godot 4.6.1 parsed and ran the project.
- All 28 gameplay integration checks passed.
- The scripted walkthrough cleared the full level with ordinary input, 4 health remaining, 7 enemies defeated, and 8 crates destroyed in about 14 seconds of simulation.
- Native OpenGL rendering was inspected at the opening, combat, reactor, and completion views on Linux using a virtual display.
- Linux, Windows x64, and universal macOS export presets are included. Only Linux runtime execution was available here; target OS and physical controller testing remain necessary.

The source screenshots are captured by Godot itself. They are documentation assets and excluded from desktop exports along with test scripts.
