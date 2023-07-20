#!/bin/bash

set -euxo pipefail

mkdir -p .github/workflows

sed -e 's@\(\${\)@\1{@g' -e 's@\(}\)@\1}@g' > \
.github/workflows/CI.yml <<'EOF'
name: CI

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
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
        uses: actions-rs/toolchain@v1
        with:
          profile: minimal
          toolchain: ${ matrix.rust-toolchain }
          override: true

      - name: Clone repo
        uses: actions/checkout@v2

      - name: Update `Cargo.lock`
        if: matrix.cargo-locked != '--locked'
        run: cargo update -v

      - name: Cargo check
        uses: actions-rs/cargo@v1
        with:
          command: check
          args: ${ matrix.cargo-locked }

  # == BUILD & TEST == #
  build-and-test:
    name: Build and test
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
        uses: actions-rs/toolchain@v1
        with:
          profile: default
          override: true
          toolchain: ${ matrix.rust-toolchain }

      - name: Clone repo
        uses: actions/checkout@v2

      - name: cargo test --lib --tests
        uses: actions-rs/cargo@v1
        with:
          command: test
          args: --lib --tests

      - name: cargo test --doc
        if: matrix.rust-toolchain == 'stable'
        uses: actions-rs/cargo@v1
        env:
          RUSTC_BOOTSTRAP: 1
        with:
          command: test
          args: --features better-docs --doc

  # == UI TESTS ==
  ui-test:
    name: UI Tests
    runs-on: ubuntu-latest
    needs: [check]
    steps:
      - name: Install Rust toolchain
        uses: actions-rs/toolchain@v1
        with:
          profile: default
          override: true
          toolchain: stable

      - name: Clone repo
        uses: actions/checkout@v2

      - name: Cargo UI test
        uses: actions-rs/cargo@v1
        env:
          RUSTC_BOOTSTRAP: 1
        with:
          command: test-ui

  required-jobs:
      needs:
        - check
        - build-and-test
      runs-on: ubuntu-latest
      if: ${ always() }
      steps:
        - name: 'All required jobs'
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
  push:
    branches:
      - master
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
          # Future-proof against compiler-regressions
          - beta
          - nightly
        cargo-locked: ['--locked']
        include:
          # Also future-proof against semver breakage from dependencies.
          - rust-toolchain: stable
            cargo-locked: ''
    steps:
      - name: Install Rust toolchain
        uses: actions-rs/toolchain@v1
        with:
          profile: default
          override: true
          toolchain: ${ matrix.rust-toolchain }

      - name: Clone repo
        uses: actions/checkout@v2

      - name: Update `Cargo.lock`
        if: matrix.cargo-locked != '--locked'
        run: cargo update -v

      - name: Cargo test
        uses: actions-rs/cargo@v1
        env:
          RUSTC_BOOTSTRAP: 1
        with:
          command: test
          args: ${ matrix.cargo-locked }

      - name: Cargo test (embed `README.md` + UI)
        if: matrix.rust-toolchain != '{{MSRV}}'
        uses: actions-rs/cargo@v1
        env:
          RUSTC_BOOTSTRAP: 1
        with:
          command: test-ui
EOF

rm -- "$0"
