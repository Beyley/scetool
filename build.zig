const std = @import("std");
const builtin = @import("builtin");

const scetool_src_dir = "src/";
const scetool_srcs = &.{
    scetool_src_dir ++ "aes_omac.c",
    scetool_src_dir ++ "bn.c",
    scetool_src_dir ++ "ec.c",
    scetool_src_dir ++ "ecdsa.c",
    scetool_src_dir ++ "frontend.c",
    scetool_src_dir ++ "keys.c",
    scetool_src_dir ++ "list.c",
    scetool_src_dir ++ "mt19937.c",
    scetool_src_dir ++ "np.c",
    scetool_src_dir ++ "rvk.c",
    scetool_src_dir ++ "sce.c",
    scetool_src_dir ++ "self.c",
    scetool_src_dir ++ "tables.c",
    scetool_src_dir ++ "util.c",
    scetool_src_dir ++ "spp.c",
    scetool_src_dir ++ "scetool_main.c",
    scetool_src_dir ++ "aes.c",
    scetool_src_dir ++ "sha1.c",
};

pub fn build(b: *std.Build) !void {
    const install_target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const scetool = createSceTool(b, install_target, optimize, null, null);

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

    const ndk_version: usize = b.option(usize, "ndk_version", "The android NDK version to use when build") orelse 21;

    // attempts in order of cmd option, env var, default unix path
    const ndk_root: ?[]const u8 = b.option([]const u8, "ndk_root", "The NDK root") orelse
        if (try std.process.hasEnvVar(b.allocator, "ANDROID_NDK_ROOT"))
        try std.process.getEnvVarOwned(b.allocator, "ANDROID_NDK_ROOT")
    else
        null;

    const ios_sdk_root = b.option([]const u8, "ios_sdk_root", "The root of the iOS SDK");
    const ios_simulator_sdk_root = b.option([]const u8, "ios_simulator_sdk_root", "The root of the iOS simulator SDK");

    for (package_targets) |package_target| {
        const target = package_target.result;

        // If the iOS SDK root is not provided, skip iOS builds
        if (target.os.tag == .ios and ios_sdk_root == null)
            continue;

        // If the iOS simulator SDK root is not provided, skip the iOS simulator builds
        if (target.abi == .simulator and ios_simulator_sdk_root == null)
            continue;

        // Skip android builds if NDK root is not set
        if (target.isAndroid() and ndk_root == null)
            continue;

        const libc: ?std.Build.LazyPath = if (target.isAndroid())
            try createAndroidLibCFile(b, target, ndk_root.?, ndk_version)
        else if (target.os.tag == .ios and target.abi == .simulator)
            try createIosLibCFile(b, target, ios_simulator_sdk_root.?)
        else if (target.os.tag == .ios)
            try createIosLibCFile(b, target, ios_sdk_root.?)
        else
            null;

        const package = createSceTool(
            b,
            package_target,
            .ReleaseSmall,
            libc,
            if (target.os.tag == .ios)
                try std.fs.path.resolve(b.allocator, &.{ ios_sdk_root.?, "usr", "lib" })
            else if (target.abi == .simulator)
                try std.fs.path.resolve(b.allocator, &.{ ios_simulator_sdk_root.?, "usr", "lib" })
            else
                null,
        );

        package.defineCMacro("PACKAGE", "1");

        const install_step = b.addInstallLibFile(package.getEmittedBin(), getDotnetRuntimePath(b, target));
        install_step.step.dependOn(&package.step);
        package_step.dependOn(&install_step.step);
    }
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

    scetool.setLibCFile(libc_file);

    scetool.linkLibC();
    scetool.linkLibCpp();

    // If we aren't on iOS, use our own zlib
    if (target.result.os.tag != .ios) {
        const zlib = b.dependency("zlib", .{ .optimize = optimize, .target = target });
        const zlib_module = zlib.artifact("z");

        zlib_module.libc_file = libc_file;
        // If we have a libc file specified, make zlib depend on it
        if (libc_file) |libc|
            libc.addStepDependencies(&zlib_module.step);

        scetool.installLibraryHeaders(zlib_module);
        scetool.linkLibrary(zlib_module);
    } else {
        // If we are on iOS, use the system zlib
        scetool.addLibraryPath(.{ .cwd_relative = ios_lib_dir.? });
        scetool.linkSystemLibrary("z");
    }

    // If we have a libc file specified, make scetool depend on it
    if (libc_file) |libc|
        libc.addStepDependencies(&scetool.step);

    // Yes I know __DATE__ and __TIME__ break reproducable builds, no, I don't care
    scetool.addCSourceFiles(.{ .files = scetool_srcs, .flags = &.{"-Wno-date-time"} });

    if (optimize != .Debug)
        scetool.root_module.strip = true;

    return scetool;
}

fn androidToolchainHostTag() []const u8 {
    return @tagName(builtin.os.tag) ++ "-" ++ @tagName(builtin.cpu.arch);
}

fn androidTriple(target: std.Target) []const u8 {
    return switch (target.cpu.arch) {
        .x86_64 => "x86_64-linux-android",
        .aarch64 => "aarch64-linux-android",
        .arm => "arm-linux-androideabi",
        else => @panic("TODO"),
    };
}

fn createAndroidLibCFile(b: *std.Build, target: std.Target, ndk_root: []const u8, ndk_version: usize) !std.Build.LazyPath {
    const android_triple = androidTriple(target);

    const lib_dir = b.fmt("{s}/toolchains/llvm/prebuilt/{s}/sysroot/usr/lib/{s}/{d}/", .{
        ndk_root,
        comptime androidToolchainHostTag(),
        android_triple,
        ndk_version,
    });
    const include_dir = try std.fs.path.resolve(b.allocator, &.{
        ndk_root,
        "toolchains",
        "llvm",
        "prebuilt",
        comptime androidToolchainHostTag(),
        "sysroot",
        "usr",
        "include",
    });
    const system_include_dir = try std.fs.path.resolve(b.allocator, &.{
        include_dir,
        android_triple,
    });

    return try createLibCFile(
        b,
        b.fmt("android-{d}-{s}.conf", .{ ndk_version, @tagName(target.cpu.arch) }),
        include_dir,
        system_include_dir,
        lib_dir,
    );
}

fn createIosLibCFile(b: *std.Build, target: std.Target, ios_sdk_root: []const u8) !std.Build.LazyPath {
    const lib_dir = try std.fs.path.resolve(b.allocator, &.{ ios_sdk_root, "usr", "lib" });
    const include_dir = try std.fs.path.resolve(b.allocator, &.{ ios_sdk_root, "usr", "include" });

    return try createLibCFile(
        b,
        b.fmt(
            "ios-{s}-{s}.conf",
            .{ @tagName(target.cpu.arch), @tagName(target.abi) },
        ),
        include_dir,
        include_dir,
        lib_dir,
    );
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

fn getDotnetRuntimePath(b: *std.Build, target: std.Target) []const u8 {
    const dotnet_os = if (target.isAndroid())
        "android"
    else switch (target.os.tag) {
        .linux => "linux",
        .macos => "osx",
        .windows => "win",
        .ios => "ios",
        else => @panic("unknown os, sorry"),
    };
    const dotnet_arch = switch (target.cpu.arch) {
        .x86_64 => "x64",
        .arm => "arm",
        .aarch64 => "arm64",
        else => @panic("unknown arch, sorry"),
    };
    const final_name = switch (target.os.tag) {
        .linux => "libscetool.so",
        .windows => "scetool.dll",
        .macos => "libscetool.dylib",
        .ios => "libscetool.a", // we build static libraries on iOS
        else => @panic("unknown os, sorry"),
    };

    return b.fmt("{s}-{s}/native/{s}", .{
        dotnet_os,
        dotnet_arch,
        final_name,
    });
}
