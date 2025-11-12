const std = @import("std");
const gst = @import("gst");
const glib = gst.glib;
const common = @import("common.zig");

var main_loop: ?glib.MainLoop = null;

fn createAndRun() !void {
    try gst.init_check(null, null);
    defer gst.deinit();

    // Create GLib main loop
    main_loop = try glib.MainLoop.init(null, false);
    defer if (main_loop) |loop| loop.deinit();

    // TODO: Make launch string come from args
    const pipeline = try gst.Pipeline.initLaunch("videotestsrc ! autovideosink");
    defer pipeline.deinit();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    const watch_id = try bus.addWatch(struct {
        fn watcher(msg: gst.Message) bool {
            switch (msg.getType()) {
                .err => {
                    _ = msg.parseErrorAndPrint() catch {
                        std.debug.print("Failed to parse error message\n", .{});
                    };
                    main_loop.?.quit();
                    return false;
                },
                .eos => {
                    std.debug.print("End of stream reached\n", .{});
                    main_loop.?.quit();
                    return false;
                },
                .state_changed => {
                    std.debug.print("State changed\n", .{});
                    return true;
                },
                else => {
                    std.debug.print("Got message type: {}\n", .{msg.getType()});
                    return true;
                },
            }
        }
    }.watcher);
    std.debug.print("Added bus watch with ID: {}\n", .{watch_id});

    try pipeline.start();
    defer _ = pipeline.setState(.null_state);

    // Run the main loop - this blocks until quit is called
    // gst.mainLoopRun(main_loop.?);
    main_loop.?.run();

    std.debug.print("Main loop finished\n", .{});
}

pub fn main() !void {
    try gst.macosMainSimple(common.run(createAndRun), null);
}
