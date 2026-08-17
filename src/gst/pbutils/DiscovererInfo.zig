const std = @import("std");
const pbutils = @import("pbutils.zig");
const video_info = @import("DiscovererVideoInfo.zig");
const audio_info = @import("DiscovererAudioInfo.zig");
const stream_info = @import("DiscovererStreamInfo.zig");

const TagList = @import("../TagList.zig").TagList;
const ClockTime = @import("../Clock.zig").ClockTime;

const c = pbutils.c_pbutils;

pub const DiscovererResult = enum(c_int) {
    ok = c.GST_DISCOVERER_OK,
    uri_invalid = c.GST_DISCOVERER_URI_INVALID,
    err = c.GST_DISCOVERER_ERROR,
    timeout = c.GST_DISCOVERER_TIMEOUT,
    busy = c.GST_DISCOVERER_BUSY,
    missing_plugins = c.GST_DISCOVERER_MISSING_PLUGINS,
};

pub const DiscovererInfo = struct {
    ptr: *c.GstDiscovererInfo,

    pub fn deinit(self: DiscovererInfo) void {
        c.gst_discoverer_info_unref(self.ptr);
    }

    pub fn getResult(self: DiscovererInfo) DiscovererResult {
        return @enumFromInt(c.gst_discoverer_info_get_result(self.ptr));
    }

    pub fn getUri(self: DiscovererInfo) [*:0]const u8 {
        return c.gst_discoverer_info_get_uri(self.ptr);
    }

    pub fn getDuration(self: DiscovererInfo) ClockTime {
        return @bitCast(c.gst_discoverer_info_get_duration(self.ptr));
    }

    pub fn isSeekable(self: DiscovererInfo) bool {
        return c.gst_discoverer_info_get_seekable(self.ptr) != 0;
    }

    pub fn isLive(self: DiscovererInfo) bool {
        return c.gst_discoverer_info_get_live(self.ptr) != 0;
    }

    /// Returns the tag list. The returned TagList is borrowed from the
    /// DiscovererInfo and valid for its lifetime.
    pub fn getTags(self: DiscovererInfo) ?TagList {
        const tags = c.gst_discoverer_info_get_tags(self.ptr) orelse return null;
        return .{ .ptr = @ptrCast(@constCast(tags)), .owned = false };
    }

    /// Returns a Zig-allocated string of all tags. Caller must free with allocator.free().
    pub fn getTagsString(self: DiscovererInfo, allocator: std.mem.Allocator) ?[]const u8 {
        const tags = self.getTags() orelse return null;
        return tags.toStringAlloc(allocator) catch return null;
    }

    /// Returns the top-level stream info. Caller must call deinit().
    pub fn getStreamInfo(self: DiscovererInfo) ?stream_info.DiscovererStreamInfo {
        const s = c.gst_discoverer_info_get_stream_info(self.ptr) orelse return null;
        return .{ .ptr = s };
    }

    /// Returns all streams as a flat list. Caller must call deinit() on the
    /// returned DiscovererStreamInfoList. Individual items from the iterator
    /// are borrowed references into the list and must not be individually deinitialized.
    pub fn getStreamList(self: DiscovererInfo) stream_info.DiscovererStreamInfoList {
        return .{ .ptr = c.gst_discoverer_info_get_stream_list(self.ptr) };
    }

    pub fn getVideoStreams(self: DiscovererInfo) video_info.DiscovererVideoInfoList {
        return .{ .ptr = c.gst_discoverer_info_get_video_streams(self.ptr) };
    }

    pub fn getAudioStreams(self: DiscovererInfo) audio_info.DiscovererAudioInfoList {
        return .{ .ptr = c.gst_discoverer_info_get_audio_streams(self.ptr) };
    }
};

test {
    @import("testing").refAllDeclsRecursive(@This());
}
