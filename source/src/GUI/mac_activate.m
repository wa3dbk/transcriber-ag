/*
 * mac_activate.m - macOS app activation helper
 *
 * GTK2 Quartz calls [NSApplication sharedApplication] during gdk_init()
 * but never calls [NSApp finishLaunching].  On macOS Big Sur (11+) this
 * leaves the NSApplication in an incomplete state where user events
 * (mouse, keyboard) are queued but never delivered through GDK's own
 * event source (the custom poll_func in gdkeventloop-quartz.c).
 *
 * Calling finishLaunching completes the application lifecycle setup
 * so that GDK's poll_func can receive events normally via
 * [NSApp nextEventMatchingMask:...].
 */

#ifdef __APPLE__

#import <Cocoa/Cocoa.h>

void mac_activate_app(void)
{
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp finishLaunching];
    [NSApp activateIgnoringOtherApps:YES];
}

/*
 * Pump Cocoa events that GDK's Quartz poll_func misses on Big Sur+.
 *
 * Dequeues pending events and sends them through [NSApp sendEvent:]
 * which dispatches to the GdkQuartzView, creating GdkEvents.
 */
void mac_pump_events(void)
{
    @autoreleasepool {
        NSEvent *event;
        while ((event = [NSApp nextEventMatchingMask:NSAnyEventMask
                                           untilDate:nil
                                              inMode:NSDefaultRunLoopMode
                                             dequeue:YES]) != nil) {
            [NSApp sendEvent:event];
        }
        [NSApp updateWindows];
    }
}

/*
 * Ensure the main window is key and accepting events.
 *
 * After heavy widget operations (file loading, modal dialogs) on
 * macOS Big Sur+, the NSWindow can lose key status or the first
 * responder chain can break, preventing GdkQuartzView from receiving
 * mouse/keyboard events.
 */
void mac_ensure_key_window(void)
{
    NSWindow *keyWin = [NSApp keyWindow];
    if (!keyWin) {
        NSWindow *mainWin = [NSApp mainWindow];
        if (mainWin) {
            [mainWin makeKeyAndOrderFront:nil];
        } else {
            NSArray *windows = [NSApp windows];
            for (NSWindow *w in windows) {
                if ([w isVisible] && [w canBecomeKeyWindow]) {
                    [w makeKeyAndOrderFront:nil];
                    break;
                }
            }
        }
    }

    if (![NSApp isActive]) {
        [NSApp activateIgnoringOtherApps:YES];
    }
}

#endif
