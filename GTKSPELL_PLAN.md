# GtkSpell2 Integration Plan

## Background

TranscriberAG has substantial **commented-out** spell-checking code across 7 files
(~107 occurrences). This was originally built against a **custom-patched** version
of gtkspell2 (`gtkspell-2.0.11-patch-BT`) created by Bertin Technologies, which
was never committed to this repository.

The patched version extends the standard gtkspell2 C API with non-standard functions
that do not exist in stock gtkspell2. This is the central challenge.

## Prerequisite

```bash
sudo port install gtkspell2    # macOS (depends on enchant, gtk2)
# or on Linux:
apt install libgtkspell-dev
```

## Analysis: Standard vs Custom gtkspell2 API

### Standard gtkspell2 API (available in stock library)
- `gtkspell_new_attach(GtkTextView*, const char* lang, GError**)` — note: stock version has 3 args, patched version has 4 (adds dict path)
- `gtkspell_detach(GtkSpell*)`
- `gtkspell_recheck_all(GtkSpell*)`
- `gtkspell_get_from_text_view(GtkTextView*)`
- `gtkspell_set_language(GtkSpell*, const char*, GError**)`

### Custom Bertin Technologies extensions (NOT in stock gtkspell2)
These functions are called in the commented-out code but **do not exist** in any
released gtkspell2:

| Function | Purpose | Used in |
|----------|---------|---------|
| `gtkspell_set_config_option("dict", path)` | Set dictionary path | AnnotationView.cpp:454 |
| `gtkspell_allow_user_dictionnary(spell, bool)` | Toggle user dictionary support | AnnotationView.cpp:511 |
| `gtkspell_allow_ignore_word(spell, bool)` | Toggle "ignore word" in popup | AnnotationView.cpp:512 |
| `gtkspell_set_elision_chars(spell, chars)` | Set elision characters (French l', d', etc.) | AnnotationView.cpp:517 |
| `gtkspell_set_preproc_callback(spell, fn, data)` | Pre-processing callback (Arabic vowel stripping) | AnnotationView.cpp:523-526 |
| `gtkspell_inhibate_check(spell, bool)` | Temporarily pause/resume checking | AnnotationBuffer.cpp (8 sites), AnnotationView.cpp:2998 |
| `gtkspell_recheck_range(spell, start, end)` | Recheck specific range (not whole buffer) | AnnotationBuffer.cpp (4 sites) |
| `gtkspell_populate_popup(spell, view, menu, label)` | Add spelling suggestions to context menu | AnnotationView.cpp:4781 |
| `gtkspell_set_confidence_tag(spell, tagname)` | Highlight low-confidence words differently | AnnotationBuffer.cpp:458-460 |

## Implementation Strategy

There are two viable approaches:

### Option A: Minimal integration with stock gtkspell2 (Recommended first step)

Use only the standard gtkspell2 API. Drop custom features that aren't available.
This gets basic spell-checking working quickly.

**What works out of the box:**
- Attach/detach speller to text views
- Recheck entire buffer
- Right-click spelling suggestions (built into gtkspell2 automatically)
- Language selection

**What gets dropped (initially):**
- Custom dictionary paths (use system enchant dictionaries instead)
- User dictionary support
- Elision character handling
- Arabic pre-processing callback
- Inhibit/resume checking during buffer edits
- Range-specific rechecking
- Confidence tag highlighting

### Option B: Write a wrapper/shim layer

Create a `SpellChecker` C++ wrapper class that implements the missing functions
using enchant (gtkspell2's backend) directly, combined with standard gtkspell2.
More work but restores full functionality.

## Implementation Plan (Option A — stock gtkspell2)

### Phase 1: Build system (1 file)

**`source/CMakeLists.txt`:**
- Add `pkg_check_modules(GTKSPELL gtkspell-2.0)` (optional, with a `HAVE_GTKSPELL` flag)
- Add `GTKSPELL_INCLUDE_DIRS` and `GTKSPELL_LIBRARIES` to the build
- Generate `#define HAVE_GTKSPELL 1` in `TranscriberAG-config.h`

**`source/libs/CMakeLists.txt`:**
- Remove the commented-out `add_subdirectory(gtkspell-2.0.11-patch-BT)` line

**`source/src/GUI/Dialogs/CMakeLists.txt`:**
- Uncomment and update the gtkspell include/link references to use pkg-config vars

### Phase 2: AnnotationView — core speller lifecycle (1 file, ~6 code blocks)

**`source/src/Editors/AnnotationEditor/AnnotationView.h`:**
- Uncomment `GtkSpell* m_speller` member (line 987)
- Uncomment `getSpeller()`, `detachSpeller()`, `speller_recheck_all()`, 
  `inhibateSpellChecking()`, `configureSpeller()` declarations
- Wrap all with `#ifdef HAVE_GTKSPELL`

**`source/src/Editors/AnnotationEditor/AnnotationView.cpp`:**
- Uncomment `#include <gtkspell/gtkspell.h>` (line 70)
- Uncomment and **rewrite** `configureSpeller()` (lines 442-528):
  - Replace `gtkspell_set_config_option()` → remove (not needed with enchant)
  - Replace `gtkspell_new_attach(view, dict, lang, &err)` → `gtkspell_new_attach(view, lang, &err)` (3-arg stock API)
  - Remove `gtkspell_allow_user_dictionnary()`, `gtkspell_allow_ignore_word()`, 
    `gtkspell_set_elision_chars()`, `gtkspell_set_preproc_callback()` calls
- Uncomment `detachSpeller()` (lines 182-189)
- Uncomment `m_speller = NULL` initialization (line 214)
- Uncomment speller cleanup in destructor (line 160)
- Uncomment `configureSpeller()` call in `configure()` (line 646)
- Uncomment `speller_recheck_all()` (lines 5034-5038)
- Uncomment `inhibateSpellChecking()` (lines 2994-3003):
  - Replace `gtkspell_inhibate_check()` → just store flag, no API equivalent
- Uncomment `gtkspell_populate_popup()` call (line 4781):
  - Stock gtkspell2 adds popup suggestions automatically — remove this manual call

### Phase 3: AnnotationBuffer — speller integration (1 file, ~10 code blocks)

**`source/src/Editors/AnnotationEditor/AnnotationBuffer.h`:**
- Uncomment `#include <gtkspell/gtkspell.h>` (line 24)
- Uncomment `GtkSpell* m_speller` member (line 1206)
- Uncomment `setSpeller()` declaration (line 839)
- Wrap with `#ifdef HAVE_GTKSPELL`

**`source/src/Editors/AnnotationEditor/AnnotationBuffer.cpp`:**
- Uncomment `m_speller = NULL` (line 48)
- Uncomment `setSpeller()` method (lines 436-441)
- For the ~8 sites calling `gtkspell_inhibate_check()` and `gtkspell_recheck_range()`:
  - **Option A (simple):** Leave commented out — stock gtkspell2 auto-rechecks on text changes
  - **Option B (better):** Replace with `gtkspell_recheck_all(m_speller)` after batch edits
- Remove `setSpellerConfidence()` and `spellerRecheck()` methods (use stock auto-recheck)

### Phase 4: AnnotationEditor — speller reset (1 file, 2 code blocks)

**`source/src/Editors/AnnotationEditor/AnnotationEditor.h`:**
- `reset_speller()` is already declared (line 534), uncomment body

**`source/src/Editors/AnnotationEditor/AnnotationEditor.cpp`:**
- Uncomment `reset_speller()` (lines 5309-5331) — calls `detachSpeller()` + `configureSpeller()` per view
- Uncomment speller detach in `terminateSession()` (lines 2215-2218)

### Phase 5: UndoableTextView — recheck after undo/redo (1 file, 2 lines)

**`source/src/Editors/AnnotationEditor/UndoableTextView.cpp`:**
- Lines 548 and 719: `buffer->spellerRecheck(...)` 
- Replace with `gtkspell_recheck_all()` or leave commented (stock auto-rechecks)

### Phase 6: Configuration

The speller configuration already exists in `etc/TransAG/userAG.rc`:
```xml
<section id="Speller" label="Spell checker">
    <parameter id="enabled" value="true"/>
    <parameter id="allow_ignore_word" value="false"/>
    <parameter id="allow_user_dic" value="false"/>
    <parameter id="directory" value="Dico"/>
</section>
```

- `enabled` → used in AnnotationEditor.cpp to decide whether to call `configureSpeller()`
- `directory` → was used for custom dict path; with stock gtkspell2, this becomes irrelevant
  (enchant uses system dictionaries from `/usr/share/myspell`, `/usr/share/hunspell`, etc.)
- `allow_ignore_word`, `allow_user_dic` → no stock API equivalent; leave config in place but ignore

Ensure enchant dictionaries are installed:
```bash
# macOS
brew install hunspell
# Download dictionaries to ~/Library/Spelling/ or /usr/local/share/hunspell/

# Linux  
apt install hunspell-en-us hunspell-fr
```

## Files Changed Summary

| File | Changes | Effort |
|------|---------|--------|
| `source/CMakeLists.txt` | Add GTKSPELL pkg-config detection | Small |
| `source/include/config.h.in` | Add `#define HAVE_GTKSPELL @HAVE_GTKSPELL@` | Trivial |
| `source/libs/CMakeLists.txt` | Remove dead comment | Trivial |
| `source/src/GUI/Dialogs/CMakeLists.txt` | Uncomment + update link | Small |
| `AnnotationView.h` | Uncomment ~10 lines, add `#ifdef` guards | Small |
| `AnnotationView.cpp` | Uncomment + rewrite ~80 lines | **Medium** |
| `AnnotationBuffer.h` | Uncomment ~5 lines, add `#ifdef` guards | Small |
| `AnnotationBuffer.cpp` | Uncomment ~3 methods, simplify ~8 sites | **Medium** |
| `AnnotationEditor.h` | No change (already declared) | None |
| `AnnotationEditor.cpp` | Uncomment 2 blocks (~20 lines) | Small |
| `UndoableTextView.cpp` | 2 lines | Trivial |

**Total estimated scope:** ~150 lines of uncommenting/rewriting across 10 files.

## Testing Checklist

1. Build with `-DHAVE_GTKSPELL=ON` — compiles without errors
2. Build without gtkspell2 installed — compiles with speller disabled (`#ifdef` guards)
3. Launch TranscriberAG, open/create a transcription
4. Verify misspelled words get red underline
5. Right-click misspelled word → spelling suggestions appear
6. Change transcription language → speller language updates
7. Disable speller in preferences → underlines disappear
8. Close file / open new file → no segfault on speller detach/reattach
9. Undo/redo text → no crash, speller rechecks
10. Test with Speller,enabled=false in config → speller doesn't attach

## Future Enhancements (Option B scope)

If full Bertin Technologies feature parity is desired later:
- Write `SpellWrapper` class using enchant API directly for:
  - Custom dictionary paths
  - User dictionaries (add/ignore words persisted to file)
  - Elision character handling (strip l', d', etc. before spell check)
  - Arabic pre-processing callback
  - Confidence tag highlighting (low-confidence ASR words)
  - Inhibit/resume checking during batch buffer operations
  - Range-specific rechecking for performance
