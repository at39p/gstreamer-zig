pub const video = @import("video.zig");

pub const caps = @import("../Caps.zig");
pub const core = @import("../core.zig");

const c_video = video.c_video;

pub const VideoFormatInfo = struct {
    ptr: *c_video.GstVideoFormatInfo,

    /// Fills `components` with the indices of the components stored in
    /// `plane`, terminated by -1 (gst_video_format_info_component). The
    /// slice should hold GST_VIDEO_MAX_COMPONENTS (4) entries.
    pub fn component(self: VideoFormatInfo, plane: u32, components: []c_int) void {
        c_video.gst_video_format_info_component(self.ptr, plane, components.ptr);
    }

    pub fn extrapolateStride(self: VideoFormatInfo, plane: u32, stride: u32) u32 {
        return @intCast(c_video.gst_video_format_info_extrapolate_stride(self.ptr, @intCast(plane), @intCast(stride)));
    }

    pub fn getBits(self: VideoFormatInfo) u32 {
        return @intCast(self.ptr.*.bits);
    }

    pub fn getFlags(self: VideoFormatInfo) c_video.GstVideoFormatFlags {
        return self.ptr.*.flags;
    }

    pub fn getFormat(self: VideoFormatInfo) c_video.GstVideoFormat {
        return self.ptr.*.format;
    }

    pub fn getName(self: VideoFormatInfo) [*c]const u8 {
        return self.ptr.*.name;
    }

    pub fn getNComponents(self: VideoFormatInfo) u32 {
        return @intCast(self.ptr.*.n_components);
    }

    pub fn getNPlanes(self: VideoFormatInfo) u32 {
        return @intCast(self.ptr.*.n_planes);
    }

    pub fn getPlane(self: VideoFormatInfo, comp: u32) u32 {
        return @intCast(self.ptr.*.plane[@intCast(comp)]);
    }

    pub fn getPStride(self: VideoFormatInfo, comp: u32) u32 {
        return @intCast(self.ptr.*.pixel_stride[@intCast(comp)]);
    }

    pub fn getWSubShift(self: VideoFormatInfo, comp: u32) u32 {
        return @intCast(self.ptr.*.w_sub[@intCast(comp)]);
    }

    pub fn getHSubShift(self: VideoFormatInfo, comp: u32) u32 {
        return @intCast(self.ptr.*.h_sub[@intCast(comp)]);
    }

    pub fn hasAlpha(self: VideoFormatInfo) bool {
        return (self.ptr.*.flags & c_video.GST_VIDEO_FORMAT_FLAG_ALPHA) != 0;
    }

    pub fn hasPalette(self: VideoFormatInfo) bool {
        return (self.ptr.*.flags & c_video.GST_VIDEO_FORMAT_FLAG_PALETTE) != 0;
    }

    pub fn isRgb(self: VideoFormatInfo) bool {
        return (self.ptr.*.flags & c_video.GST_VIDEO_FORMAT_FLAG_RGB) != 0;
    }

    pub fn isYuv(self: VideoFormatInfo) bool {
        return (self.ptr.*.flags & c_video.GST_VIDEO_FORMAT_FLAG_YUV) != 0;
    }

    pub fn isGray(self: VideoFormatInfo) bool {
        return (self.ptr.*.flags & c_video.GST_VIDEO_FORMAT_FLAG_GRAY) != 0;
    }
};

test {
    @import("testing").refAllDeclsRecursive(@This());
}
