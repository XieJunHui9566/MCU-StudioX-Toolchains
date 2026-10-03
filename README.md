# MCU StudioX 开发组件

MCU StudioX 的独立开发组件仓库，覆盖 MCU、HDL 和 Windows PC 开发。完整安装包预装组件，轻量安装包按工程需要安装组件；两者使用相同的 `.mcutoolchain` 格式和身份。

新制作脚本默认使用 7z/LZMA2。支持此功能的 IDE 自带导入和导出能力，用户无需安装 7-Zip；既有 ZIP 组件继续可用。已发布的 ZIP 资产与签名目录保持原样，后续 7z 发布须绑定新的归档摘要和实际导入验收。

## 当前状态

首个公开组件 [stc.sdcc/1.0.1（Windows x64）](https://github.com/XieJunHui9566/MCU-StudioX-Toolchains/releases/tag/stc.sdcc-1.0.1-win-x64) 已发布，归档约 55 MiB，包含 SDCC 4.5.0、CMake 4.4.0 命令行和官方 Ninja 1.10.2。匹配源码、打包配方、通知与验证材料在同一 Release，上传后的大小和摘要已核对，签名目录收录此版本。

[公开下载验收](validation/sdcc-1.0.1-public-download.json) 已通过：真实 IDE 服务从 HTTPS 目录验签，下载 Release、校验归档、复用缓存、完整导入并保留重复导入的组件。[离线构建验收](validation/sdcc-1.0.1-local-candidate.json) 覆盖标准头文件、运行库及 CMake/Ninja 构建；不包含硬件验收。

原有 11 个组件的身份和原始清单保持不变，继续为 `pending-materials`。旧 SDCC 目录混入本机厂商头文件、备份及独立运行库，新组件从官方发行归档重新组装；旧工程不会自动更换版本。

ESP-IDF 5.5.5、6.0.3、6.1.0 已登记为本地候选组件，版本并存，仍为 `pending-materials`。[7z 本地验收记录](validation/7z-local-candidates-20261003.json) 包含 11 份归档、6 次完整导入和 ARM / ESP-IDF 实际编译。其余 5 份仅完成清单预览与原生归档完整性检查；这些结果不代表公开发布或硬件验收。记录中的 1.0.1 迁移样本不代表厂商工具升级。

开源组件通常按原许可证整理对应源码、构建材料及通知，无需逐一申请额外授权；AGM 专有工具的再分发条款须另行确认。材料齐备前只提供配方和验证记录，不将本地候选归档列入签名下载目录。

- [组件登记](components/index.json)：待发布组件与不可改变的身份。
- [签名下载目录](catalog/catalog.json)：只收录已审阅、验证并公开发布的组件。
- [发布者公钥](trust/publisher.pem)与[指纹](trust/publisher.json)：RSA-PSS/SHA-256。
- [用户操作](docs/USAGE.md)、[维护与发布](docs/PUBLISHING.md)、[归档格式](docs/FORMAT.md)。
- [再分发材料与 AGM 联系方式](docs/REDISTRIBUTION.md)：区分开源许可证义务和需要厂商确认的专有部分。

归档二进制只放 GitHub Releases，Git 不收录 SDK、工具二进制或私钥。IDE 产品版本不随组件发布改变；新组件版本并存，已有工程不会自动更换版本或内容锁。

仓库内自有脚本与文档采用 MIT 许可。第三方工具、库和 SDK 继续适用各自的许可证，本仓库的许可不授予其再分发权。
