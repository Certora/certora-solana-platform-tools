# Certora Customized Rust/Clang toolchain for Solana Platform

Based on the scripts from https://github.com/anza-xyz/platform-tools/

Builds Clang and Rust compilers and libraries that are customized by Certora, and
are not yet upstreamed to Rust and LLVM teams.

## Installation of executables

The preferred way to install certora platform tools is to use our
released binaries.

1. Create directory `$HOME/platform-tools-certora`

2. Go to releases (https://github.com/Certora/certora-solana-platform-tools/releases) and download the right executable for your machine. **Please, make sure you download the latest version**.

3. Uncompress using your favourite tool the tar.bz2 file in `$HOME/platform-tools-certora`.

   Verify that `$HOME/platform-tools-certora` contains `llvm` and `rust`:
   ```shell
   ls $HOME/platform-tools-certora/
   llvm       rust       version.md
   ```
   *  On macOS, you might need to adjust the permissions for the executables and dynamic libraries:
      ```shell
      sudo xattr -rd com.apple.quarantine $HOME/platform-tools-certora
      ```
3. cd `$HOME/.cache/solana/v1.41`

   If this directory does not exist then you need to install first Solana platform-tools.

   ```
   cd $HOME/.local/share/solana/install/active_release/bin/sdk/sbf
   source env.sh
   ```

5. Backup `platform-tools`: `mv platform-tools platform-tools-backup`
6. `ln -sf $HOME/platform-tools-certora ./platform-tools`

### Known problems

If you get this error:

```
Finished release [optimized] target(s) in 0.20s
dyld[83246]: Library not loaded: /opt/local/lib/libz.1.dylib
  Referenced from: <AB7A9406-4C8E-336E-ABD7-5E95DBE589C1> /Users/gadiauerbach/platform-tools-certora/llvm/bin/llvm-objcopy
  Reason: tried: '/opt/local/lib/libz.1.dylib' (no such file), '/System/Volumes/Preboot/Cryptexes/OS/opt/local/lib/libz.1.dylib' (no such file), '/opt/local/lib/libz.1.dylib' (no such file)
/Users/gadiauerbach/.local/share/solana/install/releases/1.18.16/solana-release/bin/sdk/sbf/scripts/strip.sh: line 23: 83246 Abort trap: 6           "$sbf_sdk"/dependencies/platform-tools/llvm/bin/llvm-objcopy --strip-all "$so" "$so_stripped"
error: Recipe `build-sbf` failed on line 12 with exit code 1
```

Then, type the following command:

```
cp $HOME/.cache/solana/v1.41/platform-tools-backup/llvm/bin/llvm-objcopy $HOME/.cache/solana/v1.41/platform-tools/llvm/bin/
```

## Compiling the binaries

Currently this might not work, depending on the version of clang you
have installed, since the generated assembly code might not compile on
your compiler.

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

There is a known problem with LLVM >17 cannot build LLVM17. Use LLVM17 to build.
Note that rust calls system `cc` compiler instead of specificly provided compiler.
Make sure that `cc` resolves to `clang17`.

### Rebuild

To rebuild after a change in LLVM and/or Rust

```bash
$ just rebuild
```

To rebuild and redeploy together

```bash
$ just redeploy
```


