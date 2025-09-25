const std = @import("std");

pub fn run(createAndRunFn: fn () anyerror!void) fn (?*anyopaque) callconv(.c) c_int {
    const RunWrapper = struct {
        fn runImpl(_: ?*anyopaque) callconv(.c) c_int {
            createAndRunFn() catch |err| {
                std.debug.print("Pipeline error: {}\n", .{err});
                return -1;
            };
            return 0;
        }
    };
    return RunWrapper.runImpl;
}
