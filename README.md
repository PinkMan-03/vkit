# VKit

**面向 [VLink](https://vlink.work) workspace 的跨平台构建与交付工具**

![](https://img.shields.io/badge/version-v1.0.0-informational.svg) ![](https://img.shields.io/badge/build-CMake-informational.svg) ![](https://img.shields.io/badge/license-MIT-informational.svg) ![](https://img.shields.io/badge/platform-Linux%20|%20QNX%20|%20Android%20|%20macOS%20|%20Windows-informational.svg)

[English](tools/doc/README.en.md) | 中文 · [官方网站](https://vlink.work) · [变更日志](tools/doc/CHANGELOG.md) · [许可证](tools/doc/LICENSE)

VKit 是 VLink workspace 的统一构建入口。它把多仓库源码、跨平台工具链、分层组件、部署目录和 SDK / Runtime 包装在一套命令里，让 VLink 及其依赖在 Linux / QNX / Android / macOS / Windows 上保持一致的构建与交付方式。

<p align="center"><img src="tools/doc/images/architecture.png" alt="VKit 架构总览" width="94%"></p>

---

## 1. 核心能力

| 能力 | 说明 |
| --- | --- |
| 多平台构建 | 通过 `VKIT_PLATFORM` 选择目标平台，VKit 负责派发 CMake toolchain 和安装前缀 |
| 多设备隔离 | 通过 `VKIT_DEVICE` 派生设备层，同一 workspace 可并行维护多套设备产物 |
| 分层组件编排 | 按 `thirdparty → vendor → middleware → app` 顺序构建，组件仍保持原生 CMake 工程 |
| 单组件迭代 | 进入组件目录后用 `mm` / `mmm` 快速构建，不需要手写 build 路径 |
| 交付打包 | `make` 默认产 runtime 包，`make deploy_sdk` 额外产 SDK 包 |

VKit 不替代 CMake，也不主打通用依赖管理。它关注的是 VLink 这类多仓库、多平台、多设备工程如何稳定构建和交付。

适合使用 VKit 的场景：

- 一个 workspace 下有多个仓库，且组件之间存在固定构建顺序。
- 同一套代码需要面向多个目标平台或多个设备配置交付。
- 既要支持本地单组件迭代，也要让 CI 使用同一套入口产出 runtime / SDK 包。

不必使用 VKit 的场景：

- 只需要管理第三方库版本，优先考虑 Conan / vcpkg。
- 单仓库、单平台的小项目，直接使用 CMake 会更轻量。

---

## 2. 快速开始

### 2.1 主机依赖

推荐 Ubuntu 22.04，最低 Ubuntu 20.04。

```bash
sudo apt-get -y install \
    git git-lfs \
    autoconf automake tclsh \
    build-essential ninja-build \
    ccache rsync \
    python3 openjdk-17-jdk \
    doxygen graphviz
sudo pip install vcs2l
```

`cmake / ripvcs / protoc / flatc / fastddsgen` 随仓库提供，会由 `vkit-setup.sh` 加入 `PATH`。

依赖分工：

| 类型 | 内容 | 说明 |
| --- | --- | --- |
| 系统工具 | `git`、`git-lfs`、`ninja`、`ccache`、`rsync` | 用于源码拉取、构建加速和部署同步 |
| 生成工具 | `openjdk-17-jdk`、`doxygen`、`graphviz` | 用于代码生成和文档生成 |
| 仓库自带 | `cmake`、`ripvcs`、`protoc`、`flatc`、`fastddsgen` | source 环境后自动使用 |

### 2.2 拉取源码

```bash
git clone <vkit-url> vkit && cd vkit

$EDITOR repos/full/*.repos

make import_full
```

源码集合：

| 集合 | 内容 | 适用场景 |
| --- | --- | --- |
| `full` | `vmsgs + vlink` | 从零构建 VLink |
| `dev` | `vmsgs` | 本地已经有 `middleware/vlink/` |

如果使用开发者集合：

```bash
make import_dev
```

### 2.3 选择目标平台

默认 `VKIT_PLATFORM=auto`。常见平台只需准备对应环境：

```bash
# Linux x86_64（本机）       无需额外设置
# Linux aarch64（交叉编译）  export CROSS_COMPILE_PREFIX=/opt/.../bin/aarch64-none-linux-gnu-
# QNX                        source ~/.qnx/qnxsdp-env.sh
# Android                    export ANDROID_NDK=/opt/android-ndk-r27
```

`auto` 只自动识别常用目标。需要 `qnx-x86_64`、`android-x86_64` 等目标时，显式设置：

```bash
export VKIT_PLATFORM=qnx-x86_64
```

### 2.4 构建

```bash
source vkit-setup.sh
make
```

`make` 会按配置顺序构建组件，并生成 runtime 包。需要 SDK 包时：

```bash
make deploy_sdk
```

---

## 3. 工作区模型

### 3.1 平台、设备与目录

`VKIT_PLATFORM` 表示目标平台，例如 `linux-aarch64`。`VKIT_DEVICE` 表示可选设备层，例如 `myecu`。

两者组合得到 `VKIT_DEVICE_PLATFORM`，并用于隔离产物：

```text
build/<DEVICE_PLATFORM>/
prebuilt/<DEVICE_PLATFORM>/
prebuilt-private/<DEVICE_PLATFORM>/
packup/<DEVICE_PLATFORM>/
```

同一份源码可以同时维护多个平台或设备，只要在不同 shell 中设置不同的 `VKIT_PLATFORM` / `VKIT_DEVICE`。

### 3.2 构建流水线

<p align="center"><img src="tools/doc/images/build-pipeline.png" alt="编译流水线" width="100%"></p>

| 层 | 命令 | 配置文件 |
| --- | --- | --- |
| thirdparty | `mm_thirdparty` | `thirdparty.cfg` |
| vendor | `mm_vendor` | `vendor.cfg` |
| middleware | `mm_middleware` | `middleware.cfg` |
| app | `mm_app` | `app.cfg` |

`.cfg` 用一行描述一个组件：

```cfg
middleware/my-component; -DBUILD_SHARED_LIBS=ON -DMY_FEATURE=ON
```

分号前是组件路径，分号后是传给 CMake 的参数。

### 3.3 产物类型

| 产物 | 说明 |
| --- | --- |
| `prebuilt/<DEVICE_PLATFORM>/` | 目标平台可部署文件 |
| `prebuilt-private/<DEVICE_PLATFORM>/` | 仅编译/链接使用的依赖，不进入 runtime 包 |
| `vkit-<DEVICE_PLATFORM>-runtime.tgz` | 部署到目标设备的运行时包 |
| `vkit-<DEVICE_PLATFORM>-sdk.tgz` | 用于离线开发或二次构建的 SDK 包 |

Runtime 包面向目标设备，保留运行所需的 `target/` 内容。SDK 包在 runtime 基础上保留 CMake 配置、host 工具和开发期依赖，适合离线集成或下游工程二次构建。

### 3.4 公私安装前缀

| 前缀 | 用途 | 是否进入 runtime |
| --- | --- | --- |
| `prebuilt/<DEVICE_PLATFORM>/` | 业务可执行文件、共享库、配置和资源 | 是 |
| `prebuilt-private/<DEVICE_PLATFORM>/` | 仅编译/链接使用的依赖，例如静态库、头文件或内部工具 | 否 |

组件如果只提供编译期依赖，应安装到 `prebuilt-private/`，避免把开发期内容带进运行时包。

---

## 4. 常用命令

### 4.1 单组件构建

```bash
source vkit-setup.sh
cd middleware/vlink

mmm                         # 使用 cfg 中的参数构建当前组件
mm '-DENABLE_VIEWER=ON'     # 直接传 CMake 参数
mm clean                    # 清理当前组件
```

切换配置参数后，建议先清理当前组件再重新构建。

| 命令 | 用途 |
| --- | --- |
| `mmm` | 使用当前组件在 `.cfg` 中的参数构建 |
| `mm` | 直接构建当前组件，可临时传入参数 |
| `llcfg` | 查看当前组件命中的 `.cfg` 参数 |
| `mmc` / `mmmc` | 在单组件构建时运行 clang-tidy |
| `rdb` | 使用目标平台对应的 GDB 包装器调试 |

### 4.2 批量构建

```bash
mm_thirdparty
mm_vendor
mm_middleware
mm_app
mm_all                      # 等价于 make install
```

### 4.3 Make 入口

| 命令 | 用途 |
| --- | --- |
| `make` | 构建并输出 runtime 包 |
| `make install` | 只构建 |
| `make deploy` | 只执行部署和 runtime 打包 |
| `make deploy_sdk` | 部署并额外输出 SDK 包 |
| `make import_full` | 拉取完整源码集合 |
| `make import_dev` | 拉取开发者源码集合 |
| `make pull` | 更新已存在仓库 |
| `make clean` | 清理当前平台构建目录 |
| `make dclean` | 清理当前平台构建与产物目录 |
| `make aclean` | 清理全部平台产物 |

切换平台或设备时通常不需要清理，VKit 会按 `VKIT_DEVICE_PLATFORM` 隔离目录。只有切换同一组件的配置参数、排查缓存问题或准备干净产物时，才需要主动清理。

---

## 5. 接入与定制

### 5.1 新增组件

在 `repos/<dev|full>/<层>.repos` 注册仓库：

```yaml
repositories:
  middleware/my-component:
    type: git
    url: <git-url>
    version: <branch-or-tag>
```

在 `config/<平台>/<层>.cfg` 加入构建项：

```cfg
middleware/my-component; -DBUILD_SHARED_LIBS=ON
```

组件需要提供 `CMakeLists.txt`、`cmake/CMakeLists.txt`、`build.sh` 或 `Makefile` 之一。

### 5.2 新增仅链接依赖

仅用于编译或链接、不需要进入 runtime 包的依赖，可以显式安装到私有前缀：

```cfg
thirdparty/my-headers; -DENABLE_INSTALL_PRIVATE=ON -DBUILD_SHARED_LIBS=OFF
```

这类依赖仍会被后续组件搜索到，但不会默认进入部署包，适合 header-only 库、静态库和构建期工具。

### 5.3 新增设备层

```bash
mkdir -p config/linux-aarch64-mydev
cp config/linux-aarch64/middleware.cfg config/linux-aarch64-mydev/
$EDITOR config/linux-aarch64-mydev/middleware.cfg

export VKIT_DEVICE=mydev
export CROSS_COMPILE_PREFIX=...
make
```

设备层只需要覆盖与平台默认配置不同的部分。

### 5.4 外置 toolchain

外置 toolchain 用于接入 OE / Yocto / 厂商 SDK。推荐位置：

```text
~/vkit-toolchains/<name>/<name>_setup.sh
```

示例：

```bash
export OE_CMAKE_TOOLCHAIN_FILE=/opt/myoe/cmake-toolchain.cmake
export SYSROOT=/opt/myoe/sysroot
export CC=$SYSROOT/usr/bin/aarch64-poky-linux-gcc
export CXX=$SYSROOT/usr/bin/aarch64-poky-linux-g++
export VKIT_PLATFORM=linux-aarch64
```

使用：

```bash
source vkit-setup.sh <name>
make
```

### 5.5 新增平台或架构

当目标不属于现有平台矩阵时，按以下顺序接入：

1. 在 `cmake/toolchain.cmake` 中增加新的 `VKIT_PLATFORM` 分发分支。
2. 在 `cmake/<os>/` 下增加对应 toolchain 文件。
3. 从相近平台复制一份 `config/<platform>/`，保留需要构建的层和组件。
4. 设置 `VKIT_PLATFORM=<new-platform>` 后执行 `make` 验证。

新增平台时优先复用现有组件的 CMake 工程，不要为平台差异改动组件目录结构。

---

## 6. 参考

### 6.1 平台矩阵

| Target | 编译器 | 必需环境变量 |
| --- | --- | --- |
| `linux-x86_64` | 系统 `gcc/g++` 或 `CC` / `CXX` | - |
| `linux-aarch64` | `${CROSS_COMPILE_PREFIX}gcc/g++` 或 `CC` / `CXX` | `CROSS_COMPILE_PREFIX` 或 `CC`+`CXX` |
| `qnx-aarch64` / `qnx-x86_64` | `qcc` / `q++` | `QNX_HOST` + `QNX_TARGET` |
| `android-aarch64` / `android-x86_64` | NDK clang | `ANDROID_NDK` |
| `darwin-arm64` / `darwin-x86_64` | AppleClang | - |
| `win32-x86_64` | MSVC | - |

### 6.2 常用环境变量

| 变量 | 说明 |
| --- | --- |
| `VKIT_PLATFORM` | 目标平台 |
| `VKIT_DEVICE` | 设备层 |
| `VKIT_DEVICE_PLATFORM` | 平台与设备组合后的产物目录名 |
| `VKIT_DEBUG` | 使用 Debug 构建 |
| `VKIT_STRIP` | install 时 strip |
| `VKIT_DISABLE_CCACHE` | 关闭 ccache |
| `VKIT_PACKUP_RUNTIME` / `VKIT_PACKUP_SDK` | 控制 runtime / SDK 打包 |
| `CROSS_COMPILE_PREFIX` | linux-aarch64 编译器前缀 |
| `QNX_HOST` / `QNX_TARGET` | QNX SDP 路径 |
| `ANDROID_NDK` | Android NDK 路径 |
| `OE_CMAKE_TOOLCHAIN_FILE` | 外置 CMake toolchain |

---

## 7. 排查

| 现象 | 建议 |
| --- | --- |
| 改了组件参数但没有生效 | 先在组件目录执行 `mm clean`，再用 `mmm` 重新配置 |
| 找不到平台配置 | 检查 `VKIT_PLATFORM` 是否存在对应的 `config/<platform>/` |
| QNX 或 Android 工具链未识别 | 检查 `QNX_HOST` / `QNX_TARGET` 或 `ANDROID_NDK` 是否在当前 shell 中生效 |
| 想确认当前组件会使用哪些参数 | 进入组件目录执行 `llcfg` |
| 想看完整构建命令 | 清理后临时传入 `-DCMAKE_VERBOSE_MAKEFILE=ON` |
| 怀疑环境未初始化 | 重新执行 `source vkit-setup.sh`，再检查 `VKIT_PLATFORM` 和 `VKIT_DEVICE_PLATFORM` |

---

## 许可证

本项目采用 [MIT License](tools/doc/LICENSE) 开源。
