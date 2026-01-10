#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n\033[1m%s\033[0m\n" "$*"; }

# -----------------------------
# 1) Install toolbox command
# -----------------------------
install_toolbox() {
  log "Installing toolbox command..."

  mkdir -p "$HOME/.local/bin"

  cat > "$HOME/.local/bin/toolbox" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Only print in interactive terminals
[[ -t 1 ]] || exit 0

bold="$(tput bold 2>/dev/null || true)"
dim="$(tput dim 2>/dev/null || true)"
reset="$(tput sgr0 2>/dev/null || true)"

green="$(tput setaf 2 2>/dev/null || true)"
red="$(tput setaf 1 2>/dev/null || true)"
cyan="$(tput setaf 6 2>/dev/null || true)"

TOOLS=(
  "btop|btop|system monitor"
  "eza|eza|better ls"
  "bat|bat|better cat"
  "fd|fd|better find"
  "rg|ripgrep (rg)|fast grep"
  "nmap|nmap|network scanner"
  "bandwhich|bandwhich|per-process bandwidth"
  "zoxide|zoxide|smart cd (z)"
  "fzf|fzf|fuzzy finder"
  "whois|whois|whois lookup"
  "pv|pv|pipe progress"
  "tcpdump|tcpdump|packet capture"
  "curlie|curlie|curl + friendly UX"
  "duf|duf|disk usage"
  "gping|gping|ping with graph"
  "dust|dust|disk usage (tree)"
  "yazi|yazi|TUI file manager"
  "vd|visidata (vd)|tabular data TUI"
  "nano|nano|editor"
  "nvim|neovim (nvim)|editor"
  "lazyssh|lazyssh|SSH UI"
  "mac-cleanup|mac-cleanup|system cleanup"
)

have_cmd() { command -v "$1" >/dev/null 2>&1; }

print_header() {
  echo
  echo "${bold}${cyan}CLI Toolbox${reset} ${dim}(checked on launch)${reset}"
  echo "${dim}Run again anytime: toolbox${reset}"
  echo
}

print_section() {
  local title="$1"
  local color="$2"
  shift 2

  echo "${bold}${color}${title}${reset}"
  printf "%-18s %-28s %s\n" "Command" "Utility" "Hint"
  printf "%-18s %-28s %s\n" "------" "-------" "----"

  for line in "$@"; do
    IFS='|' read -r cmd label hint <<<"$line"
    printf "%-18s %-28s %s\n" "$cmd" "$label" "$hint"
  done
  echo
}

main() {
  local installed=()
  local missing=()

  for entry in "${TOOLS[@]}"; do
    IFS='|' read -r cmd label hint <<<"$entry"
    if have_cmd "$cmd"; then
      installed+=("$entry")
    else
      missing+=("$entry")
    fi
  done

  print_header

  if ((${#installed[@]})); then
    print_section "Installed" "${green}" "${installed[@]}"
  else
    echo "${red}No tools from the list are installed.${reset}"
    echo
  fi

  if ((${#missing[@]})); then
    print_section "Missing" "${red}" "${missing[@]}"
  fi
}

main "$@"
EOF

  chmod +x "$HOME/.local/bin/toolbox"
}

# -----------------------------
# 2) Ensure PATH has ~/.local/bin
# -----------------------------
ensure_path_line() {
  local rc="$1"

  # If file doesn't exist, create it
  touch "$rc"

  # Add PATH line if missing
  if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$rc"; then
    {
      echo ""
      echo "# Added by install-greeting.sh"
      echo 'export PATH="$HOME/.local/bin:$PATH"'
    } >> "$rc"
  fi
}

# -----------------------------
# 3) Hook into shells
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

  # Avoid duplicate block
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

  # Ensure PATH for common shells
  ensure_path_line "$HOME/.zshrc"
  ensure_path_line "$HOME/.bashrc"

  install_fish_greeting
  append_zsh_hook
  append_bash_hook

  log "Done."
  echo "Open a new terminal window/tab to see the greeting."
  echo "Or run: toolbox"
}

main "$@"
