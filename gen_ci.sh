#!/bin/bash

set -euxo pipefail

mkdir -p .github/workflows

sed -e 's@\(\${\)@\1{@g' -e 's@\(}\)@\1}@g' > \
.github/workflows/CI.yml <<'EOF'
name: CI

concurrency:
  group: ${ github.workflow }-${ github.ref }
  cancel-in-progress: true

on:
  push:
    branches:
      - master
  pull_request:

jobs:
  # == CHECK == #
  check:
    name: "Check beta stable and MSRV={{MSRV}}"
    runs-on: ubuntu-latest
    strategy:
      matrix:
        rust-toolchain:
          - {{MSRV}}
          - stable
          # Try to guard against a near-future regression.
          - beta
        cargo-locked: ['', '--locked']
        # feature-xxx: ['', '--features xxx']
        exclude:
          # MSRV guarantee only stands for `.lock`-tested dependencies.
          - rust-toolchain: {{MSRV}}
            cargo-locked: ''
    steps:
      - name: Install Rust toolchain
        uses: dtolnay/rust-toolchain@master
        with:
          toolchain: ${ matrix.rust-toolchain }
        id: installed_toolchain

      - name: Override toolchain just in case.
        run: rustup override set ${ steps.installed_toolchain.outputs.name }

      - name: Clone repo
        uses: actions/checkout@v4

      - name: Update `Cargo.lock`
        if: matrix.cargo-locked != '--locked'
        run: cargo update -v

      - name: Cargo check
        run: cargo check ${ matrix.cargo-locked }

  # == TEST == #
  test:
    name: "Run tests"
    runs-on: ${ matrix.os }
    needs: []
    strategy:
      fail-fast: false
      matrix:
        os:
          - ubuntu-latest
          - macos-latest
          - windows-latest
        rust-toolchain:
          - {{MSRV}}
          - stable
    steps:
      - name: Install Rust toolchain
        uses: dtolnay/rust-toolchain@master
        with:
          toolchain: ${ matrix.rust-toolchain }
        id: installed_toolchain

      - name: Override toolchain just in case.
        run: rustup override set ${ steps.installed_toolchain.outputs.name }

      - name: Clone repo
        uses: actions/checkout@v4

      - run: cargo test --lib --tests

      - run: cargo test --doc --features docs-rs
        if: matrix.rust-toolchain != '{{MSRV}}'
        env:
          RUSTC_BOOTSTRAP: 1

  # # == UI TESTS ==
  # ui-test:
  #   name: UI Tests
  #   runs-on: ubuntu-latest
  #   needs: [check]
  #   steps:
  #     - name: Install Rust toolchain
  #       uses: dtolnay/rust-toolchain@stable
  #       id: installed_toolchain
  #
  #     - name: Override toolchain just in case.
  #       run: rustup override set ${ steps.installed_toolchain.outputs.name }
  #
  #     - name: Clone repo
  #       uses: actions/checkout@v4
  #
  #     - name: Cargo UI test
  #       run: cargo test-ui
  #       env:
  #         RUSTC_BOOTSTRAP: 1
  #       with:
  #         command: test-ui

  required-jobs:
    name: 'All the required jobs'
    needs:
      - check
      - test
    runs-on: ubuntu-latest
    if: ${ always() }
    steps:
      - name: 'Check success of the required jobs'
        run: |
          RESULT=$(echo "${ join(needs.*.result, '') }" | sed -e "s/success//g")
          if [ -n "$RESULT" ]; then
            echo "❌"
            false
          fi
          echo "✅"
EOF

sed -e 's@\(\${\)@\1{@g' -e 's@\(}\)@\1}@g' > \
.github/workflows/future-proof.yml <<'EOF'
# Templated by `cargo-generate` using https://github.com/danielhenrymantilla/proc-macro-template
name: Cron CI

on:
  schedule:
    - cron: '0 8 * * 1,5'

jobs:
  # == TEST == #
  test-no-ui:
    name: (Check & Build &) Test
    runs-on: ${ matrix.os }
    strategy:
      fail-fast: false
      matrix:
        os:
          - ubuntu-latest
          - macos-latest
          - windows-latest
        rust-toolchain:
        # Future-proof against non-locked regressions.
          - stable
        # Future-proof against compiler-regressions
          - beta
          - nightly
        cargo-locked: ['', '--locked']
        exclude:
          # Already tested by PR CI.
          - rust-toolchain: stable
            cargo-locked: '--locked'
          # Cursed auto-`nightly`-detection logic from dtolnay's crates may break `--locked`.
          - rust-toolchain: nightly
            cargo-locked: '--locked'
    steps:
      - name: Install Rust toolchain
        uses: dtolnay/rust-toolchain@master
        with:
          toolchain: ${ matrix.rust-toolchain }
        id: installed_toolchain

      - name: Override toolchain just in case.
        run: rustup override set ${ steps.installed_toolchain.outputs.name }

      - name: Clone repo
        uses: actions/checkout@v4

      - name: Update `Cargo.lock`
        if: matrix.cargo-locked != '--locked'
        run: cargo update -v

      - run: cargo test ${ matrix.cargo-locked } --features docs-rs
        env:
          RUSTC_BOOTSTRAP: 1

      # - run: cargo test-ui
      #   if: matrix.rust-toolchain != '{{MSRV}}'
      #   env:
      #     RUSTC_BOOTSTRAP: 1
EOF

rm -- "$0"
