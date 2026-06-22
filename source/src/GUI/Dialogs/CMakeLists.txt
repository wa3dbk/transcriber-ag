# ----------------------------------
# --- TranscriberAG - CMake File ---
# ----------------------------------

# --- Includes ---
include_directories(
	${SRC}/Common
	${SRC}/GUI/Common
	${SRC}/GUI/Tools
	${SRC}/GUI/Tree
	${GTKSPELL_INCLUDE_DIRS}
)


# --- Links ---
link_directories(
	${GTKMM_LIBRARY_DIRS}
	${GTKSPELL_LIBRARY_DIRS}
)


# --- Libraries ---
add_library(
	DialogsModule
	STATIC

	# --- Sources ---
	AboutDialog.cpp
	CreateTranscriptionDialog.cpp
	Explorer_dialog.cpp
	FilePropertyDialog.cpp
	ShortcutDialog.cpp
	StartingError.cpp
	UserDialog.cpp
)


# --- Link ---
target_link_libraries(
	DialogsModule

	CommonModule
	ToolsModule
	TreeModule
	Common
	${GTKMM_LINK_LIBRARIES}
	${GTKSPELL_LIBRARIES}
	xerces-c
)

