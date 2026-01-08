const std = @import("std");
const core = @import("core.zig");
const structure = @import("Structure.zig");

const c = core.c;
pub const Structure = structure.Structure;

pub const EventType = enum(c_uint) {
    unknown = c.GST_EVENT_UNKNOWN,
    flush_start = c.GST_EVENT_FLUSH_START,
    flush_stop = c.GST_EVENT_FLUSH_STOP,
    stream_start = c.GST_EVENT_STREAM_START,
    caps = c.GST_EVENT_CAPS,
    segment = c.GST_EVENT_SEGMENT,
    stream_collection = c.GST_EVENT_STREAM_COLLECTION,
    tag = c.GST_EVENT_TAG,
    buffersize = c.GST_EVENT_BUFFERSIZE,
    sink_message = c.GST_EVENT_SINK_MESSAGE,
    stream_group_done = c.GST_EVENT_STREAM_GROUP_DONE,
    eos = c.GST_EVENT_EOS,
    toc = c.GST_EVENT_TOC,
    protection = c.GST_EVENT_PROTECTION,
    segment_done = c.GST_EVENT_SEGMENT_DONE,
    gap = c.GST_EVENT_GAP,
    instant_rate_change = c.GST_EVENT_INSTANT_RATE_CHANGE,
    qos = c.GST_EVENT_QOS,
    seek = c.GST_EVENT_SEEK,
    navigation = c.GST_EVENT_NAVIGATION,
    latency = c.GST_EVENT_LATENCY,
    step = c.GST_EVENT_STEP,
    reconfigure = c.GST_EVENT_RECONFIGURE,
    toc_select = c.GST_EVENT_TOC_SELECT,
    select_streams = c.GST_EVENT_SELECT_STREAMS,
    instant_rate_sync_time = c.GST_EVENT_INSTANT_RATE_SYNC_TIME,
    custom_upstream = c.GST_EVENT_CUSTOM_UPSTREAM,
    custom_downstream = c.GST_EVENT_CUSTOM_DOWNSTREAM,
    custom_downstream_oob = c.GST_EVENT_CUSTOM_DOWNSTREAM_OOB,
    custom_downstream_sticky = c.GST_EVENT_CUSTOM_DOWNSTREAM_STICKY,
    custom_both = c.GST_EVENT_CUSTOM_BOTH,
    custom_both_oob = c.GST_EVENT_CUSTOM_BOTH_OOB,
    _,
};

pub const Event = struct {
    ptr: *c.GstEvent,

    pub fn initCustom(event_type: EventType, s: Structure) !Event {
        const ptr = c.gst_event_new_custom(@intFromEnum(event_type), s.ptr);
        if (ptr == null) {
            return error.EventCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn initEos() !Event {
        const ptr = c.gst_event_new_eos();
        if (ptr == null) {
            return error.EventCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn initFlushStart() !Event {
        const ptr = c.gst_event_new_flush_start();
        if (ptr == null) {
            return error.EventCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn initFlushStop(reset_time: bool) !Event {
        const ptr = c.gst_event_new_flush_stop(if (reset_time) 1 else 0);
        if (ptr == null) {
            return error.EventCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn deinit(self: Event) void {
        c.gst_event_unref(self.ptr);
    }

    pub fn ref(self: Event) Event {
        return .{ .ptr = c.gst_event_ref(self.ptr) };
    }

    pub fn getType(self: Event) EventType {
        const event_type = c.GST_EVENT_TYPE(self.ptr);
        return @enumFromInt(event_type);
    }

    pub fn getTypeName(self: Event) [*:0]const u8 {
        return c.gst_event_type_get_name(c.GST_EVENT_TYPE(self.ptr));
    }

    pub fn getStructure(self: Event) ?Structure {
        const ptr = c.gst_event_get_structure(self.ptr);
        if (ptr == null) return null;
        return Structure{ .ptr = @constCast(ptr) };
    }

    pub fn getWritableStructure(self: Event) ?Structure {
        const ptr = c.gst_event_writable_structure(self.ptr);
        if (ptr == null) return null;
        return Structure{ .ptr = ptr };
    }

    pub fn hasName(self: Event, name: [*:0]const u8) bool {
        return c.gst_event_has_name(self.ptr, name) != 0;
    }

    pub fn getSeqnum(self: Event) u32 {
        return c.gst_event_get_seqnum(self.ptr);
    }

    pub fn setSeqnum(self: Event, seqnum: u32) void {
        c.gst_event_set_seqnum(self.ptr, seqnum);
    }

    pub fn getRunningTimeOffset(self: Event) i64 {
        return c.gst_event_get_running_time_offset(self.ptr);
    }

    pub fn setRunningTimeOffset(self: Event, offset: i64) void {
        c.gst_event_set_running_time_offset(self.ptr, offset);
    }

    pub fn isWritable(self: Event) bool {
        return c.gst_event_is_writable(self.ptr) != 0;
    }

    pub fn makeWritable(self: Event) Event {
        return .{ .ptr = c.gst_event_make_writable(self.ptr) };
    }

    pub fn copy(self: Event) !Event {
        const ptr = c.gst_event_copy(self.ptr);
        if (ptr == null) {
            return error.EventCopyFailed;
        }
        return .{ .ptr = ptr };
    }
};
