const std = @import("std");
const Self = @This();

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zlib = create_zlib(b, target, optimize);

    const shared_lib_options: std.build.SharedLibraryOptions = .{
        .name = "scetool",
        .target = target,
        .optimize = optimize,
    };

    const scetool: *std.Build.Step.Compile = b.addSharedLibrary(shared_lib_options);
    scetool.linkLibCpp();
    scetool.linkLibrary(zlib);
    scetool.addIncludePath(.{ .path = zlib_include_dir });

    scetool.addCSourceFiles(.{ .files = scetool_srcs });

    scetool.strip = true;

    b.installArtifact(scetool);
}

fn root() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

const root_path = root() ++ "/";

pub const zlib_include_dir = root_path ++ "zlib";

pub fn create_zlib(b: *std.build.Builder, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    var zlib = b.addStaticLibrary(.{
        .name = "z",
        .target = target,
        .optimize = optimize,
    });
    zlib.linkLibC();
    zlib.addCSourceFiles(.{ .files = srcs, .flags = &.{ "-std=c89", "-fPIC" } });

    return zlib;
}

const srcs = &.{
    root_path ++ "zlib/adler32.c",
    root_path ++ "zlib/compress.c",
    root_path ++ "zlib/crc32.c",
    root_path ++ "zlib/deflate.c",
    root_path ++ "zlib/gzclose.c",
    root_path ++ "zlib/gzlib.c",
    root_path ++ "zlib/gzread.c",
    root_path ++ "zlib/gzwrite.c",
    root_path ++ "zlib/inflate.c",
    root_path ++ "zlib/infback.c",
    root_path ++ "zlib/inftrees.c",
    root_path ++ "zlib/inffast.c",
    root_path ++ "zlib/trees.c",
    root_path ++ "zlib/uncompr.c",
    root_path ++ "zlib/zutil.c",
};

const scetool_srcs = &.{
    root_path ++ "aes_omac.cpp",
    root_path ++ "bn.cpp",
    root_path ++ "ec.cpp",
    root_path ++ "ecdsa.cpp",
    root_path ++ "frontend.cpp",
    root_path ++ "keys.cpp",
    root_path ++ "list.cpp",
    root_path ++ "mt19937.cpp",
    root_path ++ "np.cpp",
    root_path ++ "rvk.cpp",
    root_path ++ "sce.cpp",
    root_path ++ "self.cpp",
    root_path ++ "tables.cpp",
    root_path ++ "util.cpp",
    root_path ++ "spp.cpp",
    root_path ++ "main.cpp",
    root_path ++ "aes.c",
    root_path ++ "sha1.c",
};
