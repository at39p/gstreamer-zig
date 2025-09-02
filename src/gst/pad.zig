const std = @import("std");
const core = @import("core.zig");
const caps = @import("caps.zig");
const padtemplate = @import("padtemplate.zig");
const element = @import("element.zig");

pub const c = core.c;
const GstPad = *c.GstPad;
const Caps = caps.Caps;
const Element = element.Element;

pub const PadDirection = padtemplate.PadDirection;
pub const PadTemplate = padtemplate.PadTemplate;

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

    // Name functions
    pub fn getName(self: Pad) ?[]const u8 {
        const name = c.gst_pad_get_name(self.ptr);
        if (name == null) return null;
        return std.mem.span(name);
    }
};
