# SeTcbPrivilege-Sliver-C2-Extension

Sliver C2 extension for Windows local privilege escalation via `SeTcbPrivilege` abuse. Enables `SeTcbPrivilege`, hooks `AcquireCredentialsHandleW` to spoof the SYSTEM LUID, then creates/starts a Windows service running an arbitrary command as **NT AUTHORITY\SYSTEM**.

Forked from [CharminDoge/tcb-lpe](https://github.com/CharminDoge/tcb-lpe). Original authors: [@splinter_code](https://gist.github.com/antonioCoco/19563adef860614b56d010d92e67d178) and [@decoder_it](https://gist.github.com/antonioCoco/19563adef860614b56d010d92e67d178).

## How It Works

1. **Enable `SeTcbPrivilege`** — Opens the current process token with `TOKEN_ALL_ACCESS`, looks up the LUID for `SeTcbPrivilege`, adjusts the token to enable it, and verifies with `PrivilegeCheck`.
2. **Hook `AcquireCredentialsHandleW`** — Overwrites the function pointer in the SecurityFunctionTable returned by `InitSecurityInterfaceW` with a hook that forces the _logon ID_ to `SYSTEM_LUID` (`0x3E7`), impersonating SYSTEM at the SSPI layer.
3. **Service Creation & Execution** — Connects to SCM on `127.0.0.1`, creates a temporary Windows service (`AAATcb`) with the supplied command, starts it, then auto-cleans the service upon completion.
4. **Cleanup** — `tcb clean` removes the service without executing anything.

> **Prerequisite:** The current process must already hold `SeTcbPrivilege` (typically obtained via Sliver's `getsystem` or by running in a high-integrity context).

## Installation

### Within Sliver (armory)

```sliver
armory install SeTcbPrivilege
```

### Manual

```sliver
extensions install /path/to/SeTcbPrivilege-Sliver-C2-Extension
```

## Usage

```sliver
tcb -- "C:\Windows\system32\cmd.exe /c whoami"
tcb -- "C:\Windows\system32\net.exe localgroup Administrators user /add"
tcb clean
```

![Usage screenshot](https://github.com/user-attachments/assets/cf48e907-36f6-4ad1-afee-a7a559dd6711)

## Build

### Prerequisites

- Go ≥ 1.24
- MinGW-w64 (for DLL cross-compilation):
  - **Linux:** `apt install mingw-w64`
  - **macOS:** `brew install mingw-w64`
  - **Windows (MSYS2):** `pacman -S mingw-w64-x86_64-gcc`

### Targets

| Target | Output | Description |
|--------|--------|-------------|
| `make build` | `tcb.exe` | Standalone EXE (no CGO) |
| `make dll` | `tcb.x64.dll` | C-shared DLL amd64 (for Sliver) |
| `make dll_32` | `tcb.32.dll` | C-shared DLL x86 |
| `make dll_arm64` | `tcb.arm64.dll` | C-shared DLL arm64 (experimental) |
| `make all` | all above | Build all targets |
| `make clean` | — | Remove build artifacts |
| `make check` | — | Verify toolchain |

```bash
# Build the Sliver extension DLL
make dll

# Build standalone EXE (no cross-compiler needed)
make build
```

## Extension Metadata

- **Extension name:** `SeTcbPrivilege`
- **Command name:** `tcb`
- **Version:** `1.1.0`
- **Author:** [Raj Chowdhury](https://github.com/RajChowdhury240)
- **Original authors:** XCT, Doge, @splinter_code, @decoder_it

## Credits

- [@splinter_code](https://gist.github.com/antonioCoco/19563adef860614b56d010d92e67d178) and [@decoder_it](https://gist.github.com/antonioCoco/19563adef860614b56d010d92e67d178) — original SeTcbPrivilege PoC
- [CharminDoge/tcb-lpe](https://github.com/CharminDoge/tcb-lpe) — original Sliver extension
