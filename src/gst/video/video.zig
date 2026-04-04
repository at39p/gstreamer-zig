// GStreamer video plugin bindings (libgstreamer-video-1.0)
// Provides video format handling, frame access, and video metadata.
pub const c_video = @cImport({
    @cInclude("gst/video/video.h");
});

pub const VideoInfo = @import("VideoInfo.zig").VideoInfo;
pub const VideoFormat = @import("VideoFormat.zig").VideoFormat;
pub const VideoFormatInfo = @import("VideoFormatInfo.zig").VideoFormatInfo;
const videoframe = @import("VideoFrame.zig");
pub const VideoFrame = videoframe.VideoFrame;
pub const VideoFrameFlags = videoframe.VideoFrameFlags;
