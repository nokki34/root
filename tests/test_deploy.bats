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

@test "deploy reports identical files as skipped" {
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
