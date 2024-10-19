const std = @import("std");
const builtin = @import("builtin");
const path = std.fs.path;
const Builder = std.Build;
const LibExeObjStep = std.Build.Step.Compile;
const LazyPath = std.Build.LazyPath;

const imgui_build = @import("zig-imgui/imgui_build.zig");

const glslc_command = if (builtin.os.tag == .windows) "tools/win/glslc.exe" else "glslc";

pub fn build(b: *Builder) void {
    const mode = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    imgui_build.addTestStep(b, "test", mode, target);

     {
         const exe = exampleExe(b, "example_glfw_vulkan", mode, target);
         linkGlfw(b, exe, target);
         //linkGlfw(exe);
         linkVulkan(b, exe, target);
         // linkVulkan(exe);
    }
    {
        const exe = exampleExe(b, "example_glfw_opengl3", mode, target);
         linkGlfw(b, exe, target);
        //linkGlfw(exe);
        // linkGlad(exe, target);
        linkGlad(b, exe);
    }
}

fn exampleExe(b: *Builder, comptime name: []const u8, mode: std.builtin.Mode, target: std.Build.ResolvedTarget) *LibExeObjStep {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = LazyPath {.src_path = .{ .sub_path = "examples/" ++ name ++ ".zig", .owner = b }},
        .optimize = mode,
        .target = target,
    });

    imgui_build.prepareAndLink(b, exe);
    b.installArtifact(exe);

    const run_step = b.step(name, "Run " ++ name);
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    return exe;
}

//fn linkGlad(exe: *LibExeObjStep, target: std.Build.ResolvedTarget) void {
fn linkGlad(b: *Builder, exe: *LibExeObjStep) void {
    exe.addIncludePath(b.path("examples/include/c_include"));
    exe.addCSourceFile(std.Build.Module.CSourceFile {.file = b.path("examples/c_src/glad.c"), .flags = &[_][]const u8{"-std=c99"}});
    //exe.linkSystemLibrary("opengl");
}

fn linkGlfw(b: *Builder, exe: *LibExeObjStep, target: std.Build.ResolvedTarget) void {
    if (target.result.os.tag == .windows) {
        exe.addObjectFile(if (target.result.abi == .msvc) b.path("examples/lib/win/glfw3.lib") else b.path("examples/lib/win/libglfw3.a"));
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("shell32");
    } else {
        exe.linkSystemLibrary("glfw");
    }
}

fn linkVulkan(b: *Builder, exe: *LibExeObjStep, target: std.Build.ResolvedTarget) void {
    if (target.result.os.tag == .windows) {
        exe.addObjectFile(b.path("examples/lib/win/vulkan-1.lib"));
    } else {
        exe.linkSystemLibrary("vulkan");
    }
}
