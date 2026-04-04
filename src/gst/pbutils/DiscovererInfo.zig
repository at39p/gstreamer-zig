const pbutils = @import("pbutils.zig");
const video_info = @import("DiscovererVideoInfo.zig");
const audio_info = @import("DiscovererAudioInfo.zig");

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

    pub fn getDuration(self: DiscovererInfo) u64 {
        return c.gst_discoverer_info_get_duration(self.ptr);
    }

    pub fn isSeekable(self: DiscovererInfo) bool {
        return c.gst_discoverer_info_get_seekable(self.ptr) != 0;
    }

    pub fn isLive(self: DiscovererInfo) bool {
        return c.gst_discoverer_info_get_live(self.ptr) != 0;
    }

    pub fn getVideoStreams(self: DiscovererInfo) video_info.DiscovererVideoInfoList {
        return .{ .ptr = c.gst_discoverer_info_get_video_streams(self.ptr) };
    }

    pub fn getAudioStreams(self: DiscovererInfo) audio_info.DiscovererAudioInfoList {
        return .{ .ptr = c.gst_discoverer_info_get_audio_streams(self.ptr) };
    }
};
