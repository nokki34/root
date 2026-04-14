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
