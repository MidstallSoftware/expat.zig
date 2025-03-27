const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(std.builtin.LinkMode, "linkage", "whether to statically or dynamically link the library") orelse @as(std.builtin.LinkMode, if (target.result.isGnuLibC()) .dynamic else .static);

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
        .PACKAGE_TARNAME = "expat-2.6.0.tar.gz",
        .PACKAGE_VERSION = "2.6.0",
        .HAVE_GETPAGESIZE = 1,
        .XML_CONTEXT_BYTES = 1,
        .XML_DEV_URANDOM = 1,
        .XML_GE = 1,
        .off_t = "off_t",
        .size_t = "size_t",
    });
    configHeader.addValue("BYTEORDER", u16, switch (target.result.cpu.arch.endian()) {
        .little => 1234,
        .big => 4321,
    });

    const lib = b.addLibrary(.{
        .name = "expat",
        .root_module = b.addModule("expat", .{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
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
        .root = source.path("lib"),
        .files = &.{
            "xmlparse.c",
            "xmltok.c",
            "xmlrole.c",
        },
    });

    lib.installConfigHeader(configHeader);

    {
        const headers: []const []const u8 = &.{
            "expat.h",
            "expat_external.h",
        };

        for (headers) |header| {
            lib.installHeader(source.path(b.pathJoin(&.{ "lib", header })), header);
        }
    }

    b.installArtifact(lib);
}
