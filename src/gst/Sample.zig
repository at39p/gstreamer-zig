const std = @import("std");
const core = @import("core.zig");
const Buffer = @import("Buffer.zig").Buffer;

pub const c = core.c;

pub const Sample = struct {
    ptr: ?*c.GstSample,

    pub fn fromPtr(ptr: ?*c.GstSample) ?Sample {
        if (ptr) |p| {
            return Sample{ .ptr = p };
        }
        return null;
    }

    pub fn deinit(self: Sample) void {
        if (self.ptr) |p| {
            c.gst_sample_unref(p);
        } else {
            std.log.warn("Sample.deinit() called on already-consumed Sample (this is safe but unnecessary - GStreamer already freed it)", .{});
        }
    }

    pub fn getBufferSize(self: Sample) usize {
        const ptr = self.ptr orelse @panic("Sample.getBufferSize() called on consumed Sample - cannot get buffer size of a sample that was already passed to a function taking ownership");
        const buffer = c.gst_sample_get_buffer(ptr);
        if (buffer) |buf| {
            return c.gst_buffer_get_size(buf);
        }
        return 0;
    }

    pub fn getPTS(self: Sample) ?u64 {
        const ptr = self.ptr orelse @panic("Sample.getPTS() called on consumed Sample - cannot get PTS of a sample that was already passed to a function taking ownership");
        const buffer = c.gst_sample_get_buffer(ptr);
        if (buffer) |buf| {
            if (c.GST_BUFFER_PTS_IS_VALID(buf)) {
                return c.GST_BUFFER_PTS(buf);
            }
        }
        return null;
    }

    pub fn getDTS(self: Sample) ?u64 {
        const ptr = self.ptr orelse @panic("Sample.getDTS() called on consumed Sample - cannot get DTS of a sample that was already passed to a function taking ownership");
        const buffer = c.gst_sample_get_buffer(ptr);
        if (buffer) |buf| {
            if (c.GST_BUFFER_DTS_IS_VALID(buf)) {
                return c.GST_BUFFER_DTS(buf);
            }
        }
        return null;
    }

    pub fn getCapsString(self: Sample, allocator: std.mem.Allocator) !?[]u8 {
        const ptr = self.ptr orelse @panic("Sample.getCapsString() called on consumed Sample - cannot get caps of a sample that was already passed to a function taking ownership");
        const caps = c.gst_sample_get_caps(ptr);
        if (caps) |caps_ptr| {
            const caps_string = c.gst_caps_to_string(caps_ptr);
            defer c.g_free(caps_string);

            if (caps_string) |str| {
                return try allocator.dupe(u8, std.mem.span(str));
            }
        }
        return null;
    }

    /// Returns the sample's buffer as a borrowed reference — it is owned by
    /// the sample and valid for its lifetime. Do NOT call Buffer.deinit() on
    /// it; unref the sample instead.
    pub inline fn getBuffer(self: Sample) ?Buffer {
        const ptr = self.ptr orelse @panic("Sample.getBuffer() called on consumed Sample - cannot get buffer of a sample that was already passed to a function taking ownership");
        const buf = c.gst_sample_get_buffer(ptr);
        if (buf) |b| {
            return Buffer{ .ptr = b };
        }
        return null;
    }

    /// Returns the sample's caps as a borrowed pointer owned by the sample.
    /// Do not unref.
    pub inline fn getCaps(self: Sample) ?*c.GstCaps {
        const ptr = self.ptr orelse @panic("Sample.getCaps() called on consumed Sample - cannot get caps of a sample that was already passed to a function taking ownership");
        return c.gst_sample_get_caps(ptr);
    }

    pub inline fn getSegment(self: Sample) ?*c.GstSegment {
        const ptr = self.ptr orelse @panic("Sample.getSegment() called on consumed Sample - cannot get segment of a sample that was already passed to a function taking ownership");
        return c.gst_sample_get_segment(ptr);
    }

    pub inline fn getInfo(self: Sample) ?*c.GstStructure {
        const ptr = self.ptr orelse @panic("Sample.getInfo() called on consumed Sample - cannot get info of a sample that was already passed to a function taking ownership");
        return c.gst_sample_get_info(ptr);
    }
};
