const std = @import("std");
const core = @import("core.zig");

pub const c = core.c;

pub const Buffer = struct {
    ptr: ?*c.GstBuffer,

    pub fn init(size: usize) ?Buffer {
        const ptr = c.gst_buffer_new_allocate(null, size, null);
        if (ptr) |p| {
            return Buffer{ .ptr = p };
        }
        return null;
    }

    pub fn deinit(self: Buffer) void {
        if (self.ptr) |p| {
            c.gst_buffer_unref(p);
        } else {
            std.log.warn("Buffer.deinit() called on already-consumed Buffer (this is safe but unnecessary - GStreamer already freed it)", .{});
        }
    }

    pub inline fn getSize(self: Buffer) usize {
        const ptr = self.ptr orelse @panic("Buffer.getSize() called on consumed Buffer - cannot get size of a buffer that was already passed to a function taking ownership");
        return c.gst_buffer_get_size(ptr);
    }

    pub inline fn setPts(self: Buffer, pts: u64) void {
        const ptr = self.ptr orelse @panic("Buffer.setPts() called on consumed Buffer - cannot set PTS on a buffer that was already passed to a function taking ownership");
        ptr.*.pts = pts;
    }

    pub inline fn setDts(self: Buffer, dts: u64) void {
        const ptr = self.ptr orelse @panic("Buffer.setDts() called on consumed Buffer - cannot set DTS on a buffer that was already passed to a function taking ownership");
        ptr.*.dts = dts;
    }

    pub inline fn getPts(self: Buffer) ?u64 {
        const ptr = self.ptr orelse @panic("Buffer.getPts() called on consumed Buffer - cannot get PTS of a buffer that was already passed to a function taking ownership");
        if (c.GST_BUFFER_PTS_IS_VALID(ptr)) {
            return c.GST_BUFFER_PTS(ptr);
        }
        return null;
    }

    pub inline fn getDts(self: Buffer) ?u64 {
        const ptr = self.ptr orelse @panic("Buffer.getDts() called on consumed Buffer - cannot get DTS of a buffer that was already passed to a function taking ownership");
        if (c.GST_BUFFER_DTS_IS_VALID(ptr)) {
            return c.GST_BUFFER_DTS(ptr);
        }
        return null;
    }

    pub const MapInfo = struct {
        data: [*]u8,
        size: usize,
        buffer: Buffer,
        info: c.GstMapInfo,

        pub fn deinit(self: *MapInfo) void {
            const ptr = self.buffer.ptr orelse @panic("MapInfo.deinit() called on MapInfo from consumed Buffer - cannot unmap a buffer that was already passed to a function taking ownership");
            c.gst_buffer_unmap(ptr, &self.info);
        }
    };

    pub fn map(self: Buffer, flags: c.GstMapFlags) ?MapInfo {
        const ptr = self.ptr orelse @panic("Buffer.map() called on consumed Buffer - cannot map a buffer that was already passed to a function taking ownership");
        var info: c.GstMapInfo = undefined;
        if (c.gst_buffer_map(ptr, &info, flags) != 0) {
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
