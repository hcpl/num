#!/bin/bash

set -ex

echo Testing num on rustc ${TRAVIS_RUST_VERSION}

# All of these packages should build and test everywhere.
for package in bigint complex integer iter rational traits; do
  if [ "$TRAVIS_RUST_VERSION" = 1.8.0 ]; then
    # libc 0.2.34 started using #[deprecated]
    cargo generate-lockfile --manifest-path $package/Cargo.toml
    cargo update --manifest-path $package/Cargo.toml --package libc --precise 0.2.33 || :
  fi
  cargo build --manifest-path $package/Cargo.toml
  cargo test --manifest-path $package/Cargo.toml
done

# They all should build with minimal features too
for package in bigint complex integer iter rational traits; do
  cargo build --manifest-path $package/Cargo.toml --no-default-features
  cargo test --manifest-path $package/Cargo.toml --no-default-features
done

# Each isolated feature should also work everywhere.
for feature in '' bigint rational complex; do
  cargo build --verbose --no-default-features --features="$feature"
  cargo test --verbose --no-default-features --features="$feature"
done

# Build test for the serde feature
cargo build --verbose --features "serde"

# Downgrade serde and build test the 0.7.0 channel as well
cargo update -p serde --precise 0.7.0
cargo build --verbose --features "serde"


if [ "$TRAVIS_RUST_VERSION" = 1.8.0 ]; then exit; fi

# num-derive should build on 1.15.0+
cargo build --verbose --manifest-path=derive/Cargo.toml


if [ "$TRAVIS_RUST_VERSION" != nightly ]; then exit; fi

# num-derive testing requires compiletest_rs, which requires nightly
cargo test --verbose --manifest-path=derive/Cargo.toml

# benchmarks only work on nightly
cargo bench --verbose
