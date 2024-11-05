out_dir := justfile_directory() / 'out'

host_triple := if os() == 'macos' { arch() + "-apple-darwin" 
	} else if os() == 'linux' { arch() + "-unknown-linux-gnu" 
	} else if os() == 'windows' { arch() + "-pc-windows-msvc"
	} else { arch() + "-unknown-unknown" }

artifact := if os() == 'macos' { "platform-tools-osx-" + arch() + ".tar.bz2"
	} else if os() == 'linux' {  "platform-tools-linux-" + arch() + ".tar.bz2"
	} else if os() == 'windows' { "platform-tools-windows-" + arch() + ".tar.bz2"
	} else { arch()+"-unknown-unknown" }

clone:
	mkdir -p {{ out_dir }}
	./scripts/git-clone.sh

configure:
	./scripts/prepare.sh

patch:
	cd {{ out_dir }}/rust && git apply {{justfile_directory()}}/patches/01-rust-novector.patch
	cd {{ out_dir }}/rust/src/llvm-project && git apply {{justfile_directory()}}/patches/02-llvm-sroa-novector.patch


build-rust:
	cd {{ out_dir }}/rust && ./build.sh --llvm 

[macos,windows]
build-cargo:
	# AG: this fails for me with macport and libiconv
	# AG: I have to disable libiconv, run this manually
	# AG: and then re-enable it
	cd {{ out_dir }}/cargo && cargo update && env OPENSSL_STATIC=1 cargo build --release

[linux]
build-cargo:
	cd {{ out_dir }}/cargo && env OPENSSL_STATIC=1 OPENSSL_LIB_DIR=/usr/lib/x86_64-linux-gnu OPENSSL_INCLUDE_DIR=/usr/include/openssl cargo build --release


[linux,macos]
build-newlib:
	mkdir -p {{out_dir}}/newlib_build
	mkdir -p {{out_dir}}/newlib_install
	cd {{out_dir}}/newlib_build && env CC="{{out_dir}}/rust/build/{{host_triple}}/llvm/bin/clang" AR="{{out_dir}}/rust/build/{{host_triple}}/llvm/bin/llvm-ar" RANLIB="{{out_dir}}/rust/build/{{host_triple}}/llvm/bin/llvm-ranlib" ../newlib/newlib/configure --target=sbf-solana-solana --host=sbf-solana --build="{{host_triple}}" --prefix="{{ out_dir }}/newlib_install"
	cd {{out_dir}}/newlib_build && make install

[windows]
build-newlib:
	@echo "No need to build newlib on Windows"

deploy_dir := env('HOME') / '.cache/solana/v1.41/platform-tools'
artifact_tar := out_dir / artifact

package:
	./scripts/package.sh
	@echo "artifact location: {{ artifact_tar }}"
	@echo "deploy destination: {{ deploy_dir }}"
	@echo "If this is correct, use 'deploy' recipe to deploy automatically"

deploy:
	tar -C {{ deploy_dir }} -xvjf {{ artifact_tar }}

prepare: configure patch
build-all: build-rust build-cargo build-newlib
all: clone prepare build-all package

rebuild: build-rust
redeploy: build-rust package deploy
