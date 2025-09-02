pub const c = @cImport({
    @cInclude("zig-compat.h");
});

pub const GMainLoop = *c.GMainLoop;

pub const GstElement = *c.GstElement;
pub const GstPipeline = *c.GstPipeline;
pub const GstCaps = *c.GstCaps;
pub const GstPad = *c.GstPad;
pub const GstSample = *c.GstSample;
pub const GstStructure = *c.GstStructure;

pub const State = enum(c_int) {
    void_pending = c.GST_STATE_VOID_PENDING,
    null_state = c.GST_STATE_NULL,
    ready = c.GST_STATE_READY,
    paused = c.GST_STATE_PAUSED,
    playing = c.GST_STATE_PLAYING,
};

pub const StateChangeReturn = enum(c_int) {
    failure = c.GST_STATE_CHANGE_FAILURE,
    success = c.GST_STATE_CHANGE_SUCCESS,
    asyncState = c.GST_STATE_CHANGE_ASYNC,
    no_preroll = c.GST_STATE_CHANGE_NO_PREROLL,
};

pub fn init(argc: ?*c_int, argv: ?*?*?*c_char) void {
    c.gst_init(argc, argv);
}

pub fn init_check(argc: ?*c_int, argv: ?*?*?*c_char) !void {
    var err: ?*c.GError = null;
    const success = c.gst_init_check(argc, argv, &err);
    if (err) |e| {
        c.g_error_free(e);
        return error.InitializationFailed;
    }

    if (success == 0) {
        return error.InitializationFailed;
    }
}

pub fn deinit() void {
    c.gst_deinit();
}

pub inline fn objectUnref(object: anytype) void {
    c.gst_object_unref(object);
}

// TODO: Untested
pub fn macosMain(run: fn (_: ?*anyopaque) callconv(.c) c_int, argc: c_int, argv: [*c][*c]u8, user_data: ?*anyopaque) !void {
    if (c.gst_macos_main(run, argc, argv, user_data) != 0) {
        return error.GstMacOsMainFailed;
    }
}

pub fn macosMainSimple(run: fn (_: ?*anyopaque) callconv(.c) c_int, user_data: ?*anyopaque) !void {
    if (c.gst_macos_main_simple(run, user_data) != 0) {
        return error.GstMacOsMainFailed;
    }
}

// GMainLoop
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

/// Represents a fraction (rational number) used in GStreamer for frame rates, aspect ratios, etc.
/// TODO: It's probably not rightly placed.
pub const Fraction = struct {
    numerator: i32,
    denominator: i32,

    pub fn new(num: anytype, den: anytype) Fraction {
        return .{ .numerator = @intCast(num), .denominator = @intCast(den) };
    }

    pub inline fn toFloat(self: Fraction) f64 {
        return @as(f64, @floatFromInt(self.numerator)) / @as(f64, @floatFromInt(self.denominator));
    }

    pub inline fn isValid(self: Fraction) bool {
        return self.denominator != 0;
    }

    pub inline fn equals(self: Fraction, other: Fraction) bool {
        return self.numerator == other.numerator and self.denominator == other.denominator;
    }
};
