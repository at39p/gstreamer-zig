const std = @import("std");
const gst = @import("gst");
const glib = gst.glib;

const CustomEvent = struct {
    send_eos: bool,

    pub fn new(send_eos: bool) !gst.Event {
        const structure = try gst.Structure.init("example-custom-event");
        structure.setBoolean("send-eos", send_eos);
        return gst.Event.initCustom(.custom_downstream, structure);
    }

    pub fn parse(event: gst.Event) ?CustomEvent {
        if (!event.hasName("example-custom-event")) return null;

        const structure = event.getStructure() orelse return null;
        const send_eos = structure.getBoolean("send-eos") orelse return null;

        return .{ .send_eos = send_eos };
    }
};

fn probeCallback(_: gst.Pad, info: gst.PadProbeInfo) gst.PadProbeReturn {
    if (info.getEvent()) |event| {
        std.debug.print("Event: {s}\n", .{event.getTypeName()});

        if (CustomEvent.parse(event)) |custom_event| {
            std.debug.print("  → Custom event! send_eos={}\n", .{custom_event.send_eos});
        }
    }

    return .ok;
}

fn sendFirstEvent(pipeline: *gst.Pipeline) bool {
    std.debug.print("\n→ Sending event (send_eos=false)\n", .{});
    const event = CustomEvent.new(false) catch return false;
    pipeline.sendEvent(event) catch return false;
    return false; // Remove timeout source after firing once
}

fn sendSecondEventAndEOS(pipeline: *gst.Pipeline) bool {
    std.debug.print("\n→ Sending event (send_eos=true)\n", .{});
    const event = CustomEvent.new(true) catch return false;
    pipeline.sendEvent(event) catch return false;

    std.debug.print("→ Sending EOS\n", .{});
    const eos = gst.Event.initEos() catch return false;
    pipeline.sendEvent(eos) catch return false;
    return false; // Remove timeout source after firing once
}

fn run() !void {
    gst.init(null);
    defer gst.deinit();

    var main_loop = try glib.MainLoop.init(null, false);
    defer main_loop.deinit();

    var pipeline = try gst.Pipeline.initLaunch("audiotestsrc ! queue max-size-time=2000000000 ! fakesink name=sink sync=true");
    defer pipeline.deinit();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    // Add bus watch to handle messages
    _ = try bus.addWatch(&main_loop, struct {
        fn handle(loop: *glib.MainLoop, msg: gst.Message) bool {
            switch (msg.getType()) {
                .eos => {
                    std.debug.print("\n✓ Received EOS\n", .{});
                    loop.quit();
                    return false;
                },
                .err => {
                    _ = msg.parseErrorAndPrint() catch {};
                    loop.quit();
                    return false;
                },
                else => return true,
            }
        }
    }.handle);

    // Setup pad probe to intercept events
    const sink = pipeline.getByName("sink") orelse return error.ElementNotFound;
    const sink_pad = sink.getStaticPad("sink") orelse return error.PadNotFound;
    _ = sink_pad.addProbe(gst.PadProbeType.event_downstream, probeCallback, null);

    // Start pipeline
    try pipeline.start();
    defer _ = pipeline.setState(.null_state);

    // Schedule events using GLib timeouts
    _ = glib.timeoutAddSeconds(2, &pipeline, sendFirstEvent);
    _ = glib.timeoutAddSeconds(4, &pipeline, sendSecondEventAndEOS);

    std.debug.print("Pipeline started\n", .{});
    main_loop.run();
}

pub fn main() !void {
    try gst.macosMainSimple(run);
}
