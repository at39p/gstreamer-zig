pub const video = @import("video.zig");
pub const caps = @import("../Caps.zig");
pub const core = @import("../core.zig");
pub const videoformatinfo = @import("VideoFormatInfo.zig");

const c_video = video.c_video;

pub const VideoFormat = enum(c_video.GstVideoFormat) {
    unknown = c_video.GST_VIDEO_FORMAT_UNKNOWN,
    encoded = c_video.GST_VIDEO_FORMAT_ENCODED,
    i420 = c_video.GST_VIDEO_FORMAT_I420,
    yv12 = c_video.GST_VIDEO_FORMAT_YV12,
    yuy2 = c_video.GST_VIDEO_FORMAT_YUY2,
    uyvy = c_video.GST_VIDEO_FORMAT_UYVY,
    ayuv = c_video.GST_VIDEO_FORMAT_AYUV,
    rgbx = c_video.GST_VIDEO_FORMAT_RGBx,
    bgrx = c_video.GST_VIDEO_FORMAT_BGRx,
    xrgb = c_video.GST_VIDEO_FORMAT_xRGB,
    xbgr = c_video.GST_VIDEO_FORMAT_xBGR,
    rgba = c_video.GST_VIDEO_FORMAT_RGBA,
    bgra = c_video.GST_VIDEO_FORMAT_BGRA,
    argb = c_video.GST_VIDEO_FORMAT_ARGB,
    abgr = c_video.GST_VIDEO_FORMAT_ABGR,
    rgb = c_video.GST_VIDEO_FORMAT_RGB,
    bgr = c_video.GST_VIDEO_FORMAT_BGR,
    y41b = c_video.GST_VIDEO_FORMAT_Y41B,
    y42b = c_video.GST_VIDEO_FORMAT_Y42B,
    yvyu = c_video.GST_VIDEO_FORMAT_YVYU,
    y444 = c_video.GST_VIDEO_FORMAT_Y444,
    v210 = c_video.GST_VIDEO_FORMAT_v210,
    v216 = c_video.GST_VIDEO_FORMAT_v216,
    nv12 = c_video.GST_VIDEO_FORMAT_NV12,
    nv21 = c_video.GST_VIDEO_FORMAT_NV21,
    gray8 = c_video.GST_VIDEO_FORMAT_GRAY8,
    gray16_be = c_video.GST_VIDEO_FORMAT_GRAY16_BE,
    gray16_le = c_video.GST_VIDEO_FORMAT_GRAY16_LE,
    v308 = c_video.GST_VIDEO_FORMAT_v308,
    rgb16 = c_video.GST_VIDEO_FORMAT_RGB16,
    bgr16 = c_video.GST_VIDEO_FORMAT_BGR16,
    rgb15 = c_video.GST_VIDEO_FORMAT_RGB15,
    bgr15 = c_video.GST_VIDEO_FORMAT_BGR15,
    uyvp = c_video.GST_VIDEO_FORMAT_UYVP,
    a420 = c_video.GST_VIDEO_FORMAT_A420,
    rgb8p = c_video.GST_VIDEO_FORMAT_RGB8P,
    yuv9 = c_video.GST_VIDEO_FORMAT_YUV9,
    yvu9 = c_video.GST_VIDEO_FORMAT_YVU9,
    iyu1 = c_video.GST_VIDEO_FORMAT_IYU1,
    argb64 = c_video.GST_VIDEO_FORMAT_ARGB64,
    ayuv64 = c_video.GST_VIDEO_FORMAT_AYUV64,
    r210 = c_video.GST_VIDEO_FORMAT_r210,
    i420_10be = c_video.GST_VIDEO_FORMAT_I420_10BE,
    i420_10le = c_video.GST_VIDEO_FORMAT_I420_10LE,
    i422_10be = c_video.GST_VIDEO_FORMAT_I422_10BE,
    i422_10le = c_video.GST_VIDEO_FORMAT_I422_10LE,
    y444_10be = c_video.GST_VIDEO_FORMAT_Y444_10BE,
    y444_10le = c_video.GST_VIDEO_FORMAT_Y444_10LE,
    gbr = c_video.GST_VIDEO_FORMAT_GBR,
    gbr_10be = c_video.GST_VIDEO_FORMAT_GBR_10BE,
    gbr_10le = c_video.GST_VIDEO_FORMAT_GBR_10LE,
    nv16 = c_video.GST_VIDEO_FORMAT_NV16,
    nv24 = c_video.GST_VIDEO_FORMAT_NV24,
    nv12_64z32 = c_video.GST_VIDEO_FORMAT_NV12_64Z32,
    a420_10be = c_video.GST_VIDEO_FORMAT_A420_10BE,
    a420_10le = c_video.GST_VIDEO_FORMAT_A420_10LE,
    a422_10be = c_video.GST_VIDEO_FORMAT_A422_10BE,
    a422_10le = c_video.GST_VIDEO_FORMAT_A422_10LE,
    a444_10be = c_video.GST_VIDEO_FORMAT_A444_10BE,
    a444_10le = c_video.GST_VIDEO_FORMAT_A444_10LE,
    nv61 = c_video.GST_VIDEO_FORMAT_NV61,
    p010_10be = c_video.GST_VIDEO_FORMAT_P010_10BE,
    p010_10le = c_video.GST_VIDEO_FORMAT_P010_10LE,
    iyu2 = c_video.GST_VIDEO_FORMAT_IYU2,
    vyuy = c_video.GST_VIDEO_FORMAT_VYUY,
    gbra = c_video.GST_VIDEO_FORMAT_GBRA,
    gbra_10be = c_video.GST_VIDEO_FORMAT_GBRA_10BE,
    gbra_10le = c_video.GST_VIDEO_FORMAT_GBRA_10LE,
    gbr_12be = c_video.GST_VIDEO_FORMAT_GBR_12BE,
    gbr_12le = c_video.GST_VIDEO_FORMAT_GBR_12LE,
    gbra_12be = c_video.GST_VIDEO_FORMAT_GBRA_12BE,
    gbra_12le = c_video.GST_VIDEO_FORMAT_GBRA_12LE,
    i420_12be = c_video.GST_VIDEO_FORMAT_I420_12BE,
    i420_12le = c_video.GST_VIDEO_FORMAT_I420_12LE,
    i422_12be = c_video.GST_VIDEO_FORMAT_I422_12BE,
    i422_12le = c_video.GST_VIDEO_FORMAT_I422_12LE,
    y444_12be = c_video.GST_VIDEO_FORMAT_Y444_12BE,
    y444_12le = c_video.GST_VIDEO_FORMAT_Y444_12LE,

    pub fn fromString(format_str: [*c]const u8) VideoFormat {
        return @enumFromInt(c_video.gst_video_format_from_string(format_str));
    }

    pub fn toString(self: VideoFormat) [*c]const u8 {
        return c_video.gst_video_format_to_string(@intFromEnum(self));
    }

    pub fn toFourcc(self: VideoFormat) u32 {
        return c_video.gst_video_format_to_fourcc(@intFromEnum(self));
    }

    pub fn getInfo(self: VideoFormat) !videoformatinfo.VideoFormatInfo {
        const ptr = c_video.gst_video_format_get_info(@intFromEnum(self));
        if (ptr == null) {
            return error.GetInfoFailed;
        }
        return videoformatinfo.VideoFormatInfo{ .ptr = @constCast(ptr) };
    }
};

test {
    @import("testing").refAllDeclsRecursive(@This());
}
