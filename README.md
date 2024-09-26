# Certora Customized Rust/Clang toolchain for Solana Platform

Based on the scripts from https://github.com/anza-xyz/platform-tools/

Builds Clang and Rust compilers and libraries that are customized by Certora, and
are not yet upstreamed to Rust and LLVM teams.

### First time

This repo is a collection of shell scripts and [just](https://github.com/casey/just) recipies.
If you are lucky (i.e., have all the right libraries and compilation just
works), then the following should just work:

```bash
$ just all
$ just deploy
```

This clones all the necessary repositories, applies Certora patches, compiles,
and then deploys the new toolchain. The new toolchain will overwrite any
existing one. An existing toolchain is expected to be in place to ensure that
the rest of Solana CLI is configured properly.

### Step by step

If there are issues with complete automation, follow the step-by-step instructions:

```bash
$ just clone
$ just prepare
$ just build-rust
$ just build-cargo
$ just build-newlib
$ just package
$ just deploy
```

There is a known problem with MacPorts version of `libiconv` and `cargo`. Some
time it might might be necessary to disable `libiconv` while building `cargo`.

```bash
$ sudo port -f deactivate libiconv
BUILD CARGO MANUALLY'
$ sudo port activate libiconv
```

### Rebuild

To rebuild after a change in LLVM and/or Rust

```bash
$ just rebuild
```

To rebuild and redeploy together

```bash
$ just redeploy
```

### Installation of executables

1. Create directory `$HOME/platform-tools-certora`
2. Uncompress using your favourite tool
   `executables/mac/platform-tools-osx-aarch64.tar.bz2` or
   `executables/linux/platform-tools-linux-x86_64.tar.bz2` in
   `$HOME/platform-tools-certora`.

   Verify that `$HOME/platform-tools-certora` contains `llvm` and `rust`:
   ```shell
   ls $HOME/platform-tools-certora/
   llvm       rust       version.md
   ```
   *  On macOS, you need to adjust the permissions for the executables and dynamic libraries:
      ```shell
      sudo xattr -rd com.apple.quarantine $HOME/platform-tools-certora
      ```
3. cd `$HOME/.cache/solana/v1.41`
4. Backup `platform-tools`: `mv platform-tools platform-tools-backup`
5. `ln -sf $HOME/platform-tools-certora ./platform-tools`
