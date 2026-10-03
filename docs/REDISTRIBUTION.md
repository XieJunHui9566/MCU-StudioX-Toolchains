# 开发组件的再分发材料

组件包含多个工具、库和 SDK，按具体版本随附许可证分别核对。开源许可证通常已授予按条件再分发的权利，不应把整理源码材料变成逐一向维护者申请额外授权。

GNU GPL 工具即使二进制未修改，仍须按适用条款提供对应源码及编译、安装脚本等材料；仅填写上游源码链接不足以证明已经交付。参见 [GNU GPL FAQ](https://www.gnu.org/licenses/gpl-faq.en.html#UnchangedJustBinary)。ESP-IDF 多数组件采用 Apache 2.0，附带依赖及独立工具继续按各自许可证处理，参见[乐鑫说明](https://www.espressif.com/en/products/sdks/esp-idf)。这些说明不是某一完整组件包的审阅结论。

本仓库先保存本地清单、来源和验证记录，再收集与二进制对应的源码归档、补丁、构建脚本及依赖材料，记录摘要。材料与审阅完成后才将 `pending-materials` 改为可发布状态并公开二进制。现有 9 个正式 Release 已提供对应材料，包括 ARM、通用 RISC-V、PC MinGW、SDCC、Icarus Verilog 和四个 ESP-IDF 版本；其余原组件按登记中的具体缺口处理。

## AGM / Supra 联系方式

现有记录尚未证明专有部分允许再次打包公开分发。AG32 [官方网站](https://www.ag32mcu.com/)公布的联系邮箱是 `sales@ag32mcu.com`，可请其转交软件许可负责人，明确询问：

> 我们开发 MCU StudioX IDE，希望将指定版本的 AGM / Supra 工具、运行依赖和必要脚本打包为独立 `.mcutoolchain` 文件，通过公开 GitHub Releases 免费分发，用户可由 IDE 下载或手动导入。请确认允许分发的具体版本和文件范围，是否允许重打包，须保留的许可通知及其它条件；若需单独许可，请提供书面条款。

补充实际文件清单、版本和摘要后再取得审阅记录。账户、激活文件和用户的私有 Supra 许可证不进入组件包；未经确认的专有部分不公开发布。本仓库不自动发送授权询问。
