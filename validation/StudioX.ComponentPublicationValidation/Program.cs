using System.Diagnostics;
using System.Security.Cryptography;
using StudioX.Application;
using StudioX.Application.Distribution;
using StudioX.Application.Tools;
using StudioX.Engine;
using StudioX.Foundation;
using StudioX.Packages;

if (args is ["--verify-online-catalog", var catalogUrl, var publicKey, var onlineOutput])
{
    var onlineRoot = Path.GetFullPath(onlineOutput);
    if (Directory.Exists(onlineRoot)) throw new InvalidOperationException("Use a new online evidence directory.");
    Directory.CreateDirectory(onlineRoot);
    using var service = new DistributionService(onlineRoot);
    var remote = await service.ReadAsync(catalogUrl, Path.GetFullPath(publicKey));
    if (!remote.Verification.Contains("签名匹配") || remote.Catalog.Entries.Length != 0)
        throw new InvalidOperationException("Expected the real signed empty bootstrap directory.");
    await JsonStore.WriteAsync(Path.Combine(onlineRoot, "result.json"), new
    {
        success = true, network = true, hardware = false, source = catalogUrl,
        remote.CatalogSha256, remote.Verification, entries = remote.Catalog.Entries.Length
    });
    Console.WriteLine("PASS IDE verifies the public HTTPS bootstrap directory against the pinned publisher key");
    return;
}
if (args.Length != 3) throw new ArgumentException("Usage: <repository> <candidate.json> <new output directory>");
var repository = Path.GetFullPath(args[0]);
var candidatePath = Path.GetFullPath(args[1]);
var output = Path.GetFullPath(args[2]);
if (Directory.Exists(output)) throw new InvalidOperationException("Use a new validation directory.");
Directory.CreateDirectory(output);
var checks = new List<string>();
void Check(bool passed, string description)
{
    if (!passed) throw new InvalidOperationException(description);
    checks.Add(description);
    Console.WriteLine("PASS " + description);
}
var candidate = await JsonStore.ReadAsync<Candidate>(candidatePath);
var archive = PathBoundary.Resolve(Path.GetDirectoryName(candidatePath)!, candidate.Asset);
Check(candidate.CandidatePackage && !candidate.CatalogEligible && candidate.PublicationStatus == "pending-materials",
    "unapproved native package stays a local candidate and is absent from the public catalog");
var data = Path.Combine(output, "isolated-user-data");
using var distribution = new DistributionService(data);
var catalogPath = Path.Combine(repository, "catalog/catalog.json");
var key = Path.Combine(repository, "trust/publisher.pem");
var listing = await distribution.ReadAsync(catalogPath, key);
Check(listing.Verification.Contains("签名匹配") && listing.Catalog.Entries.Length == 0,
    "IDE distribution service verifies the real signed empty bootstrap catalog");
var tampered = Path.Combine(output, "tampered-catalog.json");
await File.WriteAllTextAsync(tampered, "{\"formatVersion\":1,\"publisher\":\"changed\",\"entries\":[]}");
File.Copy(catalogPath + ".sig", tampered + ".sig");
try { await distribution.ReadAsync(tampered, key); Check(false, "tampered catalog rejected"); }
catch (StudioXException ex) { Check(ex.Code == "CATALOG_SIGNATURE", "IDE rejects a changed catalog with the original signature"); }
using (var wrong = RSA.Create(3072))
{
    var wrongKey = Path.Combine(output, "wrong-publisher.pem");
    await File.WriteAllTextAsync(wrongKey, wrong.ExportSubjectPublicKeyInfoPem());
    try { await distribution.ReadAsync(catalogPath, wrongKey); Check(false, "wrong publisher rejected"); }
    catch (StudioXException ex) { Check(ex.Code == "CATALOG_SIGNATURE", "IDE rejects a catalog when the selected publisher key differs"); }
}
var toolCatalog = new ToolsetCatalog(Path.Combine(output, "isolated-runtime/toolsets"));
var management = new ToolManagementService(toolCatalog, new PackRepository(Path.Combine(data, "packs")), new RecentProjectService(data), data);
var preview = await management.PreviewInstallAsync(archive);
Check(preview.Id == candidate.Id && preview.Version == candidate.Version && preview.Host == candidate.Host &&
    preview.CompilerId == candidate.CompilerId && preview.Fingerprint.Equals(candidate.ManifestSha256, StringComparison.OrdinalIgnoreCase) &&
    preview.ArchiveSha256.Equals(candidate.Sha256, StringComparison.OrdinalIgnoreCase), "IDE preview reads the real candidate's immutable identity and archive hash");
Check(preview.Bytes == candidate.InstalledBytes && new FileInfo(archive).Length == candidate.DownloadBytes && candidate.DownloadBytes < 2L * 1024 * 1024 * 1024,
    "actual download and expanded sizes match the candidate receipt and GitHub asset limit");
await management.InstallAsync(preview);
var installed = await toolCatalog.ResolveAsync(candidate.Id, candidate.Version, candidate.CompilerId, default, true);
Check(installed.Fingerprint.Equals(candidate.ManifestSha256, StringComparison.OrdinalIgnoreCase), "fresh candidate import fully verifies all installed files without changing the manifest");
var duplicate = await management.InstallAsync(await management.PreviewInstallAsync(archive));
Check(duplicate.AlreadyInstalled, "reimport completely verifies the same native component and skips replacement");

// 只在隔离目录执行已完整校验的 SDCC，检查头文件、编译器、链接器和运行库，不访问设备。
Check(candidate.Id == "stc.sdcc" && installed.Manifest.Executables.ContainsKey("sdcc"), "native validation uses the explicitly selected SDCC component");
var native = Path.Combine(output, "native-test");
Directory.CreateDirectory(native);
var source = Path.Combine(native, "main.c");
await File.WriteAllTextAsync(source, "#include <stdint.h>\nvolatile uint32_t dividend = 123456789UL;\nvolatile uint32_t quotient;\nvoid main(void) { quotient = dividend / 37UL; for (;;) {} }\n");
var start = new ProcessStartInfo(installed.Tool("sdcc"))
{
    WorkingDirectory = native, UseShellExecute = false, CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden,
    RedirectStandardOutput = true, RedirectStandardError = true
};
foreach (var argument in new[] { "-mmcs51", "--model-small", "--out-fmt-ihx", "-o", "firmware.ihx", "main.c" }) start.ArgumentList.Add(argument);
start.Environment.Clear();
foreach (var name in new[] { "SystemRoot", "WINDIR", "ComSpec" }) if (Environment.GetEnvironmentVariable(name) is { } value) start.Environment[name] = value;
start.Environment["PATH"] = ToolsetEnvironment.Create(installed)["PATH"];
start.Environment["TEMP"] = start.Environment["TMP"] = native;
using var process = Process.Start(start) ?? throw new InvalidOperationException("Cannot start the verified compiler.");
var stdout = process.StandardOutput.ReadToEndAsync();
var stderr = process.StandardError.ReadToEndAsync();
using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(60));
try { await process.WaitForExitAsync(timeout.Token); }
catch { process.Kill(entireProcessTree: true); throw; }
await File.WriteAllTextAsync(Path.Combine(native, "compiler-stdout.txt"), await stdout);
await File.WriteAllTextAsync(Path.Combine(native, "compiler-stderr.txt"), await stderr);
var firmware = Path.Combine(native, "firmware.ihx");
Check(process.ExitCode == 0 && File.Exists(firmware) && new FileInfo(firmware).Length > 100,
    "imported SDCC really compiles and links a C51 program with stdint and division runtime support");
await JsonStore.WriteAsync(Path.Combine(output, "result.json"), new
{
    status = "passed", scope = "offline-build-and-import", hardware = false, publicBinaryReleased = false,
    id = candidate.Id, version = candidate.Version, host = candidate.Host, compilerId = candidate.CompilerId,
    manifestSha256 = candidate.ManifestSha256, archiveSha256 = candidate.Sha256,
    archiveFiles = preview.Files, candidate.DownloadBytes, candidate.InstalledBytes,
    firmwareSha256 = Convert.ToHexString(SHA256.HashData(await File.ReadAllBytesAsync(firmware))).ToLowerInvariant(), checks
});

internal sealed record Candidate(int FormatVersion, string Id, string Version, string Host, string CompilerId,
    string ManifestSha256, string Asset, string Sha256, long DownloadBytes, long InstalledBytes,
    [property: System.Text.Json.Serialization.JsonPropertyName("candidate")] bool CandidatePackage,
    bool CatalogEligible, string PublicationStatus);
