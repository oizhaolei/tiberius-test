VERSION = $(patsubst "%",%, $(word 3, $(shell grep version Cargo.toml)))
BUILD_TIME = $(shell date +"%Y/%m/%d %H:%M:%S")
GIT_REVISION = $(shell git log -1 --format="%h")
RUST_VERSION = $(word 2, $(shell rustc -V))
LONG_VERSION = "$(VERSION) ( rev: $(GIT_REVISION), rustc: $(RUST_VERSION), build at: $(BUILD_TIME) )"
BIN_NAME = $(patsubst "%",%, $(word 3, $(shell grep name Cargo.toml)))

export LONG_VERSION

.PHONY: all test clean release_lnx release_win release_mac

all: test

test:
	cargo test

watch:
	cargo watch test

clean:
	cargo clean

release_lnx:
	cargo build --release --target=x86_64-unknown-linux-musl
	mv -v target/x86_64-unknown-linux-musl/release/${BIN_NAME} ./
	mv .env.sample .env
	zip ${BIN_NAME}-v${VERSION}-x86_64-linux.zip ${BIN_NAME} assets/* assets/**/* README.md .env

release_win:
	cargo build --release --target=x86_64-pc-windows-msvc
	mv -v target/x86_64-pc-windows-msvc/release/${BIN_NAME}.exe ./
	mv .env.sample .env
	7z a ${BIN_NAME}-v${VERSION}-x86_64-windows.zip ${BIN_NAME}.exe assets/* assets/**/* README.md .env

release_mac:
	cargo build --release --target=aarch64-apple-darwin
	mv -v target/aarch64-apple-darwin/release/${BIN_NAME} ./
	mv .env.sample .env
	zip ${BIN_NAME}-v${VERSION}-x86_64-mac.zip ${BIN_NAME} assets/* assets/**/* README.md .env

release_rpm:
	mkdir -p target
	cargo rpm build
	cp target/x86_64-unknown-linux-musl/release/rpmbuild/RPMS/x86_64/* ./
