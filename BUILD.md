# Build Documentation

This document describes how to build the LM Studio Code VS Code extension.

## Prerequisites

- Node.js (v20+)
- npm (comes with Node.js)
- Linux, macOS, or Windows

### Hermit Environment Notes

If you're using a hermit-based environment (e.g., Goose), ensure:
- Node.js is available via `/usr/lib/goose/resources/bin/node`
- npm is accessible at `/home/user/.config/goose/mcp-hermit/bin/npm`
- The build script will automatically detect and use the hermit npm if available

## Quick Start

```bash
# Build with bundled OpenCode binary (default)
./build.sh

# Build without OpenCode binary (for testing)
./build.sh --no-bundled

# Build for a specific target platform
./build.sh --target win32-x64

# Output to custom directory
./build.sh --out ./dist
```

## Usage

```bash
./build.sh [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--bundled` | Bundle OpenCode binary into the VSIX (default: true) |
| `--no-bundled` | Build without bundling OpenCode binary |
| `--target <platform>` | Target platform for bundled build (e.g., `linux-x64`, `win32-x64`, `darwin-arm64`) |
| `--out <dir>` | Output directory (default: `./releases`) |
| `--help` | Show this help message |

### Platform Targets

The following platforms are supported:

- `linux-x64`
- `linux-arm64`
- `win32-x64`
- `win32-ia32`
- `darwin-x64`
- `darwin-arm64`

If `--target` is not specified and bundling is enabled, the script auto-detects the current platform.

## Build Modes

### Bundled Mode (Default)

Creates a VSIX package with the OpenCode binary bundled inside. This produces a larger file (~68MB) but provides a complete, self-contained extension.

```bash
./build.sh --bundled                    # Auto-detect target
./build.sh --target linux-arm64         # Specify target platform
```

**Output:** `lmstudio-code-<platform>-<version>.vsix`

### No-Bundled Mode

Creates a VSIX package without the OpenCode binary. This is useful for:
- Development and testing
- Reducing build time
- Creating smaller test packages

```bash
./build.sh --no-bundled
```

**Output:** `lmstudio-code-<version>.vsix` (without platform suffix)

## Output

By default, VSIX files are output to the `./releases` directory:

```
releases/
├── lmstudio-code-linux-x64-0.12.0.vsix
└── lmstudio-code-win32-x64-0.12.0.vsix
```

Customize with `--out`:

```bash
./build.sh --out ./dist
# VSIX files will be in ./dist/
```

## What Gets Packaged

### Bundled Build Includes:
- Extension code (JavaScript/TypeScript)
- OpenCode binary (~180MB) for the target platform
- Media assets (icon, styles, sample GIF)
- License and documentation files

### No-Bundled Build Includes:
- Extension code (JavaScript/TypeScript)
- Media assets (icon, styles, sample GIF)
- License and documentation files
- **Excludes:** OpenCode binary (must be installed separately)

## Troubleshooting

### npm Not Found

If you see `Error: Could not find npm or npx`:

1. Install Node.js from [nodejs.org](https://nodejs.org/)
2. Or ensure hermit is properly configured if using Goose

### Dependency Installation Fails

```bash
# Clean install dependencies
rm -rf node_modules package-lock.json
npm install
./build.sh
```

### Build Fails with Permission Error

Ensure the script is executable:

```bash
chmod +x build.sh
```

## Development Workflow

1. **Test local changes:**
   ```bash
   ./build.sh --no-bundled --out ./dist
   ```

2. **Verify VSIX contents:**
   ```bash
   # Extract and inspect (VSIX is a ZIP file)
   unzip -l ./dist/lmstudio-code-0.12.0.vsix
   ```

3. **Load in VS Code for testing:**
   - Open VS Code
   - Press `Ctrl+Shift+P` → "Extensions: Install from VSIX"
   - Select your built VSIX file

## CI/CD Integration

For automated builds, use:

```bash
# Build all platforms
./build.sh --target linux-x64 --out ./releases/linux
./build.sh --target win32-x64 --out ./releases/windows
./build.sh --target darwin-arm64 --out ./releases/mac
```
