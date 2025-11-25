const std = @import("std");
const core = @import("core.zig");

pub const c = core.c;
pub const GstClock = core.GstClock;

pub const Clock = struct {
    ptr: GstClock,

    pub fn deinit(self: Clock) void {
        c.gst_object_unref(@ptrCast(self.ptr));
    }

    /// Get the current time of the clock in nanoseconds
    /// Returns null if the clock is invalid or not synchronized (GST_CLOCK_TIME_NONE)
    pub inline fn getTime(self: Clock) ?u64 {
        const time = c.gst_clock_get_time(self.ptr);
        if (time == c.GST_CLOCK_TIME_NONE) {
            return null;
        }
        return time;
    }

    pub inline fn getResolution(self: Clock) u64 {
        return c.gst_clock_get_resolution(self.ptr);
    }

    pub inline fn setResolution(self: Clock, resolution: u64) u64 {
        return c.gst_clock_set_resolution(self.ptr, resolution);
    }
};
