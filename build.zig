const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("gstreamer", .{
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
