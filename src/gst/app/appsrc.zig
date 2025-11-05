const std = @import("std");
const core = @import("../core.zig");
const element = @import("../element.zig");
const sample = @import("../sample.zig");
const buffer = @import("../buffer.zig");
const caps = @import("../caps.zig");

pub const c = core.c;
pub const Sample = sample.Sample;
pub const Buffer = buffer.Buffer;
pub const Caps = caps.Caps;

extern fn gst_app_src_push_buffer(appsrc: ?*anyopaque, buffer: ?*anyopaque) c.GstFlowReturn;
extern fn gst_app_src_push_sample(appsrc: ?*anyopaque, sample: ?*anyopaque) c.GstFlowReturn;
extern fn gst_app_src_end_of_stream(appsrc: ?*anyopaque) c.GstFlowReturn;

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
    pub fn pushSample(self: AppSrc, sample_to_push: Sample) !void {
        const ret = gst_app_src_push_sample(@ptrCast(self.el.ptr), sample_to_push.ptr);
        if (ret != c.GST_FLOW_OK) return error.PushSampleFailed;
    }

    pub fn pushBuffer(self: AppSrc, buf: Buffer) !void {
        const ret = gst_app_src_push_buffer(@ptrCast(self.el.ptr), buf.ptr);
        if (ret != c.GST_FLOW_OK) return error.PushBufferFailed;
    }

    pub fn endOfStream(self: AppSrc) !void {
        const ret = gst_app_src_end_of_stream(@ptrCast(self.el.ptr));
        if (ret != c.GST_FLOW_OK) return error.EndOfStreamFailed;
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

    /// Connect a callback for the "need-data" signal.
    /// Callback signature: fn(appsrc: *AppSrc, length: u32, userdata: T) void
    pub fn connectNeedData(self: AppSrc, comptime callback: anytype, userdata: anytype) !u64 {
        const UserDataT = @TypeOf(userdata);
        const wrapper = struct {
            fn needDataCallback(appsrc_ptr: ?*anyopaque, length: c_uint, data: ?*anyopaque) callconv(.c) void {
                var appsrc = AppSrc{ .el = element.Element{ .ptr = @ptrCast(@alignCast(appsrc_ptr.?)) } };
                const typed_data = convertUserData(UserDataT, data);
                callback(&appsrc, @as(u32, @intCast(length)), typed_data);
            }
        }.needDataCallback;

        const handler_id = c.g_signal_connect_data(
            self.el.ptr,
            "need-data",
            @ptrCast(&wrapper),
            prepareUserData(userdata),
            null,
            0,
        );
        if (handler_id == 0) return error.SignalConnectionFailed;
        return @intCast(handler_id);
    }

    /// Connect a callback for the "enough-data" signal.
    /// Callback signature: fn(appsrc: *AppSrc, userdata: T) void
    pub fn connectEnoughData(self: AppSrc, comptime callback: anytype, userdata: anytype) !u64 {
        const UserDataT = @TypeOf(userdata);
        const wrapper = struct {
            fn enoughDataCallback(appsrc_ptr: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
                var appsrc = AppSrc{ .el = element.Element{ .ptr = @ptrCast(@alignCast(appsrc_ptr.?)) } };
                const typed_data = convertUserData(UserDataT, data);
                callback(&appsrc, typed_data);
            }
        }.enoughDataCallback;

        const handler_id = c.g_signal_connect_data(
            self.el.ptr,
            "enough-data",
            @ptrCast(&wrapper),
            prepareUserData(userdata),
            null,
            0,
        );
        if (handler_id == 0) return error.SignalConnectionFailed;
        return @intCast(handler_id);
    }

    /// Connect a callback for the "seek-data" signal.
    /// Callback signature: fn(appsrc: *AppSrc, offset: u64, userdata: T) bool
    pub fn connectSeekData(self: AppSrc, comptime callback: anytype, userdata: anytype) !u64 {
        const UserDataT = @TypeOf(userdata);
        const wrapper = struct {
            fn seekDataCallback(appsrc_ptr: ?*anyopaque, offset: c_ulong, data: ?*anyopaque) callconv(.c) c_int {
                var appsrc = AppSrc{ .el = element.Element{ .ptr = @ptrCast(@alignCast(appsrc_ptr.?)) } };
                const typed_data = convertUserData(UserDataT, data);
                const result = callback(&appsrc, @as(u64, @intCast(offset)), typed_data);
                return if (result) 1 else 0;
            }
        }.seekDataCallback;

        const handler_id = c.g_signal_connect_data(
            self.el.ptr,
            "seek-data",
            @ptrCast(&wrapper),
            prepareUserData(userdata),
            null,
            0,
        );
        if (handler_id == 0) return error.SignalConnectionFailed;
        return @intCast(handler_id);
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
        .pointer => @ptrCast(@constCast(userdata)),
        else => @ptrCast(@constCast(&userdata)),
    };
}

fn convertUserData(comptime T: type, data: ?*anyopaque) T {
    return switch (@typeInfo(T)) {
        .pointer => @ptrCast(@alignCast(data.?)),
        else => @as(*T, @ptrCast(@alignCast(data.?))).*,
    };
}
