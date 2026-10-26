# Conquest Reborn on Linux

Run [Conquest Reborn](https://conquestreborn.com) (custom WoW 3.3.5a /
Ascension-class private server) under Wine on Linux — past the world-entry
loading screen, at 60 fps with maxed-out graphics.

Verified working on: Arch/Omarchy, wine-staging 11.20, AMD Renoir iGPU
(Mesa RADV), Hyprland/Wayland. ~460-player realm.

## The problem this fixes

Out of the box on Wine the launcher, login, auth and character list all
work — then you pick a character, the loading bar fills... and nothing.
Thirty seconds later the server's packet watchdog kicks you. Every time.

Three separate issues stack into that:

1. **`DivxTac.dll` breaks the world-init stream.** The bundled DivX
   telemetry lib hooks the client's netcode. Server sends ~1 MB of world
   init then gives up; the client waits for data that never arrives and
   the watchdog fires. Rename the DLL or disable it with a Wine override
   and the stream completes.
2. **VPN/Mullvad route stalls the world server.** `46.225.96.145:8087`
   mid-stream through a relay (MTU 1380). Run the game outside the tunnel.
3. **WineD3D is slow.** DXVK (d3d9→Vulkan) is a 2-3x FPS multiplier on AMD.

## Install

1. Download the Windows client from
   [conquestreborn.com](https://conquestreborn.com) and unpack it somewhere
   (e.g. `~/Games/Conquest Reborn/`).
2. Create a 64-bit wine prefix and install whatever the launcher needs
   (.NET/mono comes with wine-staging):

   ```sh
   WINEPREFIX=~/Games/conquest-reborn/pfx wineboot
   ```

3. **Disable DivxTac** — the critical fix:

   ```sh
   cd "/path/to/Conquest Reborn"
   mv DivxTac.dll DivxTac.dll.disabled
   ```

   Keep `DivxDecoder.dll` — it's a static import; removing it kills the
   client at startup.

4. **Install DXVK** (FPS):

   ```sh
   CR_PREFIX=~/Games/conquest-reborn/pfx ./setup-dxvk.sh
   ```

5. Copy the tuned config templates into the game dir:

   ```sh
   cp Config.wtf "/path/to/Conquest Reborn/WTF/Config.wtf"
   cp dxvk.conf  "/path/to/Conquest Reborn/dxvk.conf"
   ```

6. Put the launch script on your PATH and edit the three paths at the top:

   ```sh
   install -Dm755 conquest-reborn ~/.local/bin/conquest-reborn
   install -Dm644 conquest-reborn.desktop ~/.local/share/applications/
   ```

7. Launch. You must start the game via the launcher's **PLAY** button —
   it injects a session ticket onto `Ascension.exe`'s command line.
   Launching `Ascension.exe` directly gets "Unable to connect".

## What the launch script sets

| Var | Why |
|---|---|
| `WINEDLLOVERRIDES=divxtac=d` | Disable the netcode-breaking DLL (belt to the rename's braces) |
| `d3d9=n;dxgi=n` | Route rendering through DXVK instead of WineD3D |
| `WINEESYNC=1` | Cheaper sync primitives (staging) |
| `mullvad-exclude` | Keep game traffic off the VPN — delete if not on Mullvad |

## Tuning notes

`Config.wtf` is tuned for a locked 60 fps at 1920x1080 on an iGPU:
everything maxed except `extShadowQuality 1` — shadows are the single
biggest FPS cost in 3.3.5a and "1" still looks good. If you have a real
GPU, take it to 5. If you're dipping below 60 in raids, drop it to 0 and
halve `particleDensity`.

`DXVK_HUD=fps` in the launcher env shows a frame counter while tuning.

## Debugging

- Hang at the loading bar again? Check `DivxTac.dll` isn't back (game
  updates restore it — the `divxtac=d` override covers this).
- `Logs/connection.log` in the game dir shows every opcode; a successful
  world entry ends `COP_LOGIN_CHARACTER code=77 result=TRUE`.
- `Logs/Error.txt` ends with `Packet watchdog timed out` when it fails.

## Contributing

Tested on one machine. If it works (or doesn't) on yours — distro, GPU,
Wine version — open an issue with the details.

## Licence

MIT. The game client, launcher and all Conquest Reborn assets belong to
their owners; this repo is only the Linux glue around them.
