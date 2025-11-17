const std = @import("std");

fn addGStreamerDeps(step: anytype, pkg_config_path: ?[]const u8, b: *std.Build) void {
    const T = @TypeOf(step);

    const framework_base = if (pkg_config_path) |path|
        if (std.mem.endsWith(u8, path, "/lib/pkgconfig"))
            path[0 .. path.len - "/lib/pkgconfig".len]
        else
            path
    else
        "/Library/Frameworks/GStreamer.framework/Versions/1.0";

    const gst_include = b.fmt("{s}/include/gstreamer-1.0", .{framework_base});
    const glib_include = b.fmt("{s}/include/glib-2.0", .{framework_base});
    const glib_config_include = b.fmt("{s}/lib/glib-2.0/include", .{framework_base});
    const base_include = b.fmt("{s}/include", .{framework_base});

    // Add include paths to both compile steps and modules
    step.addIncludePath(.{ .cwd_relative = gst_include });
    step.addIncludePath(.{ .cwd_relative = glib_include });
    step.addIncludePath(.{ .cwd_relative = glib_config_include });
    step.addIncludePath(.{ .cwd_relative = base_include });

    // Only link libraries for compile steps
    if (T == *std.Build.Step.Compile) {
        step.linkLibC();
        step.linkSystemLibrary("gstapp-1.0");
        step.linkSystemLibrary2("gstreamer-video-1.0", .{ .use_pkg_config = .force });
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const pkg_config_path = b.option([]const u8, "pkg_config_path", "Custom PKG_CONFIG_PATH for GStreamer");

    const gstreamer_module = b.addModule("gstreamer", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    addGStreamerDeps(gstreamer_module, pkg_config_path, b);

    const lib = b.addLibrary(.{
        .name = "gstreamer-zig",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    addGStreamerDeps(lib, pkg_config_path, b);
    addGStreamerDeps(gstreamer_module, pkg_config_path, b);

    b.installArtifact(lib);

    // Examples
    const examples = [_]struct { name: []const u8, file: []const u8, description: []const u8, skip_install: bool = false }{
        .{ .name = "launch", .file = "launch.zig", .description = "Run the launch example" },
        .{ .name = "appsrc", .file = "appsrc.zig", .description = "Run the appsrc example" },
        .{ .name = "srt", .file = "srt-transmuxer.zig", .description = "Run srt transmuxer example", .skip_install = true },
        .{ .name = "bins", .file = "bins.zig", .description = "Run the bins example", .skip_install = true },
    };

    for (examples) |example| {
        const exe_name = std.fmt.allocPrint(b.allocator, "{s}-example", .{example.name}) catch @panic("OOM");
        const source_path = std.fmt.allocPrint(b.allocator, "src/examples/{s}", .{example.file}) catch @panic("OOM");
        const step_name = std.fmt.allocPrint(b.allocator, "run-{s}", .{example.name}) catch @panic("OOM");

        const example_exe = b.addExecutable(.{
            .name = exe_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(source_path),
                .target = target,
                .optimize = optimize,
            }),
        });
        example_exe.root_module.addImport("gst", gstreamer_module);
        addGStreamerDeps(example_exe, pkg_config_path, b);

        if (!example.skip_install) {
            b.installArtifact(example_exe);
        }

        const example_run_cmd = b.addRunArtifact(example_exe);
        if (!example.skip_install) {
            example_run_cmd.step.dependOn(b.getInstallStep());
        }
        const example_run_step = b.step(step_name, example.description);
        example_run_step.dependOn(&example_run_cmd.step);
    }
}
