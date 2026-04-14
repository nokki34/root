# Dotfiles Sync — Design Spec

**Date:** 2026-04-14
**Project:** nokki-config

---

## Overview

A shell-script-based tool for syncing local configuration files (nvim, tmux, aerospace, and others) to and from a GitHub repository. The goal is to be able to capture the current state of your configs with one command, and restore them on any machine with another.

---

## Repo Structure

```
nokki-config/
├── paths.conf          # list of paths to manage
├── files/              # mirrored copies of your configs (git-tracked)
│   ├── .config/
│   │   ├── nvim/
│   │   └── aerospace/
│   └── .tmux.conf
├── collect.sh          # copies from your machine → files/
└── deploy.sh           # copies from files/ → your machine
```

Git operations (commit, push, pull) are handled manually by the user.

---

## paths.conf Format

One path per line. Blank lines and lines starting with `#` are ignored. Paths may use `~` for `$HOME`.

```
# neovim
~/.config/nvim

# tmux
~/.tmux.conf

# aerospace
~/.config/aerospace
```

---

## collect.sh

Reads each entry from `paths.conf` and copies it into `files/`, preserving the path structure relative to `$HOME`.

**Behavior:**
- Expands `~` to `$HOME`
- Skips blank lines and comments
- If the source path does not exist on disk: prints a warning and skips
- If the source is a file: copies it to `files/<relative-path>`
- If the source is a directory: replaces `files/<relative-path>/` entirely (removes old copy first, then copies recursively) — no merge, always a clean snapshot

**Example output:**
```
[collect] ~/.config/nvim → files/.config/nvim/
[collect] ~/.tmux.conf → files/.tmux.conf
[warn]    ~/.config/aerospace not found, skipping
```

---

## deploy.sh

Reads each entry from `paths.conf` and copies it from `files/` back to the machine.

**Flags:**
- `--force` / `-f` — overwrite all conflicting files without prompting

**Behavior per entry:**
1. If no copy exists in `files/`: print a warning and skip
2. If the target path does not exist on the machine: copy directly, no prompt
3. If the target path exists and is identical to the repo copy: skip silently
4. If the target path exists and differs from the repo copy:
   - Without `--force`: prompt `[conflict] <path> differs. Overwrite? [y/N]` — overwrite on `y`, skip otherwise
   - With `--force`: overwrite without prompting

**Example output (default):**
```
[deploy] ~/.config/nvim → new, copying
[deploy] ~/.tmux.conf → identical, skipping
[conflict] ~/.config/aerospace → differs. Overwrite? [y/N] y
[deploy] ~/.config/aerospace → overwritten
```

**Example output (--force):**
```
[deploy] ~/.config/nvim → new, copying
[deploy] ~/.tmux.conf → overwriting
[deploy] ~/.config/aerospace → overwriting
```

---

## GitHub Workflow

```
# Capture current state and push
./collect.sh
git add files/
git commit -m "sync: $(date +%Y-%m-%d)"
git push

# On a new machine: fetch and apply
git pull
./deploy.sh
```

---

## Out of Scope (for now)

- CLI wrapper / interactive TUI
- Automatic git operations inside the scripts
- Secrets management / encryption
- Symlink-based approach (copy-based only)
