const std = @import("std");
const core = @import("core.zig");

pub const c = core.c;
pub const GstStream = core.GstStream;
pub const GstStreamCollection = core.GstStreamCollection;

pub const Stream = struct {
    ptr: GstStream,

    pub fn deinit(self: Stream) void {
        c.gst_object_unref(@ptrCast(self.ptr));
    }

    pub fn getStreamType(self: Stream) StreamType {
        const stream_type = c.gst_stream_get_stream_type(self.ptr);
        return @enumFromInt(stream_type);
    }

    /// Returned string is owned by the stream and valid for its lifetime.
    pub fn getStreamId(self: Stream) ?[*:0]const u8 {
        return c.gst_stream_get_stream_id(self.ptr);
    }
};

pub const StreamCollection = struct {
    ptr: GstStreamCollection,

    pub fn deinit(self: StreamCollection) void {
        c.gst_object_unref(@ptrCast(self.ptr));
    }

    pub fn getSize(self: StreamCollection) u32 {
        return @intCast(c.gst_stream_collection_get_size(self.ptr));
    }

    /// Returns a borrowed reference owned by the collection — do not call
    /// deinit() on it unless you take your own ref first.
    pub fn getStream(self: StreamCollection, index: u32) ?Stream {
        const stream_ptr = c.gst_stream_collection_get_stream(self.ptr, @intCast(index));
        if (stream_ptr) |ptr| {
            return Stream{ .ptr = ptr };
        }
        return null;
    }
};

/// GstStreamType is a flags type; values may be combined (e.g. a muxed
/// stream can be `container | video`), hence the non-exhaustive enum.
pub const StreamType = enum(c_uint) {
    unknown = c.GST_STREAM_TYPE_UNKNOWN,
    audio = c.GST_STREAM_TYPE_AUDIO,
    video = c.GST_STREAM_TYPE_VIDEO,
    container = c.GST_STREAM_TYPE_CONTAINER,
    text = c.GST_STREAM_TYPE_TEXT,
    metadata = c.GST_STREAM_TYPE_METADATA,
    _,

    pub fn contains(self: StreamType, other: StreamType) bool {
        return (@intFromEnum(self) & @intFromEnum(other)) == @intFromEnum(other);
    }
};