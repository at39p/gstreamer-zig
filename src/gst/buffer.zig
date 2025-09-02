const std = @import("std");
const core = @import("core.zig");

pub const c = core.c;

pub const Buffer = struct {
    ptr: *c.GstBuffer,

    pub fn init(size: usize) ?Buffer {
        const ptr = c.gst_buffer_new_allocate(null, size, null);
        if (ptr) |p| {
            return Buffer{ .ptr = p };
        }
        return null;
    }

    pub fn deinit(self: Buffer) void {
        c.gst_buffer_unref(self.ptr);
    }

    pub inline fn getSize(self: Buffer) usize {
        return c.gst_buffer_get_size(self.ptr);
    }

    pub inline fn setPts(self: Buffer, pts: u64) void {
        self.ptr.*.pts = pts;
    }

    pub inline fn setDts(self: Buffer, dts: u64) void {
        self.ptr.*.dts = dts;
    }

    pub inline fn getPts(self: Buffer) ?u64 {
        if (c.GST_BUFFER_PTS_IS_VALID(self.ptr)) {
            return c.GST_BUFFER_PTS(self.ptr);
        }
        return null;
    }

    pub inline fn getDts(self: Buffer) ?u64 {
        if (c.GST_BUFFER_DTS_IS_VALID(self.ptr)) {
            return c.GST_BUFFER_DTS(self.ptr);
        }
        return null;
    }

    pub const MapInfo = struct {
        data: [*]u8,
        size: usize,
        buffer: Buffer,
        info: c.GstMapInfo,

        pub fn deinit(self: *MapInfo) void {
            c.gst_buffer_unmap(self.buffer.ptr, &self.info);
        }
    };

    pub fn map(self: Buffer, flags: c.GstMapFlags) ?MapInfo {
        var info: c.GstMapInfo = undefined;
        if (c.gst_buffer_map(self.ptr, &info, flags) != 0) {
            return MapInfo{
                .data = @ptrCast(info.data),
                .size = info.size,
                .buffer = self,
                .info = info,
            };
        }
        return null;
    }

    pub fn mapWrite(self: Buffer) ?MapInfo {
        return self.map(c.GST_MAP_WRITE);
    }

    pub fn mapRead(self: Buffer) ?MapInfo {
        return self.map(c.GST_MAP_READ);
    }
};
