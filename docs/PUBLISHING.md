# 维护与发布

维护机使用 PowerShell 7 / Windows；用户导入组件不需要这些发布工具。所有脚本使用显式本地输入，不自动获取 SDK 或操作硬件。

1. 检查 Git 状态和组件登记。保留精确 ID、版本、编译器和原清单指纹；内容变化必须形成新组件版本。
2. 使用 `tools/Build-ComponentCandidate.ps1 -Specification <component.json> -ToolsetDirectory <已验证目录> -OutputDirectory <新目录> [-SevenZipPath <7z.exe>]` 核对全部文件摘要，生成 7z/LZMA2 的 `.mcutoolchain` 和 `candidate.json`，保存原生完整性检查日志。仅发布维护机需要 7-Zip。输出始终是本地候选，不能直接加入公开目录。
3. 用 IDE 的应用服务验证真实归档导入、完整内容校验、重复导入及对应构建流程。保存 `offline-build-and-import` 验证材料，绑定清单指纹、归档摘要及准确的验证范围。模拟工具不能替代真实构建；离线验收不代表硬件验收。
4. 补齐版本对应的源码、构建脚本、修改与依赖材料，并核实厂商许可。提交审阅记录及摘要，登记源码资产名称、大小、SHA-256，确认后才把组件状态改为 `ready` 并填写许可。GCC 的运行库例外不等于可以不交付编译器的对应源码，见 [GCC 分发条款第 6 节](https://gcc.gnu.org/onlinedocs/gcc/Copying.html)。
5. `Prepare-ComponentRelease.ps1` 读取规格、候选目录、验证文件和本地源码材料，核对实际字节后生成可审阅的 Release 目录、更新说明与逐文件摘要。它不发布。保持 `published=false`，不上传未准备好的目录。
6. 用户明确授权发布后，在已审阅的干净提交上创建对应标签 `id-version-host` 和 Release，上传归档、匹配源码、验证及许可审阅材料。不得覆盖旧标签和旧资产。保留 GitHub 上传后的资产摘要；核对后再登记 `releases/index.json` 中的 `published` 记录。
7. `New-PublishedCatalog.ps1 -EncryptedKeyFile <仓库外DPAPI密钥> -OutputDirectory <新目录>` 只收录公开 Release；它核对 GitHub API 的实际资产名称、大小和 SHA-256，核对源码交付及审阅记录，再生成签名目录。检查后更新仓库 `catalog/`。初始空目录必须显式传入 `-AllowEmptyBootstrap`。
8. `Test-Repository.ps1 -OutputDirectory <仓库外新目录>` 验证身份、目录签名、发布条件、大小限制和仓库材料边界。目录、公钥及签名一起保存，但公钥信任仍需独立建立。

`New-PublisherKey.ps1` 生成 RSA 3072 位密钥：私钥用当前 Windows 用户 DPAPI 加密保存在仓库外，公钥可提交。不要更换已信任的密钥；换电脑时需要通过受控备份恢复或设计密钥轮换，DPAPI 文件不能直接跨用户/机器使用。脚本不会输出私钥内容。

当前 18 个真实组件登记中，9 个已补齐材料并公开发布，9 个原组件仍为 `pending-materials`。每个可发布版本的对应源码、依赖、构建配方、补丁与许可证审阅记录均有实际文件摘要。`license=NOASSERTION` 表示尚未完成聚合许可审阅，不代表组件没有许可证；SDK Apache/MIT 声明不能覆盖附带编译器、Python 依赖或厂商程序。原目录中的替换文件和旧构建通过新增明确版本处理，不改写旧清单或已有工程锁。
