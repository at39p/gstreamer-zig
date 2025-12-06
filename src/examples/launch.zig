const std = @import("std");
const gst = @import("gst");
const glib = gst.glib;

fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        return error.MissingPipelineArgument;
    }

    try gst.init_check(args);
    defer gst.deinit();

    // Create GLib main loop
    var main_loop = try glib.MainLoop.init(null, false);
    defer main_loop.deinit();

    const pipeline = try gst.Pipeline.initLaunch(args[1]);
    defer pipeline.deinit();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    const watch_id = try bus.addWatch(&main_loop, struct {
        fn handle(loop: *glib.MainLoop, msg: gst.Message) bool {
            switch (msg.getType()) {
                .err => {
                    _ = msg.parseErrorAndPrint() catch {
                        std.debug.print("Failed to parse error message\n", .{});
                    };
                    loop.quit();
                    return false;
                },
                .eos => {
                    std.debug.print("End of stream reached\n", .{});
                    loop.quit();
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
    }.handle);
    std.debug.print("Added bus watch with ID: {}\n", .{watch_id});

    try pipeline.start();
    defer _ = pipeline.setState(.null_state);

    // Run the main loop - this blocks until quit is called
    main_loop.run();

    std.debug.print("Main loop finished\n", .{});
}

pub fn main() !void {
    try gst.macosMainSimple(run);
}
