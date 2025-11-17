const std = @import("std");
const gst = @import("gst");

fn run() !void {
    gst.init(null, null);
    defer gst.deinit();

    const source = try gst.Element.init("fakesrc", "src");
    source.setProperty("num-buffers", 5);

    const sink = try gst.Element.init("fakesink", "sink");

    const bin = try gst.Bin.init("sink");
    try bin.add(source);
    try bin.add(sink);

    try source.link(sink);

    const pipeline = try gst.Pipeline.init("test-bins-pipeline");
    defer pipeline.deinit();

    try pipeline.add(bin.asElement());
    try pipeline.start();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    var running = true;
    while (running) {
        const msg = bus.popMessage(std.time.ns_per_ms * 10, .any);
        if (msg) |message| {
            defer message.deinit();

            const msg_type = message.getType();
            switch (msg_type) {
                .eos => {
                    std.debug.print("End of stream reached\n", .{});
                    running = false;
                },
                .err => {
                    const is_quit = message.parseErrorAndPrint() catch {
                        std.debug.print("Unknown error occurred\n", .{});
                        running = false;
                        continue;
                    };
                    if (is_quit) {
                        std.debug.print("Gracefully shutting down...\n", .{});
                    }
                    running = false;
                },
                .warning => {
                    // Handle warnings if needed
                },
                .state_changed => {
                    // Optionally handle state changes
                },
                .info => {
                    // Handle info messages if needed
                },
                else => {
                    // Handle other messages if needed
                },
            }
        }

        // Add a small delay to prevent busy waiting
        std.Thread.sleep(std.time.ns_per_ms * 10);
    }

    // Cleanup
    std.debug.print("Stopping pipeline...\n", .{});
    std.debug.print("Pipeline stopped and cleaned up\n", .{});

    _ = pipeline.setState(.null_state);
}

pub fn main() !void {
    try gst.macosMainSimple(run);
}
