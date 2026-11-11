#!/usr/bin/env bash
# Install the Hearth kitty setup: config, theme, font and sharpness rule.
# Safe to re-run: existing files that differ are backed up first.
#
# Usage: ./install.sh [options]
#   --install-kitty   Install/upgrade kitty with the official installer if it
#                     is missing or older than 0.36 (downloads from
#                     sw.kovidgoyal.net)
#   --link            Symlink config files to this repo instead of copying
#                     (edits in the repo then apply directly)
#   --no-hinting      Skip the fontconfig full-hinting rule (recommended on
#                     HiDPI screens, see README)
#   --no-fonts        Do not install JetBrains Mono
#   --no-reload       Do not reload running kitty instances
#   --dry-run         Show what would be done without changing anything
#   -h, --help        Show this help

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KITTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
FC_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/conf.d"
FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
STAMP="$(date +%Y%m%d-%H%M%S)"
MIN_KITTY="0.36.0"          # notify_on_cmd_finish needs 0.36+
FONT_SIZE_PT="14.25"
JBM_VERSION="2.304"

INSTALL_KITTY=0 LINK=0 HINTING=1 FONTS=1 RELOAD=1 DRY=0

# --- helpers --------------------------------------------------------------
info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ok\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
run()  { if ((DRY)); then printf '   [dry-run] %s\n' "$*"; else "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

# version_ge A B: true if version A >= B
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }

for arg in "$@"; do
  case "$arg" in
    --install-kitty) INSTALL_KITTY=1 ;;
    --link)          LINK=1 ;;
    --no-hinting)    HINTING=0 ;;
    --no-fonts)      FONTS=0 ;;
    --no-reload)     RELOAD=0 ;;
    --dry-run)       DRY=1 ;;
    -h|--help)       usage ;;
    *)               die "unknown option: $arg (see --help)" ;;
  esac
done

[ "$(uname -s)" = "Linux" ] || warn "Written for Linux; on other systems only the kitty config part applies."

# Install one file: back up a differing existing file, then copy or symlink.
place() {
  local src="$1" dest="$2"
  run mkdir -p "$(dirname "$dest")"
  if ((LINK)) && [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    ok "$dest (already linked)"; return
  fi
  if ! ((LINK)) && [ -f "$dest" ] && [ ! -L "$dest" ] && cmp -s "$src" "$dest"; then
    ok "$dest (already up to date)"; return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    run mv "$dest" "$dest.bak-$STAMP"
    warn "backed up existing $(basename "$dest") to $dest.bak-$STAMP"
  fi
  if ((LINK)); then run ln -s "$src" "$dest"; else run cp "$src" "$dest"; fi
  ok "$dest"
}

# --- 1. kitty ----------------------------------------------------------------
find_kitty() {
  if [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then echo "$HOME/.local/kitty.app/bin/kitty"
  elif have kitty; then command -v kitty
  fi
}

install_kitty() {
  have curl || die "curl is needed to install kitty"
  info "Installing kitty with the official installer"
  if ((DRY)); then
    printf '   [dry-run] curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n\n'
  else
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
  fi
  # Desktop integration, as recommended by the kitty docs
  run mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
  run ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/"
  for d in kitty.desktop kitty-open.desktop; do
    if ((DRY)) || [ -f "$HOME/.local/kitty.app/share/applications/$d" ]; then
      run cp "$HOME/.local/kitty.app/share/applications/$d" "$HOME/.local/share/applications/"
      run sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g; s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|g" \
        "$HOME/.local/share/applications/$d"
    fi
  done
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) warn "Add ~/.local/bin to your PATH to run kitty from a shell." ;; esac
}

info "Checking kitty"
KITTY="$(find_kitty || true)"
KVER=""
[ -n "$KITTY" ] && KVER="$("$KITTY" --version 2>/dev/null | awk '{print $2}')"
if [ -z "$KITTY" ] || ! version_ge "${KVER:-0}" "$MIN_KITTY"; then
  if ((INSTALL_KITTY)); then
    install_kitty
    KITTY="$HOME/.local/kitty.app/bin/kitty"
    ((DRY)) || KVER="$("$KITTY" --version | awk '{print $2}')"
  elif [ -z "$KITTY" ]; then
    die "kitty not found. Re-run with --install-kitty, or install it first."
  else
    warn "kitty $KVER is older than $MIN_KITTY: 'notify_on_cmd_finish' will be reported as unknown and ignored."
    warn "Re-run with --install-kitty to get the current version from the official installer."
  fi
fi
[ -n "$KVER" ] && ok "kitty $KVER at $KITTY"

# --- 2. font -------------------------------------------------------------------
# (grep on captured output: with pipefail, 'fc-list | grep -q' can fail on SIGPIPE)
font_present() { grep -qi 'JetBrains Mono' <<<"$(fc-list : family 2>/dev/null)"; }

install_font_download() {
  have curl && have unzip || die "curl and unzip are needed to download JetBrains Mono"
  local tmp; tmp="$(mktemp -d)"
  local url="https://github.com/JetBrains/JetBrainsMono/releases/download/v$JBM_VERSION/JetBrainsMono-$JBM_VERSION.zip"
  info "Downloading JetBrains Mono $JBM_VERSION into $FONT_DIR/JetBrainsMono"
  run curl -fsSL -o "$tmp/jbm.zip" "$url"
  run unzip -q -o "$tmp/jbm.zip" 'fonts/ttf/*' -d "$tmp"
  run mkdir -p "$FONT_DIR/JetBrainsMono"
  if ((DRY)); then printf '   [dry-run] cp %s/fonts/ttf/*.ttf %s/JetBrainsMono/\n' "$tmp" "$FONT_DIR"
  else cp "$tmp"/fonts/ttf/*.ttf "$FONT_DIR/JetBrainsMono/"; fi
  rm -rf "$tmp"
}

if ((FONTS)); then
  info "Checking font: JetBrains Mono"
  have fc-list || die "fontconfig (fc-list) is required"
  if font_present; then
    ok "JetBrains Mono already installed"
  elif have apt-get; then
    run sudo apt-get install -y fonts-jetbrains-mono
  elif have dnf; then
    run sudo dnf install -y jetbrains-mono-fonts-all
  elif have pacman; then
    run sudo pacman -S --needed --noconfirm ttf-jetbrains-mono
  else
    install_font_download
  fi
  if ! ((DRY)) && ! font_present; then
    warn "Package install did not provide JetBrains Mono; downloading it instead."
    install_font_download
  fi
fi

# --- 3. config files -------------------------------------------------------------
info "Installing kitty config into $KITTY_DIR"
place "$REPO_DIR/kitty/kitty.conf"        "$KITTY_DIR/kitty.conf"
place "$REPO_DIR/kitty/hearth-theme.conf" "$KITTY_DIR/hearth-theme.conf"

if ((HINTING)); then
  info "Installing fontconfig sharpness rule"
  place "$REPO_DIR/fontconfig/90-crisp-mono.conf" "$FC_DIR/90-crisp-mono.conf"
else
  info "Skipping fontconfig hinting rule (--no-hinting)"
fi
if have fc-cache; then run fc-cache -f >/dev/null 2>&1 || true; fi

# --- 4. verify -----------------------------------------------------------------------
if ! ((DRY)) && [ -n "${KITTY:-}" ] && [ -x "$KITTY" ]; then
  info "Verifying with kitty"
  out="$("$KITTY" +runpy "
from kitty.config import load_config
o = load_config('$KITTY_DIR/kitty.conf')
print('font', o.font_family.created_from_string if hasattr(o.font_family, 'created_from_string') else o.font_family)
print('size', o.font_size)
" 2>&1 || true)"
  printf '%s\n' "$out" | sed 's/^/   /'
  if grep -qiE 'error|unknown|invalid|traceback' <<<"$out"; then
    warn "kitty reported problems with the config (see above)."
  else
    ok "config loads without errors"
  fi
  if ((FONTS)) && font_present; then
    fullnames="$(fc-list : fullname 2>/dev/null)"
    for face in Regular SemiBold Italic "SemiBold Italic"; do
      if grep -qi "JetBrains Mono $face" <<<"$fullnames"; then ok "font face: JetBrains Mono $face"
      else warn "font face missing: JetBrains Mono $face (kitty will fall back)"; fi
    done
  fi
fi

# --- 5. screen check: whole-pixel font sizes ---------------------------------------------
info "Screen check"
dpi=""
if [ -n "${DISPLAY:-}" ] && have xrdb; then dpi="$(xrdb -query 2>/dev/null | awk '/^Xft.dpi:/{print $2}')"; fi
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
  warn "Wayland session: sizes depend on your display scaling; judge sharpness by eye."
fi
dpi="${dpi:-96}"
LC_ALL=C awk -v pt="$FONT_SIZE_PT" -v dpi="$dpi" 'BEGIN {
  px = pt * dpi / 72
  printf "   DPI %s: %spt = %.2fpx", dpi, pt, px
  if (px == int(px)) print " (whole pixels, good)"; else print " (not whole pixels)"
  printf "   Sharp sizes at this DPI:"
  for (p = 16; p <= 22; p++) printf " %.4gpt=%dpx", p * 72 / dpi, p
  print ""
}'
if awk -v d="$dpi" 'BEGIN{exit !(d > 120)}'; then
  warn "High DPI ($dpi): full hinting may slightly distort letter shapes; consider --no-hinting."
fi

# --- 6. reload ----------------------------------------------------------------------------
if ((RELOAD)) && pgrep -x kitty >/dev/null 2>&1; then
  info "Reloading running kitty instances"
  run pkill -USR1 -x kitty || true
  ok "reloaded (fully restart kitty to apply the fontconfig rule)"
fi

info "Done. See README.md for things to check and tune."
