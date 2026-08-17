const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const pkg_config_path = b.option([]const u8, "pkg_config_path", "Custom PKG_CONFIG_PATH for GStreamer");

    const framework_base = if (pkg_config_path) |path|
        if (std.mem.endsWith(u8, path, "/lib/pkgconfig"))
            path[0 .. path.len - "/lib/pkgconfig".len]
        else
            path
    else
        "/Library/Frameworks/GStreamer.framework/Versions/1.0";

    // Translate C headers to Zig (replaces @cImport which is deprecated in Zig 0.16)
    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/c_gst.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    translate_c.addIncludePath(.{ .cwd_relative = b.fmt("{s}/include/gstreamer-1.0", .{framework_base}) });
    translate_c.addIncludePath(.{ .cwd_relative = b.fmt("{s}/include/glib-2.0", .{framework_base}) });
    translate_c.addIncludePath(.{ .cwd_relative = b.fmt("{s}/lib/glib-2.0/include", .{framework_base}) });
    translate_c.addIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{framework_base}) });

    const c_module = translate_c.createModule();

    // Imported as "testing" by every source file's trailing test block, so the
    // reference is spelled the same regardless of how deep the file sits.
    const testing_module = b.createModule(.{
        .root_source_file = b.path("src/testing.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "c", .module = c_module }},
    });

    const gstreamer_module = b.addModule("gstreamer", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "c", .module = c_module },
            .{ .name = "testing", .module = testing_module },
        },
    });

    gstreamer_module.linkSystemLibrary("gstapp-1.0", .{});
    gstreamer_module.linkSystemLibrary("gstreamer-pbutils-1.0", .{ .use_pkg_config = .force });

    const lib = b.addLibrary(.{
        .name = "gstreamer-zig",
        .linkage = .static,
        .root_module = gstreamer_module,
    });
    b.installArtifact(lib);

    const check = b.step("check", "Check if project compiles (for ZLS build-on-save)");
    const lib_check = b.addLibrary(.{
        .name = "gstreamer-zig-check",
        .linkage = .static,
        .root_module = gstreamer_module,
    });
    check.dependOn(&lib_check.step);

    // refAllDeclsRecursive in each source file makes this analyze the whole
    // public API, including bindings with no call site.
    const lib_tests = b.addTest(.{ .root_module = gstreamer_module });
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);
    check.dependOn(&lib_tests.step);

    const examples = [_]struct { name: []const u8, file: []const u8, description: []const u8, skip_install: bool = false }{
        .{ .name = "launch", .file = "launch.zig", .description = "Run the launch example" },
        .{ .name = "appsrc", .file = "appsrc.zig", .description = "Run the appsrc example" },
        .{ .name = "appsink", .file = "appsink.zig", .description = "Run the appsink example" },
        .{ .name = "srt", .file = "srt-transmuxer.zig", .description = "Run srt transmuxer example", .skip_install = true },
        .{ .name = "bins", .file = "bins.zig", .description = "Run the bins example", .skip_install = true },
        .{ .name = "custom-events", .file = "custom-events.zig", .description = "Run the custom events example", .skip_install = true },
        .{ .name = "decodebin", .file = "decodebin.zig", .description = "Run the decodebin example" },
        .{ .name = "discoverer", .file = "discoverer.zig", .description = "Run the discoverer example" },
    };

    for (examples) |example| {
        const exe_name = std.fmt.allocPrint(b.allocator, "{s}-example", .{example.name}) catch @panic("OOM");
        const source_path = std.fmt.allocPrint(b.allocator, "examples/{s}", .{example.file}) catch @panic("OOM");
        const step_name = std.fmt.allocPrint(b.allocator, "run-{s}", .{example.name}) catch @panic("OOM");

        const example_module = b.createModule(.{
            .root_source_file = b.path(source_path),
            .target = target,
            .optimize = optimize,
        });
        example_module.addImport("gst", gstreamer_module);

        const example_exe = b.addExecutable(.{
            .name = exe_name,
            .root_module = example_module,
        });

        if (!example.skip_install) {
            b.installArtifact(example_exe);
        }

        if (!example.skip_install) {
            const example_check = b.addExecutable(.{
                .name = std.fmt.allocPrint(b.allocator, "{s}-check", .{exe_name}) catch @panic("OOM"),
                .root_module = example_module,
            });
            check.dependOn(&example_check.step);
        }

        const example_run_cmd = b.addRunArtifact(example_exe);
        if (!example.skip_install) {
            example_run_cmd.step.dependOn(b.getInstallStep());
        }
        const example_run_step = b.step(step_name, example.description);
        example_run_step.dependOn(&example_run_cmd.step);
    }
}
