// Events travel through the pipeline, messages come back on the bus. Here a
// main loop timeout sends an EOS *event* into the pipeline; once every element
// has drained it, GStreamer posts an EOS *message* we catch to shut down.

const std = @import("std");
const gst = @import("gst");
const glib = gst.glib;

// Contrived example of mutating an event in flight - normally element code.
// We take the CAPS event out of the probe, mark it, push it out of identity's
// src pad ourselves, then `.drop` so the original does not travel on as well.
fn mutateCaps(pad: gst.Pad, info: gst.PadProbeInfo, identity: *gst.Element) gst.PadProbeReturn {
    const event = info.getEvent() orelse return .ok;
    if (event.getType() != .caps) return .ok;

    var taken = info.takeEvent() orelse return .ok;

    // The event may be shared. Consumes `taken`, returns a writable event.
    var writable = taken.makeWritable();

    const structure = writable.getWritableStructure() orelse {
        writable.deinit();
        return .drop;
    };
    structure.setBoolean("custom-field", true);

    const src_pad = identity.getStaticPad("src") orelse {
        writable.deinit();
        return .drop;
    };
    defer src_pad.deinit();

    src_pad.pushEvent(&writable) catch |err| {
        std.debug.print("Failed to push modified caps event: {}\n", .{err});
        return .drop;
    };

    if (pad.getName()) |name| {
        std.debug.print("Marked caps event on {s} with custom-field\n", .{name});
    }

    return .drop;
}

fn sendEos(pipeline: *gst.Pipeline) bool {
    std.debug.print("sending eos\n", .{});

    // Drains the whole pipeline front to back, so nothing is left unhandled and
    // muxers get to rewrite their headers.
    var event = gst.Event.initEos() catch return false;
    pipeline.sendEvent(&event) catch |err| {
        std.debug.print("Failed to send EOS: {}\n", .{err});
        return false;
    };

    return false; // Remove timeout source after firing once
}

fn run() !void {
    gst.init(null);
    defer gst.deinit();

    var main_loop = try glib.MainLoop.init(null, false);
    defer main_loop.deinit();

    var pipeline = try gst.Pipeline.initLaunch("audiotestsrc ! identity name=capsmut ! fakesink");
    defer pipeline.deinit();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    var identity = pipeline.getByName("capsmut") orelse return error.ElementNotFound;
    defer identity.deinit();

    const sink_pad = identity.getStaticPad("sink") orelse return error.PadNotFound;
    defer sink_pad.deinit();

    _ = sink_pad.addProbe(gst.PadProbeType.event_downstream, mutateCaps, &identity);

    _ = try bus.addWatch(&main_loop, struct {
        fn handle(loop: *glib.MainLoop, msg: gst.Message) bool {
            switch (msg.getType()) {
                .eos => {
                    std.debug.print("received eos\n", .{});
                    loop.quit();
                    return false; // Remove the watch
                },
                .err => {
                    _ = msg.parseErrorAndPrint() catch {
                        std.debug.print("Failed to parse error message\n", .{});
                    };
                    loop.quit();
                    return false;
                },
                else => return true,
            }
        }
    }.handle);

    try pipeline.start();
    defer _ = pipeline.setState(.null_state);

    _ = glib.timeoutAddSeconds(5, &pipeline, sendEos);

    main_loop.run();
}

pub fn main() !void {
    try gst.macosMainSimple(run, null);
}
