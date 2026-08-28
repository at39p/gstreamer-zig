// Interactive pipeline runner: bus messages, typed commands and a position
// ticker race in one Io.Select.

const std = @import("std");
const gst = @import("gst");

const Io = std.Io;

// gst_bus_timed_pop cannot be interrupted, so this bounds how long quitting takes.
const pop_timeout: gst.ClockTime = .fromMseconds(100);
const tick_interval: Io.Duration = .fromMilliseconds(500);

const Command = enum { toggle_pause, duration, quit, unknown };

// Not `Event`: gst.Event is a different thing.
const Wakeup = union(enum) {
    message: ?gst.Message,
    command: ?Command,
    tick: void,
};

fn timedPop(bus: gst.Bus) ?gst.Message {
    return bus.timedPop(pop_timeout);
}

// One byte per call, so a typed line runs its commands in order and the
// newline that ends it falls through as .unknown. Null once stdin is closed.
fn readCommand(stdin: *Io.File.Reader) ?Command {
    const key = stdin.interface.takeByte() catch return null;
    return switch (key) {
        'p', ' ' => .toggle_pause,
        'd' => .duration,
        'q' => .quit,
        else => .unknown,
    };
}

fn tick(io: Io) void {
    io.sleep(tick_interval, .awake) catch {};
}

fn clockTime(nanoseconds: ?i64) ?gst.ClockTime {
    const ns = nanoseconds orelse return null;
    if (ns < 0) return null; // GST_CLOCK_TIME_NONE
    return .fromNseconds(@intCast(ns));
}

fn printTime(label: []const u8, nanoseconds: ?i64) void {
    if (clockTime(nanoseconds)) |time| {
        std.debug.print("{s}: {f}\n", .{ label, time });
    } else {
        std.debug.print("{s}: unknown\n", .{label});
    }
}

fn run(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    const pipeline_str = try std.mem.joinZ(arena, " ", args[1..]);

    try gst.init_check(args);
    defer gst.deinit();

    const pipeline = try gst.Pipeline.initLaunch(pipeline_str);
    defer pipeline.deinit();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    try pipeline.start();
    defer _ = pipeline.setState(.null_state);

    const stdin_file = Io.File.stdin();
    var stdin_buffer: [16]u8 = undefined;
    var stdin = stdin_file.readerStreaming(io, &stdin_buffer); // a terminal is never seekable

    // One slot per task, which is what cancel() needs to drain without deadlocking.
    var wakeups: [3]Wakeup = undefined;
    var select: Io.Select(Wakeup) = .init(io, &wakeups);
    defer {
        // Cancel hands back what the tasks produced, so a popped message still gets unreffed.
        while (select.cancel()) |wakeup| switch (wakeup) {
            .message => |msg| if (msg) |m| m.deinit(),
            else => {},
        };
    }

    try select.concurrent(.message, timedPop, .{bus});
    try select.concurrent(.command, readCommand, .{&stdin});
    try select.concurrent(.tick, tick, .{io});

    std.debug.print("p pause/play   d position+duration   q quit, then Enter\n", .{});

    var playing = true;
    while (true) {
        switch (try select.await()) {
            .message => |maybe_message| {
                if (maybe_message) |message| {
                    defer message.deinit();
                    switch (message.getType()) {
                        .eos => {
                            std.debug.print("end of stream\n", .{});
                            break;
                        },
                        .err => {
                            message.parseErrorAndPrint() catch std.debug.print("Unknown error\n", .{});
                            break;
                        },
                        else => {},
                    }
                }
                try select.concurrent(.message, timedPop, .{bus});
            },
            .command => |maybe_command| {
                const command = maybe_command orelse continue;
                switch (command) {
                    .quit => break,
                    .toggle_pause => {
                        playing = !playing;
                        _ = pipeline.setState(if (playing) .playing else .paused);
                        std.debug.print("{s}\n", .{if (playing) "playing" else "paused"});
                    },
                    .duration => {
                        printTime("position", pipeline.element.queryPosition(.time));
                        printTime("duration", pipeline.element.queryDuration(.time));
                    },
                    .unknown => {},
                }
                try select.concurrent(.command, readCommand, .{&stdin});
            },
            .tick => {
                if (clockTime(pipeline.element.queryPosition(.time))) |position| {
                    std.debug.print("position: {f}\n", .{position});
                }
                try select.concurrent(.tick, tick, .{io});
            },
        }
    }
}

pub fn main(init: std.process.Init) !void {
    try gst.macosMainSimple(run, init);
}
