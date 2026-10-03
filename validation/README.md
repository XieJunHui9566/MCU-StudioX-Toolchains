# 实际应用服务验证

`StudioX.ComponentPublicationValidation` 调用 MCU StudioX 的真实目录、组件预览、安装和完整校验服务，不实现第二套导入器。需要含开发组件接口的匹配 IDE 源码及本机已有 .NET 10；不自动下载源码或 SDK。

```powershell
dotnet run --project validation/StudioX.ComponentPublicationValidation -c Release -p:StudioXSourceDirectory=<IDE源码目录> -- <本仓库目录> <本地candidate.json> <新验证目录>
```

当前实编验证针对明确选择的 SDCC：导入归档到隔离目录、核对清单指纹和所有文件、验证重复导入，再编译并链接使用 `stdint.h` 和整数除法运行库的 C51 程序。验证不连接、复位或烧录硬件，候选包依然不能直接发布。

`--verify-online-catalog <HTTPS目录地址> <可信公钥文件> <新验证目录>` 使用同一应用服务检查实际 HTTPS 目录和签名，当前预期是零个可下载组件的初始目录。它不下载工具。

公开的 `sdcc-local-candidate.json` 只保存身份、摘要、大小、测试范围及检查项，不包含本机路径、工具二进制或硬件记录。对应的候选归档保留在维护机，本报告不是公开下载资产或许可审阅记录。
