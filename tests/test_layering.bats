#!/usr/bin/env bats
#
# Layering: files/ is the machine-agnostic base, files-<machine>/ overlays it.
#   <f>.append  -> base <f> + tail        <f> -> replaces base       no base -> machine-only

setup() {
  TEST_HOME=$(mktemp -d)
  REPO_DIR=$(mktemp -d)
  mkdir -p "$REPO_DIR/files" "$REPO_DIR/files-testm"

  cp "$BATS_TEST_DIRNAME/../collect.sh" "$REPO_DIR/collect.sh"
  cp "$BATS_TEST_DIRNAME/../deploy.sh"  "$REPO_DIR/deploy.sh"
  cp "$BATS_TEST_DIRNAME/../lib.sh"     "$REPO_DIR/lib.sh"
  chmod +x "$REPO_DIR/collect.sh" "$REPO_DIR/deploy.sh"

  echo "~/.testrc" > "$REPO_DIR/paths.conf"
  export TEST_HOME REPO_DIR
}

teardown() {
  rm -rf "$TEST_HOME" "$REPO_DIR"
}

# ---------- deploy ----------

@test "deploy: base file with no overlay is deployed verbatim" {
  printf 'base\n' > "$REPO_DIR/files/.testrc"

  HOME=$TEST_HOME bash "$REPO_DIR/deploy.sh" testm
  [ "$(cat "$TEST_HOME/.testrc")" = "base" ]
}

@test "deploy: .append concatenates base then tail" {
  printf 'base\n' > "$REPO_DIR/files/.testrc"
  printf 'tail\n' > "$REPO_DIR/files-testm/.testrc.append"

  HOME=$TEST_HOME bash "$REPO_DIR/deploy.sh" testm
  [ "$(cat "$TEST_HOME/.testrc")" = "$(printf 'base\ntail')" ]
}

@test "deploy: bare machine file replaces base outright" {
  printf 'base\n'     > "$REPO_DIR/files/.testrc"
  printf 'override\n' > "$REPO_DIR/files-testm/.testrc"

  HOME=$TEST_HOME bash "$REPO_DIR/deploy.sh" testm
  [ "$(cat "$TEST_HOME/.testrc")" = "override" ]
}

@test "deploy: machine-only file (no base counterpart) is deployed" {
  printf 'only\n' > "$REPO_DIR/files-testm/.testrc"

  HOME=$TEST_HOME bash "$REPO_DIR/deploy.sh" testm
  [ "$(cat "$TEST_HOME/.testrc")" = "only" ]
}

@test "deploy: layering applies to files inside a managed directory" {
  mkdir -p "$REPO_DIR/files/.config/t" "$REPO_DIR/files-testm/.config/t"
  printf 'shared\n' > "$REPO_DIR/files/.config/t/shared"
  printf 'base\n'   > "$REPO_DIR/files/.config/t/layered"
  printf 'tail\n'   > "$REPO_DIR/files-testm/.config/t/layered.append"
  printf 'extra\n'  > "$REPO_DIR/files-testm/.config/t/extra"
  echo "~/.config/t" > "$REPO_DIR/paths.conf"

  HOME=$TEST_HOME bash "$REPO_DIR/deploy.sh" testm
  [ "$(cat "$TEST_HOME/.config/t/shared")"  = "shared" ]
  [ "$(cat "$TEST_HOME/.config/t/layered")" = "$(printf 'base\ntail')" ]
  [ "$(cat "$TEST_HOME/.config/t/extra")"   = "extra" ]
}

@test "deploy: errors when the named machine dir does not exist" {
  printf 'base\n' > "$REPO_DIR/files/.testrc"

  HOME=$TEST_HOME run bash "$REPO_DIR/deploy.sh" nosuch
  [ "$status" -eq 1 ]
  [[ "$output" == *"files-nosuch/ does not exist"* ]]
}

# ---------- machine-scoped paths ----------

@test "scoped path: deployed only to a machine it names" {
  printf 'mac only\n' > "$REPO_DIR/files-testm/.testrc"
  printf '~/.testrc    @testm\n' > "$REPO_DIR/paths.conf"

  HOME=$TEST_HOME bash "$REPO_DIR/deploy.sh" testm
  [ -f "$TEST_HOME/.testrc" ]
}

@test "scoped path: skipped on a machine it does not name, without warning" {
  mkdir -p "$REPO_DIR/files-other"
  printf 'mac only\n' > "$REPO_DIR/files-testm/.testrc"
  printf '~/.testrc    @testm\n' > "$REPO_DIR/paths.conf"

  HOME=$TEST_HOME run bash "$REPO_DIR/deploy.sh" other
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_HOME/.testrc" ]
  [[ "$output" != *"[warn]"* ]]
}

@test "scoped path: skipped on a base run with no machine named" {
  printf 'base\n' > "$REPO_DIR/files/.testrc"
  printf '~/.testrc    @testm\n' > "$REPO_DIR/paths.conf"

  HOME=$TEST_HOME bash "$REPO_DIR/deploy.sh"
  [ ! -f "$TEST_HOME/.testrc" ]
}

@test "scoped path: not collected from a machine it does not name" {
  mkdir -p "$REPO_DIR/files-other"
  printf 'stray\n' > "$TEST_HOME/.testrc"
  printf '~/.testrc    @testm\n' > "$REPO_DIR/paths.conf"

  HOME=$TEST_HOME bash "$REPO_DIR/collect.sh" other
  [ ! -f "$REPO_DIR/files-other/.testrc" ]
  [ ! -f "$REPO_DIR/files/.testrc" ]
}

@test "scoped path: accepts a comma-separated machine list" {
  printf 'shared\n' > "$REPO_DIR/files/.testrc"
  printf '~/.testrc    @other,testm\n' > "$REPO_DIR/paths.conf"

  HOME=$TEST_HOME bash "$REPO_DIR/deploy.sh" testm
  [ "$(cat "$TEST_HOME/.testrc")" = "shared" ]
}

# ---------- collect ----------

@test "collect: a tail added on the machine is stored as .append" {
  printf 'base\n'        > "$REPO_DIR/files/.testrc"
  printf 'base\ntail\n'  > "$TEST_HOME/.testrc"

  HOME=$TEST_HOME bash "$REPO_DIR/collect.sh" testm
  [ "$(cat "$REPO_DIR/files-testm/.testrc.append")" = "tail" ]
  [ ! -f "$REPO_DIR/files-testm/.testrc" ]
}

@test "collect: an edit inside the base region becomes a full override, with a warning" {
  printf 'base\n'          > "$REPO_DIR/files/.testrc"
  printf 'tail\n'          > "$REPO_DIR/files-testm/.testrc.append"
  printf 'CHANGED\ntail\n' > "$TEST_HOME/.testrc"

  HOME=$TEST_HOME run bash "$REPO_DIR/collect.sh" testm
  [ "$status" -eq 0 ]
  [[ "$output" == *"no longer extends base"* ]]
  [ ! -f "$REPO_DIR/files-testm/.testrc.append" ]
  [ "$(cat "$REPO_DIR/files-testm/.testrc")" = "$(printf 'CHANGED\ntail')" ]
}

@test "collect: a machine file that matches base drops its overlay" {
  printf 'base\n'  > "$REPO_DIR/files/.testrc"
  printf 'old\n'   > "$REPO_DIR/files-testm/.testrc"
  printf 'base\n'  > "$TEST_HOME/.testrc"

  HOME=$TEST_HOME bash "$REPO_DIR/collect.sh" testm
  [ ! -f "$REPO_DIR/files-testm/.testrc" ]
  [ ! -f "$REPO_DIR/files-testm/.testrc.append" ]
}

@test "collect: never writes to the base layer when a machine is named" {
  printf 'base\n'    > "$REPO_DIR/files/.testrc"
  printf 'changed\n' > "$TEST_HOME/.testrc"

  HOME=$TEST_HOME bash "$REPO_DIR/collect.sh" testm
  [ "$(cat "$REPO_DIR/files/.testrc")" = "base" ]
}

@test "collect: an overlay whose file is gone locally is pruned" {
  mkdir -p "$REPO_DIR/files/.config/t" "$REPO_DIR/files-testm/.config/t" "$TEST_HOME/.config/t"
  printf 'keep\n'  > "$REPO_DIR/files/.config/t/keep"
  printf 'keep\n'  > "$TEST_HOME/.config/t/keep"
  printf 'stale\n' > "$REPO_DIR/files-testm/.config/t/stale"
  echo "~/.config/t" > "$REPO_DIR/paths.conf"

  HOME=$TEST_HOME run bash "$REPO_DIR/collect.sh" testm
  [ "$status" -eq 0 ]
  [ ! -f "$REPO_DIR/files-testm/.config/t/stale" ]
}

@test "deploy then collect is idempotent" {
  printf 'base\n'  > "$REPO_DIR/files/.testrc"
  printf 'tail\n'  > "$REPO_DIR/files-testm/.testrc.append"
  cp -r "$REPO_DIR/files-testm" "$REPO_DIR/before"

  HOME=$TEST_HOME bash "$REPO_DIR/deploy.sh"  testm
  HOME=$TEST_HOME bash "$REPO_DIR/collect.sh" testm

  run diff -r "$REPO_DIR/before" "$REPO_DIR/files-testm"
  [ "$status" -eq 0 ]
}
