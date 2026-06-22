# ----------------------------
# --- SoundTouch - Project ---
# ----------------------------

# --- CMake Internals ---
cmake_minimum_required	(VERSION 2.8.12)

# --- Project Root Name ---
project					(SoundTouch)

# --- Global Package Dependencies ---
find_package			(PkgConfig	REQUIRED)

# --- Global variables ---
set						(SRC		${SoundTouch_SOURCE_DIR})

# --- Directories ---
add_subdirectory		(source)
