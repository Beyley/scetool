const std = @import("std");
const Self = @This();

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const scetool = createSceTool(b, target, optimize);

    b.installArtifact(scetool);

    var package_step = b.step("package", "Packages scetool for all platforms");

    const package_targets: []const std.Build.ResolvedTarget = &.{
        std.Build.resolveTargetQuery(b, std.Target.Query{
            .abi = .gnu,
            .glibc_version = .{
                .major = 2,
                .minor = 17,
                .patch = 0,
            },
            .cpu_arch = .x86_64,
            .os_tag = .linux,
        }),
        std.Build.resolveTargetQuery(b, std.Target.Query{
            .abi = .gnu,
            .glibc_version = .{
                .major = 2,
                .minor = 17,
                .patch = 0,
            },
            .cpu_arch = .aarch64,
            .os_tag = .linux,
        }),
        std.Build.resolveTargetQuery(b, std.Target.Query{
            .cpu_arch = .aarch64,
            .os_tag = .windows,
        }),
        std.Build.resolveTargetQuery(b, std.Target.Query{
            .cpu_arch = .x86_64,
            .os_tag = .windows,
        }),
        std.Build.resolveTargetQuery(b, std.Target.Query{
            .cpu_arch = .aarch64,
            .os_tag = .macos,
        }),
        std.Build.resolveTargetQuery(b, std.Target.Query{
            .cpu_arch = .x86_64,
            .os_tag = .macos,
        }),
    };

    for (package_targets) |package_target| {
        const package = createSceTool(b, package_target, .ReleaseSmall);

        const dotnet_os = switch (package_target.result.os.tag) {
            .linux => "linux",
            .macos => "osx",
            .windows => "win",
            else => @panic("unknown os, sorry"),
        };
        const dotnet_arch = switch (package_target.result.cpu.arch) {
            .x86_64 => "x64",
            .aarch64 => "arm64",
            else => @panic("unknown arch, sorry"),
        };
        const final_name = switch (package_target.result.os.tag) {
            .linux => "libscetool.so",
            .windows => "scetool.dll",
            .macos => "libscetool.dylib",
            else => @panic("unknown os, sorry"),
        };

        const install_step = b.addInstallBinFile(package.getEmittedBin(), b.fmt("{s}-{s}/native/{s}", .{ dotnet_os, dotnet_arch, final_name }));
        install_step.step.dependOn(&package.step);
        package_step.dependOn(&install_step.step);
    }
}

fn createSceTool(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const zlib = createZlib(b, target, optimize);

    const shared_lib_options: std.Build.SharedLibraryOptions = .{
        .name = "scetool",
        .target = target,
        .optimize = optimize,
    };

    const scetool: *std.Build.Step.Compile = b.addSharedLibrary(shared_lib_options);
    scetool.linkLibCpp();
    scetool.linkLibrary(zlib);
    scetool.addIncludePath(.{ .path = zlib_include_dir });

    scetool.addCSourceFiles(.{ .files = scetool_srcs });

    if (optimize != .Debug)
        scetool.root_module.strip = true;

    return scetool;
}

fn root() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

const root_path = root() ++ "/";

pub const zlib_include_dir = root_path ++ "zlib";

pub fn createZlib(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    var zlib = b.addStaticLibrary(.{
        .name = "z",
        .target = target,
        .optimize = optimize,
    });
    zlib.linkLibC();
    zlib.addCSourceFiles(.{ .files = zlib_srcs, .flags = &.{ "-std=c89", "-fPIC" } });

    return zlib;
}

const zlib_srcs = &.{
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
