const std = @import("std");
const Self = @This();

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const lib: Library = create_zlib(b, target, mode);
    lib.step.install();
    
    const shared_lib_options: std.build.SharedLibraryOptions = .{
        .name = "scetool",
        .target = target,
        .optimize = mode,
    };

    const scetool: *std.build.LibExeObjStep = b.addSharedLibrary(shared_lib_options);
    scetool.linkSystemLibrary("c++");
    lib.link(scetool, .{});

    scetool.addCSourceFiles(scetool_srcs_cpp, &.{"-std=c++11", "-fPIC"});
    scetool.addCSourceFiles(scetool_srcs_c, &.{"-std=c89", "-fPIC"});
    scetool.install();
}

fn root() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

const root_path = root() ++ "/";
const package_path = root_path ++ "src/main.zig";
pub const include_dir = root_path ++ "zlib";
pub const Options = struct {
    import_name: ?[]const u8 = null,
};

pub const Library = struct {
    step: *std.build.LibExeObjStep,

    pub fn link(self: Library, other: *std.build.LibExeObjStep, opts: Options) void {
        other.addIncludePath(include_dir);
        other.linkLibrary(self.step);

        if (opts.import_name) |import_name|
            other.addAnonymousModule(
                import_name,
                .{ .source_file = .{ .path = package_path } },
            );
    }
};

pub fn create_zlib(b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.OptimizeMode) Library {
    var ret = b.addStaticLibrary(.{
        .name = "z",
        .target = target,
        .optimize = mode,
    });
    ret.linkLibC();
    ret.addCSourceFiles(srcs, &.{"-std=c89", "-fPIC"});

    return Library{ .step = ret };
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

const scetool_srcs_cpp = &.{
    root_path ++ "aes_omac.cpp",
    root_path ++ "bn.cpp",
    root_path ++ "ec.cpp",
    root_path ++ "ecdsa.cpp",
    root_path ++ "frontend.cpp",
    // root_path ++ "getopt.c",
    root_path ++ "keys.cpp",
    root_path ++ "list.cpp",
    // root_path ++ "main.c",
    root_path ++ "mt19937.cpp",
    root_path ++ "np.cpp",
    root_path ++ "rvk.cpp",
    root_path ++ "sce.cpp",
    root_path ++ "self.cpp",
    root_path ++ "tables.cpp",
    root_path ++ "util.cpp",
    root_path ++ "spp.cpp",
    root_path ++ "main.cpp"
};

const scetool_srcs_c = &.{
    root_path ++ "aes.c",
    root_path ++ "sha1.c",
};