#!/usr/bin/env bash
set -euo pipefail

log()  { printf "\n\033[1m%s\033[0m\n" "$*"; }
warn() { printf "\n\033[33m[WARN]\033[0m %s\n" "$*"; }

RAW="https://raw.githubusercontent.com/semanticparadox/configs/main"

# -----------------------------
# 1) Install toolbox command (separate file in this repo; supports usage counter)
# -----------------------------
install_toolbox() {
  log "Installing toolbox command..."
  mkdir -p "$HOME/.local/bin" "$HOME/.local/state/toolbox"

  if curl -fsSL "$RAW/toolbox" -o "$HOME/.local/bin/toolbox.tmp"; then
    mv "$HOME/.local/bin/toolbox.tmp" "$HOME/.local/bin/toolbox"
    chmod +x "$HOME/.local/bin/toolbox"
  else
    warn "could not download toolbox; keeping existing copy"
    rm -f "$HOME/.local/bin/toolbox.tmp"
  fi
}

# -----------------------------
# 1.1) Usage-tracking hooks: log each launched command's first word.
#      toolbox aggregates these into a per-tool counter and sorts the
#      Installed list by count (favorites at the bottom).
# -----------------------------
install_track_hooks() {
  log "Installing usage-tracking hooks (zsh/fish/bash)..."
  mkdir -p "$HOME/.local/state/toolbox" "$HOME/.config/fish/conf.d"

  cat > "$HOME/.config/fish/conf.d/toolbox-track.fish" <<'EOF'
function __toolbox_track --on-event fish_preexec
    set -l w (string split ' ' -- $argv)[1]
    test -n "$w"; and echo $w >> $HOME/.local/state/toolbox/usage.log 2>/dev/null
end
EOF

  if ! grep -q "BEGIN TOOLBOX TRACK" "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" <<'EOF'

# BEGIN TOOLBOX TRACK
autoload -Uz add-zsh-hook 2>/dev/null
__toolbox_track() { print -r -- "${1%% *}" >> "$HOME/.local/state/toolbox/usage.log" 2>/dev/null }
add-zsh-hook preexec __toolbox_track 2>/dev/null
# END TOOLBOX TRACK
EOF
  fi

  if ! grep -q "BEGIN TOOLBOX TRACK" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'EOF'

# BEGIN TOOLBOX TRACK
__toolbox_track() { case "$BASH_COMMAND" in __toolbox_track*|toolbox|*PROMPT*) return;; esac; echo "${BASH_COMMAND%% *}" >> "$HOME/.local/state/toolbox/usage.log" 2>/dev/null; }
trap '__toolbox_track' DEBUG
# END TOOLBOX TRACK
EOF
  fi
}

# -----------------------------
# 2.0) Ensure Homebrew + ~/.local/bin in zsh login PATH (macOS)
#      Without this, `brew`, `claude`, `agy` are NOT on PATH in a fresh
#      Terminal — the original config only wired Homebrew into fish.
# -----------------------------
ensure_zprofile() {
  local zprofile="$HOME/.zprofile"
  touch "$zprofile"

  if ! grep -q "brew shellenv" "$zprofile"; then
    log "Wiring Homebrew + ~/.local/bin into ~/.zprofile..."
    cat >> "$zprofile" <<'EOF'

# Added by install-greeting.sh
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
export PATH="$HOME/.local/bin:$PATH"
EOF
  fi
}

# -----------------------------
# 2) Ensure PATH has ~/.local/bin (zsh/bash)
# -----------------------------
ensure_path_line() {
  local rc="$1"
  touch "$rc"

  if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$rc"; then
    {
      echo ""
      echo "# Added by install-greeting.sh"
      echo 'export PATH="$HOME/.local/bin:$PATH"'
    } >> "$rc"
  fi
}

# -----------------------------
# 2.1) Ensure PATH has ~/.local/bin (fish)
# -----------------------------
ensure_fish_path() {
  if command -v fish >/dev/null 2>&1; then
    log "Ensuring ~/.local/bin is in fish_user_paths..."
    fish -c 'contains "$HOME/.local/bin" $fish_user_paths; or set -U fish_user_paths $HOME/.local/bin $fish_user_paths' || true
  fi
}

# -----------------------------
# 3) Greeting hooks (show toolbox on shell start)
# -----------------------------
install_fish_greeting() {
  log "Configuring fish greeting..."
  mkdir -p "$HOME/.config/fish/functions"

  cat > "$HOME/.config/fish/functions/fish_greeting.fish" <<'EOF'
function fish_greeting
  if type -q toolbox
    toolbox
  end
end
EOF
}

append_zsh_hook() {
  log "Configuring zsh greeting..."
  local zshrc="$HOME/.zshrc"
  touch "$zshrc"

  if ! grep -q "BEGIN TOOLBOX GREETING" "$zshrc"; then
    cat >> "$zshrc" <<'EOF'

# BEGIN TOOLBOX GREETING (added by install-greeting.sh)
if [[ -o interactive ]]; then
  if command -v toolbox >/dev/null 2>&1; then
    toolbox
  fi
fi
# END TOOLBOX GREETING
EOF
  fi
}

append_bash_hook() {
  log "Configuring bash greeting..."
  local bashrc="$HOME/.bashrc"
  touch "$bashrc"

  if ! grep -q "BEGIN TOOLBOX GREETING" "$bashrc"; then
    cat >> "$bashrc" <<'EOF'

# BEGIN TOOLBOX GREETING (added by install-greeting.sh)
case "$-" in
  *i*)
    if command -v toolbox >/dev/null 2>&1; then
      toolbox
    fi
  ;;
esac
# END TOOLBOX GREETING
EOF
  fi
}

main() {
  install_toolbox
  install_track_hooks

  # PATH for shells
  ensure_zprofile
  ensure_path_line "$HOME/.zshrc"
  ensure_path_line "$HOME/.bashrc"
  ensure_fish_path

  # greetings
  install_fish_greeting
  append_zsh_hook
  append_bash_hook

  log "Done."
  echo "Close ALL terminal windows and open a new one."
  echo "Greeting (with usage counter) appears automatically."
}

main "$@"
