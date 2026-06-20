#!/usr/bin/env bash
set -euo pipefail

log()  { printf "\n\033[1m%s\033[0m\n" "$*"; }
warn() { printf "\n\033[33m[WARN]\033[0m %s\n" "$*"; }

require() {
  command -v "$1" >/dev/null 2>&1
}

# --- Homebrew ---
install_homebrew() {
  if require brew; then
    log "Homebrew already installed."
    return
  fi

  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    warn "brew installed but not found in PATH"
    exit 1
  fi
}

# --- Packages ---
install_packages() {
  log "Installing fish + starship..."
  brew install fish starship
}

# --- fish as login shell ---
setup_fish_shell() {
  local fish_path
  fish_path="$(command -v fish)"

  if ! grep -q "^${fish_path}$" /etc/shells; then
    log "Adding fish to /etc/shells (sudo required)"
    echo "${fish_path}" | sudo tee -a /etc/shells >/dev/null
  fi

  if [[ "$SHELL" != "$fish_path" ]]; then
    log "Setting fish as default shell"
    chsh -s "$fish_path"
  fi
}

# --- Fisher (plugin manager) ---
# Oh My Fish is effectively unmaintained; Fisher is the current standard
# plugin manager for fish 3.x/4.x.
install_fisher() {
  if fish -c 'type -q fisher' 2>/dev/null; then
    log "Fisher already installed."
    return
  fi

  log "Installing Fisher..."
  fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
}

# --- fish config ---
install_fish_config() {
  log "Installing fish config..."
  mkdir -p "$HOME/.config/fish/functions"

  cat > "$HOME/.config/fish/config.fish" <<'EOF'
# ---- Homebrew ----
if test -x /opt/homebrew/bin/brew
  eval (/opt/homebrew/bin/brew shellenv)
else if test -x /usr/local/bin/brew
  eval (/usr/local/bin/brew shellenv)
end

# ---- Starship prompt ----
if type -q starship
  starship init fish | source
end

# ---- zoxide (smart cd: `z`) ----
if type -q zoxide
  zoxide init fish | source
end

# Aliases live in ~/.config/fish/conf.d/aliases.fish (see install-aliases.sh)
EOF
}

# --- fish greeting ---
install_greeting() {
  cat > "$HOME/.config/fish/functions/fish_greeting.fish" <<'EOF'
function fish_greeting
  echo
  echo "fish + Fisher + Starship ready."
  echo "Useful commands:"
  echo "  fisher update         - update plugins"
  echo "  fisher install NAME   - install a fish plugin"
  echo "  starship explain      - explain current prompt"
  echo
end
EOF
}

main() {
  install_homebrew
  install_packages
  setup_fish_shell
  install_fisher
  install_fish_config
  install_greeting

  log "Done."
  echo "Open a NEW terminal window to start fish."
}

main "$@"
