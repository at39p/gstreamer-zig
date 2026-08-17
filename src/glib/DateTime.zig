const std = @import("std");
const c = @import("../c.zig").c;

pub const DateTime = struct {
    ptr: *c.GDateTime,

    pub fn fromUtc(year: i32, month: i32, day: i32, hour: i32, minute: i32, seconds: f64) !DateTime {
        const tz = c.g_time_zone_new_utc() orelse return error.TimeZoneCreationFailed;
        defer c.g_time_zone_unref(tz);
        const ptr = c.g_date_time_new(tz, year, month, day, hour, minute, seconds) orelse
            return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromLocal(year: i32, month: i32, day: i32, hour: i32, minute: i32, seconds: f64) !DateTime {
        const tz = c.g_time_zone_new_local() orelse return error.TimeZoneCreationFailed;
        defer c.g_time_zone_unref(tz);
        const ptr = c.g_date_time_new(tz, year, month, day, hour, minute, seconds) orelse
            return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    /// Wraps an existing GDateTime pointer. Does NOT add a reference
    /// the caller is transferring ownership.
    pub fn fromPtr(ptr: *c.GDateTime) DateTime {
        return .{ .ptr = ptr };
    }

    /// Wraps an existing GDateTime pointer and adds a reference.
    /// Use this when you want to keep a copy but the original remains owned elsewhere.
    pub fn fromPtrRef(ptr: *c.GDateTime) DateTime {
        return .{ .ptr = @ptrCast(c.g_date_time_ref(ptr)) };
    }

    /// Increments the reference count and returns a new handle.
    pub fn ref(self: DateTime) DateTime {
        return .{ .ptr = @ptrCast(c.g_date_time_ref(self.ptr)) };
    }

    pub fn deinit(self: DateTime) void {
        c.g_date_time_unref(self.ptr);
    }

    pub fn getYear(self: DateTime) i32 {
        return c.g_date_time_get_year(self.ptr);
    }

    pub fn getMonth(self: DateTime) i32 {
        return c.g_date_time_get_month(self.ptr);
    }

    pub fn getDayOfMonth(self: DateTime) i32 {
        return c.g_date_time_get_day_of_month(self.ptr);
    }

    pub fn getHour(self: DateTime) i32 {
        return c.g_date_time_get_hour(self.ptr);
    }

    pub fn getMinute(self: DateTime) i32 {
        return c.g_date_time_get_minute(self.ptr);
    }

    pub fn getSecond(self: DateTime) i32 {
        return c.g_date_time_get_second(self.ptr);
    }

    pub fn getMicrosecond(self: DateTime) i32 {
        return @intCast(c.g_date_time_get_microsecond(self.ptr));
    }

    /// Zig std.fmt integration (use `{f}`). Prints the datetime in ISO 8601 format.
    pub fn format(self: DateTime, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        const str: ?[*:0]u8 = @ptrCast(c.g_date_time_format_iso8601(self.ptr));
        if (str) |s| {
            defer c.g_free(s);
            const len = std.mem.len(s);
            try writer.writeAll(s[0..len]);
        } else {
            try writer.writeAll("(invalid datetime)");
        }
    }
};

test {
    @import("testing").refAllDeclsRecursive(@This());
}
