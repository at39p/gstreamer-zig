const std = @import("std");
const c = @import("../c.zig").c;

pub const DateTime = struct {
    ptr: *c.GstDateTime,

    pub fn deinit(self: DateTime) void {
        c.gst_date_time_unref(self.ptr);
    }

    pub fn new(tzoffset: f32, year: i32, month: i32, day: i32, hour: i32, minute: i32, seconds: f64) !DateTime {
        const ptr = c.gst_date_time_new(tzoffset, year, month, day, hour, minute, seconds) orelse
            return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromLocalTime(year: i32, month: i32, day: i32, hour: i32, minute: i32, seconds: f64) !DateTime {
        const ptr = c.gst_date_time_new_local_time(year, month, day, hour, minute, seconds) orelse
            return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromY(year: i32) !DateTime {
        const ptr = c.gst_date_time_new_y(year) orelse return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromYm(year: i32, month: i32) !DateTime {
        const ptr = c.gst_date_time_new_ym(year, month) orelse return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromYmd(year: i32, month: i32, day: i32) !DateTime {
        const ptr = c.gst_date_time_new_ymd(year, month, day) orelse return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn nowLocalTime() !DateTime {
        const ptr = c.gst_date_time_new_now_local_time() orelse return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn nowUtc() !DateTime {
        const ptr = c.gst_date_time_new_now_utc() orelse return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromUnixEpochLocalTime(secs: i64) !DateTime {
        const ptr = c.gst_date_time_new_from_unix_epoch_local_time(secs) orelse return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromUnixEpochUtc(secs: i64) !DateTime {
        const ptr = c.gst_date_time_new_from_unix_epoch_utc(secs) orelse return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromUnixEpochLocalTimeUsecs(usecs: i64) !DateTime {
        const ptr = c.gst_date_time_new_from_unix_epoch_local_time_usecs(usecs) orelse return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromUnixEpochUtcUsecs(usecs: i64) !DateTime {
        const ptr = c.gst_date_time_new_from_unix_epoch_utc_usecs(usecs) orelse return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromIso8601(str: [*:0]const u8) !DateTime {
        const ptr = c.gst_date_time_new_from_iso8601_string(str) orelse return error.DateTimeCreationFailed;
        return .{ .ptr = ptr };
    }

    // Field availability checks

    pub fn hasYear(self: DateTime) bool {
        return c.gst_date_time_has_year(self.ptr) != 0;
    }

    pub fn hasMonth(self: DateTime) bool {
        return c.gst_date_time_has_month(self.ptr) != 0;
    }

    pub fn hasDay(self: DateTime) bool {
        return c.gst_date_time_has_day(self.ptr) != 0;
    }

    pub fn hasTime(self: DateTime) bool {
        return c.gst_date_time_has_time(self.ptr) != 0;
    }

    pub fn hasSecond(self: DateTime) bool {
        return c.gst_date_time_has_second(self.ptr) != 0;
    }

    // Getters

    pub fn getYear(self: DateTime) i32 {
        return c.gst_date_time_get_year(self.ptr);
    }

    pub fn getMonth(self: DateTime) ?i32 {
        if (!self.hasMonth()) return null;
        return c.gst_date_time_get_month(self.ptr);
    }

    pub fn getDay(self: DateTime) ?i32 {
        if (!self.hasDay()) return null;
        return c.gst_date_time_get_day(self.ptr);
    }

    pub fn getHour(self: DateTime) ?i32 {
        if (!self.hasTime()) return null;
        return c.gst_date_time_get_hour(self.ptr);
    }

    pub fn getMinute(self: DateTime) ?i32 {
        if (!self.hasTime()) return null;
        return c.gst_date_time_get_minute(self.ptr);
    }

    pub fn getSecond(self: DateTime) ?i32 {
        if (!self.hasSecond()) return null;
        return c.gst_date_time_get_second(self.ptr);
    }

    pub fn getMicrosecond(self: DateTime) ?i32 {
        if (!self.hasSecond()) return null;
        return c.gst_date_time_get_microsecond(self.ptr);
    }

    pub fn getTimeZoneOffset(self: DateTime) ?f32 {
        if (!self.hasTime()) return null;
        return c.gst_date_time_get_time_zone_offset(self.ptr);
    }

    /// Returns an ISO 8601 string. Caller must free with allocator.free().
    pub fn toIso8601(self: DateTime, allocator: std.mem.Allocator) ![]const u8 {
        const str = c.gst_date_time_to_iso8601_string(self.ptr) orelse return error.DateTimeStringFailed;
        defer c.g_free(str);
        return allocator.dupe(u8, std.mem.span(str));
    }

    pub fn ref(self: DateTime) DateTime {
        return .{ .ptr = @ptrCast(c.gst_date_time_ref(self.ptr)) };
    }

    /// Zig std.fmt integration (use `{f}`). Prints the datetime in ISO 8601 format.
    pub fn format(self: DateTime, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        const str: ?[*:0]u8 = c.gst_date_time_to_iso8601_string(self.ptr);
        if (str) |s| {
            defer c.g_free(s);
            try writer.writeAll(std.mem.span(s));
        } else {
            try writer.writeAll("(invalid datetime)");
        }
    }
};
