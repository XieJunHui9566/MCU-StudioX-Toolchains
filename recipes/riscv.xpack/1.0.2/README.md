# riscv.xpack / 1.0.2

从 inputs.json 的官方地址取得精确归档，核对 SHA-256 后使用配方组装。编译器版本保持原样；组件版本独立于 IDE 产品版本，已有工程不会自动迁移。

```powershell
./Assemble-Toolset.ps1 -RecipeDirectory . -InputsDirectory <官方输入目录> -SevenZipExecutable <7z.exe> -ScratchDirectory <新临时目录> -OutputDirectory <新输出目录>
```

匹配的编译器、运行库和构建工具源码及上游构建补丁在同版本 Release。配方复现组件组装，不宣称逐字节复现上游源码编译结果。原始许可证随组件和源码保留。CMake GUI 使用静态 Qt，Release 提供匹配 QtBase 源码（含其第三方源码和许可证）与 CMake 官方构建配方；此程序与 IDE 为独立进程。离线导入和编译验证不代表硬件验收。
