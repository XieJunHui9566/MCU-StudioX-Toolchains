# studiox.cmake-4.4.0-win-x64

独立 CMake 4.4.0 / Ninja 1.10.2 工程构建组件。清单与已安装的 4.4.0 相同；原始 GUI 中 Qt 6.10.1 的对应 QtBase 源码和许可证随本 Release 提供。

使用随包原始 toolset.json 和包内各文件不变地重新归档：

```powershell
./New-McuToolchain.ps1 -ToolsetDirectory <component-directory> -OutputFile studiox.cmake-4.4.0-win-x64.mcutoolchain
```

组件重打包不声称上游二进制可以逐字节源码重建。MX251 源码包含 build/工具脚本；CMake、Ninja、Qt 源码归档内含各自构建流程，Qt 可修改后重编，再以 Qt 路径配置 CMake GUI。随组件版权声明保留。
