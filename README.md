# MCU StudioX 开发环境组件

MCU StudioX 的独立开发环境组件仓库，覆盖 MCU、HDL 和 Windows PC 开发。完整安装包预装组件，轻量安装包按工程需要安装；两者使用相同的 `.mcutoolchain` 格式和组件身份。

新制作脚本默认使用 7z/LZMA2。支持此功能的 IDE 自带导入和导出能力，用户无需安装 7-Zip；既有 ZIP 组件继续可用。发布后的归档、身份、原始清单与摘要保持不变。

## 已公开发布

| 开发环境组件 | 包大小 | 内容 |
| --- | ---: | --- |
| [stc.sdcc/1.0.1](https://github.com/XieJunHui9566/MCU-StudioX-Toolchains/releases/tag/stc.sdcc-1.0.1-win-x64) | 55.0 MiB | SDCC 4.5、CMake/Ninja |
| [pc.mingw/1.0.0](https://github.com/XieJunHui9566/MCU-StudioX-Toolchains/releases/tag/pc.mingw-1.0.0-win-x64) | 48.9 MiB | GCC 13.1、Binutils 2.39、MinGW-w64 11 |
| [arm.gnu/1.0.2](https://github.com/XieJunHui9566/MCU-StudioX-Toolchains/releases/tag/arm.gnu-1.0.2-win-x64) | 135.8 MiB | Arm GNU 15.2.Rel1、OpenOCD、CMake/Ninja |
| [riscv.xpack/1.0.2](https://github.com/XieJunHui9566/MCU-StudioX-Toolchains/releases/tag/riscv.xpack-1.0.2-win-x64) | 220.7 MiB | xPack GCC 15.2、OpenOCD、CMake/Ninja |
| [hdl.iverilog/14.0.1](https://github.com/XieJunHui9566/MCU-StudioX-Toolchains/releases/tag/hdl.iverilog-14.0.1-win-x64) | 3.1 MiB | 固定源码提交构建的 Icarus Verilog 14.0 devel |
| [espressif.idf/5.5.4](https://github.com/XieJunHui9566/MCU-StudioX-Toolchains/releases/tag/espressif.idf-5.5.4-win-x64) | 607.8 MiB | 完整 SDK、隔离 Python、Git 和目标编译器 |
| [espressif.idf/5.5.5](https://github.com/XieJunHui9566/MCU-StudioX-Toolchains/releases/tag/espressif.idf-5.5.5-win-x64) | 651.0 MiB | 完整 SDK、隔离 Python、Git 和目标编译器 |
| [espressif.idf/6.0.3](https://github.com/XieJunHui9566/MCU-StudioX-Toolchains/releases/tag/espressif.idf-6.0.3-win-x64) | 727.5 MiB | 完整 SDK、隔离 Python、Git 和目标编译器 |
| [espressif.idf/6.1.0](https://github.com/XieJunHui9566/MCU-StudioX-Toolchains/releases/tag/espressif.idf-6.1.0-win-x64) | 730.7 MiB | 完整 SDK、隔离 Python、Git 和目标编译器 |

以上 9 个组件均已补齐实际对应源码、构建配方、补丁、依赖及许可证材料，同版本 Release 保存这些文件；签名下载目录只收录已发布且摘要核对通过的资产。

全部组件通过真实 IDE 服务的完整导入与重复导入验证。ARM / RISC-V 生成真实 ELF；PC 编译并运行 C/C++ 和 LTO 示例；HDL 编译并运行 Verilog 仿真；四个 ESP-IDF 版本分别完成三个架构的基础编译与 ESP32-S3 完整 SDK 构建。公开下载记录验证 HTTPS 下载、验签、SHA-256、缓存复用和完整导入。验证不代表硬件验收或所有器件验收。

## 仍保留本地的原组件

AGM 的三个组件暂缺专有工具再分发材料；WCH 定制 GCC / OpenOCD 缺匹配源码，按用户要求暂缓；ESP8266 RTOS 3.4 的导入和基础编译通过，但历史构建所用 Newlib 提交未能精确确认。

原 ARM 1.0.0、RISC-V 1.0.0、Icarus 14.0.0、SDCC 1.0.0 混有未核对来源的替换文件或旧构建，继续为 `pending-materials`。已分别提供新的 ARM 1.0.2、RISC-V 1.0.2、Icarus 14.0.1、SDCC 1.0.1；旧组件与工程内容锁保持原样，不自动迁移。每项具体缺口见组件登记中的 `publication.blockers`。

本地验证中使用的 1.0.1 迁移样本不是厂商升级版本，不列入公开目录。当前安装的完整版是否含新组件取决于其实际预装清单，独立组件发布不会自动修改 IDE 安装。

- [组件登记](components/index.json)：全部真实版本的身份与状态。
- [签名下载目录](catalog/catalog.json)：已发布组件。
- [发布者公钥](trust/publisher.pem)与[指纹](trust/publisher.json)：RSA-PSS/SHA-256。
- [用户操作](docs/USAGE.md)、[维护与发布](docs/PUBLISHING.md)、[归档格式](docs/FORMAT.md)。
- [再分发材料与 AGM 联系方式](docs/REDISTRIBUTION.md)。

二进制只放 GitHub Releases，Git 保存配方、来源、审阅与验证记录。IDE 产品版本不随组件发布改变；工程按明确版本和内容锁选择组件。

仓库自有脚本与文档采用 MIT 许可。第三方工具、库和 SDK 适用各自的许可证。
