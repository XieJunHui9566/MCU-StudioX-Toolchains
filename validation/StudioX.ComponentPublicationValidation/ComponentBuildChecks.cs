using System.Diagnostics;
using System.Security.Cryptography;
using StudioX.Application;
using StudioX.Application.Tools;
using StudioX.Engine;
using StudioX.Foundation;
using StudioX.Packages;

internal static class ComponentBuildChecks
{
    public static async Task RunAsync(string archive, string output)
    {
        if (Directory.Exists(output)) throw new InvalidOperationException("Use a new isolated validation directory.");
        Directory.CreateDirectory(output);
        var checks = new List<string>();
        void Check(bool ok, string text)
        {
            if (!ok) throw new InvalidOperationException(text);
            checks.Add(text);
            Console.WriteLine("PASS " + text);
        }
        var tools = new ToolsetCatalog(Path.Combine(output, "runtime/toolsets"));
        var manager = new ToolManagementService(tools, new PackRepository(Path.Combine(output, "packs")), new RecentProjectService(output), output);
        var preview = await manager.PreviewInstallAsync(archive);
        Check(preview.Id is "pc.mingw" or "arm.gnu" or "riscv.xpack" or "wch.riscv" or "espressif.idf" or "espressif.esp8266-rtos" or "hdl.iverilog", "explicit supported component identity");
        await manager.InstallAsync(preview);
        var installed = await tools.ResolveAsync(preview.Id, preview.Version, preview.CompilerId, default, true);
        Check(installed.Fingerprint.Equals(preview.Fingerprint, StringComparison.OrdinalIgnoreCase), "full archive import preserves exact manifest and verifies every file");
        Check((await manager.InstallAsync(await manager.PreviewInstallAsync(archive))).AlreadyInstalled, "duplicate import verifies and preserves installed component");
        var native = Path.Combine(output, "native");
        Directory.CreateDirectory(native);
        async Task<string> Run(string name, string executable, params string[] arguments)
        {
            var start = new ProcessStartInfo(executable) { WorkingDirectory = native, UseShellExecute = false, CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden, RedirectStandardOutput = true, RedirectStandardError = true };
            foreach (var argument in arguments) start.ArgumentList.Add(argument);
            start.Environment.Clear();
            foreach (var variable in new[] { "SystemRoot", "WINDIR", "ComSpec" })
                if (Environment.GetEnvironmentVariable(variable) is { } value) start.Environment[variable] = value;
            foreach (var pair in ToolsetEnvironment.Create(installed)) start.Environment[pair.Key] = pair.Value;
            start.Environment["TEMP"] = start.Environment["TMP"] = native;
            using var process = Process.Start(start) ?? throw new InvalidOperationException("Cannot execute verified component tool.");
            var stdout = process.StandardOutput.ReadToEndAsync();
            var stderr = process.StandardError.ReadToEndAsync();
            using var deadline = new CancellationTokenSource(TimeSpan.FromMinutes(2));
            try { await process.WaitForExitAsync(deadline.Token); }
            catch { process.Kill(entireProcessTree: true); throw; }
            var text = await stdout;
            await File.WriteAllTextAsync(Path.Combine(native, name + "-stdout.txt"), text);
            await File.WriteAllTextAsync(Path.Combine(native, name + "-stderr.txt"), await stderr);
            Check(process.ExitCode == 0, name + " succeeds with isolated environment");
            return text;
        }
        if (preview.Id == "pc.mingw")
        {
            await File.WriteAllTextAsync(Path.Combine(native, "main.c"), "#include <stdio.h>\n#include <stdint.h>\nint main(void) { volatile uint64_t value=123456789012345ULL; printf(\"PC_C_OK:%llu\\n\", (unsigned long long)(value/37)); return 0; }\n");
            await Run("c-build", installed.Tool("gcc"), "-O2", "-flto", "-Wall", "-Werror", "main.c", "-o", "c-test.exe");
            Check((await Run("c-run", Path.Combine(native, "c-test.exe"))).Trim() == "PC_C_OK:3336669973306", "real C program executes integer division and runtime IO");
            await File.WriteAllTextAsync(Path.Combine(native, "main.cpp"), "#include <vector>\n#include <numeric>\n#include <iostream>\nint main() { std::vector<int> values{1,2,3,4}; std::cout << \"PC_CPP_OK:\" << std::accumulate(values.begin(),values.end(),0) << std::endl; }\n");
            await Run("cpp-build", installed.Tool("gxx"), "-std=c++17", "-O2", "-flto", "-Wall", "-Werror", "main.cpp", "-o", "cpp-test.exe");
            Check((await Run("cpp-run", Path.Combine(native, "cpp-test.exe"))).Contains("PC_CPP_OK:10"), "real C++ program executes STL and bundled runtime libraries");
        }
        else if (preview.Id == "hdl.iverilog")
        {
            await File.WriteAllTextAsync(Path.Combine(native, "main.v"), "module test; reg [7:0] a,b; initial begin a=8'hA5;b=8'h0F; #1; if ((a & b) !== 8'h05) $fatal(1,\"AND failed\"); $display(\"HDL_OK\"); $finish; end endmodule\n");
            await Run("verilog-build", installed.Tool("iverilog"), "-g2012", "-o", "test.vvp", "main.v");
            Check((await Run("verilog-simulation", installed.Tool("vvp"), "test.vvp")).Contains("HDL_OK"), "real Verilog simulation validates bitwise operation");
        }
        else
        {
            await File.WriteAllTextAsync(Path.Combine(native, "main.c"), "#include <stdint.h>\nvolatile uint32_t counter; void _start(void) { for (;;) { counter += 3; } }\n");
            var keys = preview.Id == "espressif.idf" ? new[] { "gcc-esp32", "gcc-esp32s3", "gcc-riscv" } : new[] { "gcc" };
            foreach (var key in keys)
            {
                var flags = new List<string> { "-O2", "-ffreestanding", "-nostdlib", "-Wl,-e,_start", "main.c", "-o", key + ".elf" };
                if (preview.Id == "arm.gnu") flags.InsertRange(0, ["-mcpu=cortex-m4", "-mthumb"]);
                if (preview.Id is "wch.riscv" or "riscv.xpack") flags.InsertRange(0, ["-march=rv32imac", "-mabi=ilp32"]);
                await Run(key + "-build", installed.Tool(key), flags.ToArray());
                var bytes = await File.ReadAllBytesAsync(Path.Combine(native, key + ".elf"));
                Check(bytes.Length > 100 && bytes.AsSpan(0, 4).SequenceEqual(new byte[] { 0x7f, 0x45, 0x4c, 0x46 }), key + " creates real ELF with installed headers, compiler and linker");
            }
            if (installed.Manifest.Executables.ContainsKey("gdb")) await Run("gdb-version", installed.Tool("gdb"), "--nx", "--nh", "--version");
            if (installed.Manifest.Executables.ContainsKey("openocd")) await Run("openocd-version", installed.Tool("openocd"), "--version");
            if (installed.Manifest.Executables.ContainsKey("cmake")) await Run("cmake-version", installed.Tool("cmake"), "--version");
            if (installed.Manifest.Executables.ContainsKey("ninja")) await Run("ninja-version", installed.Tool("ninja"), "--version");
        }
        await JsonStore.WriteAsync(Path.Combine(output, "result.json"), new { formatVersion = 1, status = "passed", scope = "offline-build-and-import", hardware = false, id = preview.Id, version = preview.Version, host = preview.Host, compilerId = preview.CompilerId, manifestSha256 = preview.Fingerprint, archiveSha256 = preview.ArchiveSha256, downloadBytes = new FileInfo(archive).Length, installedBytes = preview.Bytes, checks, limitations = "Compiler and component import acceptance only; SDK integration and hardware acceptance are reported separately." });
    }
}
