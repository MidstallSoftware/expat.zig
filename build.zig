const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(std.Build.Step.Compile.Linkage, "linkage", "whether to statically or dynamically link the library") orelse .static;

    const source = b.dependency("expat", .{});

    const configHeader = b.addConfigHeader(.{
        .style = .{
            .cmake = source.path("expat_config.h.cmake"),
        },
        .include_path = "expat_config.h",
    }, .{
        .PACKAGE_BUGREPORT = "https://github.com/libexpat/libexpat/issues",
        .PACKAGE_NAME = "expat",
        .PACKAGE_STRING = "expat 2.6.0",
        .HAVE_GETPAGESIZE = 1,
        .XML_CONTEXT_BYTES = 1,
        .XML_DEV_URANDOM = 1,
        .XML_GE = 1,
    });

    const lib = std.Build.Step.Compile.create(b, .{
        .name = "expat",
        .root_module = .{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        },
        .kind = .lib,
        .linkage = linkage,
        .version = .{
            .major = 1,
            .minor = 9,
            .patch = 0,
        },
    });

    lib.addConfigHeader(configHeader);
    lib.addIncludePath(source.path("lib"));

    lib.addCSourceFiles(.{
        .files = &.{
            source.path("lib/xmlparse.c").getPath(source.builder),
            source.path("lib/xmltok.c").getPath(source.builder),
            source.path("lib/xmlrole.c").getPath(source.builder),
        },
    });

    lib.installConfigHeader(configHeader, .{});

    {
        const headers: []const []const u8 = &.{
            "expat.h",
            "expat_external.h",
        };

        for (headers) |header| {
            const install_file = b.addInstallFileWithDir(source.path(b.pathJoin(&.{ "lib", header })), .header, header);
            b.getInstallStep().dependOn(&install_file.step);
            lib.installed_headers.append(&install_file.step) catch @panic("OOM");
        }
    }

    b.installArtifact(lib);
}
