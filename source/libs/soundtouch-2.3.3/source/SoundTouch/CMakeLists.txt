# ---------------------------
# --- SoundTouch - Source ---
# ---------------------------

# --- Includes ---
include_directories(
	${SRC}/include
)


# --- Libraries ---
add_library(
	SoundTouch
	STATIC

	# --- Sources ---
	AAFilter.cpp
	FIRFilter.cpp
	FIFOSampleBuffer.cpp
	mmx_optimized.cpp
	sse_optimized.cpp
	RateTransposer.cpp
	SoundTouch.cpp
	TDStretch.cpp
	cpu_detect_x86.cpp
	BPMDetect.cpp
	PeakFinder.cpp
	InterpolateCubic.cpp
	InterpolateLinear.cpp
	InterpolateShannon.cpp
)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang|AppleClang")
	target_compile_options(SoundTouch PRIVATE -fcheck-new)
	# Only add -msse on x86 architectures
	if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|i[3-6]86|AMD64")
		target_compile_options(SoundTouch PRIVATE -msse)
	endif()
endif()
