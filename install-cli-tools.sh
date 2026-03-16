#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Helpers
# -----------------------------
log()  { printf "\n\033[1m%s\033[0m\n" "$*"; }
warn() { printf "\n\033[33m[WARN]\033[0m %s\n" "$*"; }

require() {
  command -v "$1" >/dev/null 2>&1
}

# -----------------------------
# Homebrew
# -----------------------------
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
    warn "brew not found after installation"
    exit 1
  fi
}

# -----------------------------
# Brew packages
# -----------------------------
BREW_PACKAGES=(
  btop
  eza
  bat
  fd
  ripgrep
  nmap
  bandwhich
  zoxide
  fzf
  whois
  pv
  tcpdump
  curlie
  duf
  gping
  dust
  yazi
  visidata
  nano
  neovim
  sshing
  mac-cleanup-py
)

install_brew_packages() {
  log "Installing Homebrew packages..."
  brew update

  for pkg in "${BREW_PACKAGES[@]}"; do
    if brew list "$pkg" >/dev/null 2>&1; then
      echo "✔ $pkg already installed"
    else
      echo "→ installing $pkg"
      brew install "$pkg"
    fi
  done
}

# -----------------------------
# fzf post-install
# -----------------------------
setup_fzf() {
  local fzf_install
  fzf_install="$(brew --prefix)/opt/fzf/install"

  if [[ -x "$fzf_install" ]]; then
    log "Configuring fzf..."
    "$fzf_install" --all --no-bash --no-zsh || true
  fi
}

# -----------------------------
# Main
# -----------------------------
main() {
  install_homebrew
  install_brew_packages
  setup_fzf

  log "CLI tools installation complete."
  echo "Restart terminal or run: exec fish"
}

main "$@"
