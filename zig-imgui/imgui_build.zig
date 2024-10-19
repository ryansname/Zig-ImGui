const std = @import("std");
const version: std.SemanticVersion = @import("builtin").zig_version;
const LibExeObjStep = std.Build.Step.Compile;
const LazyPath = std.Build.LazyPath;

// @src() is only allowed inside of a function, so we need this wrapper
fn srcFile() []const u8 {
    return @src().file;
}
const sep = std.fs.path.sep_str;

const zig_imgui_path = "zig-imgui";
const zig_imgui_file = zig_imgui_path ++ sep ++ "imgui.zig";

var module: ?*std.Build.Module = null;

pub fn prepareModule(b: *std.Build) *std.Build.Module {
    if (module) |mod| {
        std.debug.assert(mod.builder == b);
        return mod;
    }

    const mod = b.createModule(.{
        .source_file = LazyPath{.src_path = .{ .sub_path = zig_imgui_file, .owner = b }},
    });
    module = mod;
    return mod;
}

pub fn link(b: *std.Build, exe: *LibExeObjStep) void {
    linkWithoutPackage(b, exe);
    const m = b.addModule("imgui", std.Build.Module.CreateOptions {});
    _ = m;
}

pub fn prepareAndLink(b: *std.Build, exe: *LibExeObjStep) void {
    linkWithoutPackage(b, exe);
    const m = b.addModule("imgui", std.Build.Module.CreateOptions {});
    _ = m;
}

pub fn linkWithoutPackage(b: *std.Build, exe: *LibExeObjStep) void {
    const imgui_cpp_file = zig_imgui_path ++ sep ++ "cimgui_unity.cpp";

    exe.linkLibCpp();
    exe.addCSourceFile(.{
        .file = b.path(imgui_cpp_file),
        .flags = &[_][]const u8{
            "-fno-sanitize=undefined",
            "-ffunction-sections",
        },
    });
}

pub fn addTestStep(
    b: *std.Build,
    step_name: []const u8,
    mode: std.builtin.Mode,
    target: std.Build.ResolvedTarget,
) void {
    const test_exe = b.addTest(.{
        .root_source_file = LazyPath{.src_path = .{ .sub_path = zig_imgui_path ++ std.fs.path.sep_str ++ "tests.zig" , .owner = b}},
        .optimize = mode,
        .target = target,
    });

    prepareAndLink(b, test_exe);

    const test_step = b.step(step_name, "Run zig-imgui tests");
    test_step.dependOn(&test_exe.step);
}
