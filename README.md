# MCU StudioX 开发组件

MCU StudioX 的独立开发组件仓库，覆盖 MCU、HDL 和 Windows PC 开发。完整安装包预装组件，轻量安装包按工程需要安装组件；两者使用相同的 `.mcutoolchain` 格式和身份。

## 当前状态

已登记现有 11 个组件的精确 ID、版本、平台、编译器和原始 `toolset.json` 指纹。**当前均为 `pending-materials`，尚无公开二进制 Release，下载目录为空。** 正在补齐对应源码、构建脚本、依赖材料和厂商再分发条款。本地打包或通过编译不自动代表满足公开发布条件。

- [组件登记](components/index.json)：待发布组件与不可改变的身份。
- [签名下载目录](catalog/catalog.json)：只收录已审阅、验证并公开发布的组件。
- [发布者公钥](trust/publisher.pem)与[指纹](trust/publisher.json)：RSA-PSS/SHA-256。
- [用户操作](docs/USAGE.md)、[维护与发布](docs/PUBLISHING.md)、[归档格式](docs/FORMAT.md)。

归档二进制只放 GitHub Releases，Git 不收录 SDK、工具二进制或私钥。IDE 产品版本不随组件发布改变；新组件版本并存，已有工程不会自动更换版本或内容锁。

仓库内自有脚本与文档采用 MIT 许可。第三方工具、库和 SDK 继续适用各自的许可证，本仓库的许可不授予其再分发权。
