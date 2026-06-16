# SeTcbPrivilege LPE - Cross-platform Makefile
# Host OS: auto-detected (Linux, macOS, Windows via MSYS2)

GOOS      ?= windows
GOFLAGS   ?= -ldflags "-s -w"
OUTPUT    ?= tcb.exe
DLL_X64   ?= tcb.x64.dll
DLL_X86   ?= tcb.32.dll
DLL_ARM64 ?= tcb.arm64.dll

# Detect host OS for platform-specific defaults
UNAME_S := $(shell uname -s 2>/dev/null || echo Windows)

# MinGW cross-compiler selection
# Linux:   apt install mingw-w64          -> x86_64-w64-mingw32-gcc
# macOS:   brew install mingw-w64          -> x86_64-w64-mingw32-gcc
# Windows (MSYS2): pacman -S mingw-w64-x86_64-gcc -> x86_64-w64-mingw32-gcc
CC_x64    ?= x86_64-w64-mingw32-gcc
CC_x86    ?= i686-w64-mingw32-gcc
CC_arm64  ?= aarch64-w64-mingw32-gcc

# macOS ARM needs Rosetta 2 for x86_64 cross-compiler;
# native aarch64 MinGW may not be widely available, so fallback gracefully.
ifeq ($(UNAME_S),Darwin)
  ARCH := $(shell uname -m)
  ifeq ($(ARCH),arm64)
    # brew install mingw-w64 gives x86_64-w64-mingw32-gcc (runs under Rosetta 2)
    # aarch64 variant is not commonly packaged.
  endif
endif

.PHONY: all build dll dll_32 dll_arm64 clean check help

all: build dll

help:
	@echo "Targets:"
	@echo "  build      - Standalone EXE (CGO disabled, universal)"
	@echo "  dll        - C-shared DLL amd64 (for Sliver C2)"
	@echo "  dll_32     - C-shared DLL x86"
	@echo "  dll_arm64  - C-shared DLL arm64 (experimental)"
	@echo "  all        - build + dll"
	@echo "  clean      - Remove all build artifacts"
	@echo "  check      - Verify toolchain availability"
	@echo ""
	@echo "Variables (all overridable):"
	@echo "  CC_x64   = $(CC_x64)"
	@echo "  CC_x86   = $(CC_x86)"
	@echo "  CC_arm64 = $(CC_arm64)"
	@echo "  GOFLAGS  = $(GOFLAGS)"
	@echo ""
	@echo "Host OS: $(UNAME_S)"
	@echo "To build locally (no cross-compiler needed):"
	@echo "  $$ make build"
	@echo "To cross-compile DLL (requires MinGW):"
	@echo "  $$ make dll"
	@echo "  $$ make dll CC_x64=x86_64-w64-mingw32-gcc-posix  (some Linux distros)"

# Standalone EXE — no C compiler needed, works on any host OS
build:
	CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=amd64 go build $(GOFLAGS) -o $(OUTPUT)

# 64-bit C-shared DLL (matching extension.json -> tcb.x64.dll)
dll:
	CGO_ENABLED=1 GOOS=$(GOOS) GOARCH=amd64 CC=$(CC_x64) go build -buildmode=c-shared $(GOFLAGS) -o $(DLL_X64)

# 32-bit C-shared DLL
dll_32:
	CGO_ENABLED=1 GOOS=$(GOOS) GOARCH=386 CC=$(CC_x86) go build -buildmode=c-shared $(GOFLAGS) -o $(DLL_X86)

# ARM64 C-shared DLL (experimental — host CC_arm64 must exist)
dll_arm64:
	CGO_ENABLED=1 GOOS=$(GOOS) GOARCH=arm64 CC=$(CC_arm64) go build -buildmode=c-shared $(GOFLAGS) -o $(DLL_ARM64)

clean:
	rm -f $(OUTPUT) $(DLL_X64) $(DLL_X86) $(DLL_ARM64) tcb.x64.h tcb.32.h tcb.arm64.h

check:
	@echo "=== Host OS: $(UNAME_S) ==="
	@echo ""
	@echo "[CC x64]"
	which $(CC_x64) 2>/dev/null && $(CC_x64) --version | head -1 || echo "  NOT FOUND — install mingw-w64"
	@echo ""
	@echo "[CC x86]"
	which $(CC_x86) 2>/dev/null && $(CC_x86) --version | head -1 || echo "  NOT FOUND — install mingw-w64"
	@echo ""
	@echo "[CC arm64]"
	which $(CC_arm64) 2>/dev/null && $(CC_arm64) --version | head -1 || echo "  NOT FOUND — optional, for arm64 target"
	@echo ""
	@echo "[Go]"
	go version
	@echo ""
	@echo "[golang.org/x/sys]"
	go list -m golang.org/x/sys 2>/dev/null || echo "  run: go mod tidy"
