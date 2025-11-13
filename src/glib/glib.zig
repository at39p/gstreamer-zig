pub const c = @import("../c.zig").c;

const GMainLoop = *c.GMainLoop;

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
