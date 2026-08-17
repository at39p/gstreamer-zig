const std = @import("std");
const core = @import("core.zig");
const caps = @import("Caps.zig");

const c = core.c;
const Caps = caps.Caps;

pub const PadDirection = enum(c_uint) {
    unknown = c.GST_PAD_UNKNOWN,
    src = c.GST_PAD_SRC,
    sink = c.GST_PAD_SINK,
};

pub const PadPresence = enum(c_uint) {
    always = c.GST_PAD_ALWAYS,
    sometimes = c.GST_PAD_SOMETIMES,
    request = c.GST_PAD_REQUEST,
};

pub const PadTemplate = struct {
    ptr: *c.GstPadTemplate,

    pub fn init(name_template: [*:0]const u8, direction: PadDirection, presence: PadPresence, template_caps: Caps) !PadTemplate {
        const ptr = c.gst_pad_template_new(name_template, @intFromEnum(direction), @intFromEnum(presence), template_caps.ptr);
        if (ptr == null) {
            return error.PadTemplateCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn deinit(self: PadTemplate) void {
        c.gst_object_unref(@ptrCast(self.ptr));
    }

    pub fn getCaps(self: PadTemplate) !Caps {
        const ptr = c.gst_pad_template_get_caps(self.ptr);
        if (ptr == null) {
            return error.GetTemplateCapsFailed;
        }
        return Caps{ .ptr = ptr };
    }

    pub fn getDocumentationCaps(self: PadTemplate) !Caps {
        const ptr = c.gst_pad_template_get_documentation_caps(self.ptr);
        if (ptr == null) {
            return error.GetDocumentationCapsFailed;
        }
        return Caps{ .ptr = ptr };
    }

    pub fn setDocumentationCaps(self: PadTemplate, documentation_caps: Caps) void {
        c.gst_pad_template_set_documentation_caps(self.ptr, documentation_caps.ptr);
    }

    pub fn padCreated(self: PadTemplate, pad: anytype) void {
        c.gst_pad_template_pad_created(self.ptr, pad.ptr);
    }
};

test {
    @import("testing").refAllDeclsRecursive(@This());
}
