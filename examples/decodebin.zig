// This example demonstrates the use of the decodebin element
// The decodebin element tries to automatically detect the incoming
// format and to autoplug the appropriate demuxers / decoders to handle it.
// and decode it to raw audio, video or subtitles.
// Before the pipeline hasn't been prerolled, the decodebin can't possibly know what
// format it gets as its input. So at first, the pipeline looks like this:

// {filesrc} - {decodebin}

// As soon as the decodebin has detected the stream format, it will try to decode every
// contained stream to its raw format.
// The application connects a signal-handler to decodebin's pad-added signal, which tells us
// whenever the decodebin provided us with another contained (raw) stream from the input file.

// This application supports audio and video streams. Video streams are
// displayed using an autovideosink, and audiostreams are played back using autoaudiosink.
// So for a file that contains one audio and one video stream,
// the pipeline looks like the following:

//                        /-[audio]-{audioconvert}-{audioresample}-{autoaudiosink}
// {filesrc}-{decodebin}-|
//                        \-[video]-{videoconvert}-{videoscale}-{autovideosink}

// Both auto-sinks at the end automatically select the best available (actual) sink. Since the
// selection of available actual sinks is platform specific
// (like using pulseaudio for audio output on linux, e.g.),
// we need to add the audioconvert and audioresample elements before handing the stream to the
// autoaudiosink, because we need to make sure, that the stream is always supported by the actual sink.
// Especially Windows APIs tend to be quite picky about samplerate and sample-format.
// The same applies to videostreams.

const std = @import("std");
const gst = @import("gst");

const Context = struct {
    pipeline: gst.Pipeline,
};

fn run(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len < 2) {
        return error.MissingPipelineArgument;
    }

    gst.init(null);
    defer gst.deinit();

    const pipeline = try gst.Pipeline.init("example-decodebin");
    defer pipeline.deinit();

    const src = try gst.Element.init("filesrc", null);
    src.set(.{ .location = args[1] });

    const decodebin = try gst.Element.init("decodebin", "decodebin");

    try pipeline.addMany(&.{ src, decodebin });
    try src.link(decodebin);

    var context = Context{
        .pipeline = pipeline,
    };
    _ = decodebin.connect("pad-added", pad_added_handler, &context);

    const bus = try pipeline.getBus();
    defer bus.deinit();

    try pipeline.start();

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

    std.debug.print("Stopping pipeline...\n", .{});
    std.debug.print("Pipeline stopped and cleaned up\n", .{});

    _ = pipeline.setState(.null_state);
}

const MediaType = enum {
    video,
    audio,
};

fn detectMediaType(name: []const u8) ?MediaType {
    if (std.mem.startsWith(u8, name, "video")) return .video;
    if (std.mem.startsWith(u8, name, "audio")) return .audio;
    return null;
}

fn linkPads(context: *Context, srcPad: gst.Pad, media_type: MediaType) !void {
    const queue = switch (media_type) {
        .video => try gst.Element.init("queue", "video_queue"),
        .audio => try gst.Element.init("queue", "audio_queue"),
    };

    const convert = switch (media_type) {
        .video => try gst.Element.init("videoconvert", "video_convert"),
        .audio => try gst.Element.init("audioconvert", "audio_convert"),
    };

    const processor = switch (media_type) {
        .video => try gst.Element.init("videoscale", "video_scale"),
        .audio => try gst.Element.init("audioresample", "audio_resample"),
    };

    const sink = switch (media_type) {
        .video => try gst.Element.init("autovideosink", "video_sink"),
        .audio => try gst.Element.init("autoaudiosink", "audio_sink"),
    };

    try context.pipeline.addMany(&.{ queue, convert, processor, sink });
    try gst.Element.linkMany(&.{ queue, convert, processor, sink });

    // Sync state of new elements with the pipeline
    // Explaination can be found here: https://github.com/sdroege/gstreamer-rs/blob/main/examples/src/bin/decodebin.rs#L138
    try queue.syncStateWithParent();
    try convert.syncStateWithParent();
    try processor.syncStateWithParent();
    try sink.syncStateWithParent();

    const sink_pad = queue.getStaticPad("sink") orelse return error.NoSinkPad;
    defer sink_pad.deinit();

    try srcPad.link(sink_pad);
}

fn pad_added_handler(element: gst.Element, srcPad: gst.Pad, user_data: ?*anyopaque) void {
    std.debug.print("Pad added callback triggered!\n", .{});

    const data = user_data orelse return;
    const context: *Context = @ptrCast(@alignCast(data));

    if (element.getName()) |elementName| {
        std.debug.print("element: {s}\n", .{elementName});
    }

    const caps = srcPad.getCurrentCaps() catch |err| {
        std.debug.print("Failed to get current caps from srcPad: {}\n", .{err});
        return;
    };
    defer caps.deinit();

    const structure = caps.getStructure(0) catch {
        std.debug.print("Failed to get structure\n", .{});
        return;
    };
    if (structure) |s| {
        defer s.deinit();

        const name = s.getName() orelse return;
        std.debug.print("Structure name: {s}\n", .{name});

        const media_type = detectMediaType(name) orelse return;
        linkPads(context, srcPad, media_type) catch |err| {
            std.debug.print("Failed to link {s} pad: {}\n", .{ @tagName(media_type), err });
            return;
        };
    }
}

pub fn main(init: std.process.Init) !void {
    try gst.macosMainSimple(run, init);
}
