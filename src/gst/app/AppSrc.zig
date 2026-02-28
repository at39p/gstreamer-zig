const core = @import("../core.zig");
const element = @import("../Element.zig");
const sample = @import("../Sample.zig");
const buffer = @import("../Buffer.zig");
const caps = @import("../Caps.zig");

pub const c = core.c;
pub const Sample = sample.Sample;
pub const Buffer = buffer.Buffer;
pub const Caps = caps.Caps;

pub const AppSrc = struct {
    el: element.Element,

    pub fn init(name: ?[*:0]const u8) !AppSrc {
        const el = try element.Element.init("appsrc", name);
        return .{ .el = el };
    }

    pub fn deinit(self: AppSrc) void {
        const parent = c.gst_element_get_parent(self.el.ptr);
        if (parent) |p| {
            const pipeline_type = c.gst_pipeline_get_type();
            const is_pipeline = c.g_type_check_instance_is_a(@ptrCast(p), pipeline_type) != 0;
            c.gst_object_unref(p);

            if (is_pipeline) {
                return;
            }
        }
        self.el.deinit();
    }

    pub inline fn asElement(self: AppSrc) element.Element {
        return self.el;
    }

    // Core operations

    /// Push a sample into the appsrc. The sample is borrowed; the caller
    /// retains ownership and is responsible for unreffing it.
    pub fn pushSample(self: AppSrc, sample_to_push: *const Sample) !void {
        const sample_ptr = sample_to_push.ptr orelse return error.PushSampleFailed;
        const ret = c.gst_app_src_push_sample(@ptrCast(self.el.ptr), @ptrCast(sample_ptr));
        if (ret != c.GST_FLOW_OK) {
            return error.PushSampleFailed;
        }
    }

    /// Push a buffer into the appsrc. Ownership of the buffer is transferred
    /// to GStreamer; the caller must not use it afterwards.
    pub fn pushBuffer(self: AppSrc, buf: *Buffer) !void {
        const buf_ptr = buf.ptr orelse return error.PushBufferFailed;
        buf.ptr = null; // Ownership transferred to GStreamer
        const ret = c.gst_app_src_push_buffer(@ptrCast(self.el.ptr), @ptrCast(buf_ptr));
        if (ret != c.GST_FLOW_OK) {
            return error.PushBufferFailed;
        }
    }

    pub fn endOfStream(self: AppSrc) !void {
        const ret = c.gst_app_src_end_of_stream(@ptrCast(self.el.ptr));
        if (ret != c.GST_FLOW_OK) {
            return error.EndOfStreamFailed;
        }
    }

    // Property setters
    pub fn setCaps(self: AppSrc, capability: Caps) void {
        c.g_object_set(self.el.ptr, "caps", capability.ptr, @as(?*anyopaque, null));
    }

    pub fn setFormat(self: AppSrc, format: Format) void {
        c.g_object_set(self.el.ptr, "format", @intFromEnum(format), @as(?*anyopaque, null));
    }

    pub fn setIsLive(self: AppSrc, is_live: bool) void {
        const value: c_int = if (is_live) 1 else 0;
        c.g_object_set(self.el.ptr, "is-live", value, @as(?*anyopaque, null));
    }

    pub fn setStreamType(self: AppSrc, stream_type: StreamType) void {
        c.g_object_set(self.el.ptr, "stream-type", @intFromEnum(stream_type), @as(?*anyopaque, null));
    }

    pub fn setMaxBytes(self: AppSrc, max_bytes: u64) void {
        c.g_object_set(self.el.ptr, "max-bytes", max_bytes, @as(?*anyopaque, null));
    }

    pub fn setBlockSize(self: AppSrc, block_size: u32) void {
        c.g_object_set(self.el.ptr, "blocksize", block_size, @as(?*anyopaque, null));
    }

    pub fn setEmitSignals(self: AppSrc, emit: bool) void {
        const value: c_int = if (emit) 1 else 0;
        c.g_object_set(self.el.ptr, "emit-signals", value, @as(?*anyopaque, null));
    }

    /// Set callbacks using the GStreamer 1.28+ simple callbacks API.
    ///
    /// Pass an anonymous struct with optional `{function, userdata}` tuple fields:
    ///   - `.need_data`    — fn(*AppSrc, u32, T) void
    ///   - `.enough_data`  — fn(*AppSrc, T) void
    ///   - `.seek_data`    — fn(*AppSrc, u64, T) bool
    ///
    /// Each field is optional; omit any callbacks you don't need.
    ///
    /// Example:
    /// ```zig
    /// appsrc.setCallbacks(.{
    ///     .need_data   = .{ onNeedData, &ctx },
    ///     .enough_data = .{ onEnoughData, &ctx },
    /// });
    /// ```
    pub fn setCallbacks(self: AppSrc, callbacks: anytype) void {
        const CallbacksT = @TypeOf(callbacks);
        const cb = c.gst_app_src_simple_callbacks_new();

        if (@hasField(CallbacksT, "need_data")) {
            const entry = callbacks.need_data;
            const fn_ptr = comptime entry[0];
            const has_userdata = comptime @TypeOf(entry[1]) != @TypeOf(null);
            const wrapper = struct {
                fn thunk(appsrc_ptr: ?*c.GstAppSrc, length: c.guint, data: c.gpointer) callconv(.c) void {
                    var src = AppSrc{ .el = element.Element{ .ptr = @ptrCast(@alignCast(appsrc_ptr)) } };
                    if (has_userdata) {
                        fn_ptr(&src, @as(u32, @intCast(length)), convertUserData(@TypeOf(entry[1]), data));
                    } else {
                        fn_ptr(&src, @as(u32, @intCast(length)));
                    }
                }
            };
            c.gst_app_src_simple_callbacks_set_need_data(cb, wrapper.thunk, prepareUserData(entry[1]), null);
        }

        if (@hasField(CallbacksT, "enough_data")) {
            const entry = callbacks.enough_data;
            const fn_ptr = comptime entry[0];
            const has_userdata = comptime @TypeOf(entry[1]) != @TypeOf(null);
            const wrapper = struct {
                fn thunk(appsrc_ptr: ?*c.GstAppSrc, data: c.gpointer) callconv(.c) void {
                    var src = AppSrc{ .el = element.Element{ .ptr = @ptrCast(@alignCast(appsrc_ptr)) } };
                    if (has_userdata) {
                        fn_ptr(&src, convertUserData(@TypeOf(entry[1]), data));
                    } else {
                        fn_ptr(&src);
                    }
                }
            };
            c.gst_app_src_simple_callbacks_set_enough_data(cb, wrapper.thunk, prepareUserData(entry[1]), null);
        }

        if (@hasField(CallbacksT, "seek_data")) {
            const entry = callbacks.seek_data;
            const fn_ptr = comptime entry[0];
            const has_userdata = comptime @TypeOf(entry[1]) != @TypeOf(null);
            const wrapper = struct {
                fn thunk(appsrc_ptr: ?*c.GstAppSrc, offset: c.guint64, data: c.gpointer) callconv(.c) c.gboolean {
                    var src = AppSrc{ .el = element.Element{ .ptr = @ptrCast(@alignCast(appsrc_ptr)) } };
                    if (has_userdata) {
                        return if (fn_ptr(&src, @as(u64, offset), convertUserData(@TypeOf(entry[1]), data))) 1 else 0;
                    } else {
                        return if (fn_ptr(&src, @as(u64, offset))) 1 else 0;
                    }
                }
            };
            c.gst_app_src_simple_callbacks_set_seek_data(cb, wrapper.thunk, prepareUserData(entry[1]), null);
        }

        c.gst_app_src_set_simple_callbacks(@ptrCast(self.el.ptr), cb);
    }

    pub const Format = enum(c_int) {
        undefined = 0,
        default = 1,
        bytes = 2,
        time = 3,
        buffers = 4,
        percent = 5,
    };

    pub const StreamType = enum(c_int) {
        stream = 0,
        seekable = 1,
        random_access = 2,
    };
};

fn prepareUserData(userdata: anytype) ?*anyopaque {
    const T = @TypeOf(userdata);
    return switch (@typeInfo(T)) {
        .null => null,
        .pointer => @ptrCast(@constCast(userdata)),
        else => @compileError("userdata must be a pointer or null"),
    };
}

fn convertUserData(comptime T: type, data: c.gpointer) T {
    return switch (@typeInfo(T)) {
        .pointer => @ptrCast(@alignCast(data.?)),
        else => @compileError("userdata type must be a pointer or null"),
    };
}
