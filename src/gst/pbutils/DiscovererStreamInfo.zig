const pbutils = @import("pbutils.zig");
const Caps = @import("../Caps.zig").Caps;
const c = pbutils.c_pbutils;

pub const DiscovererStreamInfo = struct {
    ptr: *c.GstDiscovererStreamInfo,
    owned: bool = true,

    pub fn deinit(self: DiscovererStreamInfo) void {
        if (self.owned) {
            c.gst_discoverer_stream_info_unref(self.ptr);
        }
    }

    pub fn getStreamId(self: DiscovererStreamInfo) ?[*:0]const u8 {
        return c.gst_discoverer_stream_info_get_stream_id(self.ptr);
    }

    /// Returns the stream's caps. Caller must call deinit().
    pub fn getCaps(self: DiscovererStreamInfo) ?Caps {
        const caps_ptr = c.gst_discoverer_stream_info_get_caps(self.ptr) orelse return null;
        return Caps{ .ptr = @ptrCast(caps_ptr) };
    }
};

pub const DiscovererStreamInfoIterator = struct {
    current: ?*c.GList,

    pub fn next(self: *DiscovererStreamInfoIterator) ?DiscovererStreamInfo {
        const list = self.current orelse return null;
        const ptr: *c.GstDiscovererStreamInfo = @ptrCast(@alignCast(list.*.data));
        self.current = list.*.next;
        return .{ .ptr = ptr, .owned = false };
    }
};

pub const DiscovererStreamInfoList = struct {
    ptr: ?*c.GList,

    pub fn deinit(self: DiscovererStreamInfoList) void {
        c.gst_discoverer_stream_info_list_free(self.ptr);
    }

    pub fn iterator(self: DiscovererStreamInfoList) DiscovererStreamInfoIterator {
        return .{ .current = self.ptr };
    }
};
