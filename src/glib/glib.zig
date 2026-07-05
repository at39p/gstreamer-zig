pub const c = @import("../c.zig").c;
pub const DateTime = @import("DateTime.zig").DateTime;

const GMainLoop = *c.GMainLoop;

fn addTimeout(
    comptime c_fn: anytype,
    interval: u32,
    context: anytype,
    comptime callback: fn (@TypeOf(context)) bool,
) u32 {
    const Context = @TypeOf(context);
    comptime {
        if (Context != void and @typeInfo(Context) != .pointer) {
            @compileError("context must be a pointer type (e.g., *T) or void ({})");
        }
    }

    const Wrapper = struct {
        fn cCallback(user_data: ?*anyopaque) callconv(.c) c_int {
            const ctx: Context = if (Context == void) {} else @ptrCast(@alignCast(user_data));
            const result = callback(ctx);
            return if (result) 1 else 0; // G_SOURCE_CONTINUE : G_SOURCE_REMOVE
        }
    };

    const user_data: ?*anyopaque = if (Context == void) null else @ptrCast(@constCast(context));
    return c_fn(interval, Wrapper.cCallback, user_data);
}

pub fn timeoutAddSeconds(
    interval: u32,
    context: anytype,
    comptime callback: fn (@TypeOf(context)) bool,
) u32 {
    return addTimeout(c.g_timeout_add_seconds, interval, context, callback);
}

/// `interval` is in milliseconds. For second-resolution timers, prefer
/// `timeoutAddSeconds`, which lets GLib coalesce wake-ups.
pub fn timeoutAdd(
    interval: u32,
    context: anytype,
    comptime callback: fn (@TypeOf(context)) bool,
) u32 {
    return addTimeout(c.g_timeout_add, interval, context, callback);
}

pub fn sourceRemove(source_id: u32) bool {
    return c.g_source_remove(source_id) != 0;
}

pub const LogLevel = struct {
    pub const critical: c.GLogLevelFlags = c.G_LOG_LEVEL_CRITICAL;
    pub const warning: c.GLogLevelFlags = c.G_LOG_LEVEL_WARNING;
};

pub fn logSetHandler(
    domain: [*:0]const u8,
    levels: c.GLogLevelFlags,
    comptime predicate: fn ([*:0]const u8) bool,
) u32 {
    const Wrapper = struct {
        fn cCallback(
            log_domain: [*c]const u8,
            log_levels: c.GLogLevelFlags,
            message: [*c]const u8,
            _: ?*anyopaque,
        ) callconv(.c) void {
            if (predicate(@ptrCast(message))) return;
            c.g_log_default_handler(log_domain, log_levels, message, null);
        }
    };
    return c.g_log_set_handler(domain, levels, Wrapper.cCallback, null);
}

pub fn logRemoveHandler(domain: [*:0]const u8, handler_id: u32) void {
    c.g_log_remove_handler(domain, handler_id);
}

// GLib MainLoop wrapper
pub const MainLoop = struct {
    ptr: GMainLoop,

    pub fn init(context: ?*c.GMainContext, is_running: bool) !MainLoop {
        const mainLoop = c.g_main_loop_new(context, if (is_running) 1 else 0) orelse {
            return error.MainLoopCreationFailed;
        };
        return .{ .ptr = mainLoop };
    }

    pub fn deinit(self: MainLoop) void {
        c.g_main_loop_unref(self.ptr);
    }

    pub fn run(self: MainLoop) void {
        c.g_main_loop_run(self.ptr);
    }

    pub fn quit(self: MainLoop) void {
        c.g_main_loop_quit(self.ptr);
    }
};
