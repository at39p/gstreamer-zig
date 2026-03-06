const std = @import("std");
const c = @import("video.zig").c_video;
const glib_c = @import("../../c.zig").c;
const Fraction = @import("../Fraction.zig").Fraction;
const DateTime = @import("../../glib/DateTime.zig").DateTime;

pub const VideoTimeCodeFlags = packed struct(c_uint) {
    drop_frame: bool = false,
    interlaced: bool = false,
    _padding: u30 = 0,

    pub const none = VideoTimeCodeFlags{};

    pub fn toCInt(self: VideoTimeCodeFlags) c_uint {
        return @bitCast(self);
    }

    pub fn fromCInt(val: c_uint) VideoTimeCodeFlags {
        return @bitCast(val);
    }
};

pub const VideoTimeCode = struct {
    ptr: *c.GstVideoTimeCode,

    pub fn init(
        fps_val: Fraction,
        latest_daily_jam: ?DateTime,
        flags_val: VideoTimeCodeFlags,
        hours_val: u32,
        minutes_val: u32,
        seconds_val: u32,
        frames_val: u32,
        field_count_val: u32,
    ) !VideoTimeCode {
        if (!fps_val.isValidFps()) return error.TimeCodeCreationFailed;
        const jam_ptr: ?*glib_c.GDateTime = if (latest_daily_jam) |dt| dt.ptr else null;
        const ptr = c.gst_video_time_code_new(
            @intCast(fps_val.numerator),
            @intCast(fps_val.denominator),
            @ptrCast(jam_ptr),
            @bitCast(flags_val),
            hours_val,
            minutes_val,
            seconds_val,
            frames_val,
            field_count_val,
        ) orelse return error.TimeCodeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn initEmpty() !VideoTimeCode {
        const ptr = c.gst_video_time_code_new_empty() orelse
            return error.TimeCodeCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromString(tc_str: [*:0]const u8) !VideoTimeCode {
        const ptr = c.gst_video_time_code_new_from_string(tc_str) orelse
            return error.TimeCodeFromStringFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromDateTimeFull(
        fps_val: Fraction,
        dt: DateTime,
        flags_val: VideoTimeCodeFlags,
        field_count_val: u32,
    ) !VideoTimeCode {
        if (!fps_val.isValidFps()) return error.TimeCodeFromDateTimeFailed;
        const ptr = c.gst_video_time_code_new_from_date_time_full(
            @intCast(fps_val.numerator),
            @intCast(fps_val.denominator),
            @ptrCast(dt.ptr),
            @bitCast(flags_val),
            field_count_val,
        ) orelse return error.TimeCodeFromDateTimeFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromPtr(ptr: *c.GstVideoTimeCode) VideoTimeCode {
        return .{ .ptr = ptr };
    }

    pub fn deinit(self: VideoTimeCode) void {
        c.gst_video_time_code_free(self.ptr);
    }

    pub fn copy(self: VideoTimeCode) !VideoTimeCode {
        const ptr = c.gst_video_time_code_copy(self.ptr) orelse
            return error.TimeCodeCopyFailed;
        return .{ .ptr = ptr };
    }

    pub fn isValid(self: VideoTimeCode) bool {
        return c.gst_video_time_code_is_valid(self.ptr) != 0;
    }

    pub fn hours(self: VideoTimeCode) u32 {
        return self.ptr.hours;
    }

    pub fn minutes(self: VideoTimeCode) u32 {
        return self.ptr.minutes;
    }

    pub fn seconds(self: VideoTimeCode) u32 {
        return self.ptr.seconds;
    }

    pub fn frames(self: VideoTimeCode) u32 {
        return self.ptr.frames;
    }

    pub fn fieldCount(self: VideoTimeCode) u32 {
        return self.ptr.field_count;
    }

    pub fn fps(self: VideoTimeCode) Fraction {
        return Fraction.new(
            @as(i32, @intCast(self.ptr.config.fps_n)),
            @as(i32, @intCast(self.ptr.config.fps_d)),
        );
    }

    pub fn getFlags(self: VideoTimeCode) VideoTimeCodeFlags {
        return @bitCast(self.ptr.config.flags);
    }

    pub fn latestDailyJam(self: VideoTimeCode) ?DateTime {
        const jam: ?*glib_c.GDateTime = @ptrCast(self.ptr.config.latest_daily_jam);
        if (jam) |ptr| {
            return DateTime.fromPtrRef(ptr);
        }
        return null;
    }

    pub fn setHours(self: VideoTimeCode, val: u32) void {
        self.ptr.hours = val;
    }

    pub fn setMinutes(self: VideoTimeCode, val: u32) void {
        std.debug.assert(val < 60);
        self.ptr.minutes = val;
    }

    pub fn setSeconds(self: VideoTimeCode, val: u32) void {
        std.debug.assert(val < 60);
        self.ptr.seconds = val;
    }

    pub fn setFrames(self: VideoTimeCode, val: u32) void {
        self.ptr.frames = val;
    }

    pub fn setFieldCount(self: VideoTimeCode, val: u32) void {
        std.debug.assert(val <= 2);
        self.ptr.field_count = val;
    }

    pub fn setFps(self: VideoTimeCode, new_fps: Fraction) !void {
        if (!new_fps.isValidFps()) return error.InvalidFps;
        self.ptr.config.fps_n = @intCast(new_fps.numerator);
        self.ptr.config.fps_d = @intCast(new_fps.denominator);
    }

    pub fn setFlags(self: VideoTimeCode, flags_val: VideoTimeCodeFlags) void {
        self.ptr.config.flags = @bitCast(flags_val);
    }

    pub fn setLatestDailyJam(self: VideoTimeCode, dt: ?DateTime) void {
        const old: ?*glib_c.GDateTime = @ptrCast(self.ptr.config.latest_daily_jam);
        if (old) |old_ptr| {
            glib_c.g_date_time_unref(old_ptr);
        }
        if (dt) |new_dt| {
            self.ptr.config.latest_daily_jam = @ptrCast(glib_c.g_date_time_ref(new_dt.ptr));
        } else {
            self.ptr.config.latest_daily_jam = null;
        }
    }

    pub fn addFrames(self: VideoTimeCode, frames_to_add: i64) !void {
        if (!self.isValid()) return error.InvalidTimeCode;
        c.gst_video_time_code_add_frames(self.ptr, frames_to_add);
    }

    pub fn addInterval(self: VideoTimeCode, interval: VideoTimeCodeInterval) !VideoTimeCode {
        if (!self.isValid()) return error.InvalidTimeCode;
        const ptr = c.gst_video_time_code_add_interval(self.ptr, interval.ptr) orelse
            return error.AddIntervalFailed;
        return .{ .ptr = ptr };
    }

    pub fn compare(self: VideoTimeCode, other: VideoTimeCode) std.math.Order {
        const result = c.gst_video_time_code_compare(self.ptr, other.ptr);
        if (result < 0) return .lt;
        if (result > 0) return .gt;
        return .eq;
    }

    pub fn framesSinceDailyJam(self: VideoTimeCode) !u64 {
        if (!self.isValid()) return error.InvalidTimeCode;
        return c.gst_video_time_code_frames_since_daily_jam(self.ptr);
    }

    pub fn incrementFrame(self: VideoTimeCode) !void {
        if (!self.isValid()) return error.InvalidTimeCode;
        c.gst_video_time_code_increment_frame(self.ptr);
    }

    pub fn nsecSinceDailyJam(self: VideoTimeCode) !u64 {
        if (!self.isValid()) return error.InvalidTimeCode;
        return c.gst_video_time_code_nsec_since_daily_jam(self.ptr);
    }

    pub fn toDateTime(self: VideoTimeCode) !DateTime {
        if (!self.isValid()) return error.InvalidTimeCode;
        const ptr: ?*glib_c.GDateTime = @ptrCast(c.gst_video_time_code_to_date_time(self.ptr));
        if (ptr) |p| {
            return DateTime.fromPtr(p);
        }
        return error.TimeCodeToDateTimeFailed;
    }

    pub fn format(self: VideoTimeCode, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        const str: ?[*:0]u8 = @ptrCast(c.gst_video_time_code_to_string(self.ptr));
        if (str) |s| {
            defer glib_c.g_free(s);
            const len = std.mem.len(s);
            try writer.writeAll(s[0..len]);
        } else {
            try writer.writeAll("(invalid timecode)");
        }
    }
};

pub const VideoTimeCodeInterval = struct {
    ptr: *c.GstVideoTimeCodeInterval,

    pub fn init(hours_val: u32, minutes_val: u32, seconds_val: u32, frames_val: u32) !VideoTimeCodeInterval {
        const ptr = c.gst_video_time_code_interval_new(hours_val, minutes_val, seconds_val, frames_val) orelse
            return error.IntervalCreationFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromString(tc_str: [*:0]const u8) !VideoTimeCodeInterval {
        const ptr = c.gst_video_time_code_interval_new_from_string(tc_str) orelse
            return error.IntervalFromStringFailed;
        return .{ .ptr = ptr };
    }

    pub fn fromPtr(ptr: *c.GstVideoTimeCodeInterval) VideoTimeCodeInterval {
        return .{ .ptr = ptr };
    }

    pub fn deinit(self: VideoTimeCodeInterval) void {
        c.gst_video_time_code_interval_free(self.ptr);
    }

    pub fn copy(self: VideoTimeCodeInterval) !VideoTimeCodeInterval {
        const ptr = c.gst_video_time_code_interval_copy(self.ptr) orelse
            return error.IntervalCopyFailed;
        return .{ .ptr = ptr };
    }

    pub fn hours(self: VideoTimeCodeInterval) u32 {
        return self.ptr.hours;
    }

    pub fn minutes(self: VideoTimeCodeInterval) u32 {
        return self.ptr.minutes;
    }

    pub fn seconds(self: VideoTimeCodeInterval) u32 {
        return self.ptr.seconds;
    }

    pub fn frames(self: VideoTimeCodeInterval) u32 {
        return self.ptr.frames;
    }

    pub fn setHours(self: VideoTimeCodeInterval, val: u32) void {
        self.ptr.hours = val;
    }

    pub fn setMinutes(self: VideoTimeCodeInterval, val: u32) void {
        std.debug.assert(val < 60);
        self.ptr.minutes = val;
    }

    pub fn setSeconds(self: VideoTimeCodeInterval, val: u32) void {
        std.debug.assert(val < 60);
        self.ptr.seconds = val;
    }

    pub fn setFrames(self: VideoTimeCodeInterval, val: u32) void {
        self.ptr.frames = val;
    }

    pub fn eql(self: VideoTimeCodeInterval, other: VideoTimeCodeInterval) bool {
        return self.ptr.hours == other.ptr.hours and
            self.ptr.minutes == other.ptr.minutes and
            self.ptr.seconds == other.ptr.seconds and
            self.ptr.frames == other.ptr.frames;
    }

    pub fn order(self: VideoTimeCodeInterval, other: VideoTimeCodeInterval) std.math.Order {
        if (self.ptr.hours != other.ptr.hours) return std.math.order(self.ptr.hours, other.ptr.hours);
        if (self.ptr.minutes != other.ptr.minutes) return std.math.order(self.ptr.minutes, other.ptr.minutes);
        if (self.ptr.seconds != other.ptr.seconds) return std.math.order(self.ptr.seconds, other.ptr.seconds);
        return std.math.order(self.ptr.frames, other.ptr.frames);
    }

    pub fn format(self: VideoTimeCodeInterval, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try std.fmt.format(writer, "{d:0>2}:{d:0>2}:{d:0>2}:{d:0>2}", .{
            self.ptr.hours,
            self.ptr.minutes,
            self.ptr.seconds,
            self.ptr.frames,
        });
    }
};

pub const VideoTimeCodeMeta = struct {
    ptr: *c.GstVideoTimeCodeMeta,

    const Buffer = @import("../Buffer.zig").Buffer;

    pub fn getFromBuffer(buffer: Buffer) ?VideoTimeCodeMeta {
        const buf_ptr: *c.GstBuffer = @ptrCast(buffer.ptr orelse @panic("VideoTimeCodeMeta.getFromBuffer() called on consumed Buffer"));
        const meta_ptr = c.gst_buffer_get_meta(buf_ptr, c.gst_video_time_code_meta_api_get_type());
        if (meta_ptr) |ptr| {
            return .{ .ptr = @ptrCast(ptr) };
        }
        return null;
    }

    pub fn addToBuffer(buffer: Buffer, tc: VideoTimeCode) ?VideoTimeCodeMeta {
        const buf_ptr: *c.GstBuffer = @ptrCast(buffer.ptr orelse @panic("VideoTimeCodeMeta.addToBuffer() called on consumed Buffer"));
        const meta_ptr = c.gst_buffer_add_video_time_code_meta(buf_ptr, tc.ptr);
        if (meta_ptr) |ptr| {
            return .{ .ptr = ptr };
        }
        return null;
    }

    pub fn addToBufferFull(
        buffer: Buffer,
        fps_val: Fraction,
        latest_daily_jam: ?DateTime,
        flags_val: VideoTimeCodeFlags,
        hours_val: u32,
        minutes_val: u32,
        seconds_val: u32,
        frames_val: u32,
        field_count_val: u32,
    ) ?VideoTimeCodeMeta {
        if (!fps_val.isValidFps()) return null;
        const buf_ptr: *c.GstBuffer = @ptrCast(buffer.ptr orelse @panic("VideoTimeCodeMeta.addToBufferFull() called on consumed Buffer"));
        const jam_ptr: ?*glib_c.GDateTime = if (latest_daily_jam) |dt| dt.ptr else null;
        const meta_ptr = c.gst_buffer_add_video_time_code_meta_full(
            buf_ptr,
            @intCast(fps_val.numerator),
            @intCast(fps_val.denominator),
            @ptrCast(jam_ptr),
            @bitCast(flags_val),
            hours_val,
            minutes_val,
            seconds_val,
            frames_val,
            field_count_val,
        );
        if (meta_ptr) |ptr| {
            return .{ .ptr = ptr };
        }
        return null;
    }

    /// Get the timecode from this meta. Returns an owned copy that the caller
    /// must free with deinit().
    pub fn getTimeCode(self: VideoTimeCodeMeta) !VideoTimeCode {
        return VideoTimeCode.copy(.{ .ptr = &self.ptr.tc });
    }

    pub fn fromPtr(ptr: *c.GstVideoTimeCodeMeta) VideoTimeCodeMeta {
        return .{ .ptr = ptr };
    }
};
