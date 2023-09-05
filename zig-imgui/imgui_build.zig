const std = @import("std");
const version: std.SemanticVersion = @import("builtin").zig_version;

// @src() is only allowed inside of a function, so we need this wrapper
fn srcFile() []const u8 {
    return @src().file;
}
const sep = std.fs.path.sep_str;

const zig_imgui_path = std.fs.path.dirname(srcFile()).?;
const zig_imgui_file = zig_imgui_path ++ sep ++ "imgui.zig";

var module: ?*std.Build.Module = null;

pub fn prepareModule(b: *std.Build) *std.Build.Module {
    if (module) |mod| {
        std.debug.assert(mod.builder == b);
        return mod;
    }

    var mod = b.createModule(.{
        .source_file = .{ .path = zig_imgui_file },
    });
    module = mod;
    return mod;
}

pub fn link(exe: *std.build.LibExeObjStep) void {
    linkWithoutPackage(exe);
    exe.addModule("imgui", module.?);
}

pub fn prepareAndLink(b: *std.Build, exe: *std.Build.LibExeObjStep) void {
    linkWithoutPackage(exe);
    exe.addModule("imgui", prepareModule(b));
}

pub fn linkWithoutPackage(exe: *std.build.LibExeObjStep) void {
    const imgui_cpp_file = .{ .path = zig_imgui_path ++ sep ++ "cimgui_unity.cpp" };

    exe.linkLibCpp();
    exe.addCSourceFile(.{
        .file = imgui_cpp_file,
        .flags = &[_][]const u8{
            "-fno-sanitize=undefined",
            "-ffunction-sections",
        },
    });
}

pub fn addTestStep(
    b: *std.build.Builder,
    step_name: []const u8,
    mode: std.builtin.Mode,
    target: std.zig.CrossTarget,
) void {
    const test_exe = b.addTest(.{
        .root_source_file = .{ .path = zig_imgui_path ++ std.fs.path.sep_str ++ "tests.zig" },
        .optimize = mode,
        .target = target,
    });

    prepareAndLink(b, test_exe);

    const test_step = b.step(step_name, "Run zig-imgui tests");
    test_step.dependOn(&test_exe.step);
}
