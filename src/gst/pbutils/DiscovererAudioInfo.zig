const pbutils = @import("pbutils.zig");
const c = pbutils.c_pbutils;

pub const DiscovererAudioInfo = struct {
    ptr: *c.GstDiscovererAudioInfo,

    pub fn getChannels(self: DiscovererAudioInfo) u32 {
        return c.gst_discoverer_audio_info_get_channels(self.ptr);
    }

    pub fn getSampleRate(self: DiscovererAudioInfo) u32 {
        return c.gst_discoverer_audio_info_get_sample_rate(self.ptr);
    }

    pub fn getBitrate(self: DiscovererAudioInfo) u32 {
        return c.gst_discoverer_audio_info_get_bitrate(self.ptr);
    }

    pub fn getMaxBitrate(self: DiscovererAudioInfo) u32 {
        return c.gst_discoverer_audio_info_get_max_bitrate(self.ptr);
    }
};

pub const DiscovererAudioInfoIterator = struct {
    current: ?*c.GList,

    pub fn next(self: *DiscovererAudioInfoIterator) ?DiscovererAudioInfo {
        const list = self.current orelse return null;
        const ptr: *c.GstDiscovererAudioInfo = @ptrCast(@alignCast(list.*.data));
        self.current = list.*.next;
        return .{ .ptr = ptr };
    }
};

pub const DiscovererAudioInfoList = struct {
    ptr: ?*c.GList,

    pub fn deinit(self: DiscovererAudioInfoList) void {
        c.gst_discoverer_stream_info_list_free(self.ptr);
    }

    pub fn iterator(self: DiscovererAudioInfoList) DiscovererAudioInfoIterator {
        return .{ .current = self.ptr };
    }
};
