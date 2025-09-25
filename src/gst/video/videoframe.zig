pub const video = @import("video.zig");
pub const VideoInfo = @import("videoinfo.zig").VideoInfo;
pub const Buffer = @import("../buffer.zig").Buffer;
pub const core = @import("../core.zig");

const c = video.c_video;
const std = @import("std");

pub const VideoFrameFlags = enum(u32) {
    none = 0,
    interlaced = 1,
    tff = 2,
    rff = 4,
    onefield = 8,
    multiple_view = 16,
    first_in_bundle = 32,
};

pub const VideoFrame = struct {
    ptr: c.GstVideoFrame,

    pub fn fromBufferReadable(buffer_ref: Buffer, info: VideoInfo) !VideoFrame {
        var frame: c.GstVideoFrame = undefined;
        const success = c.gst_video_frame_map(&frame, info.ptr, @ptrCast(buffer_ref.ptr), c.GST_MAP_READ);
        if (success == 0) {
            return error.VideoFrameMapFailed;
        }
        return .{ .ptr = frame };
    }

    pub fn fromBufferWritable(buffer_ref: Buffer, info: VideoInfo) !VideoFrame {
        var frame: c.GstVideoFrame = undefined;
        const success = c.gst_video_frame_map(&frame, info.ptr, @ptrCast(buffer_ref.ptr), c.GST_MAP_WRITE);
        if (success == 0) {
            return error.VideoFrameMapFailed;
        }
        return .{ .ptr = frame };
    }

    pub fn fromBufferReadWrite(buffer_ref: Buffer, info: VideoInfo) !VideoFrame {
        var frame: c.GstVideoFrame = undefined;
        const success = c.gst_video_frame_map(&frame, info.ptr, @ptrCast(buffer_ref.ptr), c.GST_MAP_READWRITE);
        if (success == 0) {
            return error.VideoFrameMapFailed;
        }
        return .{ .ptr = frame };
    }

    pub fn deinit(self: *VideoFrame) void {
        c.gst_video_frame_unmap(&self.ptr);
    }

    pub fn copy(self: *const VideoFrame, dest: *VideoFrame) !void {
        const success = c.gst_video_frame_copy(dest.frame, self.ptr);
        if (success == 0) {
            return error.VideoFrameCopyFailed;
        }
    }

    pub fn copyPlane(self: *const VideoFrame, dest: *VideoFrame, plane: u32) !void {
        const success = c.gst_video_frame_copy_plane(dest.frame, self.ptr, plane);
        if (success == 0) {
            return error.VideoFrameCopyPlaneFailed;
        }
    }

    pub fn getWidth(self: *const VideoFrame) u32 {
        return @intCast(self.ptr.info.width);
    }

    pub fn getHeight(self: *const VideoFrame) u32 {
        return @intCast(self.ptr.info.height);
    }

    pub fn getFormat(self: *const VideoFrame) c.GstVideoFormat {
        return self.ptr.info.finfo.*.format;
    }

    pub fn getFlags(self: *const VideoFrame) VideoFrameFlags {
        return VideoFrameFlags.fromC(self.ptr.flags);
    }

    pub fn getNPlanes(self: *const VideoFrame) u32 {
        return @intCast(self.ptr.info.finfo.*.n_planes);
    }

    pub fn getNComponents(self: *const VideoFrame) u32 {
        return @intCast(self.ptr.info.finfo.*.n_components);
    }

    pub fn planeStride(self: *const VideoFrame, plane: u32) !i32 {
        const n_planes = self.getNPlanes();
        if (plane >= n_planes) {
            return error.InvalidPlaneIndex;
        }
        return self.ptr.info.stride[plane];
    }

    pub fn planeOffset(self: *const VideoFrame, plane: u32) !usize {
        const n_planes = self.getNPlanes();
        if (plane >= n_planes) {
            return error.InvalidPlaneIndex;
        }
        return self.ptr.info.offset[plane];
    }

    pub fn planeData(self: *VideoFrame, plane: u32) ![]u8 {
        const n_planes = self.getNPlanes();
        if (plane >= n_planes) {
            return error.InvalidPlaneIndex;
        }

        const data_ptr = self.ptr.data[plane];
        if (data_ptr == null) {
            return error.InvalidPlaneData;
        }

        const stride = try self.planeStride(plane);
        const height = self.getHeight();
        const size = @as(usize, @intCast(stride)) * height;

        return @as([*]u8, @ptrCast(data_ptr))[0..size];
    }

    pub fn componentData(self: *VideoFrame, comp: u32) ![]u8 {
        const n_components = self.getNComponents();
        if (comp >= n_components) {
            return error.InvalidComponentIndex;
        }

        const comp_info = &self.ptr.info.finfo.*.comp[comp];
        const plane = comp_info.plane;
        const plane_data = try self.planeData(plane);

        const offset = comp_info.offset;
        const stride = try self.planeStride(plane);
        const height = self.getHeight();
        const comp_stride = @as(usize, @intCast(stride));
        const comp_height = height >> comp_info.h_sub;

        if (offset >= plane_data.len) {
            return error.InvalidComponentOffset;
        }

        const comp_size = comp_stride * comp_height;
        const available_size = plane_data.len - offset;
        const actual_size = @min(comp_size, available_size);

        return plane_data[offset .. offset + actual_size];
    }

    pub fn getInfo(self: *const VideoFrame) VideoInfo {
        return VideoInfo{ .ptr = @constCast(&self.ptr.info) };
    }

    pub fn getBuffer(self: *const VideoFrame) Buffer {
        return Buffer{ .ptr = self.ptr.buffer };
    }
};
