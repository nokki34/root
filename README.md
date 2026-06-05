# nokki-config

Personal dotfiles sync — captures local configs into this repo and restores them on any machine.

## What's tracked

| Tool | Path |
|------|------|
| Neovim | `~/.config/nvim` |
| tmux | `~/.tmux.conf` |
| tmuxinator | `~/.config/tmuxinator` |
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

## Per-machine configs

Both scripts take an optional machine name to use a separate folder, keeping
configs from different machines from overwriting each other:

```bash
./collect.sh arch    # captures into files-arch/ instead of files/
./deploy.sh arch     # restores from files-arch/
```

With no machine name they use `files/` (the mac originals) as before.
Currently `files-arch/` holds the Arch versions of `.zshrc` and `.tmux.conf`.

**Restore configs on a new machine:**
```bash
brew install tmux tmuxinator
git clone git@github.com:nokki34/root.git ~/nokki-config
cd ~/nokki-config
./deploy.sh           # prompts before overwriting existing files
./deploy.sh --force   # overwrites everything without prompting
```

Start the dev session:
```bash
tmuxinator start dev
```

## How it works

`paths.conf` lists paths to manage (one per line, `#` for comments, `~` supported).

`collect.sh` copies each path into `files/`, mirroring the home-relative structure.

`deploy.sh` copies from `files/` back to their original locations. If a file already exists and differs, it asks before overwriting — unless `--force` is passed.
