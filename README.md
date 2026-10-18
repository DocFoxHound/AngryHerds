# AngryHerds

A take on Angry Birds: fling angry herd animals at the wolves' hideouts. Built with Godot 4, runs on Linux and Windows.

## Running

Open this folder in Godot 4.7+ and press F5, or from a terminal:

```
godot --path .            # or: flatpak run org.godotengine.Godot --path .
```

## Controls

- Drag the animal back from the slingshot and release to fire
- R restarts the level

## Layout

- `scenes/main.tscn` is the entry scene
- `scripts/main.gd` builds the level, HUD and win/lose logic
- `scripts/slingshot.gd`, `animal.gd`, `wolf.gd`, `block.gd`, `destructible.gd`

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
