#!/usr/bin/env bash
#
# install_dependencies.sh - Install all build dependencies for TranscriberAG
#
# Usage: ./install_dependencies.sh
#
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

OS="$(uname -s)"

case "$OS" in
    Linux)
        if [ -f /etc/debian_version ]; then
            info "Detected Debian/Ubuntu"
            info "Installing build dependencies via apt..."
            sudo apt-get update
            sudo apt-get install -y \
                build-essential \
                cmake \
                gettext \
                libxerces-c-dev \
                libavcodec-dev \
                libavformat-dev \
                libswscale-dev \
                libavdevice-dev \
                libavfilter-dev \
                libgtkmm-2.4-dev \
                portaudio19-dev \
                libsndfile1-dev \
                xsltproc \
                libxt-dev \
                libgtkspell-dev \
                pkg-config

            info "All dependencies installed."
        elif [ -f /etc/redhat-release ]; then
            info "Detected Red Hat / Fedora"
            warn "Package names may vary. Attempting dnf install..."
            sudo dnf install -y \
                gcc gcc-c++ make \
                cmake \
                gettext-devel \
                xerces-c-devel \
                ffmpeg-devel \
                gtkmm24-devel \
                portaudio-devel \
                libsndfile-devel \
                xsltproc \
                libXt-devel \
                gtkspell-devel \
                pkg-config
            info "All dependencies installed."
        else
            error "Unsupported Linux distribution."
            echo "Please install the equivalent of these packages manually:"
            echo "  cmake, gettext, xerces-c, ffmpeg (4.x), gtkmm-2.4,"
            echo "  portaudio, libsndfile, gtkspell2, pkg-config"
            exit 1
        fi
        ;;

    Darwin)
        info "Detected macOS"

        # Check for Homebrew
        if ! command -v brew &>/dev/null; then
            error "Homebrew not found. Install it from https://brew.sh/"
            exit 1
        fi

        info "Installing Homebrew packages..."
        brew install gtkmm gettext portaudio libsndfile pkg-config ffmpeg@4

        # Check for MacPorts
        if ! command -v port &>/dev/null; then
            warn "MacPorts not found."
            echo "MacPorts is needed for xerces-c and gtkspell2."
            echo "Install it from https://www.macports.org/"
            echo ""
            echo "Then run:"
            echo "  sudo port install xercesc3 gtkspell2"
            exit 1
        fi

        info "Installing MacPorts packages..."
        sudo port install xercesc3 gtkspell2

        info "All dependencies installed."
        echo ""
        info "Before building, set PKG_CONFIG_PATH:"
        echo '  export PKG_CONFIG_PATH="/usr/local/opt/ffmpeg@4/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/opt/local/lib/pkgconfig"'
        ;;

    *)
        error "Unsupported OS: $OS"
        echo "See README.md for manual dependency installation."
        exit 1
        ;;
esac
