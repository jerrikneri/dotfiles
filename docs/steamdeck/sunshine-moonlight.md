# Steam Deck — Sunshine (Flatpak) → Moonlight (macOS)

Fix for the invisible mouse cursor when streaming the Deck's Desktop Mode to Moonlight.
Diagnosed and applied 2026-09-07. The working reference is nixos-game
(`nix/modules/common/sunshine.nix`), whose identical-purpose setup streams with a
visible cursor — the difference turned out to be Flatpak sandboxing, not KDE.

## Environment

| Component | Version |
|---|---|
| SteamOS Desktop Mode | KDE Plasma / KWin 6.4.3, PipeWire 1.6.4, xdg-desktop-portal-kde 6.4.3 |
| Sunshine | Flatpak `dev.lizardbyte.app.Sunshine` v2026.906.222525 |
| Client | Moonlight on macOS |
| Reference host | nixos-game — native Sunshine v2026.516 (nixpkgs), Plasma 6 Wayland |

Deck paths referenced below (SSH alias: `deck`):

- Flatpak appdata: `~/.var/app/dev.lizardbyte.app.Sunshine/config/sunshine/` (`sunshine.conf`, `sunshine.log`, `portal_token`)
- Sandbox-visible appdata (KWin never reads this): `~/.var/app/dev.lizardbyte.app.Sunshine/data/applications/`

## Symptom

Stream works, desktop visible, input lands — but no mouse cursor in the video.
The NixOS host shows the cursor fine, ruling out the Moonlight client.

## Root cause

Chain of fallbacks, each losing the cursor:

1. **Flatpak sandbox has no file capabilities.** `CAP_SYS_ADMIN` is required for KMS
   capture (log: `Couldn't get handle for DRM Framebuffer [...] Probably not permitted`,
   `AppImage and Flatpak do not support KMS capture`). `CAP_SYS_NICE` failures
   (`setpriority failed for nice -15`, `EGL: context priority ... CAP_SYS_NICE missing`)
   are cosmetic fallouts of the same restriction.
2. **KWin Screencast backend is blocked by KWin's permission check.** This backend
   (`zkde_screencast_unstable_v1`, requests `POINTER_EMBEDDED` — cursor baked into the
   stream) is Sunshine's best option on Plasma and is what the NixOS host uses. KWin only
   exposes the interface to binaries listed in a `.desktop` file with
   `X-KDE-Wayland-Interfaces=zkde_screencast_unstable_v1` whose `Exec=` matches the
   client's real binary path. Sunshine auto-creates that file **inside the sandbox**
   (`~/.var/app/.../data/applications/`), where KWin never scans. Even copied to the real
   `~/.local/share/applications/` with `Exec=/app/bin/sunshine`, KWin refuses —
   `/app/bin/sunshine` doesn't resolve on the host filesystem (verified after a fresh
   KWin start: `zkde_screencast_unstable_v1 not found in registry`).
3. **Fallback = XDG Portal capture, and it arrives cursor-less.** Sunshine requests
   `cursor_mode=EMBEDDED` (`portalgrab.cpp`), but on this Plasma stack the stream comes
   through without the cursor, and Sunshine cannot draw one client-side — its PipeWire
   capture path ignores cursor metadata entirely (`pipewire.cpp`: `// FIXME: show_cursor
   is ignored`).
4. **Why NixOS works:** native Sunshine runs from a real path (`/run/wrappers/bin/sunshine`,
   a `cap_sys_admin` wrapper), so Sunshine's auto-created permission `.desktop` in the
   real `~/.local/share/applications/` matches, KWin grants the interface, and the
   KWin Screencast backend runs with the embedded cursor.

Capture-method cheat sheet for the "Force a Specific Capture Method" dropdown on this
machine: NvFBC (NVIDIA-only) and KMS (needs `CAP_SYS_ADMIN`) are impossible in the
sandbox; wlroots requires a wlroots compositor, not KWin; X11 only sees Xwayland's root
window; the viable options are **KWin Screencast** (best, direct protocol) and
**XDG Portal** (sandbox-safe fallback).

## Fix applied

1. `~/.config/environment.d/90-kwin-screencast.conf` (applies to the systemd user
   session, inherited by KWin, read at login):

   ```ini
   KWIN_WAYLAND_NO_PERMISSION_CHECKS=1
   KWIN_FORCE_SW_CURSOR=1
   ```

   - `KWIN_WAYLAND_NO_PERMISSION_CHECKS=1` — disables KWin's Wayland interface
     permission gate so the sandboxed Sunshine can bind `zkde_screencast_unstable_v1`.
     Security tradeoff: any local app could screencast without consent. Acceptable on a
     single-user Deck.
   - `KWIN_FORCE_SW_CURSOR=1` — belt-and-braces: KWin renders a software cursor into the
     composited frame, so any capture backend (portal included) would see it even if the
     screencast path regressed.

2. `~/.var/app/dev.lizardbyte.app.Sunshine/config/sunshine/sunshine.conf`:

   ```ini
   capture = kwin
   ```

3. Reboot → Desktop Mode → start Sunshine (it does not autostart).

Verified in logs at 2026-09-07 19:45: `[kwingrab] Screencasting output name eDP-1` +
`[kwingrab] Pipewire stream created: node=96`, no more `not found in registry`.

## Verification

```bash
# KWin screencast engaged (expect "Pipewire stream created", no "not found in registry")
ssh deck 'grep -a kwingrab ~/.var/app/dev.lizardbyte.app.Sunshine/config/sunshine/sunshine.log | tail'

# Current capture setting
ssh deck 'cat ~/.var/app/dev.lizardbyte.app.Sunshine/config/sunshine/sunshine.conf'
```

## Rollback

```bash
ssh deck 'rm ~/.config/environment.d/90-kwin-screencast.conf'
ssh deck 'printf "capture = portal\n" > ~/.var/app/dev.lizardbyte.app.Sunshine/config/sunshine/sunshine.conf'
ssh deck 'rm ~/.local/share/applications/dev.lizardbyte.app.Sunshine.kwin*.desktop'  # inert leftover, optional
ssh deck 'flatpak kill dev.lizardbyte.app.Sunshine'  # then relaunch; log out/in for env rollback
```

## Gotchas learned the hard way

- **Never `systemctl --user restart plasma-kwin_wayland.service` on SteamOS.** It kills
  the entire desktop session (plasmashell dies, the Wayland socket vanishes). sddm then
  auto-logins into **Game Mode** (SteamOS default). Recovery: Steam menu → Power →
  Switch to Desktop, or `steamos-session-select plasma` — which may need a retry (races
  with `ibus-gamescope.service` while Game Mode is still booting) and plain `sudo`
  requires a password, so the on-device menu is the reliable route.
- **Duplicate Sunshine instances** can run simultaneously (`flatpak ps | grep -i sun`).
  Two were fighting during debugging. Clean up with
  `flatpak kill dev.lizardbyte.app.Sunshine`, then start one.
- **Web UI saves rewrite `sunshine.conf`** — a manual `capture = kwin` was reverted to
   `portal` by a later UI save. Re-check the file after touching the UI.
- `[portalgrab] Falling back to position 0x0 for stream with resolution 1280x800` is
  benign — single-panel fallback for the portal's missing `position` property.
- Starting Sunshine outside the session (SSH/systemd) needs
  `WAYLAND_DISPLAY=wayland-0` in the environment, e.g.
  `systemd-run --user --setenv=WAYLAND_DISPLAY=wayland-0 flatpak run dev.lizardbyte.app.Sunshine`.

## Known open issue — Vulkan encoder emits malformed HEVC

The Deck's Flatpak prefers the Vulkan video encoder (`Found HEVC encoder: hevc_vulkan`),
and RADV's HEVC encode on the Deck APU produces a corrupt bitstream. FFmpeg's bitstream
parser rejects it (Sunshine runs packets through a CBS-style parse to rewrite VPS/SPS):

```
alignment_bit_equal_to zero out of range: 1, but must be in [0,0]
Failed to reset unit 4 (type 19): Invalid data found when processing input
Couldn't read packet: Invalid data found when processing input
```

(`type 19` = HEVC IDR slice; Moonlight masks this by requesting keyframes.) If it
becomes a problem, force `encoder = vaapi` in `sunshine.conf` — the same knob as
`dotfiles.sunshine.encoder` on the NixOS host. Deliberately left on Vulkan for now.
