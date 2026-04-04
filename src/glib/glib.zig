pub const c = @import("../c.zig").c;
pub const DateTime = @import("DateTime.zig").DateTime;

const GMainLoop = *c.GMainLoop;

pub fn timeoutAddSeconds(
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
    return c.g_timeout_add_seconds(interval, Wrapper.cCallback, user_data);
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
