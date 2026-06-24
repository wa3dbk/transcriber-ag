/*
 * quartz_threads.h - Disable GDK thread locking on macOS Quartz
 *
 * On macOS, the Quartz GDK backend serializes all GUI operations natively.
 * The GDK thread lock (gdk_threads_enter/leave) is unnecessary and causes
 * deadlocks when called from background threads.
 *
 * gdk_threads_init() is NOT disabled here — it must run so that GDK's
 * internal event dispatch state is properly initialized (the Quartz backend
 * needs it to dispatch user events).  Instead, main() calls
 * gdk_threads_set_lock_functions() with no-op callbacks before
 * gdk_threads_init(), so all actual locking is harmless.
 *
 * Application-level gdk_threads_enter/leave calls are still no-op'd via
 * these macros to prevent re-entrant lock acquisition in callbacks.
 *
 * Include this header AFTER any GDK/GTK headers in source files that call
 * gdk_threads_enter() or gdk_threads_leave().
 */

#ifndef _QUARTZ_THREADS_H
#define _QUARTZ_THREADS_H

#ifdef __APPLE__
  #define gdk_threads_enter()  ((void)0)
  #define gdk_threads_leave()  ((void)0)
#endif

#endif /* _QUARTZ_THREADS_H */
