#!/usr/bin/env bash
set -ex

unameOut="$(uname -s)"
case "${unameOut}" in
    Darwin*)
        EXE_SUFFIX=
        if [[ "$(uname -m)" == "arm64" ]] || [[ "$(uname -m)" == "aarch64" ]]; then
            HOST_TRIPLE=aarch64-apple-darwin
            ARTIFACT=platform-tools-osx-aarch64.tar.bz2
        else
            HOST_TRIPLE=x86_64-apple-darwin
            ARTIFACT=platform-tools-osx-x86_64.tar.bz2
        fi;;
    MINGW*)
        EXE_SUFFIX=.exe
        HOST_TRIPLE=x86_64-pc-windows-msvc
        ARTIFACT=platform-tools-windows-x86_64.tar.bz2;;
    Linux* | *)
        EXE_SUFFIX=
        if [[ "$(uname -m)" == "arm64" ]] || [[ "$(uname -m)" == "aarch64" ]]; then
            HOST_TRIPLE=aarch64-unknown-linux-gnu
            ARTIFACT=platform-tools-linux-aarch64.tar.bz2
        else
            HOST_TRIPLE=x86_64-unknown-linux-gnu
            ARTIFACT=platform-tools-linux-x86_64.tar.bz2
        fi
esac

OUT_DIR=$(realpath "${1:-out}")

pushd "${OUT_DIR}"

# Copy rust build products
mkdir -p deploy/rust

cp version.md deploy/
cp -R "rust/build/${HOST_TRIPLE}/stage1/bin" deploy/rust/
cp -R "cargo/target/release/cargo${EXE_SUFFIX}" deploy/rust/bin/
mkdir -p deploy/rust/lib/rustlib/
cp -R "rust/build/${HOST_TRIPLE}/stage1/lib/rustlib/${HOST_TRIPLE}" deploy/rust/lib/rustlib/
cp -R "rust/build/${HOST_TRIPLE}/stage1/lib/rustlib/sbf-solana-solana" deploy/rust/lib/rustlib/
find . -maxdepth 6 -type f -path "./rust/build/${HOST_TRIPLE}/stage1/lib/*" -exec cp {} deploy/rust/lib \;
mkdir -p deploy/rust/lib/rustlib/src/rust
cp "rust/build/${HOST_TRIPLE}/stage1/lib/rustlib/src/rust/Cargo.lock" deploy/rust/lib/rustlib/src/rust
cp -R "rust/build/${HOST_TRIPLE}/stage1/lib/rustlib/src/rust/library" deploy/rust/lib/rustlib/src/rust

# Copy llvm build products
mkdir -p deploy/llvm/{bin,lib}
while IFS= read -r f
do
    bin_file="rust/build/${HOST_TRIPLE}/llvm/build/bin/${f}${EXE_SUFFIX}"
    if [[ -f "$bin_file" ]] ; then
        cp -R "$bin_file" deploy/llvm/bin/
    fi
done < <(cat <<EOF
clang
clang++
clang-cl
clang-cpp
clang-17
ld.lld
ld64.lld
llc
lld
lld-link
lldb
lldb-vscode
llvm-ar
llvm-objcopy
llvm-objdump
llvm-readelf
llvm-readobj
llvm-addr2line
llvm-symbolizer
opt
EOF
         )
cp -R "rust/build/${HOST_TRIPLE}/llvm/build/lib/clang" deploy/llvm/lib/
if [[ "${HOST_TRIPLE}" != "x86_64-pc-windows-msvc" ]] ; then
    cp -R newlib_install/sbf-solana/lib/lib{c,m}.a deploy/llvm/lib/
    cp -R newlib_install/sbf-solana/include deploy/llvm/
    cp -R rust/src/llvm-project/lldb/scripts/solana/* deploy/llvm/bin/
    cp -R rust/build/${HOST_TRIPLE}/llvm/lib/liblldb.* deploy/llvm/lib/
    #cp -R rust/build/${HOST_TRIPLE}/llvm/lib/python* deploy/llvm/lib/
fi

# Sign macOS binaries - Disabled
# if [[ $HOST_TRIPLE == *apple-darwin* ]] && [[ ! -z "$APPLE_CODESIGN_IDENTITY" ]]; then
#     LLVM_BIN="./deploy/llvm/bin"
#     RUST_BIN="./deploy/rust/bin"
#     RUST_LIB="./deploy/rust/lib"
#     RUST_LIB_BIN="$RUST_LIB/rustlib/aarch64-apple-darwin/bin"

#     ../scripts/sign.sh \
#         "$LLVM_BIN/llvm-objdump" \
#         "$LLVM_BIN/llvm-ar" \
#         "$LLVM_BIN/llvm-readobj" \
#         "$LLVM_BIN/llvm-objcopy" \
#         "$RUST_BIN/rustdoc" \
#         "$RUST_BIN/cargo" \
#         "$RUST_LIB/librustc_driver-b4e91886a4c059a0.dylib" \
#         "$RUST_LIB/libstd-6eff127b55c063c2.dylib" \
#         "$RUST_LIB_BIN/rust-lld"
#        # "$RUST_BIN/rustc" # Not signing 'rustc' duo to failing cargo build
# fi

# Check the Rust binaries
while IFS= read -r f
do
    "./deploy/rust/bin/${f}${EXE_SUFFIX}" --version
done < <(cat <<EOF
cargo
rustc
rustdoc
EOF
         )
# Check the LLVM binaries
while IFS= read -r f
do
    if [[ -f "./deploy/llvm/bin/${f}${EXE_SUFFIX}" ]] ; then
        "./deploy/llvm/bin/${f}${EXE_SUFFIX}" --version
    fi
done < <(cat <<EOF
clang
clang++
clang-cl
clang-cpp
ld.lld
llc
lld-link
llvm-ar
llvm-objcopy
llvm-objdump
llvm-readelf
llvm-readobj
solana-lldb
EOF
         )

tar -C deploy -jcf ${ARTIFACT} .

popd
