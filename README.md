Transcriber AG (non-official)
===========================

This repository is _not_ the official Transcriber AG repository, which is
[here](http://transag.sourceforge.net/), but an unofficial repository for
people needing to build it from sources, with a few improvements.

## Changelog

Start version is 2.0.0 version plus Debian patches.

 * improving translation system
 * improving CMAKE general build system
 * adding Tibetan as possible input language
 * make compilation possible on modern systems:
    * xerces 2 -> 3
    * small fixes for recent versions of gtkmm
 * **macOS Big Sur (11.x) and newer compilation support:**
    * C++11 modernization (`ext/hash_map` -> `std::unordered_map`, `hash_map::resize` -> `rehash`)
    * FFmpeg 4.x API migration (send/receive decode pattern, updated constants and functions)
    * Glib::RefPtr C++11 compatibility (replaced `== 0` comparisons with boolean checks)
    * Carbon framework includes updated for modern macOS SDK
    * CMake auto-detection of Homebrew and MacPorts paths
    * Clang/AppleClang compiler support with C++11 standard
    * Added missing includes (`FormatToUTF8.h`, `<fstream>`) across format parsers
    * gettext/NLS calls guarded for builds with NLS disabled
    * Guard `g_thread_init()` for GLib >= 2.32 (no-op since 2.32)
    * Configuration directory auto-discovery (searches relative to binary, `/usr/local/etc/TransAG`, `/etc/TransAG`)

## Build and installation

### Linux (Debian/Ubuntu)

You'll have to play a bit with apt/aptitude to get the right dependencies, but
globally

`aptitude install build-essential cmake gettext cdbs libxerces-c-dev libavcodec-dev libavformat-dev libswscale-dev libavdevice-dev libavfilter-dev libgtkmm-2.4-dev portaudio19-dev libsndfile1-dev xsltproc libxt-dev`

should do it. On some systems, you might have dependency conflicts; in this case install `libjack-jackd2-dev`. Then

 * `mkdir source/build && cd source/build`
 * `cmake ..`
 * `make`
 * `sudo make install`
 * `sudo cp -R ../etc/TransAG /etc/`

### macOS (Big Sur 11.x and newer)

#### Prerequisites

Install dependencies via [Homebrew](https://brew.sh/) and [MacPorts](https://www.macports.org/):

```bash
# Homebrew packages
brew install gtkmm gettext portaudio libsndfile pkg-config ffmpeg@4

# MacPorts (for xerces-c)
sudo port install xercesc3
```

**Note:** xerces-c is installed via MacPorts because the Homebrew version may conflict with other dependencies. Both package managers coexist without issues for this build.

#### Building

```bash
# Set up package config paths for both Homebrew and MacPorts
export PKG_CONFIG_PATH="/usr/local/opt/ffmpeg@4/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/opt/local/lib/pkgconfig"

# Ensure system compiler is used (avoid conda or other toolchain interference)
export PATH="/usr/bin:/usr/local/bin:/bin:/usr/sbin:/sbin:$PATH"

mkdir -p source/build && cd source/build

cmake .. \
  -DCMAKE_C_COMPILER=/usr/bin/cc \
  -DCMAKE_CXX_COMPILER=/usr/bin/c++ \
  -DGETTEXT_INCLUDE_DIR=/usr/local/opt/gettext/include \
  -DCMAKE_PREFIX_PATH="/usr/local;/opt/local" \
  -DENABLE_POT_UPDATE_TARGET=OFF \
  -DENABLENLS=OFF

make -j$(sysctl -n hw.ncpu)
```

#### Running

The binary is at `source/build/src/GUI/TranscriberAG`. It automatically searches for the configuration directory (`etc/TransAG`) by walking up from the executable path, so it works directly from the build tree:

```bash
./src/GUI/TranscriberAG
```

For a system-wide install, copy the config files:

```bash
sudo mkdir -p /usr/local/etc
sudo cp -R ../etc/TransAG /usr/local/etc/
```

#### Known limitations on macOS

 * NLS (internationalization) is disabled due to macOS `sed -i` incompatibility with the po file build system
 * Requires ffmpeg@4 specifically (ffmpeg 5+/6+ have additional API breaking changes)
 * Two harmless linker warnings about missing directories may appear

### Building for Windows

See `README.md` in `windows` directory.

## Platform packaging directories

 * **`debian/`** - Debian/Ubuntu packaging files (changelog, control, rules, etc.) for building `.deb` packages
 * **`windows/`** - Windows installer scripts (InnoSetup `.iss` and NSIS `.nsi`) and cross-compilation instructions via MXE

## TODO

 * ~~OSX compilation~~ (done - macOS Big Sur 11.x and newer)
 * ~~remove deprecated functions in ffmpeg~~ (done - migrated to FFmpeg 4.x API)
 * ~~remove deprecated functions in gthread and glib~~ (partially done - `g_thread_init` guarded; `gdk_threads_enter/leave` still used but deeply integrated)
 * debugging Windows build (almost done)
 * separate etc/, share/ and doc/ to be more Debian-compliant (and facilitate a future well-formed Debian package)
 * making Windows binaries smaller (find the good mxe options)
 * include a variable in the conf to change UI language (especially for Windows)
 * update SoundTouch (1.4 -> 1.8)
 * possibility to link against stock SoundTouch (quite difficult: Debian SoundTouch is compiled with float samples, while the code here expects int16_t...)
 * re-enable NLS on macOS (fix po file copy and macOS sed -i incompatibility)
 * support FFmpeg 5+/6+ API changes
 * gtkspellmm inclusion
