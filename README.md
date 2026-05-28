
# SilentPillHUD v1.0.5 — Final Source Package

This is the upgraded source package for the iOS 12 Silent/Ringer HUD tweak.

## Changes included
- Replaces the old yellow 3D bell design with custom 2D bell PNGs.
- Silent ON uses `bell_silent_red.png`.
- Silent OFF uses `bell_normal_gray.png`.
- HUD text is now:
  - `Silent Mode`
  - `On` / `Off`
- Dark pill HUD background for dark-mode visibility.
- Grey status text for `On` / `Off`.
- Icons are included in both:
  - `Resources/`
  - `layout/Library/Application Support/SilentPillHUD/`

## Important
This ZIP is Windows-friendly and does NOT require Ubuntu, WSL, or any Linux distro for repo metadata generation.

However, compiling an iOS jailbreak tweak still requires a Theos-compatible iOS build environment with an iPhoneOS SDK. Windows PowerShell alone cannot compile Logos/Objective-C iOS tweaks into a new `.dylib`.

## Files
- `Tweak.xm` — final source code with custom HUD/icon logic.
- `Makefile` — Theos build file.
- `control` — Debian package metadata.
- `Resources/` — icon PNGs for bundle/resource packaging.
- `layout/` — icon PNGs installed to `/Library/Application Support/SilentPillHUD/`.
- `repo/` — place your final built `.deb` here.
- `windows_make_repo.py` — Windows Python script to generate `Packages`, `Packages.bz2`, and `Release` after you have a final `.deb`.

## Windows repo generation after you have the final .deb
1. Put the final `.deb` inside the `repo` folder.
2. Open PowerShell inside this folder.
3. Run:

```powershell
py windows_make_repo.py
```

This creates/updates:
- `repo/Packages`
- `repo/Packages.bz2`
- `repo/Release`

Then upload the contents of `repo/` to GitHub Pages.
