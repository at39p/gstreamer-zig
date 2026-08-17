const std = @import("std");
const core = @import("core.zig");
const element = @import("Element.zig");
const bus = @import("Bus.zig");

const Clock = @import("Clock.zig").Clock;
const Event = @import("Event.zig").Event;

pub const c = core.c;
pub const State = core.State;
pub const StateChangeReturn = core.StateChangeReturn;
pub const Element = element.Element;
pub const GetStateResult = element.Element.GetStateResult;

pub const Pipeline = struct {
    element: Element,

    pub fn init(name: ?[*:0]const u8) !Pipeline {
        const ptr = c.gst_pipeline_new(name);
        if (ptr == null) {
            return error.PipelineCreationFailed;
        }
        return .{ .element = .{ .ptr = @ptrCast(ptr) } };
    }

    pub fn initLaunch(launch_string: [:0]const u8) !Pipeline {
        var err: ?*c.GError = null;
        const ptr = c.gst_parse_launch(launch_string.ptr, &err);
        if (ptr == null) {
            if (err) |e| {
                std.log.err("Failed to parse pipeline: {s}", .{e.message});
                c.g_error_free(e);
            }
            return error.PipelineCreationFailed;
        }
        // gst_parse_launch can return a pipeline AND set a recoverable error.
        if (err) |e| {
            std.log.warn("Pipeline created with warnings: {s}", .{e.message});
            c.g_error_free(e);
        }
        return .{ .element = .{ .ptr = @ptrCast(ptr) } };
    }

    pub fn initLaunchFull(launch_string: [:0]const u8) !Pipeline {
        var err: ?*c.GError = null;
        const ptr = c.gst_parse_launch_full(launch_string.ptr, null, c.GST_PARSE_FLAG_NONE, &err);
        if (ptr == null) {
            if (err) |e| {
                std.log.err("Failed to parse pipeline: {s}", .{e.message});
                c.g_error_free(e);
            }
            return error.PipelineCreationFailed;
        }
        if (err) |e| {
            std.log.warn("Pipeline created with warnings: {s}", .{e.message});
            c.g_error_free(e);
        }
        return .{ .element = .{ .ptr = @ptrCast(ptr) } };
    }

    pub fn deinit(self: Pipeline) void {
        self.element.deinit();
    }

    pub fn add(self: Pipeline, e: Element) !void {
        if (c.gst_bin_add(@ptrCast(self.element.ptr), e.ptr) == 0) {
            return error.FailedToAddElement;
        }
    }

    pub fn addMany(self: Pipeline, elements: []const Element) !void {
        for (elements) |e| {
            try self.add(e);
        }
    }

    pub fn remove(self: Pipeline, e: Element) !void {
        if (c.gst_bin_remove(@ptrCast(self.element.ptr), e.ptr) == 0) {
            return error.FailedToRemoveElement;
        }
    }

    pub fn getByName(self: Pipeline, name: [*:0]const u8) ?Element {
        if (c.gst_bin_get_by_name(@ptrCast(self.element.ptr), name)) |ptr| {
            return Element{ .ptr = ptr };
        }
        return null;
    }

    pub fn getBus(self: Pipeline) !bus.Bus {
        const bus_ptr = c.gst_element_get_bus(self.element.ptr);
        if (bus_ptr) |b| {
            return bus.Bus{ .ptr = @ptrCast(b) };
        } else {
            return error.BusNotFound;
        }
    }

    // Delegate common methods to element
    pub fn setState(self: Pipeline, state: State) StateChangeReturn {
        return self.element.setState(state);
    }

    pub fn getState(self: Pipeline, timeout: u64) !GetStateResult {
        return self.element.getState(timeout);
    }

    pub fn setProperty(self: Pipeline, property_name: [*:0]const u8, value: anytype) void {
        self.element.setProperty(property_name, value);
    }

    /// Borrowed name; see `Element.getName` for the thread-safety caveat.
    pub fn getName(self: Pipeline) ?[:0]const u8 {
        return self.element.getName();
    }

    /// Owned copy of the pipeline's name. Caller frees with `allocator.free()`.
    pub fn getNameAlloc(self: Pipeline, allocator: std.mem.Allocator) !?[]u8 {
        return self.element.getNameAlloc(allocator);
    }

    pub fn start(self: Pipeline) !void {
        const result = self.setState(.playing);
        if (result == .failure) {
            return error.StateChangeFailed;
        }
    }

    pub fn getClock(self: Pipeline) !Clock {
        const clock_ptr = c.gst_pipeline_get_pipeline_clock(@ptrCast(self.element.ptr));
        if (clock_ptr) |clk| {
            return Clock{ .ptr = @ptrCast(clk) };
        } else {
            return error.ClockNotFound;
        }
    }

    /// Sends an event to the pipeline.
    pub fn sendEvent(self: Pipeline, event: *Event) !void {
        return self.element.sendEvent(event);
    }
};

test {
    @import("testing").refAllDeclsRecursive(@This());
}
