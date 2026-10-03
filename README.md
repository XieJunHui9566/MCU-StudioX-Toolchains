# MCU StudioX 开发组件

MCU StudioX 的独立开发组件仓库，覆盖 MCU、HDL 和 Windows PC 开发。完整安装包预装组件，轻量安装包按工程需要安装组件；两者使用相同的 `.mcutoolchain` 格式和身份。

## 当前状态

首个公开组件 [stc.sdcc/1.0.1（Windows x64）](https://github.com/XieJunHui9566/MCU-StudioX-Toolchains/releases/tag/stc.sdcc-1.0.1-win-x64) 已发布，归档约 55 MiB，包含 SDCC 4.5.0、CMake 4.4.0 命令行和官方 Ninja 1.10.2。匹配源码、打包配方、通知与验证材料在同一 Release，上传后的大小和摘要已核对，签名目录收录此版本。

[公开下载验收](validation/sdcc-1.0.1-public-download.json) 已通过：真实 IDE 服务从 HTTPS 目录验签，下载 Release、校验归档、复用缓存、完整导入并保留重复导入的组件。[离线构建验收](validation/sdcc-1.0.1-local-candidate.json) 覆盖标准头文件、运行库及 CMake/Ninja 构建；不包含硬件验收。

原有 11 个组件的身份和原始清单保持不变，继续为 `pending-materials`。旧 SDCC 目录混入本机厂商头文件、备份及独立运行库，新组件从官方发行归档重新组装；旧工程不会自动更换版本。

- [组件登记](components/index.json)：待发布组件与不可改变的身份。
- [签名下载目录](catalog/catalog.json)：只收录已审阅、验证并公开发布的组件。
- [发布者公钥](trust/publisher.pem)与[指纹](trust/publisher.json)：RSA-PSS/SHA-256。
- [用户操作](docs/USAGE.md)、[维护与发布](docs/PUBLISHING.md)、[归档格式](docs/FORMAT.md)。

归档二进制只放 GitHub Releases，Git 不收录 SDK、工具二进制或私钥。IDE 产品版本不随组件发布改变；新组件版本并存，已有工程不会自动更换版本或内容锁。

仓库内自有脚本与文档采用 MIT 许可。第三方工具、库和 SDK 继续适用各自的许可证，本仓库的许可不授予其再分发权。
