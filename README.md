# nokki-config

Personal dotfiles sync — captures local configs into this repo and restores them on any machine.

## What's tracked

| Tool | Path |
|------|------|
| Neovim | `~/.config/nvim` |
| tmux | `~/.tmux.conf` |
| tmuxinator | `~/.config/tmuxinator` |
| Aerospace | `~/.aerospace.toml` (mac only) |
| WezTerm | `~/.wezterm.lua` |
| Zsh | `~/.zshrc` |

Add or remove entries in `paths.conf` to manage more tools.

## Usage

**Capture current configs → repo:**
```bash
./collect.sh arch          # or `./collect.sh` to update the shared base
git add files files-arch
git commit -m "sync: $(date +%Y-%m-%d)"
git push
```

## Per-machine configs

`files/` is the **machine-agnostic base** — every machine gets it. A machine
folder (`files-mac/`, `files-arch/`) is a thin **overlay** on top, holding only
what actually differs. Nothing is duplicated between them.

Each overlay entry declares its own mode by filename:

| Overlay entry | Mode | Deployed result |
|---|---|---|
| `<f>.append` | append | base `<f>` **+** this tail, concatenated |
| `<f>` (base has `<f>`) | replace | this file, base ignored |
| `<f>` (no base `<f>`) | machine-only | this file |
| *(no entry)* | base | base `<f>` verbatim |

```bash
./deploy.sh arch     # files/ + files-arch/  → ~
./collect.sh arch    # ~ → files/ + files-arch/
```

### Which machine am I?

`$DOTFILES_MACHINE`, else the argument. If neither is set the run fails —
guessing is how you end up applying the other machine's configs.

```bash
export DOTFILES_MACHINE=arch   # in ~/.zshrc, then just:
./deploy.sh
./collect.sh

./deploy.sh arch               # or name it each time
./deploy.sh --base             # files/ alone, no machine layer
```

### What each machine currently overrides

```
files-mac/
  .aerospace.toml        mac-only tool, no base counterpart
  .zshrc.append          fxpro PATH, awake/awake-off (pmset), FD_PATH
  .tmux.conf.append      Ctrl-A prefix, pbcopy
files-arch/
  .zshrc.append          ssh-agent + key, FD_PATH
  .tmux.conf.append      wl-copy
  .config/nvim/lazy-lock.json
```

Everything else — the whole Neovim config, tmuxinator, wezterm, `.fd.zsh` —
lives once in `files/`.

Machine-specific *values* are best handled by exporting them from
`.zshrc.append` rather than by duplicating the file that reads them. `.fd.zsh`
is shared by both machines; only `FD_PATH` differs, so each machine exports it
from its own `.zshrc` tail.

### Tools that only exist on some machines

A `paths.conf` entry can be scoped with a trailing `@machine` list, so it is
skipped entirely elsewhere — neither deployed to nor collected from:

```
# aerospace (macOS-only window manager)
~/.aerospace.toml    @mac
```

Scoped entries are also skipped on a base run (`./deploy.sh` with no machine),
since `files/` is meant to be machine-agnostic.

### Collecting a machine's changes

`./collect.sh <machine>` decomposes the live config against the base rather
than snapshotting it:

- file matches base → its overlay is dropped
- file only *extends* base → the tail is written to `<f>.append`
- file diverges inside the base region → stored as a full `<f>` override, with
  a warning (an append tail could not represent it without losing the edit)
- file has no base counterpart → kept as a machine-only file
- file gone locally → its stale overlay is pruned

It never writes to `files/`. To change something for *every* machine, edit
`files/` directly (or run `./collect.sh` with no machine name).

Note for `.tmux.conf`: overlays are concatenated *below* the `run .../tpm` line.
That is fine for key bindings, which simply win over plugin defaults, but any
new `set -g @plugin` must go in `files/.tmux.conf` above that line.

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

`paths.conf` lists paths to manage (one per line, `#` for comments, `~`
supported, optional trailing `@machine` scope).

`lib.sh` holds the layering logic both scripts share: which layer a file comes
from, and how base and overlay are combined.

`deploy.sh` assembles `files/` + `files-<machine>/` into a staging dir, then
compares that against the live path. If it exists and differs, it asks before
overwriting — unless `--force` is passed. With a machine named, it prints a
`[layer]` line for each file that is not plain base, so the overlay is auditable.

`collect.sh` goes the other way, decomposing live config back into base and
overlay as described above.

`tests/` is a bats suite (`bats tests/`) covering both scripts and the layering.
