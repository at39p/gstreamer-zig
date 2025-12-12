const std = @import("std");
const core = @import("core.zig");

const c = core.c;
const GstClock = core.GstClock;

pub const TIME_NONE: u64 = c.GST_CLOCK_TIME_NONE;

pub const Return = enum(c_int) {
    ok = c.GST_CLOCK_OK,
    early = c.GST_CLOCK_EARLY,
    unscheduled = c.GST_CLOCK_UNSCHEDULED,
    busy = c.GST_CLOCK_BUSY,
    badtime = c.GST_CLOCK_BADTIME,
    @"error" = c.GST_CLOCK_ERROR,
    unsupported = c.GST_CLOCK_UNSUPPORTED,
    done = c.GST_CLOCK_DONE,
};

pub const EntryType = enum(c_int) {
    single = c.GST_CLOCK_ENTRY_SINGLE,
    periodic = c.GST_CLOCK_ENTRY_PERIODIC,
};

pub const Clock = struct {
    ptr: GstClock,

    pub fn deinit(self: Clock) void {
        c.gst_object_unref(@ptrCast(self.ptr));
    }

    /// Get the current time of the clock in nanoseconds
    /// Returns null if the clock is invalid or not synchronized
    pub inline fn getTime(self: Clock) ?u64 {
        const time = c.gst_clock_get_time(self.ptr);
        if (time == TIME_NONE) {
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
