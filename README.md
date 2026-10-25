# AngryHerds

A take on Angry Birds: fling angry herd animals at the wolves' hideouts. Built with Godot 4, runs on Linux and Windows.

## Running

Open this folder in Godot 4.7+ and press F5, or from a terminal:

```
godot --path .            # or: flatpak run org.godotengine.Godot --path .
```

## Playing

Pick a save slot on the title screen (progress saves automatically, three slots). The herd travels across ten areas of ten levels each, from Sunny Farm to the Wolf King's Castle. Each area opens with a short story, ends with a boss, and clears the clouds off the next area on the map.

- Drag the animal back from the slingshot and release to fire
- Click (or Space) mid-flight to use the animal's ability
- R restarts the level, Esc pauses
- The Herd button (on the map, or before your first shot in a level) sets your lineup, which carries over between levels
- Stuck? After losing a level twice you can skip it, and come back for its stars later

New animals join as you go:

| Level | Animal | Ability |
|---|---|---|
| 1 | Sheep | none |
| 11 | Goat | charges forward |
| 21 | Cow | slams straight down |
| 31 | Chicken | drops an exploding egg |
| 51 | Duck | splits into three |
| 71 | Pig | explodes (click, or it goes off after landing) |
| 91 | Bull | stampedes straight ahead |

For testing, `godot --path . -- --unlock-all` opens every level and animal.

## Layout

- `scenes/title.tscn` (entry), `map.tscn`, `story.tscn` and `main.tscn` (a level), each driven by the script of the same name
- `scripts/game.gd` (autoload): save slots, progress, lineup, and moving between screens
- `scripts/levels.gd` generates each level from its number: prefab structures on terrain shaped by the area
- `scripts/areas.gd`, `catalog.gd` and `story_data.gd` hold the areas, animal and wolf kinds, and the story scripts
- `scripts/art.gd` draws every animal and wolf; `background.gd`, `terrain.gd` and `pools.gd` draw the scenery
- `scripts/effects.gd` spawns splinters, poofs, explosions, splashes, score popups and screen shake
- `scripts/sfx.gd` (autoload) synthesizes all sound effects at startup, so there are no audio files

Tools for checking levels and making store media:

```
# Every level stands up on its own, and each ability fires without errors
godot --headless --fixed-fps 60 --path . --script res://tools/level_check.gd [-- first last]
# A bot plays like a fairly accurate kid and reports wins, stars and the wolves left on a loss
godot --headless --fixed-fps 60 --path . --script res://tools/autoplay.gd [-- first last tries]
# Store pictures for .slop/ (needs a window)
godot --disable-vsync --path . --script res://tools/screenshots.gd -- $PWD/.slop/screenshots
# The trailer, recorded with Godot's movie writer
godot --disable-vsync --path . --fixed-fps 30 --write-movie trailer.avi --script res://tools/trailer.gd
```

## Building

Requires the Godot 4.7.2 export templates (Editor > Manage Export Templates). Then:

```
./build.sh
```

This produces `export/linux/AngryHerds.x86_64` and `export/windows/AngryHerds.exe`. Each is a single self-contained file.

## Download

Prebuilt Linux and Windows executables are on the [Releases page](https://github.com/DocFoxHound/AngryHerds/releases).

## License

MIT, see [LICENSE](LICENSE). Built with [Godot Engine](https://godotengine.org) (also MIT).
