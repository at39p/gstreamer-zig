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

    pub fn getStream(self: StreamCollection, index: u32) ?Stream {
        const stream_ptr = c.gst_stream_collection_get_stream(self.ptr, @intCast(index));
        if (stream_ptr) |ptr| {
            return Stream{ .ptr = ptr };
        }
        return null;
    }
};

pub const StreamType = enum(c_uint) {
    unknown = 0,
    audio = 1,
    video = 2,
    container = 4,
    text = 8,
};