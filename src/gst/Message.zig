const std = @import("std");
const core = @import("core.zig");

pub const c = core.c;
pub const GstMessage = core.GstMessage;

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
};

pub const Message = struct {
    ptr: GstMessage,

    pub fn deinit(self: Message) void {
        c.gst_message_unref(self.ptr);
    }

    pub fn getType(self: Message) MessageType {
        const raw_type = self.ptr.*.type;
        return std.meta.intToEnum(MessageType, raw_type) catch {
            std.debug.print("Unknown message type: {}\n", .{raw_type});
            return MessageType.unknown;
        };
    }

    pub fn parseErrorAndPrint(self: Message) !bool {
        var err: ?*c.GError = null;
        var debug: [*c]u8 = null;

        c.gst_message_parse_error(self.ptr, &err, &debug);

        if (err) |e| {
            defer c.g_error_free(e);
            defer if (debug != null) c.g_free(debug);

            const is_quit = std.mem.indexOf(u8, std.mem.span(e.message), "Quit requested") != null;

            if (is_quit) {
                std.debug.print("Application quit requested\n", .{});
                return true;
            }

            std.debug.print("Error: {s}\n", .{e.message});
            if (debug != null) {
                std.debug.print("Debug: {s}\n", .{debug});
            }
            return false;
        }

        return error.NoErrorInMessage;
    }
};
