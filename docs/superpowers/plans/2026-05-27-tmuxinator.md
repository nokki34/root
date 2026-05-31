# Tmuxinator Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a tracked `dev` tmuxinator layout (nvim, shell, claude as separate windows) to the dotfiles repo.

**Architecture:** Add `~/.config/tmuxinator` as a tracked directory in `paths.conf` (mirroring the existing `~/.config/nvim` pattern), create the `dev.yml` template under `files/`, and document the tool in the README.

**Tech Stack:** Bash, tmuxinator (Ruby gem, install via `brew install tmuxinator`), bats (existing test suite)

---

### Task 1: Create the tmuxinator dev template

**Files:**
- Create: `files/.config/tmuxinator/dev.yml`

No new tests needed — directory collection/deployment is already covered by the existing bats suite (`tests/test_collect.bats` and `tests/test_deploy.bats`).

- [ ] **Step 1: Create the directory and file**

```bash
mkdir -p files/.config/tmuxinator
```

- [ ] **Step 2: Write `files/.config/tmuxinator/dev.yml`**

```yaml
name: dev
root: ~/

windows:
  - editor: nvim .
  - shell: ""
  - claude: claude
```

- [ ] **Step 3: Verify the file exists and looks correct**

```bash
cat files/.config/tmuxinator/dev.yml
```

Expected output:
```
name: dev
root: ~/

windows:
  - editor: nvim .
  - shell: ""
  - claude: claude
```

- [ ] **Step 4: Commit**

```bash
git add files/.config/tmuxinator/dev.yml
git commit -m "feat: add tmuxinator dev layout (nvim, shell, claude)"
```

---

### Task 2: Register the tmuxinator directory in paths.conf

**Files:**
- Modify: `paths.conf`

- [ ] **Step 1: Run the existing test suite to confirm baseline**

```bash
bats tests/
```

Expected: all tests pass.

- [ ] **Step 2: Add the tmuxinator entry to `paths.conf`**

Open `paths.conf` and add after the `# tmux` block:

```
# tmuxinator
~/.config/tmuxinator
```

Final `paths.conf` should look like:

```
# neovim
~/.config/nvim

# tmux
~/.tmux.conf

# tmuxinator
~/.config/tmuxinator

# aerospace
~/.aerospace.toml

# wezterm
~/.wezterm.lua

# zsh
~/.zshrc
```

- [ ] **Step 3: Run the test suite again to confirm nothing broke**

```bash
bats tests/
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add paths.conf
git commit -m "chore: track ~/.config/tmuxinator in paths.conf"
```

---

### Task 3: Update README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add tmuxinator to the "What's tracked" table**

Find this block in `README.md`:

```markdown
| Tool | Path |
|------|------|
| Neovim | `~/.config/nvim` |
| tmux | `~/.tmux.conf` |
| Aerospace | `~/.aerospace.toml` |
| WezTerm | `~/.wezterm.lua` |
| Zsh | `~/.zshrc` |
```

Replace with:

```markdown
| Tool | Path |
|------|------|
| Neovim | `~/.config/nvim` |
| tmux | `~/.tmux.conf` |
| tmuxinator | `~/.config/tmuxinator` |
| Aerospace | `~/.aerospace.toml` |
| WezTerm | `~/.wezterm.lua` |
| Zsh | `~/.zshrc` |
```

- [ ] **Step 2: Add install + usage note to the "Restore configs" section**

Find this block:

```markdown
**Restore configs on a new machine:**
```bash
git clone git@github.com:nokki34/root.git ~/nokki-config
cd ~/nokki-config
./deploy.sh           # prompts before overwriting existing files
./deploy.sh --force   # overwrites everything without prompting
```
```

Replace with:

```markdown
**Restore configs on a new machine:**
```bash
brew install tmuxinator
git clone git@github.com:nokki34/root.git ~/nokki-config
cd ~/nokki-config
./deploy.sh           # prompts before overwriting existing files
./deploy.sh --force   # overwrites everything without prompting
```

Start the dev session:
```bash
tmuxinator start dev
```
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add tmuxinator to README (install, tracked path, usage)"
```
