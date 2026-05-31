# Tmuxinator Integration Design

**Date:** 2026-05-27

## Goal

Add tmuxinator to this dotfiles repo so a `dev` session layout (nvim, shell, claude — each in its own tmux window) is versioned and deployable on any machine.

## Files Changed

| File | Change |
|---|---|
| `paths.conf` | Add `~/.config/tmuxinator` (directory, consistent with `~/.config/nvim`) |
| `files/.config/tmuxinator/dev.yml` | New tmuxinator template with three windows |
| `README.md` | Add tmuxinator to the "What's tracked" table and document install + usage |

## Template Layout (`dev.yml`)

Three tmux windows, no splits:

```yaml
name: dev
root: ~/

windows:
  - editor: nvim .
  - shell: ""
  - claude: claude
```

- `editor` — opens nvim in the current directory
- `shell` — empty shell prompt
- `claude` — launches the `claude` CLI

Start with: `tmuxinator start dev`

## README Additions

- Add `tmuxinator` row to "What's tracked" table (`~/.config/tmuxinator`)
- Add `brew install tmuxinator` to prerequisites under "Restore configs on a new machine"
- Add `tmuxinator start dev` usage example

## How It Fits the Existing Pattern

`collect.sh` and `deploy.sh` already handle directories (see `~/.config/nvim`). Tracking `~/.config/tmuxinator` as a directory means all future templates are collected and deployed automatically without further `paths.conf` changes.
