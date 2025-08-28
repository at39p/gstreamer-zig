const std = @import("std");

pub const c = @cImport({
    @cInclude("gst/gst.h");
    @cInclude("glib.h");
    @cInclude("glib-object.h");
});

pub fn init(argc: ?*c_int, argv: ?*[*:null]?[*:0]u8) bool {
    return c.gst_init_check(argc, argv, null);
}

pub fn deinit() void {
    c.gst_deinit();
}

pub fn version() struct { major: u32, minor: u32, micro: u32, nano: u32 } {
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

test "gstreamer version" {
    const ver = version();
    std.testing.expect(ver.major > 0) catch |err| {
        std.debug.print("GStreamer version: {}.{}.{}.{}\n", .{ ver.major, ver.minor, ver.micro, ver.nano });
        return err;
    };
}
