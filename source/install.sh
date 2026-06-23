#!/usr/bin/env bash
#
# install.sh - Build and install TranscriberAG
#
# Usage:
#   ./install.sh              # Build only (run from build directory)
#   ./install.sh --install    # Build and install system-wide
#   ./install.sh --clean      # Remove build directory and rebuild
#
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Resolve the directory where this script lives (source/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

DO_INSTALL=false
DO_CLEAN=false

for arg in "$@"; do
    case "$arg" in
        --install) DO_INSTALL=true ;;
        --clean)   DO_CLEAN=true ;;
        --help|-h)
            echo "Usage: $0 [--install] [--clean]"
            echo ""
            echo "  --install   Build and install system-wide (requires sudo)"
            echo "  --clean     Remove build directory before building"
            echo "  --help      Show this help"
            exit 0
            ;;
        *)
            error "Unknown option: $arg"
            echo "Run '$0 --help' for usage."
            exit 1
            ;;
    esac
done

OS="$(uname -s)"

# ------------------------------------------------------------------
# Clean
# ------------------------------------------------------------------
if $DO_CLEAN && [ -d "$BUILD_DIR" ]; then
    info "Removing existing build directory..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# ------------------------------------------------------------------
# Configure
# ------------------------------------------------------------------
info "Configuring build..."

CMAKE_ARGS=()

if [ "$OS" = "Darwin" ]; then
    # macOS-specific setup
    export PKG_CONFIG_PATH="/usr/local/opt/ffmpeg@4/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/opt/local/lib/pkgconfig"
    export PATH="/usr/bin:/usr/local/bin:/bin:/usr/sbin:/sbin:$PATH"

    GETTEXT_PREFIX=""
    if command -v brew &>/dev/null; then
        GETTEXT_PREFIX="$(brew --prefix gettext 2>/dev/null || true)"
    fi

    CMAKE_ARGS+=(
        -DCMAKE_C_COMPILER=/usr/bin/cc
        -DCMAKE_CXX_COMPILER=/usr/bin/c++
        -DCMAKE_PREFIX_PATH="/usr/local;/opt/local"
        -DENABLE_POT_UPDATE_TARGET=OFF
    )

    if [ -n "$GETTEXT_PREFIX" ]; then
        CMAKE_ARGS+=(-DGETTEXT_INCLUDE_DIR="$GETTEXT_PREFIX/include")
    fi
fi

cmake "$SCRIPT_DIR" "${CMAKE_ARGS[@]}"

# ------------------------------------------------------------------
# Build
# ------------------------------------------------------------------
info "Building TranscriberAG..."

if [ "$OS" = "Darwin" ]; then
    NPROC=$(sysctl -n hw.ncpu)
else
    NPROC=$(nproc 2>/dev/null || echo 4)
fi

make -j"$NPROC"

info "Build complete."
echo ""
info "Binary: $BUILD_DIR/src/GUI/TranscriberAG"

# ------------------------------------------------------------------
# Install (optional)
# ------------------------------------------------------------------
if $DO_INSTALL; then
    info "Installing..."
    sudo make install

    if [ "$OS" = "Darwin" ]; then
        sudo mkdir -p /usr/local/etc
        sudo cp -R "$SCRIPT_DIR/etc/TransAG" /usr/local/etc/
        info "Configuration installed to /usr/local/etc/TransAG"
    else
        sudo cp -R "$SCRIPT_DIR/etc/TransAG" /etc/
        info "Configuration installed to /etc/TransAG"
    fi

    info "Installation complete."
else
    echo ""
    info "To run without installing:"
    echo "  $BUILD_DIR/src/GUI/TranscriberAG"
    echo ""
    info "To install system-wide, re-run with --install:"
    echo "  $0 --install"
fi
