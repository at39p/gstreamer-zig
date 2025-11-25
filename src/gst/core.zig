const std = @import("std");
pub const c = @import("../c.zig").c;

// GStreamer C type aliases
pub const GstElement = *c.GstElement;
pub const GstPipeline = *c.GstPipeline;
pub const GstBin = *c.GstBin;
pub const GstCaps = *c.GstCaps;
pub const GstPad = *c.GstPad;
pub const GstBus = *c.GstBus;
pub const GstMessage = *c.GstMessage;
pub const GstSample = *c.GstSample;
pub const GstStructure = *c.GstStructure;
pub const GstStream = *c.GstStream;
pub const GstStreamCollection = *c.GstStreamCollection;
pub const GstClock = *c.GstClock;

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

pub const SECOND: u64 = 1_000_000_000; // GST_SECOND
pub const MSECOND: u64 = 1_000_000; // GST_MSECOND
pub const USECOND: u64 = 1_000; // GST_USECOND
pub const NSECOND: u64 = 1; // GST_NSECOND

pub fn init(args: ?[]const [:0]const u8) void {
    if (args) |a| {
        var c_argv_buf: [256][*:0]u8 = undefined;
        std.debug.assert(a.len <= c_argv_buf.len);

        for (a, 0..) |arg, i| {
            c_argv_buf[i] = @constCast(arg.ptr);
        }

        var argc: c_int = @intCast(a.len);
        var argv_ptr: [*][*:0]u8 = &c_argv_buf;
        c.gst_init(&argc, @ptrCast(&argv_ptr));
    } else {
        c.gst_init(null, null);
    }
}

pub fn init_check(args: ?[]const [:0]const u8) !void {
    var err: ?*c.GError = null;

    const success = if (args) |a| blk: {
        var c_argv_buf: [256][*:0]u8 = undefined;
        if (a.len > c_argv_buf.len) return error.TooManyArguments;

        for (a, 0..) |arg, i| {
            c_argv_buf[i] = @constCast(arg.ptr);
        }

        var argc: c_int = @intCast(a.len);
        var argv_ptr: [*][*:0]u8 = &c_argv_buf;
        break :blk c.gst_init_check(&argc, @ptrCast(&argv_ptr), &err);
    } else blk: {
        break :blk c.gst_init_check(null, null, &err);
    };

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

// macOS specific funcs
fn macosMakeWrapper(comptime func: fn () anyerror!void) fn (?*anyopaque) callconv(.c) c_int {
    const Wrapper = struct {
        fn runImpl(_: ?*anyopaque) callconv(.c) c_int {
            func() catch |err| {
                std.debug.print("Error: {}\n", .{err});
                return -1;
            };
            return 0;
        }
    };
    return Wrapper.runImpl;
}

pub fn macosMain(comptime func: fn () anyerror!void, argc: c_int, argv: [*c][*c]u8) !void {
    if (c.gst_macos_main(macosMakeWrapper(func), argc, argv, null) != 0) {
        return error.GstMacOsMainFailed;
    }
}

pub fn macosMainSimple(comptime func: fn () anyerror!void) !void {
    if (c.gst_macos_main_simple(macosMakeWrapper(func), null) != 0) {
        return error.GstMacOsMainFailed;
    }
}

// Version
pub const Version = struct {
    major: u32,
    minor: u32,
    micro: u32,
    nano: u32,

    pub fn format(
        self: Version,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        if (self.nano == 0) {
            try writer.print("{d}.{d}.{d}", .{ self.major, self.minor, self.micro });
        } else {
            try writer.print("{d}.{d}.{d}.{d}", .{ self.major, self.minor, self.micro, self.nano });
        }
    }
};

pub fn version() Version {
    var major: c_uint = undefined;
    var minor: c_uint = undefined;
    var micro: c_uint = undefined;
    var nano: c_uint = undefined;

    c.gst_version(&major, &minor, &micro, &nano);

    return .{
        .major = major,
        .minor = minor,
        .micro = micro,
        .nano = nano,
    };
}

pub fn versionString() [*:0]const u8 {
    return c.gst_version_string();
}
