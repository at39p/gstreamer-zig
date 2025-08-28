const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const pkg_config_path = b.option([]const u8, "pkg_config_path", "Custom PKG_CONFIG_PATH for GStreamer");

    const gstreamer_module = b.addModule("gstreamer", .{
        .root_source_file = b.path("src/gstreamer.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "gstreamer-zig",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/gstreamer.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.linkLibC();

    // If custom pkg_config_path is provided, derive include paths
    if (pkg_config_path) |path| {
        // Remove /lib/pkgconfig suffix and add include paths
        const framework_base = if (std.mem.endsWith(u8, path, "/lib/pkgconfig"))
            path[0 .. path.len - "/lib/pkgconfig".len]
        else
            path;

        const gst_include = b.fmt("{s}/include/gstreamer-1.0", .{framework_base});
        const glib_include = b.fmt("{s}/include/glib-2.0", .{framework_base});
        const glib_config_include = b.fmt("{s}/lib/glib-2.0/include", .{framework_base});
        const base_include = b.fmt("{s}/include", .{framework_base});

        gstreamer_module.addIncludePath(.{ .cwd_relative = gst_include });
        gstreamer_module.addIncludePath(.{ .cwd_relative = glib_include });
        gstreamer_module.addIncludePath(.{ .cwd_relative = glib_config_include });
        gstreamer_module.addIncludePath(.{ .cwd_relative = base_include });

        lib.addIncludePath(.{ .cwd_relative = gst_include });
        lib.addIncludePath(.{ .cwd_relative = glib_include });
        lib.addIncludePath(.{ .cwd_relative = glib_config_include });
        lib.addIncludePath(.{ .cwd_relative = base_include });
    }

    lib.linkSystemLibrary2("gstreamer-1.0", .{ .use_pkg_config = .force });
    lib.linkSystemLibrary2("glib-2.0", .{ .use_pkg_config = .force });
    lib.linkSystemLibrary2("gobject-2.0", .{ .use_pkg_config = .force });

    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/gstreamer.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    lib_unit_tests.linkLibC();
    lib_unit_tests.linkSystemLibrary2("gstreamer-1.0", .{ .use_pkg_config = .force });
    lib_unit_tests.linkSystemLibrary2("glib-2.0", .{ .use_pkg_config = .force });
    lib_unit_tests.linkSystemLibrary2("gobject-2.0", .{ .use_pkg_config = .force });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
