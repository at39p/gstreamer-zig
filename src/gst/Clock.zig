const std = @import("std");
const core = @import("core.zig");

const c = core.c;
const GstClock = core.GstClock;

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

    /// Get the current time of the clock
    /// Returns null if the clock is invalid or not synchronized
    pub inline fn getTime(self: Clock) ?ClockTime {
        const time = c.gst_clock_get_time(self.ptr);
        if (time == TIME_NONE.nanoseconds) {
            return null;
        }
        return @bitCast(time);
    }

    pub inline fn getResolution(self: Clock) u64 {
        return c.gst_clock_get_resolution(self.ptr);
    }

    pub inline fn setResolution(self: Clock, resolution: u64) u64 {
        return c.gst_clock_set_resolution(self.ptr, resolution);
    }
};

pub const ClockTime = packed struct(u64) {
    nanoseconds: u64,

    pub fn fromSeconds(s: u64) ClockTime {
        return .{ .nanoseconds = s * 1_000_000_000 };
    }

    pub fn fromMseconds(ms: u64) ClockTime {
        return .{ .nanoseconds = ms * 1_000_000 };
    }

    pub fn fromNseconds(ns: u64) ClockTime {
        return .{ .nanoseconds = ns };
    }

    pub fn format(self: ClockTime, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        const ns = self.nanoseconds % 1_000_000_000;
        const total_s = self.nanoseconds / 1_000_000_000;
        const s = total_s % 60;
        const m = (total_s / 60) % 60;
        const h = total_s / 3600;
        try writer.print("{d}:{d:0>2}:{d:0>2}.{d:0>9}", .{ h, m, s, ns });
    }
};

pub const TIME_NONE: ClockTime = .{ .nanoseconds = c.GST_CLOCK_TIME_NONE };

test {
    @import("testing").refAllDeclsRecursive(@This());
}
