# 格式与身份

组件身份来自原始 `toolset.json` 的 `id/version/host/compilerId`，版本是明确的三段数字，当前平台为 `win-x64`。组件组合版本与 GCC、SDK、Python 等内部版本分别记录，文件名不决定身份。

`.mcutoolchain` 格式 1 默认使用真实 7z/LZMA2，既有 ZIP 包继续被新版 IDE 按签名识别。根目录保存原始 `toolset.json`，其 `sha256` 索引所有其余文件。只有文件条目，不接受目录条目、重复名称、链接或越界路径。原始清单逐字节复制；不能为补充来源资料而改写已发布清单。对应源码和审阅材料可作为同一 Release 的独立资产交付。

发布制作使用 7-Zip，清单独立压缩，负载为 64 MiB 固实块、32 MiB 字典；IDE 内置托管读写器，完整和轻量版均无需用户另装 7-Zip。导入最多 200,000 个普通文件、展开总量 40 GiB、清单 32 MiB；解码前限制压缩/展开头及字典各不超过 64 MiB，拒绝加密、分卷和超限资源。更换容器不能改组件身份、原清单指纹或工程内容锁。

已发布 ZIP 资产及其目录签名保持原样；不得覆盖同版本 Release。未来公开 7z 包前须先交付支持该容器的 IDE，并绑定实际归档大小、SHA-256 及完整导入验收，不能只因为产品版本号相同就假定旧安装版支持 7z。

`components/<id>/<version>/component.json` 登记精确身份、清单 SHA-256、来源、验证范围、许可及发布状态。`pending-materials` 只允许生成本地候选；`ready` 需要保存审阅记录摘要、匹配的源码资产摘要和真实离线构建/导入验证材料。

目录是 MCU StudioX 已有格式 1，条目 `kind=tool`，保存精确 ID/版本、下载及展开大小、许可、来源、更新说明、归档 SHA-256 和固定版本 Release URL。目录不接受 `latest` 下载链接。组件主机和编译器仍在预览归档时核对。

目录签名是原始 UTF-8 字节的 RSA-PSS/SHA-256，公钥是 SubjectPublicKeyInfo PEM。签名文件采用 Base64。已签名目录保持字节不变，Git 属性禁止对它转换换行符。

每个 Release 资产必须小于 2 GiB，见 [GitHub Releases 限制](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)。超出时拒绝发布，不能直接切开归档假装格式 1 支持分卷。后续需单独设计分卷传输或经验证的托管方式，已有组件身份不改变。
