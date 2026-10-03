# MCU StudioX 开发组件

MCU StudioX 的独立开发组件仓库，覆盖 MCU、HDL 和 Windows PC 开发。完整安装包预装组件，轻量安装包按工程需要安装组件；两者使用相同的 `.mcutoolchain` 格式和身份。

## 当前状态

已登记原有 11 个组件的精确身份和清单指纹，它们仍为 `pending-materials`。新增 `stc.sdcc/1.0.1` 从官方发行归档组装，已补齐源码和通知，并通过完整导入及 C51/CMake/Ninja 构建验证，准备独立发布。目录只在核对真实公开 Release 之后收录该版本。

- [组件登记](components/index.json)：待发布组件与不可改变的身份。
- [签名下载目录](catalog/catalog.json)：只收录已审阅、验证并公开发布的组件。
- [发布者公钥](trust/publisher.pem)与[指纹](trust/publisher.json)：RSA-PSS/SHA-256。
- [用户操作](docs/USAGE.md)、[维护与发布](docs/PUBLISHING.md)、[归档格式](docs/FORMAT.md)。

归档二进制只放 GitHub Releases，Git 不收录 SDK、工具二进制或私钥。IDE 产品版本不随组件发布改变；新组件版本并存，已有工程不会自动更换版本或内容锁。

仓库内自有脚本与文档采用 MIT 许可。第三方工具、库和 SDK 继续适用各自的许可证，本仓库的许可不授予其再分发权。
