### Quick install (macOS)

Run in this order:

```bash
curl -fsSL https://raw.githubusercontent.com/semanticparadox/configs/main/install-fish-fisher-starship.sh | bash

curl -fsSL https://raw.githubusercontent.com/semanticparadox/configs/main/install-cli-tools.sh | bash

curl -fsSL https://raw.githubusercontent.com/semanticparadox/configs/main/install-greeting.sh | bash

curl -fsSL https://raw.githubusercontent.com/semanticparadox/configs/main/install-aliases.sh | bash
```

What each script does:

- **install-fish-fisher-starship.sh** — installs `fish` + `starship`, sets fish as the default login shell (asks for your password via `chsh`), installs the [Fisher](https://github.com/jorgebucaran/fisher) plugin manager, and writes `~/.config/fish/config.fish`.
- **install-cli-tools.sh** — installs the modern CLI toolset via Homebrew (`eza`, `bat`, `fd`, `ripgrep`, `zoxide`, `fzf`, `dust`, `duf`, `yazi`, `sshs`, `mac-cleanup-py`, …).
- **install-greeting.sh** — installs the `toolbox` command (shows which tools are installed/missing), wires `Homebrew` + `~/.local/bin` into `~/.zprofile`, and shows the toolbox on every new shell.
- **install-aliases.sh** — writes shared aliases for fish/zsh/bash (`ls→eza`, `cat→bat`, `grep→rg`, `find→fd`, …), keeping originals available as `ggrep`, `gfind`, `gls`, `gcat`.

#### AI CLIs (claude, agy)

`claude` (Claude Code) and `agy` (Google Antigravity) install themselves into `~/.local/bin` via their own installers / apps — they are **not** Homebrew packages:

```bash
# Claude Code (official installer)
curl -fsSL https://claude.ai/install.sh | bash

# Antigravity CLI (`agy`) ships with the Antigravity.app
```

They become available on `PATH` automatically because `install-greeting.sh` adds `~/.local/bin` to `~/.zprofile` (zsh) and `fish_user_paths` (fish). They are also listed in the `toolbox` greeting.

#### Terminal themes (Modus)

Modus themes for **Alacritty** and **iTerm2** — light = Modus Operandi Tinted, dark = Modus Vivendi (matching the Zed setup):

```bash
curl -fsSL https://raw.githubusercontent.com/semanticparadox/configs/main/install-terminal-themes.sh | bash
```

- **Alacritty**: switch any time with `modus-light` / `modus-dark` (aliases from `install-aliases.sh`); applies instantly via live reload.
- **iTerm2**: imports both color presets, then a one-time checkbox enables automatic light/dark switching (see the script's printed instructions). Source: [miikanissi/modus-themes.nvim](https://github.com/miikanissi/modus-themes.nvim).

### For quick settings on VPS Debian 13 Servers

```bash
curl -fsSL https://raw.githubusercontent.com/semanticparadox/configs/main/debian13-master-bootstrap.sh | bash
```
