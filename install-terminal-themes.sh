#!/usr/bin/env bash
set -euo pipefail

# Installs Modus themes for Alacritty + iTerm2 (macOS):
#   light = Modus Operandi Tinted, dark = Modus Vivendi
# Theme source: https://github.com/miikanissi/modus-themes.nvim (extras)

log()  { printf "\n\033[1m%s\033[0m\n" "$*"; }
warn() { printf "\n\033[33m[WARN]\033[0m %s\n" "$*"; }

RAW="https://raw.githubusercontent.com/miikanissi/modus-themes.nvim/master/extras"

# -----------------------------
# Nerd Font (JetBrainsMono) — glyphs for starship / eza icons
# brew cask can hang on some setups, so install from the GitHub release.
# -----------------------------
install_nerd_font() {
  if ls "$HOME/Library/Fonts/JetBrainsMonoNerdFont"* >/dev/null 2>&1; then
    log "JetBrainsMono Nerd Font already installed."
    return
  fi
  log "Installing JetBrainsMono Nerd Font..."
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/jbm.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  unzip -oq "$tmp/jbm.zip" -d "$tmp/fonts"
  mkdir -p "$HOME/Library/Fonts"
  cp "$tmp/fonts/"*.ttf "$HOME/Library/Fonts/" 2>/dev/null || true
  rm -rf "$tmp"
}

# -----------------------------
# Alacritty
# -----------------------------
install_alacritty_themes() {
  log "Installing Alacritty Modus themes..."
  local dir="$HOME/.config/alacritty/themes"
  mkdir -p "$dir"

  curl -fsSL "$RAW/alacritty/modus_operandi_tinted.toml" -o "$dir/modus_operandi_tinted.toml"
  curl -fsSL "$RAW/alacritty/modus_vivendi.toml"         -o "$dir/modus_vivendi.toml"

  # current.toml holds the active theme (default: light). Switch with modus-light / modus-dark.
  cp "$dir/modus_operandi_tinted.toml" "$dir/current.toml"

  local cfg="$HOME/.config/alacritty/alacritty.toml"
  if [[ ! -f "$cfg" ]] || ! grep -q "themes/current.toml" "$cfg"; then
    cat > "$cfg" <<'EOF'
# Theme = whatever themes/current.toml holds. Switch: modus-light / modus-dark
[general]
import = ["~/.config/alacritty/themes/current.toml"]
live_config_reload = true

[font]
size = 13.0
normal = { family = "JetBrainsMono Nerd Font Mono", style = "Regular" }
bold   = { family = "JetBrainsMono Nerd Font Mono", style = "Bold" }
italic = { family = "JetBrainsMono Nerd Font Mono", style = "Italic" }
EOF
  fi
}

# -----------------------------
# iTerm2 (color presets imported via plist; auto light/dark is a 1-time checkbox)
# -----------------------------
install_iterm_presets() {
  log "Importing iTerm2 Modus color presets..."

  if pgrep -x iTerm2 >/dev/null 2>&1; then
    warn "iTerm2 is running - quit it first so changes are not overwritten on exit."
  fi

  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "$RAW/iterm/modus_operandi_tinted.itermcolors" -o "$tmp/operandi.itermcolors"
  curl -fsSL "$RAW/iterm/modus_vivendi.itermcolors"         -o "$tmp/vivendi.itermcolors"

  OPERANDI="$tmp/operandi.itermcolors" VIVENDI="$tmp/vivendi.itermcolors" \
  /usr/bin/python3 - <<'PY'
import plistlib, os, subprocess
DOMAIN="com.googlecode.iterm2"; EXPORT="/tmp/iterm_prefs_export.plist"
subprocess.run(["defaults","export",DOMAIN,EXPORT],check=True)
try:
    with open(EXPORT,"rb") as f: prefs=plistlib.load(f)
except Exception:
    prefs={}
if not isinstance(prefs,dict): prefs={}
ccp=prefs.get("Custom Color Presets")
if not isinstance(ccp,dict): ccp={}
for name,env in [("Modus Operandi Tinted","OPERANDI"),("Modus Vivendi","VIVENDI")]:
    with open(os.environ[env],"rb") as f: ccp[name]=plistlib.load(f)
    print("preset:",name)
prefs["Custom Color Presets"]=ccp
with open(EXPORT,"wb") as f: plistlib.dump(prefs,f)
subprocess.run(["defaults","import",DOMAIN,EXPORT],check=True)
PY

  rm -rf "$tmp"
  cat <<'EOF'

iTerm2 one-time setup for automatic light/dark switching:
  Settings -> Profiles -> Colors
    [x] Use separate colors for light and dark mode
    Color Presets... (Light) -> Modus Operandi Tinted
    Editing: Dark, Color Presets... -> Modus Vivendi
EOF
}

main() {
  install_nerd_font
  install_alacritty_themes
  install_iterm_presets
  log "Done. Alacritty: 'modus-light' / 'modus-dark' to switch (aliases from install-aliases.sh)."
}

main "$@"
