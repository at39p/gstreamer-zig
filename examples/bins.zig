const std = @import("std");
const gst = @import("gst");

fn run() !void {
    gst.init(null);
    defer gst.deinit();

    const source = try gst.Element.init("fakesrc", "src");
    source.setProperty("num-buffers", 5);

    const sink = try gst.Element.init("fakesink", "sink");

    const bin = try gst.Bin.init("example");
    try bin.add(source);
    try bin.add(sink);

    try source.link(sink);

    const pipeline = try gst.Pipeline.init("test-bins-pipeline");
    defer pipeline.deinit();

    try pipeline.add(bin.asElement());
    try pipeline.start();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    while (bus.timedPop(gst.clock.TIME_NONE)) |message| {
        defer message.deinit();
        switch (message.getType()) {
            .eos => {
                std.debug.print("End of stream reached\n", .{});
                break;
            },
            .err => {
                _ = message.parseErrorAndPrint() catch {
                    std.debug.print("Unknown error occurred\n", .{});
                };
                break;
            },
            else => {},
        }
    }

    // Cleanup
    std.debug.print("Stopping pipeline...\n", .{});
    std.debug.print("Pipeline stopped and cleaned up\n", .{});

    _ = pipeline.setState(.null_state);
}

pub fn main() !void {
    try gst.macosMainSimple(run, null);
}
