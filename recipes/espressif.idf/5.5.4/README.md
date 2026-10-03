# ESP-IDF 开发环境组件

本配方保留原始 toolset.json、组件身份与工程内容锁。对应源码、厂商构建脚本、补丁及依赖在同版本 Release；源码归档包含 SDK 的实际源码、子模块内容、许可证及厂商允许分发的库，去除 Git 历史不会丢失当前源码。

编译器来自固定 Espressif 14.2/15.2 分支标签。实际编译器报告的 GMP 6.3.0、MPFR 4.2.1、MPC 1.3.1、ISL 0.26 有匹配源码；Windows libgcc DLL 与 Debian Stretch 原始发行逐字节匹配，提供该版本源码包和构建补丁。Git 2.55.0.windows.5 的 169 个已安装软件包逐一对应到实际源码归档、PKGBUILD 和补丁；Python 包、CPython Windows 依赖、CMake/Qt 构建脚本一并提供。

使用 New-ToolsetArchive.ps1 对完整组件目录重新打包时，每个文件必须与清单摘要相符。此步骤复现包装流程，不宣称从源码逐字节重建所有厂商二进制。别名与 Python 运行时布局已经保存在组件目录中，禁止改写清单或把开发者绝对路径写入工程。

通过完整 IDE 导入、重复导入、三个架构的基础 ELF 编译和 ESP32-S3 完整 SDK 构建。后续版本包含的 GDB/OpenOCD 仅作离线启动检查；不代表硬件调试或所有器件验收。既有工程不会自动迁移。
