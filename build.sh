#!/bin/bash
# build.sh - Build script for LM Studio Code VS Code extension
#
# Usage: ./build.sh [options]
# Options:
#   --bundled    Bundle OpenCode binary into the VSIX (default: true)
#   --target     Target platform for bundled build (e.g., linux-x64, win32-x64, darwin-arm64)
#                If not specified, auto-detects from current platform
#   --out        Output directory (default: ./releases)
#   --help       Show this help message
#
# Examples:
#   ./build.sh                    # Build with bundled binary, auto-detect target
#   ./build.sh --bundled          # Same as above (explicit bundled flag)
#   ./build.sh --no-bundled       # Build without bundling OpenCode
#   ./build.sh --target win32-x64 # Bundle for Windows 64-bit
#   ./build.sh --out ./dist       # Output to custom directory

set -euo pipefail

# Default values
BUNDLED=true
TARGET=""
OUT_DIR="./releases"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect npm/npx command (try multiple approaches)
# Note: Hermit environment has npm in /home/alessandro/.config/goose/mcp-hermit/bin/
if [[ -x "$SCRIPT_DIR/node_modules/.bin/npm" ]]; then
    NPM_CMD="$SCRIPT_DIR/node_modules/.bin/npm"
elif [[ -x "/home/alessandro/.config/goose/mcp-hermit/bin/npm" ]]; then
    # Hermit environment has npm but it might not be in PATH
    echo "Using hermit npm from /home/alessandro/.config/goose/mcp-hermit/bin/"
    NPM_CMD="/home/alessandro/.config/goose/mcp-hermit/bin/npm"
elif type -P npm &> /dev/null; then
    NPM_CMD="npm"
elif [[ -x "/home/alessandro/.config/goose/mcp-hermit/bin/npx" ]]; then
    # Fallback to npx if npm is not available
    echo "Warning: npm not found in PATH, using hermit npx"
    NPM_CMD="/home/alessandro/.config/goose/mcp-hermit/bin/npx"
elif type -P npx &> /dev/null; then
    echo "Warning: npm not found, using npx (some commands may fail)"
    NPM_CMD="npx"
else
    echo "Error: Could not find npm or npx. Please install Node.js."
    exit 1
fi

# Check if dependencies exist
DEPS_EXIST=false
if [[ -d "$SCRIPT_DIR/node_modules" ]]; then
    # Use npm ls to check for dependencies
    if $NPM_CMD ls --depth=0 @vscode/vsce &> /dev/null; then
        DEPS_EXIST=true
    fi
fi

# Install dependencies if they don't exist
if [[ "$DEPS_EXIST" != "true" ]]; then
    echo "Installing dependencies..."
    cd "$SCRIPT_DIR"
    
    # Install dependencies using npm
    if ! $NPM_CMD ci --ignore-scripts; then
        echo "$NPM_CMD ci failed, falling back to $NPM_CMD install..."
        $NPM_CMD install
    fi
    
    # Update NPM_CMD if we now have npm available locally
    if [[ -x "$SCRIPT_DIR/node_modules/.bin/npm" ]]; then
        NPM_CMD="$SCRIPT_DIR/node_modules/.bin/npm"
    fi
fi

# Verify vsce is available (as a dev dependency in package.json)
if ! $NPM_CMD ls --depth=0 @vscode/vsce &> /dev/null; then
    echo "Error: @vscode/vsce not found. Run npm install first."
    exit 1
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --bundled)
            BUNDLED=true
            shift
            ;;
        --no-bundled)
            BUNDLED=false
            shift
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --out)
            OUT_DIR="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --bundled     Bundle OpenCode binary into the VSIX (default: true)"
            echo "  --no-bundled  Build without bundling OpenCode"
            echo "  --target      Target platform for bundled build (e.g., linux-x64, win32-x64, darwin-arm64)"
            echo "                If not specified, auto-detects from current platform"
            echo "  --out         Output directory (default: ./releases)"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Determine target platform if not specified and bundling is enabled
if [[ "$BUNDLED" == "true" && -z "$TARGET" ]]; then
    cd "$SCRIPT_DIR"
    PLATFORM=$($NPM_CMD exec -- node -p "process.platform")
    ARCH=$($NPM_CMD exec -- node -p "process.arch")

    case "$PLATFORM-$ARCH" in
        "linux-x64")   TARGET="linux-x64" ;;
        "linux-arm64") TARGET="linux-arm64" ;;
        "win32-x64")   TARGET="win32-x64" ;;
        "win32-ia32")  TARGET="win32-ia32" ;;
        "darwin-x64")  TARGET="darwin-x64" ;;
        "darwin-arm64") TARGET="darwin-arm64" ;;
        *)
            echo "Error: Unsupported platform $PLATFORM-$ARCH"
            echo "Please specify --target explicitly (e.g., --target linux-x64)"
            exit 1
            ;;
    esac
    echo "Auto-detected target: $TARGET"
fi

# Verify vsce is available
if ! $NPM_CMD ls --depth=0 | grep -q "@vscode/vsce"; then
    echo "Error: @vscode/vsce not found. Run npm install first."
    exit 1
fi

# Check for npm dependencies
if [[ ! -d "$SCRIPT_DIR/node_modules" ]]; then
    echo "Installing dependencies..."
    cd "$SCRIPT_DIR"
    if ! $NPM_CMD ci --ignore-scripts; then
        echo "$NPM_CMD ci failed, falling back to $NPM_CMD install..."
        $NPM_CMD install
    fi
fi

# Clean previous build artifacts
echo "Cleaning previous builds..."
cd "$SCRIPT_DIR"

# Create output directory
mkdir -p "$OUT_DIR"

# Compile TypeScript and build with esbuild
echo "Building extension..."
if [[ "$BUNDLED" == "true" ]]; then
    echo "Bundling OpenCode binary for $TARGET..."
    cd "$SCRIPT_DIR"
    $NPM_CMD run bundle:opencode
fi

# Package the extension
echo "Creating VSIX package..."
cd "$SCRIPT_DIR"

if [[ "$BUNDLED" == "true" ]]; then
    # Bundle and package with optional target
    if [[ -n "$TARGET" ]]; then
        echo "Packaging for $TARGET..."
        export VSCE_TARGET="$TARGET"
        $NPM_CMD run package:vsix:bundled -- --out "$OUT_DIR"
    else
        # No explicit target, let vsce auto-detect
        $NPM_CMD run bundle:opencode && $NPM_CMD exec -- vsce package --out "$OUT_DIR"
    fi
else
    # No bundling - remove opencode binary before packaging, restore after
    echo "Packaging without OpenCode binary..."
    
    # Remove bin/opencode if it exists (will be restored on exit if needed)
    OPENCODE_BAK=""
    OPENCODE_VER_BAK=""
    if [[ -f "$SCRIPT_DIR/bin/opencode" ]]; then
        OPENCODE_BAK="/tmp/.opencode.bak.$$"
        mv "$SCRIPT_DIR/bin/opencode" "$OPENCODE_BAK"
        # Also save the version file
        if [[ -f "$SCRIPT_DIR/bin/opencode.version" ]]; then
            OPENCODE_VER_BAK="/tmp/.opencode.version.bak.$$"
            mv "$SCRIPT_DIR/bin/opencode.version" "$OPENCODE_VER_BAK"
        fi
        
        # Set up cleanup on exit to restore files
        trap 'if [[ -f "$OPENCODE_BAK" ]]; then mv "$OPENCODE_BAK" "$SCRIPT_DIR/bin/opencode"; else rm -f "$SCRIPT_DIR/bin/opencode"; fi; if [[ -n "$OPENCODE_VER_BAK" && -f "$OPENCODE_VER_BAK" ]]; then mv "$OPENCODE_VER_BAK" "$SCRIPT_DIR/bin/opencode.version"; else rm -f "$SCRIPT_DIR/bin/opencode.version"; fi' EXIT
    fi
    
    $NPM_CMD run package:vsix -- --out "$OUT_DIR"
fi

# Verify the output
if ls "$OUT_DIR"/*.vsix &>/dev/null; then
    echo ""
    echo "Build successful!"
    echo "VSIX packages created in: $OUT_DIR/"
    ls -lh "$OUT_DIR"/*.vsix
else
    echo ""
    echo "Build failed - no VSIX file found"
    exit 1
fi
