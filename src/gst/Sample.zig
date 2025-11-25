const std = @import("std");
const core = @import("core.zig");

pub const c = core.c;

pub const Sample = struct {
    ptr: *c.GstSample,

    pub fn deinit(self: Sample) void {
        c.gst_sample_unref(self.ptr);
    }

    pub fn getBufferSize(self: Sample) usize {
        const buffer = c.gst_sample_get_buffer(self.ptr);
        if (buffer) |buf| {
            return c.gst_buffer_get_size(buf);
        }
        return 0;
    }

    pub fn getPTS(self: Sample) ?u64 {
        const buffer = c.gst_sample_get_buffer(self.ptr);
        if (buffer) |buf| {
            if (c.GST_BUFFER_PTS_IS_VALID(buf)) {
                return c.GST_BUFFER_PTS(buf);
            }
        }
        return null;
    }

    pub fn getDTS(self: Sample) ?u64 {
        const buffer = c.gst_sample_get_buffer(self.ptr);
        if (buffer) |buf| {
            if (c.GST_BUFFER_DTS_IS_VALID(buf)) {
                return c.GST_BUFFER_DTS(buf);
            }
        }
        return null;
    }

    pub fn getCapsString(self: Sample, allocator: std.mem.Allocator) !?[]u8 {
        const caps = c.gst_sample_get_caps(self.ptr);
        if (caps) |caps_ptr| {
            const caps_string = c.gst_caps_to_string(caps_ptr);
            defer c.g_free(caps_string);

            if (caps_string) |str| {
                return try allocator.dupe(u8, std.mem.span(str));
            }
        }
        return null;
    }

    pub inline fn getBuffer(self: Sample) ?*c.GstBuffer {
        return c.gst_sample_get_buffer(self.ptr);
    }

    pub inline fn getCaps(self: Sample) ?*c.GstCaps {
        return c.gst_sample_get_caps(self.ptr);
    }

    pub inline fn getSegment(self: Sample) ?*c.GstSegment {
        return c.gst_sample_get_segment(self.ptr);
    }

    pub inline fn getInfo(self: Sample) ?*c.GstStructure {
        return c.gst_sample_get_info(self.ptr);
    }
};
