pub const video = @import("video.zig");
pub const videoFormat = @import("videoformat.zig");
pub const caps = @import("../caps.zig");
pub const core = @import("../core.zig");

const c_video = video.c_video;

pub const VideoInfo = struct {
    ptr: *c_video.GstVideoInfo,

    pub fn new() !VideoInfo {
        const ptr = c_video.gst_video_info_new();
        if (ptr == null) {
            return error.NewVideoInfoFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn newFromCaps(cs: caps.Caps) !VideoInfo {
        const ptr = c_video.gst_video_info_new_from_caps(@constCast(cs.ptr));
        if (ptr == null) {
            return error.NewFromCapsVideoInfoFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn init(self: *VideoInfo) void {
        c_video.gst_video_info_init(self.ptr);
    }

    pub fn copy(self: VideoInfo) !VideoInfo {
        const ptr = c_video.gst_video_info_copy(self.ptr);
        if (ptr == null) {
            return error.CopyVideoInfoFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn deinit(self: VideoInfo) void {
        c_video.gst_video_info_free(self.ptr);
    }

    pub fn setFormat(self: *VideoInfo, format: videoFormat.VideoFormat, width: u32, height: u32) !void {
        const success = c_video.gst_video_info_set_format(self.ptr, format, width, height);
        if (success == 0) {
            return error.SetFormatFailed;
        }
    }

    pub fn setInterlacedFormat(self: *VideoInfo, format: c_video.GstVideoFormat, mode: c_video.GstVideoInterlaceMode, width: u32, height: u32) !void {
        const success = c_video.gst_video_info_set_interlaced_format(self.ptr, format, mode, width, height);
        if (success == 0) {
            return error.SetInterlacedFormatFailed;
        }
    }

    pub fn fromCaps(self: *VideoInfo, cs: caps.Caps) !void {
        const success = c_video.gst_video_info_from_caps(self.ptr, cs.ptr);
        if (success == 0) {
            return error.FromCapsFailed;
        }
    }

    pub fn toCaps(self: VideoInfo) !caps.Caps {
        const ptr = c_video.gst_video_info_to_caps(self.ptr);
        if (ptr == null) {
            return error.ToCapsFailed;
        }
        return caps.Caps{ .ptr = ptr };
    }

    pub fn isEqual(self: VideoInfo, other: VideoInfo) bool {
        return c_video.gst_video_info_is_equal(self.ptr, other.ptr) != 0;
    }

    // Note: since align is a reserved keyword in Zig, we call it alignInfo instead.
    pub fn alignInfo(self: *VideoInfo, alignment: *c_video.GstVideoAlignment) !void {
        const success = c_video.gst_video_info_align(self.ptr, alignment);
        if (success == 0) {
            return error.AlignFailed;
        }
    }

    pub fn convert(self: VideoInfo, src_format: c_video.GstFormat, src_value: i64, dest_format: c_video.GstFormat) !i64 {
        var dest_value: i64 = 0;
        const success = c_video.gst_video_info_convert(self.ptr, src_format, src_value, dest_format, &dest_value);
        if (success == 0) {
            return error.ConvertFailed;
        }
        return dest_value;
    }

    pub fn getWidth(self: VideoInfo) u32 {
        return @intCast(self.ptr.*.width);
    }

    pub fn getHeight(self: VideoInfo) u32 {
        return @intCast(self.ptr.*.height);
    }

    pub fn getFormat(self: VideoInfo) c_video.GstVideoFormat {
        return self.ptr.*.finfo.*.format;
    }

    pub fn getFps(self: VideoInfo) struct { num: i32, den: i32 } {
        return .{ .num = self.ptr.*.fps_n, .den = self.ptr.*.fps_d };
    }

    pub fn getPar(self: VideoInfo) struct { num: i32, den: i32 } {
        return .{ .num = self.ptr.*.par_n, .den = self.ptr.*.par_d };
    }

    pub fn getFlags(self: VideoInfo) c_video.GstVideoFlags {
        return self.ptr.*.flags;
    }

    pub fn getInterlaceMode(self: VideoInfo) c_video.GstVideoInterlaceMode {
        return self.ptr.*.interlace_mode;
    }

    pub fn getMultiviewMode(self: VideoInfo) c_video.GstVideoMultiviewMode {
        return self.ptr.*.multiview_mode;
    }

    pub fn getMultiviewFlags(self: VideoInfo) c_video.GstVideoMultiviewFlags {
        return self.ptr.*.multiview_flags;
    }

    pub fn getSize(self: VideoInfo) usize {
        return self.ptr.*.size;
    }

    pub fn getViews(self: VideoInfo) u32 {
        return @intCast(self.ptr.*.views);
    }
};
