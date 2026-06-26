/*
 * quartz_threads.h - Disable GDK thread locking on macOS Quartz
 *
 * On macOS, the Quartz GDK backend serializes all GUI operations natively.
 * The GDK thread lock (gdk_threads_enter/leave) is unnecessary and causes
 * deadlocks when called from background threads.
 *
 * gdk_threads_init() must also be disabled: when it runs, it sets an
 * internal gdk_threads_enabled flag that changes the Quartz event loop's
 * dispatch path.  With that flag set, the Quartz backend stops delivering
 * events after heavy widget operations (e.g. loading a file with waveform
 * and annotation views).  Event delivery on macOS is handled by
 * mac_activate_app() ([NSApp finishLaunching]) instead.
 *
 * Include this header AFTER any GDK/GTK headers in source files that call
 * gdk_threads_enter(), gdk_threads_leave(), or gdk_threads_init().
 */

#ifndef _QUARTZ_THREADS_H
#define _QUARTZ_THREADS_H

#ifdef __APPLE__
  #define gdk_threads_init()   ((void)0)
  #define gdk_threads_enter()  ((void)0)
  #define gdk_threads_leave()  ((void)0)
#endif

#endif /* _QUARTZ_THREADS_H */
