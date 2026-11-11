# kitty-config: Hearth

A kitty terminal setup tuned for **long, comfortable reading**: a warm, low-glare
dark theme (*Hearth*), JetBrains Mono at a pixel-exact size, generous line
spacing, and settings that keep the screen calm.

## Goals

1. **Easy on the eyes:** no glare, no harsh contrast.
2. **Low fatigue:** comfortable after hours, not just at first glance.
3. **Optimised for reading:** prose, terminal output, logs and code.
4. **Pleasant flow:** the eye moves through text without effort or distraction.
5. **Crisp text:** sharp rendering, especially on low-resolution (96 DPI) screens,
   because blurry text is tiring no matter how good the colours are.

## Contents

| Path | Installed to | Purpose |
|---|---|---|
| `kitty/kitty.conf` | `~/.config/kitty/kitty.conf` | Font, size, spacing, cursor, bell, tabs, zoom keys |
| `kitty/hearth-theme.conf` | `~/.config/kitty/hearth-theme.conf` | The Hearth colour theme |
| `fontconfig/90-crisp-mono.conf` | `~/.config/fontconfig/conf.d/` | Full hinting for JetBrains Mono / IBM Plex Mono (sharpness on low DPI) |
| `extras/prompt-separator.bash` | *not installed* | Optional full-width bash prompt separator (see below) |
| `install.sh` | | Installer |

## Requirements

- Linux (X11 or Wayland). The kitty config also works on macOS, but the
  installer and the fontconfig rule are Linux-specific.
- **kitty 0.36 or newer** (tested on 0.50.0). Older versions work, but
  `notify_on_cmd_finish` is ignored. Many distributions ship an older kitty;
  for example, Ubuntu 24.04's package is 0.32.2.
- `fontconfig`, plus `sudo` for the font package, or `curl` and `unzip` for the download fallback.

## Install

```sh
git clone <this repo> ~/Projects/kitty-config
cd ~/Projects/kitty-config
./install.sh --dry-run      # preview, changes nothing
./install.sh                # install
```

On a machine without a recent kitty:

```sh
./install.sh --install-kitty
```

### Options

| Option | Effect |
|---|---|
| `--install-kitty` | Installs or upgrades kitty with the [official installer](https://sw.kovidgoyal.net/kitty/binary/) into `~/.local/kitty.app` if it is missing or older than 0.36, and adds the launcher and desktop entries |
| `--link` | Symlinks the config files to this repo instead of copying them, so edits in the repo apply directly (after a kitty reload) |
| `--no-hinting` | Skips the fontconfig rule. Recommended on HiDPI screens |
| `--no-fonts` | Doesn't install JetBrains Mono |
| `--no-reload` | Doesn't reload running kitty instances |
| `--dry-run` | Shows every action without performing it |

### What the installer does

1. **kitty:** finds kitty (preferring `~/.local/kitty.app`), checks the version, and installs it if asked.
2. **Font:** installs JetBrains Mono with `apt`, `dnf` or `pacman`. Without
   those, it downloads v2.304 from GitHub into `~/.local/share/fonts`.
3. **Config:** copies (or links) the files into place. **Any existing file that differs is
   backed up** as `<name>.bak-<timestamp>` first. Re-running is safe.
4. **Sharpness rule:** installs the fontconfig rule and refreshes the font cache.
5. **Verification:** loads the config with kitty to catch errors, and checks that all four font
   faces (Regular, SemiBold, Italic, SemiBold Italic) exist.
6. **Screen check:** reports your DPI, whether 14.25pt lands on whole pixels, and the
   sharp sizes for your screen.
7. **Reload:** reloads running kitty windows. **Fully restart kitty** afterwards so the
   fontconfig rule takes effect.

## After installing: things to check

- **Font really in use:** italics should look like JetBrains Mono's italic and
  `0` should be dotted. If kitty falls back to another font, run
  `kitty +list-fonts` and compare the face names with `kitty/kitty.conf`.
- **Font size vs. DPI:** text is sharpest when the pixel size is a whole number.
  `px = pt × DPI ÷ 72`. At 96 DPI, steps of **0.75pt = 1px**: 13.5 (18px),
  **14.25 (19px, default)**, 15 (20px). The installer prints the sharp sizes for
  the machine's DPI; set `font_size` to one of them if your DPI isn't 96.
- **HiDPI screens:** full hinting forces letters onto the pixel grid, which helps on
  ~96–120 DPI screens but slightly distorts shapes on sharp ones. Install with
  `--no-hinting`, or delete `~/.config/fontconfig/conf.d/90-crisp-mono.conf`.
- **Wayland:** sizes depend on display scaling, so judge sharpness by eye.
- **Notifications:** need kitty's shell integration (on by default) and a desktop
  notification service. Test: run `sleep 35`, switch to another tab, and wait.
- **Monitor settings matter as much as the theme:** lower the brightness until a white
  page looks like paper, and pick a *Warm* or 6500K colour mode so Hearth's warm tones
  don't look grey.
- **External monitors on X11:** kitty uses one DPI for every screen. Press `Ctrl+=` once
  (15pt / 20px) if text feels small at monitor distance; `Ctrl+0` resets.

## Daily use

| Keys | Action |
|---|---|
| `Ctrl+=` / `Ctrl+-` | Zoom by 0.75pt (exactly 1px at 96 DPI, so it stays sharp) |
| `Ctrl+0` | Reset to 14.25pt |
| `Ctrl+Shift+F5` | Reload config |

**Bell:** silent. No sound, flash or taskbar alert. A 🔔 appears on a background
tab that rang, and a split pane that rang gets a wheat border. A **desktop notification**
appears when a command that ran for 30s or more finishes in a window you can't see.

## Design notes

### Hearth palette

Contrast against the background `#1D1B18`:

| Role | Colour | Contrast |
|---|---|---|
| Text | `#E3DBCD` | 12.5:1, crisp without the harshness of white on black (15–21:1) |
| Dim text (`color8`) | `#A0978A` | ~6:1 |
| Accents | terracotta `#D98C7E`, sage `#A8BB84`, wheat `#D9B776`, dusk `#8FADD0`, heather `#C49DC0`, sea glass `#8EC1B4` | 6.5–9:1 |
| Selection | `#EDE6DA` on `#3D4650` | 7.7:1 |
| ANSI black (`color0`) | `#3A3631` | 1.43:1 (see Known limitations) |

### Why these choices

- **Warm charcoal, not black:** light text on pure black tends to "glow" (halation).
- **JetBrains Mono:** chosen after a side-by-side comparison with DejaVu Sans Mono
  (tiring over long reading), Ubuntu Sans Mono (a bit loose) and IBM Plex Mono
  (beautiful but soft on a 96 DPI screen, even in its Text weight). It has a tall
  x-height and clearly distinct look-alikes (`0/O`, `1/l/I`, `rn/m`).
- **SemiBold for bold:** full Bold clumps at low resolution.
- **120% line height:** the biggest single win for reading flow.
- **Ligatures off:** `->` and `!=` stay as typed.
- **Default text composition:** making strokes heavier smeared edges at 96 DPI.
- **Inactive panes not faded:** faded text looked blurry.
- **Slim padding (6px / 10px):** keeps text off the edges without wasting space on a
  1280px-wide screen.
- **Steady block cursor, silent bell:** nothing pulls the eye off the text. The block
  stays at the shell prompt too (`shell_integration enabled no-cursor`).

## Optional: full-width prompt separator

`extras/prompt-separator.bash` keeps a dashed separator line exactly as wide as the
terminal, and rebuilds it before every prompt, so it follows resizes and zoom from the
next prompt on. Source it from `~/.bashrc` and use `\${separator}` in `PS1` (the
backslash makes bash expand it at each prompt):

```sh
. ~/Projects/kitty-config/extras/prompt-separator.bash
PS1="\${separator}\n\u@\h:\W\n\\$ "
```

Lines already on screen are re-wrapped by kitty when you zoom, and that cannot be
avoided. Press Enter for a fresh, correct line.

## Restore / uninstall

- The installer's backups sit next to each file: `~/.config/kitty/*.bak-<timestamp>`.
  Move one back to restore it.
- Remove the sharpness rule with `rm ~/.config/fontconfig/conf.d/90-crisp-mono.conf && fc-cache -f`.

## Known limitations

- **ANSI black text (`color0`) is nearly invisible** on the background (1.43:1). This only
  matters when a program prints black text on the default background, which is rare.
  Selecting the text reveals it. See *Future work* for the fix.
- **`font_family` uses the legacy name form** (`JetBrains Mono Regular`). kitty 0.50 fully
  supports it, but the new `family="…"` syntax is the documented way.
- **Comments in `kitty.conf`** describe the original machine (1280×800, 96 DPI).
- **The fontconfig rule also applies outside kitty**, to any app using those fonts.
- `wayland_titlebar_color` / `macos_titlebar_color` have no effect on X11.

## Future work

- **Minimum contrast:** `text_fg_override_threshold 3 ratio` (kitty 0.36+) would fix
  near-invisible ANSI black while keeping faint text faint. It was considered and
  deliberately left out. Avoid `4.5 ratio`, which flattens intentionally dim text.
- **Per-monitor size toggle:** a key that switches between 14.25pt (laptop) and 15pt
  (external monitor), or a launcher for each.
- **External monitor script:** `~/.screenlayout/1440p.sh` doesn't position the
  monitor (`--right-of`/`--left-of`), so a freshly enabled output overlaps the laptop
  screen at `+0+0`. It also fails noisily when re-run (`--newmode` already exists).
- **Scrollbar styling (kitty 0.43+):** tune `scrollbar_handle_color`/opacity to the
  palette, or disable it.
- **Light variant:** a "Hearth Day" theme for bright rooms.
- **HiDPI profile:** auto-detect DPI in the installer, pick a sharp `font_size`, and
  skip hinting on HiDPI screens.
- **Modern font syntax:** move to `font_family family="JetBrains Mono"` once older
  kitty versions no longer matter.
- **CI check:** lint `install.sh` with shellcheck, and load the config with the latest
  kitty in CI.
