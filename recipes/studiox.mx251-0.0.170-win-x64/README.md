# studiox.mx251-0.0.170-win-x64

MX251 0.0170（测试）：合并通用编译器优化和原生整数/浮点运行库，提供 AI8051U-32bit、STC32G Target Profile，保留独立 CMake/Ninja 入口。体积达线与实板性能仍逐项区分。

使用随包原始 toolset.json 和包内各文件不变地重新归档：

```powershell
./New-McuToolchain.ps1 -ToolsetDirectory <component-directory> -OutputFile studiox.mx251-0.0.170-win-x64.mcutoolchain
```

组件重打包不声称上游二进制可以逐字节源码重建。MX251 源码包含 build/工具脚本；CMake、Ninja、Qt 源码归档内含各自构建流程，Qt 可修改后重编，再以 Qt 路径配置 CMake GUI。随组件版权声明保留。
