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

extern fn gst_app_src_push_buffer(appsrc: ?*anyopaque, buffer: ?*anyopaque) callconv(.c) c.GstFlowReturn;
extern fn gst_app_src_push_sample(appsrc: ?*anyopaque, sample: ?*anyopaque) callconv(.c) c.GstFlowReturn;
extern fn gst_app_src_end_of_stream(appsrc: ?*anyopaque) callconv(.c) c.GstFlowReturn;

pub const AppSrc = struct {
    el: element.Element,

    pub fn init(name: ?[*:0]const u8) !AppSrc {
        const el = try element.Element.init("appsrc", name);
        return AppSrc{ .el = el };
    }

    // TODO: Not sure deinit is needed here. Pipeline owns it and takes care of clean up
    pub fn deinit(self: AppSrc) void {
        _ = self;
    }

    pub inline fn asElement(self: AppSrc) element.Element {
        return self.el;
    }

    pub fn pushSample(self: AppSrc, sample_to_push: Sample) !void {
        const ret = gst_app_src_push_sample(@ptrCast(self.el.ptr), sample_to_push.ptr);
        if (ret != c.GST_FLOW_OK) {
            return error.PushSampleFailed;
        }
    }

    pub fn pushBuffer(self: AppSrc, buf: Buffer) !void {
        const ret = gst_app_src_push_buffer(@ptrCast(self.asElement().ptr), buf.ptr);
        if (ret != c.GST_FLOW_OK) {
            return error.PushBufferFailed;
        }
    }

    pub fn endOfStream(self: AppSrc) !void {
        const ret = gst_app_src_end_of_stream(@ptrCast(self.el.ptr));
        if (ret != c.GST_FLOW_OK) {
            return error.EndOfStreamFailed;
        }
    }

    // Property setters
    pub fn setCaps(self: AppSrc, capability: Caps) void {
        c.g_object_set(self.el.ptr, "caps", capability.ptr, @as(?*anyopaque, null));
    }

    pub fn setFormat(self: AppSrc, format: Format) void {
        c.g_object_set(self.el.ptr, "format", @as(c_int, @intFromEnum(format)), @as(?*anyopaque, null));
    }

    pub const Format = enum(c_int) {
        undefined = 0,
        default = 1,
        bytes = 2,
        time = 3,
        buffers = 4,
        percent = 5,
    };

    pub fn setIsLive(self: AppSrc, is_live: bool) void {
        c.g_object_set(self.el.ptr, "is-live", @as(c_int, if (is_live) 1 else 0), @as(?*anyopaque, null));
    }

    pub fn setStreamType(self: AppSrc, stream_type: StreamType) void {
        c.g_object_set(self.el.ptr, "stream-type", @as(c_int, @intFromEnum(stream_type)), @as(?*anyopaque, null));
    }

    pub fn setMaxBytes(self: AppSrc, max_bytes: u64) void {
        c.g_object_set(self.el.ptr, "max-bytes", @as(c_ulong, max_bytes), @as(?*anyopaque, null));
    }

    pub fn setBlockSize(self: AppSrc, block_size: u32) void {
        c.g_object_set(self.el.ptr, "blocksize", @as(c_uint, block_size), @as(?*anyopaque, null));
    }

    pub fn setEmitSignals(self: AppSrc, emit: bool) void {
        c.g_object_set(self.el.ptr, "emit-signals", @as(c_int, if (emit) 1 else 0), @as(?*anyopaque, null));
    }

    pub fn setCallbacks(self: AppSrc, callbacks: AppSrcCallbacks) !void {
        if (callbacks.need_data_wrapper) |wrapper| {
            const handler_id = c.g_signal_connect_data(self.el.ptr, "need-data", @ptrCast(wrapper), self.el.ptr, null, 0);
            if (handler_id == 0) return error.SignalConnectionFailed;
        }
        if (callbacks.enough_data_wrapper) |wrapper| {
            const handler_id = c.g_signal_connect_data(self.el.ptr, "enough-data", @ptrCast(wrapper), self.el.ptr, null, 0);
            if (handler_id == 0) return error.SignalConnectionFailed;
        }
        if (callbacks.seek_data_wrapper) |wrapper| {
            const handler_id = c.g_signal_connect_data(self.el.ptr, "seek-data", @ptrCast(wrapper), self.el.ptr, null, 0);
            if (handler_id == 0) return error.SignalConnectionFailed;
        }
    }

    pub const StreamType = enum(c_int) {
        stream = 0,
        seekable = 1,
        random_access = 2,
    };

    pub const AppSrcCallbacks = struct {
        need_data_wrapper: ?*const fn (?*anyopaque, c_uint, ?*anyopaque) callconv(.c) void = null,
        enough_data_wrapper: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) void = null,
        seek_data_wrapper: ?*const fn (?*anyopaque, c_ulong, ?*anyopaque) callconv(.c) c_int = null,

        pub fn builder() Builder {
            return Builder{};
        }

        pub const Builder = struct {
            callbacks: AppSrcCallbacks = AppSrcCallbacks{},

            pub fn needData(self: Builder, comptime callback_fn: anytype) Builder {
                validateNeedDataCallback(@TypeOf(callback_fn));
                var result = self;

                const wrapper = struct {
                    fn needDataWrapper(_: ?*anyopaque, length: c_uint, user_data: ?*anyopaque) callconv(.c) void {
                        var appsrc = AppSrc{ .el = element.Element{ .ptr = @ptrCast(@alignCast(user_data.?)) } };
                        callback_fn(&appsrc, length, null);
                    }
                }.needDataWrapper;

                result.callbacks.need_data_wrapper = wrapper;
                return result;
            }

            pub fn enoughData(self: Builder, comptime callback_fn: anytype) Builder {
                validateEnoughDataCallback(@TypeOf(callback_fn));
                var result = self;

                const wrapper = struct {
                    fn enoughDataWrapper(_: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) void {
                        var appsrc = AppSrc{ .el = element.Element{ .ptr = @ptrCast(@alignCast(user_data.?)) } };
                        callback_fn(&appsrc);
                    }
                }.enoughDataWrapper;

                result.callbacks.enough_data_wrapper = wrapper;
                return result;
            }

            pub fn seekData(self: Builder, comptime callback_fn: anytype) Builder {
                validateSeekDataCallback(@TypeOf(callback_fn));
                var result = self;

                const wrapper = struct {
                    fn seekDataWrapper(_: ?*anyopaque, offset: c_ulong, user_data: ?*anyopaque) callconv(.c) c_int {
                        var appsrc = AppSrc{ .el = element.Element{ .ptr = @ptrCast(@alignCast(user_data.?)) } };
                        return if (callback_fn(&appsrc, offset)) 1 else 0;
                    }
                }.seekDataWrapper;

                result.callbacks.seek_data_wrapper = wrapper;
                return result;
            }

            pub fn build(self: Builder) AppSrcCallbacks {
                return self.callbacks;
            }
        };

        fn validateNeedDataCallback(comptime FnType: type) void {
            const info = @typeInfo(FnType);
            if (info != .@"fn") @compileError("needData callback must be a function");
            const params = info.@"fn".params;
            if (params.len != 3) @compileError("needData callback must take (appsrc: *AppSrc, length: u32, user_data: ?*anyopaque)");
        }

        fn validateEnoughDataCallback(comptime FnType: type) void {
            const info = @typeInfo(FnType);
            if (info != .@"fn") @compileError("enoughData callback must be a function");
            const params = info.@"fn".params;
            if (params.len != 1) @compileError("enoughData callback must take (appsrc: *AppSrc)");
        }

        fn validateSeekDataCallback(comptime FnType: type) void {
            const info = @typeInfo(FnType);
            if (info != .@"fn") @compileError("seekData callback must be a function");
            const params = info.@"fn".params;
            if (params.len != 2) @compileError("seekData callback must take (appsrc: *AppSrc, offset: u64) and return bool");
        }
    };
};
