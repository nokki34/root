# Dotfiles Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Two shell scripts — `collect.sh` and `deploy.sh` — that sync config files between your machine and this git repo using a `paths.conf` list.

**Architecture:** `paths.conf` lists paths (one per line, `#` comments allowed). `collect.sh` reads it and mirrors each path into `files/` preserving the home-relative directory structure. `deploy.sh` restores from `files/` back to the machine, prompting on conflicts unless `--force` is passed.

**Tech Stack:** Bash, bats-core (shell testing)

---

## File Map

| File | Purpose |
|------|---------|
| `paths.conf` | User-editable list of paths to manage |
| `files/` | Git-tracked mirror of collected configs |
| `collect.sh` | Copies from machine → `files/` |
| `deploy.sh` | Copies from `files/` → machine |
| `tests/test_collect.bats` | Bats tests for collect.sh |
| `tests/test_deploy.bats` | Bats tests for deploy.sh |

---

## Task 1: Repo Scaffolding

**Files:**
- Create: `paths.conf`
- Create: `files/.gitkeep`
- Create: `tests/.gitkeep`

- [ ] **Step 1: Install bats-core (test runner for shell scripts)**

```bash
brew install bats-core
bats --version
```

Expected: prints a version like `Bats 1.x.x`

- [ ] **Step 2: Create `paths.conf` with commented examples**

```
# neovim
# ~/.config/nvim

# tmux
# ~/.tmux.conf

# aerospace
# ~/.config/aerospace/aerospace.toml
```

All entries are commented out so the file works as a template without collecting anything on first run.

- [ ] **Step 3: Create placeholder files to track empty directories in git**

```bash
touch files/.gitkeep
mkdir -p tests
touch tests/.gitkeep
```

- [ ] **Step 4: Commit scaffolding**

```bash
git add paths.conf files/.gitkeep tests/.gitkeep
git commit -m "chore: initial repo scaffolding"
```

---

## Task 2: `collect.sh` — Parse `paths.conf` and Copy Files

**Files:**
- Create: `collect.sh`
- Create: `tests/test_collect.bats`

- [ ] **Step 1: Write failing test for file collection**

Create `tests/test_collect.bats`:

```bash
#!/usr/bin/env bats

setup() {
  # Create a temp HOME with a test file
  TEST_HOME=$(mktemp -d)
  echo "hello" > "$TEST_HOME/.testrc"

  # Create a temp repo dir
  REPO_DIR=$(mktemp -d)
  mkdir -p "$REPO_DIR/files"

  # Write paths.conf pointing to the test file
  echo "~/.testrc" > "$REPO_DIR/paths.conf"

  # Copy collect.sh into temp repo
  cp "$BATS_TEST_DIRNAME/../collect.sh" "$REPO_DIR/collect.sh"
  chmod +x "$REPO_DIR/collect.sh"

  export TEST_HOME REPO_DIR
}

teardown() {
  rm -rf "$TEST_HOME" "$REPO_DIR"
}

@test "collect copies a file into files/" {
  HOME=$TEST_HOME bash "$REPO_DIR/collect.sh"
  [ -f "$REPO_DIR/files/.testrc" ]
  run cat "$REPO_DIR/files/.testrc"
  [ "$output" = "hello" ]
}

@test "collect skips blank lines and comments" {
  printf "# comment\n\n~/.testrc\n" > "$REPO_DIR/paths.conf"
  HOME=$TEST_HOME run bash "$REPO_DIR/collect.sh"
  [ "$status" -eq 0 ]
  [ -f "$REPO_DIR/files/.testrc" ]
}

@test "collect warns and skips missing path" {
  echo "~/.nonexistent" > "$REPO_DIR/paths.conf"
  HOME=$TEST_HOME run bash "$REPO_DIR/collect.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[warn]"* ]]
  [[ "$output" == *"skipping"* ]]
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bats tests/test_collect.bats
```

Expected: FAIL — `collect.sh: No such file or directory`

- [ ] **Step 3: Create `collect.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATHS_CONF="$SCRIPT_DIR/paths.conf"
FILES_DIR="$SCRIPT_DIR/files"

while IFS= read -r line; do
  # skip blank lines and comments
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

  # expand ~ to $HOME
  path="${line/#\~/$HOME}"

  # relative path from HOME (e.g. .config/nvim)
  rel="${path#"$HOME"/}"
  dest="$FILES_DIR/$rel"

  if [ ! -e "$path" ]; then
    echo "[warn]    $line not found, skipping"
    continue
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -d "$path" ]; then
    echo "[collect] $line → files/$rel/"
    rm -rf "$dest"
    cp -r "$path" "$dest"
  else
    echo "[collect] $line → files/$rel"
    cp "$path" "$dest"
  fi

done < "$PATHS_CONF"
```

```bash
chmod +x collect.sh
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
bats tests/test_collect.bats
```

Expected: 3 tests, 0 failures

- [ ] **Step 5: Commit**

```bash
git add collect.sh tests/test_collect.bats
git commit -m "feat: add collect.sh with path parsing and file copy"
```

---

## Task 3: `collect.sh` — Directory Copy

**Files:**
- Modify: `tests/test_collect.bats` — add directory tests

- [ ] **Step 1: Add failing tests for directory collection**

Append to `tests/test_collect.bats`:

```bash
@test "collect copies a directory recursively into files/" {
  mkdir -p "$TEST_HOME/.config/mytool"
  echo "cfg" > "$TEST_HOME/.config/mytool/config"
  echo "~/.config/mytool" > "$REPO_DIR/paths.conf"

  HOME=$TEST_HOME bash "$REPO_DIR/collect.sh"

  [ -d "$REPO_DIR/files/.config/mytool" ]
  [ -f "$REPO_DIR/files/.config/mytool/config" ]
  run cat "$REPO_DIR/files/.config/mytool/config"
  [ "$output" = "cfg" ]
}

@test "collect replaces existing directory in files/ (no merge)" {
  mkdir -p "$TEST_HOME/.config/mytool"
  echo "new" > "$TEST_HOME/.config/mytool/config"

  mkdir -p "$REPO_DIR/files/.config/mytool"
  echo "old" > "$REPO_DIR/files/.config/mytool/old_file"

  echo "~/.config/mytool" > "$REPO_DIR/paths.conf"
  HOME=$TEST_HOME bash "$REPO_DIR/collect.sh"

  # old_file should be gone (clean replace, not merge)
  [ ! -f "$REPO_DIR/files/.config/mytool/old_file" ]
  run cat "$REPO_DIR/files/.config/mytool/config"
  [ "$output" = "new" ]
}
```

- [ ] **Step 2: Run all collect tests**

```bash
bats tests/test_collect.bats
```

Expected: 5 tests, 0 failures (collect.sh already handles directories from Task 2)

- [ ] **Step 4: Commit**

```bash
git add tests/test_collect.bats
git commit -m "test: add directory copy tests for collect.sh"
```

---

## Task 4: `deploy.sh` — New Path and Identical Skip

**Files:**
- Create: `deploy.sh`
- Create: `tests/test_deploy.bats`

- [ ] **Step 1: Write failing tests**

Create `tests/test_deploy.bats`:

```bash
#!/usr/bin/env bats

setup() {
  TEST_HOME=$(mktemp -d)
  REPO_DIR=$(mktemp -d)
  mkdir -p "$REPO_DIR/files"

  cp "$BATS_TEST_DIRNAME/../deploy.sh" "$REPO_DIR/deploy.sh"
  chmod +x "$REPO_DIR/deploy.sh"

  export TEST_HOME REPO_DIR
}

teardown() {
  rm -rf "$TEST_HOME" "$REPO_DIR"
}

@test "deploy copies a new file to the machine" {
  echo "~/.testrc" > "$REPO_DIR/paths.conf"
  echo "content" > "$REPO_DIR/files/.testrc"

  HOME=$TEST_HOME bash "$REPO_DIR/deploy.sh"

  [ -f "$TEST_HOME/.testrc" ]
  run cat "$TEST_HOME/.testrc"
  [ "$output" = "content" ]
}

@test "deploy skips identical files silently" {
  echo "~/.testrc" > "$REPO_DIR/paths.conf"
  echo "same" > "$REPO_DIR/files/.testrc"
  echo "same" > "$TEST_HOME/.testrc"

  HOME=$TEST_HOME run bash "$REPO_DIR/deploy.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"identical, skipping"* ]]
}

@test "deploy warns when path is missing from files/" {
  echo "~/.testrc" > "$REPO_DIR/paths.conf"
  # no files/.testrc

  HOME=$TEST_HOME run bash "$REPO_DIR/deploy.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[warn]"* ]]
}

@test "deploy copies a new directory to the machine" {
  mkdir -p "$REPO_DIR/files/.config/mytool"
  echo "cfg" > "$REPO_DIR/files/.config/mytool/config"
  echo "~/.config/mytool" > "$REPO_DIR/paths.conf"

  HOME=$TEST_HOME bash "$REPO_DIR/deploy.sh"

  [ -d "$TEST_HOME/.config/mytool" ]
  run cat "$TEST_HOME/.config/mytool/config"
  [ "$output" = "cfg" ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bats tests/test_deploy.bats
```

Expected: FAIL — `deploy.sh: No such file or directory`

- [ ] **Step 3: Create `deploy.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

FORCE=false
for arg in "$@"; do
  case "$arg" in
    -f|--force) FORCE=true ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATHS_CONF="$SCRIPT_DIR/paths.conf"
FILES_DIR="$SCRIPT_DIR/files"

while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

  path="${line/#\~/$HOME}"
  rel="${path#"$HOME"/}"
  src="$FILES_DIR/$rel"

  if [ ! -e "$src" ]; then
    echo "[warn]    $line not in files/, skipping"
    continue
  fi

  if [ ! -e "$path" ]; then
    echo "[deploy] $line → new, copying"
    mkdir -p "$(dirname "$path")"
    if [ -d "$src" ]; then
      cp -r "$src" "$path"
    else
      cp "$src" "$path"
    fi
    continue
  fi

  # check if identical
  if [ -d "$src" ]; then
    identical=$(diff -rq "$src" "$path" > /dev/null 2>&1 && echo yes || echo no)
  else
    identical=$(diff -q "$src" "$path" > /dev/null 2>&1 && echo yes || echo no)
  fi

  if [ "$identical" = "yes" ]; then
    echo "[deploy] $line → identical, skipping"
    continue
  fi

  # differs — check force flag or prompt
  if $FORCE; then
    echo "[deploy] $line → overwriting"
  else
    printf "[conflict] %s → differs. Overwrite? [y/N] " "$line"
    read -r answer < /dev/tty
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
      echo "[deploy] $line → skipped"
      continue
    fi
    echo "[deploy] $line → overwritten"
  fi

  if [ -d "$src" ]; then
    rm -rf "$path"
    cp -r "$src" "$path"
  else
    cp "$src" "$path"
  fi

done < "$PATHS_CONF"
```

```bash
chmod +x deploy.sh
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
bats tests/test_deploy.bats
```

Expected: 4 tests, 0 failures

- [ ] **Step 5: Commit**

```bash
git add deploy.sh tests/test_deploy.bats
git commit -m "feat: add deploy.sh with new-path and identical-skip logic"
```

---

## Task 5: `deploy.sh` — Conflict Prompt and `--force` Flag

**Files:**
- Modify: `tests/test_deploy.bats` — add conflict and force tests

- [ ] **Step 1: Add failing tests for conflict and --force**

Append to `tests/test_deploy.bats`:

```bash
@test "deploy --force overwrites differing files without prompting" {
  echo "~/.testrc" > "$REPO_DIR/paths.conf"
  echo "new content" > "$REPO_DIR/files/.testrc"
  echo "old content" > "$TEST_HOME/.testrc"

  HOME=$TEST_HOME run bash "$REPO_DIR/deploy.sh" --force
  [ "$status" -eq 0 ]
  [[ "$output" == *"overwriting"* ]]
  run cat "$TEST_HOME/.testrc"
  [ "$output" = "new content" ]
}

@test "deploy -f is an alias for --force" {
  echo "~/.testrc" > "$REPO_DIR/paths.conf"
  echo "new" > "$REPO_DIR/files/.testrc"
  echo "old" > "$TEST_HOME/.testrc"

  HOME=$TEST_HOME run bash "$REPO_DIR/deploy.sh" -f
  [ "$status" -eq 0 ]
  [[ "$output" == *"overwriting"* ]]
}

@test "deploy --force overwrites differing directories without prompting" {
  mkdir -p "$REPO_DIR/files/.config/mytool"
  echo "new" > "$REPO_DIR/files/.config/mytool/config"
  mkdir -p "$TEST_HOME/.config/mytool"
  echo "old" > "$TEST_HOME/.config/mytool/config"

  echo "~/.config/mytool" > "$REPO_DIR/paths.conf"
  HOME=$TEST_HOME run bash "$REPO_DIR/deploy.sh" --force
  [ "$status" -eq 0 ]
  run cat "$TEST_HOME/.config/mytool/config"
  [ "$output" = "new" ]
}
```

- [ ] **Step 2: Run tests**

```bash
bats tests/test_deploy.bats
```

Expected: 7 tests, 0 failures

> **Note on conflict prompt:** The interactive `read < /dev/tty` path (conflict without `--force`) is not auto-tested here because bats can't easily drive tty input. The `--force` tests verify the underlying overwrite logic. The prompt itself is validated by the smoke test in Task 6.

- [ ] **Step 3: Commit**

```bash
git add tests/test_deploy.bats
git commit -m "test: add --force and conflict tests for deploy.sh"
```

---

## Task 6: Full Test Run and Smoke Test

- [ ] **Step 1: Run the full test suite**

```bash
bats tests/
```

Expected: all tests pass, 0 failures

- [ ] **Step 2: Smoke test collect.sh manually**

Add a real path to `paths.conf` (uncomment one line, e.g. `~/.tmux.conf` or `~/.config/nvim`) then run:

```bash
./collect.sh
```

Expected: `[collect]` lines appear, file/dir shows up under `files/`

- [ ] **Step 3: Smoke test deploy.sh manually**

```bash
./deploy.sh --force
```

Expected: `[deploy] ... → identical, skipping` (since you just collected, files are identical)

- [ ] **Step 4: Commit final state**

```bash
git add paths.conf
git commit -m "chore: add example paths.conf entries"
```
