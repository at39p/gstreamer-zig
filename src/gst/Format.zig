const c = @import("../c.zig").c;

pub const Format = enum(c.GstFormat) {
    undefined = c.GST_FORMAT_UNDEFINED,
    default = c.GST_FORMAT_DEFAULT,
    bytes = c.GST_FORMAT_BYTES,
    time = c.GST_FORMAT_TIME,
    buffers = c.GST_FORMAT_BUFFERS,
    percent = c.GST_FORMAT_PERCENT,
};
