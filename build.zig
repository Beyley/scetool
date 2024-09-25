const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const scetool = createSceTool(b, target, optimize, null, null);

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
            .abi = .gnueabihf,
            .glibc_version = .{
                .major = 2,
                .minor = 17,
                .patch = 0,
            },
            .cpu_arch = .arm,
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
        std.Build.resolveTargetQuery(b, std.Target.Query{
            .cpu_arch = .x86_64,
            .os_tag = .linux,
            .abi = .android,
        }),
        std.Build.resolveTargetQuery(b, std.Target.Query{
            .cpu_arch = .aarch64,
            .os_tag = .linux,
            .abi = .android,
        }),
        std.Build.resolveTargetQuery(b, std.Target.Query{
            .cpu_arch = .arm,
            .os_tag = .linux,
            .abi = .androideabi,
        }),
        std.Build.resolveTargetQuery(b, std.Target.Query{
            .cpu_arch = .aarch64,
            .os_tag = .ios,
        }),
        std.Build.resolveTargetQuery(b, std.Target.Query{
            .cpu_arch = .x86_64,
            .os_tag = .ios,
            .abi = .simulator,
        }),
        std.Build.resolveTargetQuery(b, std.Target.Query{
            .cpu_arch = .aarch64,
            .os_tag = .ios,
            .abi = .simulator,
        }),
    };

    const android_version = 21;

    // attempts in order of cmd option, env var, default unix path
    const ndk_root = b.option([]const u8, "ndk_root", "The NDK root") orelse
        if (try std.process.hasEnvVar(b.allocator, "ANDROID_NDK_ROOT"))
        try std.process.getEnvVarOwned(b.allocator, "ANDROID_NDK_ROOT")
    else
        "/opt/android-ndk";

    const ios_sdk_root = b.option([]const u8, "ios_sdk_root", "The root of the iOS SDK");
    const ios_simulator_sdk_root = b.option([]const u8, "ios_simulator_sdk_root", "The root of the iOS simulator SDK");

    for (package_targets) |package_target| {
        // If the iOS SDK root is not provided, skip iOS builds
        if (package_target.result.os.tag == .ios and ios_sdk_root == null)
            continue;

        // If the iOS simulator SDK root is not provided, skip the iOS simulator builds
        if (package_target.result.abi == .simulator and ios_simulator_sdk_root == null)
            continue;

        const libc = if (package_target.result.isAndroid()) blk: {
            const android_triple = switch (package_target.result.cpu.arch) {
                .x86_64 => "x86_64-linux-android",
                .aarch64 => "aarch64-linux-android",
                .arm => "arm-linux-androideabi",
                else => @panic("TODO"),
            };

            const lib_dir = b.fmt("{s}/toolchains/llvm/prebuilt/{s}/sysroot/usr/lib/{s}/{d}/", .{
                ndk_root,
                comptime androidToolchainHostTag(),
                android_triple,
                android_version,
            });
            const include_dir = std.fs.path.resolve(b.allocator, &[_][]const u8{
                ndk_root,
                "toolchains",
                "llvm",
                "prebuilt",
                comptime androidToolchainHostTag(),
                "sysroot",
                "usr",
                "include",
            }) catch unreachable;
            const system_include_dir = std.fs.path.resolve(b.allocator, &[_][]const u8{ include_dir, android_triple }) catch unreachable;

            break :blk try createLibCFile(
                b,
                b.fmt("android-{d}-{s}.conf", .{ android_version, @tagName(package_target.result.cpu.arch) }),
                include_dir,
                system_include_dir,
                lib_dir,
            );
        } else if (package_target.result.os.tag == .ios) blk: {
            const lib_dir = try std.fs.path.resolve(b.allocator, &.{ ios_sdk_root.?, "usr", "lib" });
            const include_dir = try std.fs.path.resolve(b.allocator, &.{ ios_sdk_root.?, "usr", "include" });

            break :blk try createLibCFile(
                b,
                b.fmt("ios-{s}.conf", .{@tagName(package_target.result.cpu.arch)}),
                include_dir,
                include_dir,
                lib_dir,
            );
        } else if (package_target.result.abi == .simulator) blk: {
            const lib_dir = try std.fs.path.resolve(b.allocator, &.{ ios_simulator_sdk_root.?, "usr", "lib" });
            const include_dir = try std.fs.path.resolve(b.allocator, &.{ ios_simulator_sdk_root.?, "usr", "include" });

            break :blk try createLibCFile(
                b,
                b.fmt("ios-simulator-{s}.conf", .{@tagName(package_target.result.cpu.arch)}),
                include_dir,
                include_dir,
                lib_dir,
            );
        } else null;

        const package = createSceTool(
            b,
            package_target,
            .ReleaseSmall,
            libc,
            if (package_target.result.os.tag == .ios)
                try std.fs.path.resolve(b.allocator, &.{ ios_sdk_root.?, "usr", "lib" })
            else if (package_target.result.abi == .simulator)
                try std.fs.path.resolve(b.allocator, &.{ ios_simulator_sdk_root.?, "usr", "lib" })
            else
                null,
        );

        const dotnet_os = if (package_target.result.isAndroid())
            "android"
        else switch (package_target.result.os.tag) {
            .linux => "linux",
            .macos => "osx",
            .windows => "win",
            .ios => "ios",
            else => @panic("unknown os, sorry"),
        };
        const dotnet_arch = switch (package_target.result.cpu.arch) {
            .x86_64 => "x64",
            .arm => "arm",
            .aarch64 => "arm64",
            else => @panic("unknown arch, sorry"),
        };
        const final_name = switch (package_target.result.os.tag) {
            .linux => "libscetool.so",
            .windows => "scetool.dll",
            .macos => "libscetool.dylib",
            .ios => "libscetool.a", // we build static libraries on iOS
            else => @panic("unknown os, sorry"),
        };

        const install_step = b.addInstallBinFile(package.getEmittedBin(), b.fmt("{s}-{s}/native/{s}", .{ dotnet_os, dotnet_arch, final_name }));
        install_step.step.dependOn(&package.step);
        package_step.dependOn(&install_step.step);
    }
}

pub fn androidToolchainHostTag() []const u8 {
    return @tagName(builtin.os.tag) ++ "-" ++ @tagName(builtin.cpu.arch);
}

fn createLibCFile(b: *std.Build, file_name: []const u8, include_dir: []const u8, sys_include_dir: []const u8, crt_dir: []const u8) !std.Build.LazyPath {
    var contents = std.ArrayList(u8).init(b.allocator);
    errdefer contents.deinit();

    var writer = contents.writer();

    //  The directory that contains `stdlib.h`.
    //  On POSIX-like systems, include directories be found with: `cc -E -Wp,-v -xc /dev/null
    try writer.print("include_dir={s}\n", .{include_dir});

    // The system-specific include directory. May be the same as `include_dir`.
    // On Windows it's the directory that includes `vcruntime.h`.
    // On POSIX it's the directory that includes `sys/errno.h`.
    try writer.print("sys_include_dir={s}\n", .{sys_include_dir});

    try writer.print("crt_dir={s}\n", .{crt_dir});
    try writer.writeAll("msvc_lib_dir=\n");
    try writer.writeAll("kernel32_lib_dir=\n");
    try writer.writeAll("gcc_dir=\n");

    const step = b.addWriteFiles();
    return step.add(file_name, contents.items);
}

fn createSceTool(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    libc_file: ?std.Build.LazyPath,
    ios_lib_dir: ?[]const u8,
) *std.Build.Step.Compile {
    const lib_options = .{
        .name = "scetool",
        .target = target,
        .optimize = optimize,
    };

    const scetool: *std.Build.Step.Compile = if (target.result.os.tag == .ios) b.addStaticLibrary(lib_options) else b.addSharedLibrary(lib_options);
    scetool.linkLibCpp();
    if (target.result.os.tag != .ios) {
        const zlib = createZlib(b, target, optimize, libc_file);
        scetool.linkLibrary(zlib);
    } else {
        scetool.addLibraryPath(.{ .cwd_relative = ios_lib_dir.? });
        scetool.linkSystemLibrary("z");
    }
    scetool.addIncludePath(b.path(zlib_include_dir));
    scetool.setLibCFile(libc_file);
    if (libc_file) |libc|
        libc.addStepDependencies(&scetool.step);

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

pub fn createZlib(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, libc_file: ?std.Build.LazyPath) *std.Build.Step.Compile {
    var zlib = b.addStaticLibrary(.{
        .name = "z",
        .target = target,
        .optimize = optimize,
    });
    zlib.setLibCFile(libc_file);
    zlib.linkLibC();

    zlib.addCSourceFiles(.{ .files = zlib_srcs, .flags = &.{ "-std=c89", "-fPIC" } });
    if (libc_file) |libc|
        libc.addStepDependencies(&zlib.step);

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
    root_path ++ "scetool_main.cpp",
    root_path ++ "aes.c",
    root_path ++ "sha1.c",
};
