const std = @import("std");
const core = @import("core.zig");
const element = @import("element.zig");
const bus = @import("bus.zig");

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

    pub fn initLaunch(launch_string: [*c]const u8) !Pipeline {
        var err: ?*c.GError = null;
        const ptr = c.gst_parse_launch(launch_string, &err);
        if (ptr == null) {
            if (err) |e| {
                std.log.err("Failed to parse pipeline: {s}", .{e.message});
                c.g_error_free(e);
            }
            return error.PipelineCreationFailed;
        }
        return .{ .element = .{ .ptr = @ptrCast(ptr) } };
    }

    pub fn initLaunchFull(launch_string: [*c]const u8) !Pipeline {
        var err: ?*c.GError = null;
        const ptr = c.gst_parse_launch_full(launch_string, null, c.GstParseFlags(0), &err);
        if (ptr == null) {
            if (err) |e| {
                std.log.err("Failed to parse pipeline: {s}", .{e.message});
                c.g_error_free(e);
            }
            return error.PipelineCreationFailed;
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

    pub fn getName(self: Pipeline) ?[*:0]const u8 {
        return self.element.getName();
    }

    pub fn start(self: Pipeline) !void {
        const result = self.setState(.playing);
        if (result == .failure) {
            return error.StateChangeFailed;
        }
    }

    // TODO: Return Clock, but first convert GstClock to Zig Clock struct:
    // pub fn getClock(self: Pipeline) !Clock {
    //     const clock_ptr = c.gst_pipeline_get_pipeline_clock(self.element.ptr);
    //     if (clock_ptr) |c| {
    //         return Clock{ .ptr = @ptrCast(c) };
    //     } else {
    //         return error.ClockNotFound;
    //     }
    // }
};
