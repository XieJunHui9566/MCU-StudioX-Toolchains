# SDCC 1.0.1 组件配方

从 `upstream-files.json` 指向的官方发行归档准备本地输入，校验摘要后，用 `Prepare-Toolset.ps1` 在新目录组装组件。维护机需要已有 PowerShell 7 和 7-Zip；用户只需在 IDE 导入 `.mcutoolchain`。

脚本不执行 SDCC 安装程序、不下载安装 SDK，也不修改系统 PATH。它按白名单提取官方 SDCC 的 MCS-51 编译工具、标准头文件和库，保留 CMake 命令行和原始依赖通知，使用官方 Ninja。输入归档、程序和附加许可证均核对精确 SHA-256。额外许可证文本可从同版本 Release 的 `stc.sdcc-1.0.1-build-and-notices.zip` 提取。

```powershell
./Prepare-Toolset.ps1 -SdccInstaller <官方SDCC安装程序> -CMakeArchive <官方Windows-x86_64.zip> -NinjaArchive <官方ninja-win.zip> -NoticesDirectory <源码补充资产中的notices目录> -SevenZipExecutable <已有7z.exe> -ScratchDirectory <新解压目录> -OutputDirectory <新工具集目录>
```

归档与许可证审阅见 [组件登记](../../../components/stc.sdcc/1.0.1/component.json) 和 [审阅记录](../../../reviews/stc.sdcc-1.0.1-win-x64.json)。这里的配方复现组件组装，不宣称重新编译上游源码会得到逐字节相同的上游程序。该版本只验收 MCS-51 构建，不含下载、调试或实板验收。

旧 `stc.sdcc/1.0.0` 包含本机额外厂商头文件、备份和尚未完成材料核对的运行库，因此继续保留为未发布组件。其清单和旧工程版本锁不变。`1.0.1` 是独立组件版本，编译器仍是 `sdcc-4.5.0-15242`；现有器件包不会自动改用该版本，必须由新器件包明确声明或用户显式切换工程组件。
