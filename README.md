# nokki-config

Personal dotfiles sync — captures local configs into this repo and restores them on any machine.

## What's tracked

| Tool | Path |
|------|------|
| Neovim | `~/.config/nvim` |
| tmux | `~/.tmux.conf` |
| Aerospace | `~/.aerospace.toml` |
| WezTerm | `~/.wezterm.lua` |
| Zsh | `~/.zshrc` |

Add or remove entries in `paths.conf` to manage more tools.

## Usage

**Capture current configs → repo:**
```bash
./collect.sh
git add files/
git commit -m "sync: $(date +%Y-%m-%d)"
git push
```

**Restore configs on a new machine:**
```bash
git clone git@github.com:nokki34/root.git ~/nokki-config
cd ~/nokki-config
./deploy.sh           # prompts before overwriting existing files
./deploy.sh --force   # overwrites everything without prompting
```

## How it works

`paths.conf` lists paths to manage (one per line, `#` for comments, `~` supported).

`collect.sh` copies each path into `files/`, mirroring the home-relative structure.

`deploy.sh` copies from `files/` back to their original locations. If a file already exists and differs, it asks before overwriting — unless `--force` is passed.
