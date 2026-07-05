const std = @import("std");
const core = @import("core.zig");

const c = core.c;
const GstMessage = core.GstMessage;

// GStreamer message types
pub const MessageType = enum(c_int) {
    unknown = c.GST_MESSAGE_UNKNOWN,
    eos = c.GST_MESSAGE_EOS,
    err = c.GST_MESSAGE_ERROR,
    warning = c.GST_MESSAGE_WARNING,
    info = c.GST_MESSAGE_INFO,
    tag = c.GST_MESSAGE_TAG,
    buffering = c.GST_MESSAGE_BUFFERING,
    state_changed = c.GST_MESSAGE_STATE_CHANGED,
    state_dirty = c.GST_MESSAGE_STATE_DIRTY,
    step_done = c.GST_MESSAGE_STEP_DONE,
    clock_provide = c.GST_MESSAGE_CLOCK_PROVIDE,
    clock_lost = c.GST_MESSAGE_CLOCK_LOST,
    new_clock = c.GST_MESSAGE_NEW_CLOCK,
    structure_change = c.GST_MESSAGE_STRUCTURE_CHANGE,
    stream_status = c.GST_MESSAGE_STREAM_STATUS,
    application = c.GST_MESSAGE_APPLICATION,
    element = c.GST_MESSAGE_ELEMENT,
    segment_start = c.GST_MESSAGE_SEGMENT_START,
    segment_done = c.GST_MESSAGE_SEGMENT_DONE,
    duration_changed = c.GST_MESSAGE_DURATION_CHANGED,
    latency = c.GST_MESSAGE_LATENCY,
    async_start = c.GST_MESSAGE_ASYNC_START,
    async_done = c.GST_MESSAGE_ASYNC_DONE,
    request_state = c.GST_MESSAGE_REQUEST_STATE,
    step_start = c.GST_MESSAGE_STEP_START,
    qos = c.GST_MESSAGE_QOS,
    progress = c.GST_MESSAGE_PROGRESS,
    toc = c.GST_MESSAGE_TOC,
    reset_time = c.GST_MESSAGE_RESET_TIME,
    stream_start = c.GST_MESSAGE_STREAM_START,
    need_context = c.GST_MESSAGE_NEED_CONTEXT,
    have_context = c.GST_MESSAGE_HAVE_CONTEXT,
    any = c.GST_MESSAGE_ANY,
    _,

    /// GstMessageType values are bit flags. Combine several types into a
    /// mask for the filtered bus functions, e.g.
    /// `bus.popMessage(timeout, MessageType.combine(&.{ .err, .eos }))`.
    pub fn combine(types: []const MessageType) MessageType {
        var mask: c_int = 0;
        for (types) |t| mask |= @intFromEnum(t);
        return @enumFromInt(mask);
    }
};

pub const Message = struct {
    ptr: ?GstMessage,

    pub fn deinit(self: Message) void {
        if (self.ptr) |p| {
            c.gst_message_unref(p);
        } else {
            std.log.warn("Message.deinit() called on already-consumed Message (this is safe but unnecessary - GStreamer already freed it)", .{});
        }
    }

    pub fn getType(self: Message) MessageType {
        const ptr = self.ptr orelse @panic("Message.getType() called on consumed Message - cannot get type of a message that was already passed to a function taking ownership");
        return @enumFromInt(ptr.*.type);
    }

    pub const ParsedError = struct {
        err: *c.GError,
        debug: ?[*:0]u8,

        pub fn message(self: ParsedError) [:0]const u8 {
            return std.mem.span(@as([*:0]const u8, @ptrCast(self.err.message)));
        }

        pub fn debugInfo(self: ParsedError) ?[:0]const u8 {
            return if (self.debug) |d| std.mem.span(d) else null;
        }

        pub fn deinit(self: ParsedError) void {
            c.g_error_free(self.err);
            if (self.debug) |d| c.g_free(d);
        }
    };

    /// Extracts the GError and debug string from an `.err` message
    /// (gst_message_parse_error). Caller must call deinit() on the result.
    pub fn parseError(self: Message) !ParsedError {
        const ptr = self.ptr orelse @panic("Message.parseError() called on consumed Message - cannot parse a message that was already passed to a function taking ownership");
        var err: ?*c.GError = null;
        var debug: [*c]u8 = null;

        c.gst_message_parse_error(ptr, &err, &debug);

        const e = err orelse return error.NoErrorInMessage;
        return .{ .err = e, .debug = debug };
    }

    /// Convenience: parse an `.err` message and print it to stderr.
    pub fn parseErrorAndPrint(self: Message) !void {
        const parsed = try self.parseError();
        defer parsed.deinit();

        std.debug.print("Error: {s}\n", .{parsed.message()});
        if (parsed.debugInfo()) |d| {
            std.debug.print("Debug: {s}\n", .{d});
        }
    }
};
