# PC MinGW 1.0.0

Compiler: MinGW-Builds GCC 13.1.0, win32 threads, SEH, MSVCRT, MinGW-w64 v11.

`Assemble-Toolset.ps1` accepts the exact official archive identified by `inputs.json`, extracts into a new scratch directory and copies only original manifest entries. Every copied file must match its pinned SHA-256. The original manifest bytes and component identity remain unchanged. It does not download files, change PATH, install a global runtime or connect hardware.

All 3,661 selected upstream files were compared against the official release archive. Matching compiler, binutils, MinGW-w64, static host-library sources and original build scripts/patches are delivered as Release assets. The compiler and host-library patches named in the retained upstream build-info are present in the pinned 2023-05-24 build snapshot. The supplement also retains that build-info, this assembly recipe and notices.

Validation covers full IDE archive import, duplicate import, real C/C++ compilation with LTO and execution of the resulting Windows programs using only component runtime libraries and Windows system directories. It does not claim bit-identical upstream compiler recompilation.
