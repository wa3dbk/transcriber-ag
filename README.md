Transcriber AG
==============

An audio transcription tool for linguists. This is an unofficial fork of [Transcriber AG](https://transag.sourceforge.net/) (originally by DGA and Bertin Technologies), maintained for people who need to build it from modern sources.

The [official source code](https://sourceforge.net/projects/transag/files/) is hosted on SourceForge.


## Build and installation

### Quick start

```bash
# 1. Install dependencies
./install_dependencies.sh

# 2. Build
cd source
./install.sh

# 3. (Optional) Install system-wide
./install.sh --install
```

### Linux (Debian/Ubuntu)

Install dependencies:

```bash
sudo apt-get install build-essential cmake gettext libxerces-c-dev \
  libavcodec-dev libavformat-dev libswscale-dev libavdevice-dev \
  libavfilter-dev libgtkmm-2.4-dev portaudio19-dev libsndfile1-dev \
  xsltproc libxt-dev libgtkspell-dev pkg-config
```

On some systems you may need `libjack-jackd2-dev` to resolve dependency conflicts.

Build and run:

```bash
mkdir -p source/build && cd source/build
cmake ..
make -j$(nproc)

# Run directly from build tree
./src/GUI/TranscriberAG

# Or install system-wide
sudo make install
sudo cp -R ../etc/TransAG /etc/
```

### macOS (Big Sur 11.x and newer)

Install dependencies via [Homebrew](https://brew.sh/) and [MacPorts](https://www.macports.org/):

```bash
# Homebrew packages
brew install gtkmm gettext portaudio libsndfile pkg-config ffmpeg@4

# MacPorts (for xerces-c and gtkspell2)
sudo port install xercesc3 gtkspell2
```

**Note:** xerces-c is installed via MacPorts because the Homebrew version may conflict with other dependencies. Both package managers coexist without issues for this build.

Build and run:

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
  -DENABLE_POT_UPDATE_TARGET=OFF

make -j$(sysctl -n hw.ncpu)
```

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

 * Requires ffmpeg@4 specifically (ffmpeg 5+/6+ have additional API breaking changes)
 * Two harmless linker warnings about missing directories may appear
 * **GDK threading deadlocks (fixed):** GTK2's `gdk_threads_enter/leave` mechanism deadlocks with the macOS Quartz backend. This has been fixed by disabling GDK thread locking on macOS via `quartz_threads.h` (Quartz serializes all GUI operations natively, making the lock unnecessary)
 * **Plugin loading from build tree:** Format plugins (TransAG, TXT, etc.) are loaded from the build tree automatically when running without installing. If you see "Cannot load plugin" errors, the plugin loader searches `AG_PLUGINDIR` (default `/usr/local/lib/ag/`) and the build tree relative to the executable
 * **Input method quirks:** The app detects SCIM as the input method environment by default. Arabic and other non-Latin keyboard layouts may behave differently than expected due to the custom `InputLanguageHandler` layer. This is a known upstream issue
 * **pkg-config `bzip2` dependency:** On some macOS setups, `pkg-config` fails to resolve `gtkmm-2.4` because `freetype2.pc` lists `bzip2` as a private dependency and Homebrew's bzip2 is keg-only (not linked). The build system works around this with manual fallback include/library paths when `gtkmm-2.4` pkg-config resolution fails
 * **MacPorts header conflicts:** If you have MacPorts packages installed (e.g. `irstlm`), their headers in `/opt/local/include/` may shadow project headers. The build system handles the known `Doc.h` conflict by prioritizing project include paths

### Windows

See `README.md` in the `windows/` directory.

## Platform packaging directories

 * **`debian/`** - Debian/Ubuntu packaging files (changelog, control, rules, etc.) for building `.deb` packages
 * **`windows/`** - Windows installer scripts (InnoSetup `.iss` and NSIS `.nsi`) and cross-compilation instructions via MXE

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
    * Guard `g_thread_init()` for GLib >= 2.32 (no-op since 2.32)
    * Configuration directory auto-discovery (searches relative to binary, `/usr/local/etc/TransAG`, `/etc/TransAG`)
 * **SoundTouch 1.4.0 -> 2.3.3:**
    * Updated bundled SoundTouch library from 1.4.0 (2009) to 2.3.3
    * Improved audio processing algorithms (interpolation: cubic, linear, Shannon)
    * Multichannel support (up to 16 channels)
    * Configured with integer samples (int16_t) to match existing audio pipeline
 * **GtkSpell2 integration (optional spell-checking):**
    * Enabled stock gtkspell2 spell-checking via `#ifdef HAVE_GTKSPELL` guards
    * Auto-detected via pkg-config; builds cleanly without gtkspell2 installed
    * Uses system enchant/hunspell dictionaries (no custom dictionary paths needed)
    * Speller attaches/detaches per text view lifecycle; inhibited during bulk buffer updates
    * Right-click spelling suggestions provided automatically by gtkspell2
    * Removed dead references to custom Bertin Technologies gtkspell2 patch (never committed)
 * **NLS (internationalization) re-enabled on macOS:**
    * Fixed `sed -i` incompatibility between GNU sed and macOS BSD sed in pot-update target
    * Fixed po files not being copied from source tree to build directory for `msgfmt`
    * French and Tibetan translations now build correctly on macOS
 * **macOS GDK threading fix:**
    * Disabled `gdk_threads_enter/leave/init` on macOS via `quartz_threads.h` force-included header
    * Prevents deadlocks caused by GTK2's X11-style thread locking conflicting with the Quartz event loop
    * Quartz natively serializes GUI operations, making the GDK lock unnecessary
 * **macOS build system hardening:**
    * Manual fallback for `GTKMM_INCLUDE_DIRS`/`GTKMM_LIBRARY_DIRS` when pkg-config fails (bzip2/freetype2 dependency chain)
    * Added missing include paths: `freetype2`, `pixman-1`, `libpng16`, `fribidi`, `atkmm-1.6`
    * Fixed include directory ordering to prevent MacPorts header shadowing (`Doc.h` conflict)
 * **Plugin loading from build tree:**
    * On macOS, the plugin loader now searches relative to the executable in the build tree
    * Plugins are found automatically without `make install`

## TODO

 * ~~OSX compilation~~ (done - macOS Big Sur 11.x and newer)
 * ~~remove deprecated functions in ffmpeg~~ (done - migrated to FFmpeg 4.x API)
 * ~~remove deprecated functions in gthread and glib~~ (done - `g_thread_init` guarded for GLib >= 2.32; `gdk_threads_enter/leave` disabled on macOS Quartz via `quartz_threads.h`)
 * ~~update SoundTouch (1.4 -> 1.8)~~ (done - updated to 2.3.3)
 * ~~re-enable NLS on macOS~~ (done - fixed po file copy and macOS sed -i incompatibility)
 * ~~gtkspell integration~~ (done - stock gtkspell2 integration via `#ifdef HAVE_GTKSPELL`, auto-detected by pkg-config)
 * debugging Windows build (almost done)
 * separate etc/, share/ and doc/ to be more Debian-compliant (and facilitate a future well-formed Debian package)
 * making Windows binaries smaller (find the good mxe options)
 * include a variable in the conf to change UI language (especially for Windows)
 * possibility to link against stock SoundTouch (quite difficult: Debian SoundTouch is compiled with float samples, while the code here expects int16_t...)
 * support FFmpeg 5+/6+ API changes
