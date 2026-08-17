// GStreamer video plugin bindings (libgstreamer-video-1.0)
// Provides video format handling, frame access, and video metadata.
pub const c_video = @import("c");

pub const VideoInfo = @import("VideoInfo.zig").VideoInfo;
pub const VideoFormat = @import("VideoFormat.zig").VideoFormat;
pub const VideoFormatInfo = @import("VideoFormatInfo.zig").VideoFormatInfo;
const videoframe = @import("VideoFrame.zig");
pub const VideoFrame = videoframe.VideoFrame;
pub const VideoFrameFlags = videoframe.VideoFrameFlags;
const videotimecode = @import("VideoTimeCode.zig");
pub const VideoTimeCode = videotimecode.VideoTimeCode;
pub const VideoTimeCodeInterval = videotimecode.VideoTimeCodeInterval;
pub const VideoTimeCodeFlags = videotimecode.VideoTimeCodeFlags;
pub const VideoTimeCodeMeta = videotimecode.VideoTimeCodeMeta;

test {
    @import("testing").refAllDeclsRecursive(@This());
}
