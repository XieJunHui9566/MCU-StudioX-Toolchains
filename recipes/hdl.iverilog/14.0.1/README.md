# Icarus Verilog 14.0.1

从固定上游提交 `2f296d88ae0d9af54fdf59d8bc0d91d7679edce3` 构建 Icarus Verilog 14.0 devel。组件版本 14.0.1 是独立的包装版本，不修改 IDE 版本，也不自动替换工程已锁定的 14.0.0。

在独立 MSYS2 构建目录中准备 make、autoconf、bison、flex 和 gperf，指定已验证的 pc.mingw/1.0.0 GCC 13.1.0，再按 Build-Hdl.sh 的四个路径参数进行构建。构建不修改系统 PATH；readline 未启用。GNU C++ 和 GCC 运行库静态链接，zlib 和 MinGW-w64 的匹配源码、构建补丁随本版本 Release 提供。

源归档、编译器输入摘要及许可证均在 inputs.json 和同版本 Release。原始 toolset.json 保留精确文件摘要；源构建可能因构建器、时间戳等差异产生不同二进制，不宣称逐字节重建。

已通过 IDE 完整导入、重复导入、Verilog 编译及真实仿真。验证是软件仿真，不代表 FPGA 硬件验收。
