const pbutils = @import("pbutils.zig");
const c = pbutils.c_pbutils;

pub const DiscovererVideoInfo = struct {
    ptr: *c.GstDiscovererVideoInfo,

    pub fn getWidth(self: DiscovererVideoInfo) u32 {
        return c.gst_discoverer_video_info_get_width(self.ptr);
    }

    pub fn getHeight(self: DiscovererVideoInfo) u32 {
        return c.gst_discoverer_video_info_get_height(self.ptr);
    }

    pub fn getFramerateNum(self: DiscovererVideoInfo) u32 {
        return c.gst_discoverer_video_info_get_framerate_num(self.ptr);
    }

    pub fn getFramerateDenom(self: DiscovererVideoInfo) u32 {
        return c.gst_discoverer_video_info_get_framerate_denom(self.ptr);
    }

    pub fn getDepth(self: DiscovererVideoInfo) u32 {
        return c.gst_discoverer_video_info_get_depth(self.ptr);
    }

    pub fn getParNum(self: DiscovererVideoInfo) u32 {
        return c.gst_discoverer_video_info_get_par_num(self.ptr);
    }

    pub fn getParDenom(self: DiscovererVideoInfo) u32 {
        return c.gst_discoverer_video_info_get_par_denom(self.ptr);
    }

    pub fn isInterlaced(self: DiscovererVideoInfo) bool {
        return c.gst_discoverer_video_info_is_interlaced(self.ptr) != 0;
    }

    pub fn getBitrate(self: DiscovererVideoInfo) u32 {
        return c.gst_discoverer_video_info_get_bitrate(self.ptr);
    }

    pub fn getMaxBitrate(self: DiscovererVideoInfo) u32 {
        return c.gst_discoverer_video_info_get_max_bitrate(self.ptr);
    }

    pub fn isImage(self: DiscovererVideoInfo) bool {
        return c.gst_discoverer_video_info_is_image(self.ptr) != 0;
    }
};

pub const DiscovererVideoInfoIterator = struct {
    current: ?*c.GList,

    pub fn next(self: *DiscovererVideoInfoIterator) ?DiscovererVideoInfo {
        const list = self.current orelse return null;
        const ptr: *c.GstDiscovererVideoInfo = @ptrCast(@alignCast(list.*.data));
        self.current = list.*.next;
        return .{ .ptr = ptr };
    }
};

pub const DiscovererVideoInfoList = struct {
    ptr: ?*c.GList,

    pub fn deinit(self: DiscovererVideoInfoList) void {
        c.gst_discoverer_stream_info_list_free(self.ptr);
    }

    pub fn iterator(self: DiscovererVideoInfoList) DiscovererVideoInfoIterator {
        return .{ .current = self.ptr };
    }
};
