const std = @import("std");
const pbutils = @import("pbutils.zig");
const Clock = @import("../Clock.zig");
const DiscovererInfo = @import("DiscovererInfo.zig").DiscovererInfo;

const c = pbutils.c_pbutils;

pub const Discoverer = struct {
    ptr: *c.GstDiscoverer,

    pub fn init(timeout: Clock.ClockTime) !Discoverer {
        var err: ?*c.GError = null;
        const ptr = c.gst_discoverer_new(@bitCast(timeout), &err);
        if (ptr == null) {
            if (err) |e| {
                std.log.err("Failed to create discoverer: {s}", .{e.message});
                c.g_error_free(e);
            }
            return error.DiscovererCreationFailed;
        }
        return .{ .ptr = ptr.? };
    }

    pub fn deinit(self: Discoverer) void {
        c.g_object_unref(@ptrCast(self.ptr));
    }

    pub fn discoverUri(self: Discoverer, allocator: std.mem.Allocator, uri: []const u8) !DiscovererInfo {
        const uri_z = try allocator.dupeZ(u8, uri);
        defer allocator.free(uri_z);

        var err: ?*c.GError = null;
        const info = c.gst_discoverer_discover_uri(self.ptr, uri_z.ptr, &err);
        if (info == null) {
            if (err) |e| {
                std.log.err("Discovery failed for '{s}': {s}", .{ uri, e.message });
                c.g_error_free(e);
            }
            return error.DiscoveryFailed;
        }
        return .{ .ptr = info.? };
    }

    /// Asynchronously queue a URI for discovery. Must call start() first.
    pub fn discoverUriAsync(self: Discoverer, allocator: std.mem.Allocator, uri: []const u8) !bool {
        const uri_z = try allocator.dupeZ(u8, uri);
        defer allocator.free(uri_z);

        return c.gst_discoverer_discover_uri_async(self.ptr, uri_z.ptr) != 0;
    }

    pub fn start(self: Discoverer) void {
        c.gst_discoverer_start(self.ptr);
    }

    pub fn stop(self: Discoverer) void {
        c.gst_discoverer_stop(self.ptr);
    }
};
