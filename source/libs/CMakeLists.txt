cmake_minimum_required(VERSION 2.6)

# --- Core Libraries ---
add_subdirectory(aglib-2.0.1)
add_subdirectory(live555)
add_subdirectory(soundtouch-2.3.3)

# --- Win32 ---
if(WIN32 AND NOT MINGW)
	add_subdirectory(portaudio)
endif(WIN32 AND NOT MINGW)

