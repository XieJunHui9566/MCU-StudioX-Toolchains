# 实际应用服务验证

`StudioX.ComponentPublicationValidation` 调用 MCU StudioX 的真实目录、组件预览、安装和完整校验服务，不实现第二套导入器。需要含开发组件接口的匹配 IDE 源码及本机已有 .NET 10；不自动下载源码或 SDK。

```powershell
dotnet run --project validation/StudioX.ComponentPublicationValidation -c Release -p:StudioXSourceDirectory=<IDE源码目录> -- <本仓库目录> <本地candidate.json> <新验证目录>
```

当前实编验证针对明确选择的 SDCC：导入归档到隔离目录、核对清单指纹和所有文件、验证重复导入，再编译并链接使用 `stdint.h` 和整数除法运行库的 C51 程序，并用同组件的 CMake/Ninja 构建、比较固件字节。验证不连接、复位或烧录硬件，候选包依然不能直接发布。

`--verify-online-catalog <HTTPS目录地址> <可信公钥文件> <新验证目录> [预期条目数]` 使用同一应用服务检查实际 HTTPS 目录和签名；省略条目数时预期为空。它不下载工具。

`--verify-public-component <HTTPS目录地址> <可信公钥文件> <组件ID> <精确版本> <新验证目录>` 从已验签目录实际下载指定 Release，校验摘要、缓存复用、归档身份与大小、完整导入和重复导入。只使用隔离数据与工具目录，不更换用户现有组件或工程锁。

公开验证 JSON 只保存身份、摘要、大小、测试范围及检查项，不包含本机路径、工具二进制或硬件记录。验证报告与许可审阅记录分开保存；只有公开 Release 登记和签名目录才表示可下载状态。
