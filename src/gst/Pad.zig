const std = @import("std");
const core = @import("core.zig");
const caps = @import("Caps.zig");
const padtemplate = @import("PadTemplate.zig");
const element = @import("Element.zig");
const buffer = @import("Buffer.zig");
const event = @import("Event.zig");

const c = core.c;
const GstPad = *c.GstPad;
const Caps = caps.Caps;
const Element = element.Element;
const Buffer = buffer.Buffer;
pub const Event = event.Event;
pub const EventType = event.EventType;

pub const PadDirection = padtemplate.PadDirection;
pub const PadTemplate = padtemplate.PadTemplate;

pub const PadProbeReturn = enum(c_uint) {
    drop = c.GST_PAD_PROBE_DROP,
    ok = c.GST_PAD_PROBE_OK,
    remove = c.GST_PAD_PROBE_REMOVE,
    pass = c.GST_PAD_PROBE_PASS,
    handled = c.GST_PAD_PROBE_HANDLED,
};

pub const PadProbeType = struct {
    value: c_uint,

    // Individual flags
    pub const idle = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_IDLE };
    pub const block = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_BLOCK };
    pub const buffer = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_BUFFER };
    pub const buffer_list = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_BUFFER_LIST };
    pub const event_downstream = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_EVENT_DOWNSTREAM };
    pub const event_upstream = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_EVENT_UPSTREAM };
    pub const event_flush = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_EVENT_FLUSH };
    pub const query_downstream = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_QUERY_DOWNSTREAM };
    pub const query_upstream = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_QUERY_UPSTREAM };
    pub const push = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_PUSH };
    pub const pull = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_PULL };

    // Common flag combinations
    pub const blocking = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_BLOCKING };
    pub const data_downstream = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_DATA_DOWNSTREAM };
    pub const data_upstream = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_DATA_UPSTREAM };
    pub const data_both = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_DATA_BOTH };
    pub const block_downstream = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_BLOCK_DOWNSTREAM };
    pub const block_upstream = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_BLOCK_UPSTREAM };
    pub const event_both = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_EVENT_BOTH };
    pub const query_both = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_QUERY_BOTH };
    pub const all_both = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_ALL_BOTH };
    pub const scheduling = PadProbeType{ .value = c.GST_PAD_PROBE_TYPE_SCHEDULING };

    // Methods for combining flags
    pub fn bitwiseOr(self: PadProbeType, other: PadProbeType) PadProbeType {
        return .{ .value = self.value | other.value };
    }

    pub fn bitwiseAnd(self: PadProbeType, other: PadProbeType) PadProbeType {
        return .{ .value = self.value & other.value };
    }

    pub fn contains(self: PadProbeType, other: PadProbeType) bool {
        return (self.value & other.value) == other.value;
    }

    pub fn toInt(self: PadProbeType) c_uint {
        return self.value;
    }

    pub fn fromInt(value: c_uint) PadProbeType {
        return .{ .value = value };
    }
};

pub const PadProbeInfo = struct {
    ptr: *c.GstPadProbeInfo,

    pub fn getType(self: PadProbeInfo) PadProbeType {
        return PadProbeType.fromInt(self.ptr.*.type);
    }

    pub fn getId(self: PadProbeInfo) u64 {
        return self.ptr.*.id;
    }

    pub fn getBuffer(self: PadProbeInfo) ?Buffer {
        const data = self.ptr.*.data;
        if (data == null) return null;
        const probe_type = self.getType();
        if (!probe_type.contains(PadProbeType.buffer)) return null;
        return Buffer{ .ptr = @ptrCast(@alignCast(data)) };
    }

    pub fn getEvent(self: PadProbeInfo) ?Event {
        const data = self.ptr.*.data;
        if (data == null) return null;
        const probe_type = self.getType();
        if (!probe_type.contains(PadProbeType.event_downstream) and !probe_type.contains(PadProbeType.event_upstream)) return null;
        return Event{ .ptr = @ptrCast(@alignCast(data)) };
    }

    pub fn getOffset(self: PadProbeInfo) u64 {
        return self.ptr.*.offset;
    }

    pub fn getSize(self: PadProbeInfo) u32 {
        return self.ptr.*.size;
    }
};

pub const Pad = struct {
    ptr: GstPad,

    pub fn init(name: [*:0]const u8, direction: PadDirection) !Pad {
        const ptr = c.gst_pad_new(name, @intFromEnum(direction));
        if (ptr == null) {
            return error.PadCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn initWithTemplate(name: [*:0]const u8, template: PadTemplate) !Pad {
        const ptr = c.gst_pad_new_from_template(template.ptr, name);
        if (ptr == null) {
            return error.PadCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn deinit(self: Pad) void {
        c.gst_object_unref(@ptrCast(self.ptr));
    }

    pub fn getCaps(self: Pad) !Caps {
        const currentCaps = c.gst_pad_get_current_caps(@ptrCast(self.ptr));
        if (currentCaps == null) {
            return error.GetCurrentCapsFailed;
        }
        return Caps{ .ptr = currentCaps };
    }

    // Linking functions
    pub fn link(self: Pad, sink_pad: Pad) !void {
        const result = c.gst_pad_link(self.ptr, sink_pad.ptr);
        if (result != c.GST_PAD_LINK_OK) {
            return error.PadLinkFailed;
        }
    }

    pub fn unlink(self: Pad, sink_pad: Pad) !void {
        const result = c.gst_pad_unlink(self.ptr, sink_pad.ptr);
        if (result == 0) {
            return error.PadUnlinkFailed;
        }
    }

    pub fn canLink(self: Pad, sink_pad: Pad) bool {
        return c.gst_pad_can_link(self.ptr, sink_pad.ptr) != 0;
    }

    pub fn isLinked(self: Pad) bool {
        return c.gst_pad_is_linked(self.ptr) != 0;
    }

    // State functions
    pub fn setActive(self: Pad, active: bool) !void {
        const result = c.gst_pad_set_active(self.ptr, if (active) 1 else 0);
        if (result == 0) {
            return error.SetActiveFailed;
        }
    }

    pub fn isActive(self: Pad) bool {
        return c.gst_pad_is_active(self.ptr) != 0;
    }

    pub fn getDirection(self: Pad) PadDirection {
        const dir = c.gst_pad_get_direction(self.ptr);
        return @enumFromInt(dir);
    }

    // Peer functions
    pub fn getPeer(self: Pad) ?Pad {
        const peer = c.gst_pad_get_peer(self.ptr);
        if (peer == null) return null;
        return Pad{ .ptr = peer };
    }

    // Parent functions
    pub fn getParentElement(self: Pad) ?Element {
        const parent = c.gst_pad_get_parent_element(self.ptr);
        if (parent == null) return null;
        return Element{ .ptr = parent };
    }

    // Template functions
    pub fn getPadTemplate(self: Pad) ?PadTemplate {
        const template = c.gst_pad_get_pad_template(self.ptr);
        if (template == null) return null;
        return PadTemplate{ .ptr = template };
    }

    pub fn getPadTemplateCaps(self: Pad) !Caps {
        const caps_ptr = c.gst_pad_get_pad_template_caps(self.ptr);
        if (caps_ptr == null) {
            return error.GetPadTemplateCapsError;
        }
        return Caps{ .ptr = caps_ptr };
    }

    // Caps negotiation functions
    pub fn getAllowedCaps(self: Pad) !Caps {
        const caps_ptr = c.gst_pad_get_allowed_caps(self.ptr);
        if (caps_ptr == null) {
            return error.GetAllowedCapsError;
        }
        return Caps{ .ptr = caps_ptr };
    }

    pub fn hasCurrentCaps(self: Pad) bool {
        return c.gst_pad_has_current_caps(self.ptr) != 0;
    }

    pub fn queryCaps(self: Pad, filter: ?Caps) !Caps {
        const filter_ptr = if (filter) |f| f.ptr else null;
        const caps_ptr = c.gst_pad_query_caps(self.ptr, filter_ptr);
        if (caps_ptr == null) {
            return error.QueryCapsError;
        }
        return Caps{ .ptr = caps_ptr };
    }

    pub fn queryAcceptCaps(self: Pad, currentCaps: Caps) bool {
        return c.gst_pad_query_accept_caps(self.ptr, currentCaps.ptr) != 0;
    }

    // Offset functions
    pub fn getOffset(self: Pad) i64 {
        return c.gst_pad_get_offset(self.ptr);
    }

    pub fn setOffset(self: Pad, offset: i64) void {
        c.gst_pad_set_offset(self.ptr, offset);
    }

    pub fn getName(self: Pad) ?[]const u8 {
        const name = c.gst_pad_get_name(self.ptr);
        if (name == null) return null;
        return std.mem.span(name);
    }

    pub fn addProbe(self: Pad, mask: PadProbeType, comptime callback_fn: anytype, user_data: anytype) u64 {
        const CallbackType = @TypeOf(callback_fn);
        const callback_info = @typeInfo(CallbackType);

        if (callback_info != .@"fn") {
            @compileError("callback_fn must be a function");
        }

        const params = callback_info.@"fn".params;
        if (params.len < 2 or params.len > 3) {
            @compileError("callback must have 2 or 3 parameters: (Pad, PadProbeInfo) or (Pad, PadProbeInfo, user_data)");
        }

        const UserDataType = @TypeOf(user_data);

        const wrapper = struct {
            fn c_wrapper(pad_ptr: ?*c.GstPad, info_ptr: ?*c.GstPadProbeInfo, data: ?*anyopaque) callconv(.c) c.GstPadProbeReturn {
                if (pad_ptr == null or info_ptr == null) {
                    return c.GST_PAD_PROBE_OK;
                }

                const pad = Pad{ .ptr = pad_ptr.? };
                const info = PadProbeInfo{ .ptr = info_ptr.? };

                const result = if (params.len == 2) blk: {
                    break :blk callback_fn(pad, info);
                } else blk: {
                    const typed_data: UserDataType = if (@typeInfo(UserDataType) == .pointer)
                        @ptrCast(@alignCast(data))
                    else if (@typeInfo(UserDataType) == .optional)
                        if (data) |d| @as(UserDataType, @ptrCast(@alignCast(d))) else null
                    else
                        @compileError("user_data must be a pointer type");
                    break :blk callback_fn(pad, info, typed_data);
                };

                return @intFromEnum(result);
            }
        }.c_wrapper;

        const converted_user_data: ?*anyopaque = switch (@typeInfo(UserDataType)) {
            .pointer => @ptrCast(@constCast(user_data)),
            .null => null,
            .optional => if (user_data) |ud| @ptrCast(@constCast(ud)) else null,
            else => @compileError("user_data must be a pointer, optional pointer, or null"),
        };

        const id = c.gst_pad_add_probe(self.ptr, mask.toInt(), wrapper, converted_user_data, null);
        return @intCast(id);
    }

    pub fn removeProbe(self: Pad, id: u64) void {
        c.gst_pad_remove_probe(self.ptr, @intCast(id));
    }
};
