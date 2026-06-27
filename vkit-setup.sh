#!/usr/bin/env bash

[ -n "$BASH_VERSION" ] && shopt -s extglob
[ -n "$ZSH_VERSION" ] && setopt extendedglob

if [ -z "$VKIT_ROOT_DIR" ]; then
    export VKIT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)"
fi
export VKIT_HOST_OS="$(uname -o 2>/dev/null | tr '[:upper:]' '[:lower:]')"
export VKIT_HOST_TYPE="$(uname -s | tr '[:upper:]' '[:lower:]')"
export VKIT_HOST_ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')"

if [ "$VKIT_HOST_OS" = "cygwin" ] || [ "$VKIT_HOST_OS" = "msys" ] || [ "$VKIT_HOST_OS" = "mingw" ]; then
    export VKIT_HOST_PLATFORM="$VKIT_HOST_OS-$VKIT_HOST_ARCH"
else
    export VKIT_HOST_PLATFORM="$VKIT_HOST_TYPE-$VKIT_HOST_ARCH"
fi

if [ "$0" != "$BASH_SOURCE" ] && [ -n "$1" ]; then
    if [ -f "$VKIT_ROOT_DIR/toolchains/$1/$1_setup.sh" ]; then
        . "$VKIT_ROOT_DIR/toolchains/$1/$1_setup.sh"
    elif [ -f "$VKIT_ROOT_DIR/vkit-toolchains/$1/$1_setup.sh" ]; then
        . "$VKIT_ROOT_DIR/vkit-toolchains/$1/$1_setup.sh"
    elif [ -f ~/vkit-toolchains/"$1/$1_setup.sh" ]; then
        . ~/vkit-toolchains/"$1/$1_setup.sh"
    elif [ -f "/opt/vkit-toolchains/$1/$1_setup.sh" ]; then
        . "/opt/vkit-toolchains/$1/$1_setup.sh"
    elif [ -f "/opt/$1/$1_setup.sh" ]; then
        . "/opt/$1/$1_setup.sh"
    else
        echo -e "\033[1m\033[31mError: Can not find $1_setup.sh!\033[0m"
        return 1
    fi
fi

if [ -z "$VKIT_PLATFORM" ] || [ "$VKIT_PLATFORM" = "auto" ]; then
    if [ -n "$QNX_TARGET" ] && [ -n "$QNX_HOST" ]; then
        export VKIT_PLATFORM="qnx-aarch64"
    elif [ -n "$ANDROID_NDK" ]; then
        export VKIT_PLATFORM="android-aarch64"
    elif [ -n "$CROSS_COMPILE_PREFIX" ]; then
        export VKIT_PLATFORM="linux-aarch64"
    else
        export VKIT_PLATFORM="$VKIT_HOST_PLATFORM"
    fi
fi

if [ -z "$VKIT_DEVICE" ]; then
    export VKIT_DEVICE_PLATFORM="$VKIT_PLATFORM"
else
    export VKIT_DEVICE_PLATFORM="$VKIT_PLATFORM-$VKIT_DEVICE"
fi

if [ -d "$VKIT_ROOT_DIR/config/$VKIT_DEVICE_PLATFORM" ]; then
    export VKIT_PLATFORM_CONFIG_DIR="$VKIT_ROOT_DIR/config/$VKIT_DEVICE_PLATFORM"
elif [ -d "$VKIT_ROOT_DIR/config/$VKIT_PLATFORM" ]; then
    export VKIT_PLATFORM_CONFIG_DIR="$VKIT_ROOT_DIR/config/$VKIT_PLATFORM"
else
    export VKIT_PLATFORM_CONFIG_DIR=
fi

if [ -d "$VKIT_ROOT_DIR/deploy/$VKIT_DEVICE_PLATFORM" ]; then
    export VKIT_PLATFORM_DEPLOY_DIR="$VKIT_ROOT_DIR/deploy/$VKIT_DEVICE_PLATFORM"
elif [ -d "$VKIT_ROOT_DIR/deploy/$VKIT_PLATFORM" ]; then
    export VKIT_PLATFORM_DEPLOY_DIR="$VKIT_ROOT_DIR/deploy/$VKIT_PLATFORM"
else
    export VKIT_PLATFORM_DEPLOY_DIR=
fi

if [ -z "$VKIT_PLATFORM_CONFIG_DIR" ]; then
    echo -e "\033[1m\033[31mError: Can not find platform config!\033[0m"
    [ "$0" != "$BASH_SOURCE" ] && return 1
    exit 1
fi

export VKIT_HOST_TOOL_DIR="$VKIT_ROOT_DIR/tools/$VKIT_HOST_PLATFORM"
export VKIT_BUILD_DIR="$VKIT_ROOT_DIR/build/$VKIT_DEVICE_PLATFORM"
export VKIT_PREBUILT_DIR="$VKIT_ROOT_DIR/prebuilt/$VKIT_DEVICE_PLATFORM"
export VKIT_PREBUILT_PRIVATE_DIR="$VKIT_ROOT_DIR/prebuilt-private/$VKIT_DEVICE_PLATFORM"
export VKIT_PACKUP_DIR="$VKIT_ROOT_DIR/packup/$VKIT_DEVICE_PLATFORM"
export VKIT_SETUP_DIR="$VKIT_ROOT_DIR/setup/$VKIT_DEVICE_PLATFORM"
export VKIT_ETC_DIR="$VKIT_PREBUILT_DIR/etc"
export VKIT_CODE_COMPLETE_DIR="$VKIT_ETC_DIR/vkit-completions"
export VKIT_PACKUP_RUNTIME=${VKIT_PACKUP_RUNTIME:-"1"}
export VKIT_PACKUP_SDK=${VKIT_PACKUP_SDK:-"0"}
export VKIT_VCS_TOOL=ripvcs

export CMAKE_TOOLCHAIN_FILE="$VKIT_ROOT_DIR/cmake/toolchain.cmake"
export CMAKE_INSTALL_PREFIX="$VKIT_PREBUILT_DIR"
command -v ninja &> /dev/null && export CMAKE_GENERATOR="${CMAKE_GENERATOR:-Ninja}"

export CCACHE_COMPRESS=1
export CCACHE_MAXSIZE=10G

export VLINK_ROOT_DIR="$VKIT_PREBUILT_DIR"
export VLINK_ETC_DIR="$VKIT_ETC_DIR"
export VLINK_COMPLETIONS="$VLINK_ETC_DIR/vlink/vlink-completions.sh"

[[ "$PATH" != *"$VKIT_HOST_TOOL_DIR/bin"* ]] && export PATH="$VKIT_HOST_TOOL_DIR/bin:$PATH"
[[ "$LD_LIBRARY_PATH" != *"$VKIT_HOST_TOOL_DIR/lib"* ]] && export LD_LIBRARY_PATH="$VKIT_HOST_TOOL_DIR/lib:$LD_LIBRARY_PATH"

if ! command -v "$VKIT_VCS_TOOL" &>/dev/null; then
    export VKIT_VCS_TOOL=vcs
fi

[ -d "$VKIT_ROOT_DIR/build" ] && mkdir -p "$VKIT_BUILD_DIR"
[ -d "$VKIT_ROOT_DIR/prebuilt" ] && mkdir -p "$VKIT_PREBUILT_DIR"
[ -d "$VKIT_ROOT_DIR/prebuilt-private" ] && mkdir -p "$VKIT_PREBUILT_PRIVATE_DIR"

if [ -d "$VKIT_ROOT_DIR/middleware/vmsgs/schemas" ]; then
    [ -z "$VLINK_PROTO_DIR" ] && export VLINK_PROTO_DIR="$VKIT_ROOT_DIR/middleware/vmsgs/schemas"
    [ -z "$VLINK_FBS_DIR" ] && export VLINK_FBS_DIR="$VKIT_ROOT_DIR/middleware/vmsgs/schemas"
    export VLINK_SCHEMA_PLUGIN=vmsgs
fi

# [ -f $VKIT_ROOT_DIR/rust/rust_setup.sh ] && . $VKIT_ROOT_DIR/rust/rust_setup.sh

function _get_build_cpu_count() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        _cpu_count=$(sysctl -n hw.physicalcpu)
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        _cpu_count=$(sysctl -n hw.ncpu)
    else
        _cpu_count=$(grep "core id" /proc/cpuinfo | sort -u | wc -l)
    fi
    echo $_cpu_count
}

export VKIT_BUILD_CPU_CORE=${VKIT_BUILD_CPU_CORE:-$(_get_build_cpu_count)}
unset MAKEFLAGS
unset MAKELEVEL
unset __cache_mm_project
unset __cache_mm_dir
unset __cache_mmm_cfg

function mm() {
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo -e "Usage:"
        echo -e "       mm"
        echo -e "       mm '-D{CMAKE_FLAG}'"
        echo -e "       mm clean"
        return 0
    fi
    if [ -n "$__cache_mm_dir" ]; then
        local _project_dir="$__cache_mm_dir"
    else
        local _project_dir="$(pwd)"
    fi
    if [ -n "$__cache_mm_project" ]; then
        local _project="$__cache_mm_project"
    elif [[ "$_project_dir" == "$VKIT_ROOT_DIR/"* ]]; then
        local _project="${_project_dir#$VKIT_ROOT_DIR/}"
    else
        local _project="$(basename "$_project_dir")"
    fi
    local _build_type=0
    if [ -f "$_project_dir/CMakeLists.txt" ]; then
        _build_type=0 # cmake
    elif [ -f "$_project_dir/cmake/CMakeLists.txt" ]; then
        _build_type=0 # cmake
        _project_dir="$_project_dir/cmake"
    elif [ -f "$_project_dir/build.sh" ]; then
        _build_type=1 # build.sh
    elif [ -f "$_project_dir/Makefile" ]; then
        _build_type=2 # Makefile
        [ "$_project_dir" = "$VKIT_ROOT_DIR" ] && echo -e "\033[1m\033[31mError: Can not mm project [$_project_dir]!\033[0m" && return 1
    elif [ -n "$__cache_mm_dir" ] && [ -z "$(ls -A "$_project_dir")" ]; then
        echo -e "\033[1m\033[33m=== Note: Skip [$_project] ===\033[0m"
        return 0
    else
        echo -e "\033[1m\033[31mError: Can not mm project [$_project_dir]!\033[0m" && return 1
    fi
    if [ "$1" = "clean" ]; then
        if [ -d "$VKIT_BUILD_DIR/$_project" ]; then
            echo -e "\033[1m\033[34m=== Clean [$_project] ===\033[0m"
            if [ $_build_type -eq 2 ]; then
                make -C "$_project_dir" clean
            fi
            rm -rf "$VKIT_BUILD_DIR/$_project"
        fi
        return 0
    elif [ "$1" = "dclean" ]; then
        if [ -d "$VKIT_BUILD_DIR/$_project" ]; then
            echo -e "\033[1m\033[34m=== Clean [$_project] ===\033[0m"
            if [ $_build_type -eq 0 ]; then
                cmake --build "$VKIT_BUILD_DIR/$_project" --target __uninstall
            elif [ $_build_type -eq 2 ]; then
                make -C "$_project_dir" clean
            fi
            rm -rf "$VKIT_BUILD_DIR/$_project"
        fi
        return 0
    else
        echo -e "\n\033[1m\033[34m=== Build [$_project] ===\033[0m"
        if [ $_build_type -eq 0 ]; then
            local _has_target=0
            local _a
            for _a in "$@"; do
                if [ "$_a" = "--target" ] || [[ "$_a" == "--target="* ]]; then
                    _has_target=1
                    break
                fi
            done
            if [ $_has_target -eq 1 ]; then
                cmake --build "$VKIT_BUILD_DIR/$_project" -j"$VKIT_BUILD_CPU_CORE" "$@"
            else
                if [ ! -f "$VKIT_BUILD_DIR/$_project/CMakeCache.txt" ]; then
                    cmake -S "$_project_dir" -B "$VKIT_BUILD_DIR/$_project" -DCMAKE_TOOLCHAIN_FILE="$VKIT_ROOT_DIR/cmake/toolchain.cmake" "$@"
                    if [ $? -ne 0 ]; then
                        echo -e "\n\033[1m\033[31m=== Build [$_project] failed ===\033[0m"
                        return 1
                    fi
                fi
                cmake --build "$VKIT_BUILD_DIR/$_project" -j"$VKIT_BUILD_CPU_CORE"
                if [ $? -ne 0 ]; then
                    echo -e "\n\033[1m\033[31m=== Build [$_project] failed ===\033[0m"
                    return 1
                fi
                if [ "$VKIT_STRIP" = "1" ]; then
                    cmake --install "$VKIT_BUILD_DIR/$_project" --strip >/dev/null
                else
                    cmake --install "$VKIT_BUILD_DIR/$_project" >/dev/null
                fi
            fi
        elif [ $_build_type -eq 1 ]; then
            mkdir -p "$VKIT_BUILD_DIR/$_project" && cp -rf "$_project_dir"/* "$VKIT_BUILD_DIR/$_project/"
            "$VKIT_BUILD_DIR/$_project/build.sh" "$@"
        elif [ $_build_type -eq 2 ]; then
            make -C "$_project_dir" "$@" -j"$VKIT_BUILD_CPU_CORE"
        fi
        if [ $? -ne 0 ]; then
            echo -e "\n\033[1m\033[31m=== Build [$_project] failed ===\033[0m"
            return 1
        fi
        echo -e ""
        return 0
    fi
}

function _mm_for_cfg() {
    local _path="$1"
    local _arg="${2-}"
    [ $# -ge 1 ] && shift
    [ $# -ge 1 ] && shift
    local _reval=0
    [ ! -f "$_path" ] && echo -e "\033[1m\033[31mError: Path [$_path] not exists!\033[0m" && return 1
    local lines=()
    while read _line || [[ -n "$_line" ]]; do
        _line="${_line#"${_line%%[![:space:]]*}"}"
        ([ -z "$_line" ] || [[ "$_line" == \#* ]] || [[ "$_line" == \;* ]] || [[ "$_line" == //* ]]) && continue
        lines+=("$_line")
    done < "$_path"
    for _line in "${lines[@]}"; do
        local _project=$(echo "$_line" | cut -d ";" -f 1)
        local _cfg_arg=$(echo "$_line" | cut -d ";" -f 2)
        local __cache_mm_project="$_project"
        local __cache_mm_dir="$VKIT_ROOT_DIR/$_project"
        [ -z "$_project" ] && echo -e "Warning: Split line [$_line] failed!" && continue
        [ ! -d "$__cache_mm_dir" ] && echo -e "\033[1m\033[33m=== Note: Skip [$_project] ===\033[0m" && continue
        if [ "$_arg" = "clean" ]; then
            mm clean
        elif [ -n "$_arg" ]; then
            mm $(echo "${_cfg_arg}") "$_arg" "$@"
        else
            mm $(echo "${_cfg_arg}") "$@"
        fi
        [ $? -ne 0 ] && _reval=1 && break
    done
    return $_reval
}

function _mmm_get_cfg() {
    local _path="$1"
    local _pwd="$2"
    [ ! -f "$_path" ] && echo -e "\033[1m\033[31mError: Path [$_path] not exists!\033[0m" && return 1
    local lines=()
    while read _line || [[ -n "$_line" ]]; do
        _line="${_line#"${_line%%[![:space:]]*}"}"
        ([ -z "$_line" ] || [[ "$_line" == \#* ]] || [[ "$_line" == \;* ]] || [[ "$_line" == //* ]]) && continue
        lines+=("$_line")
    done < "$_path"
    for _line in "${lines[@]}"; do
        local _project=$(echo "$_line" | cut -d ";" -f 1)
        local _cfg_arg=$(echo "$_line" | cut -d ";" -f 2)
        local __cache_mm_project="$_project"
        local __cache_mm_dir="$VKIT_ROOT_DIR/$_project"
        [ -z "$_project" ]  && continue
        [ ! -d "$__cache_mm_dir" ]  && continue
        if [[ "$_pwd" == */"$_project" ]]; then
            __cache_mmm_cfg="$_cfg_arg"
            return 0
        fi
    done
    return 1
}

function _mmm_ll_cfg() {
    local _project_dir="$1"
    local _skip_app=0
    local _skip_middleware=0
    local _skip_vendor=0
    local _skip_thirdparty=0
    if [[ "$_project_dir" == "$VKIT_ROOT_DIR/app/"* ]]; then
        _skip_app=1
        _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/app.cfg" "$_project_dir" && return 0
    elif [[ "$_project_dir" == "$VKIT_ROOT_DIR/middleware/"* ]]; then
        _skip_middleware=1
        _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/middleware.cfg" "$_project_dir" && return 0
    elif [[ "$_project_dir" == "$VKIT_ROOT_DIR/vendor/"* ]]; then
        _skip_vendor=1
        _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/vendor.cfg" "$_project_dir" && return 0
    elif [[ "$_project_dir" == "$VKIT_ROOT_DIR/thirdparty/"* ]]; then
        _skip_thirdparty=1
        _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/thirdparty.cfg" "$_project_dir" && return 0
    fi
    [ $_skip_app -ne 1 ] && _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/app.cfg" "$_project_dir" && return 0
    [ $_skip_middleware -ne 1 ] && _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/middleware.cfg" "$_project_dir" && return 0
    [ $_skip_vendor -ne 1 ] && _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/vendor.cfg" "$_project_dir" && return 0
    [ $_skip_thirdparty -ne 1 ] && _mmm_get_cfg "$VKIT_PLATFORM_CONFIG_DIR/thirdparty.cfg" "$_project_dir" && return 0
    return 1
}

function mm_thirdparty() {
    _mm_for_cfg "$VKIT_PLATFORM_CONFIG_DIR/thirdparty.cfg" "$@"
}

function mm_vendor() {
    _mm_for_cfg "$VKIT_PLATFORM_CONFIG_DIR/vendor.cfg" "$@"
}

function mm_middleware() {
    if [ "$1" != "clean" ] && [ "${VKIT_MIDDLEWARE_RELWITHDEBINFO}" = "1" ]; then
        _mm_for_cfg "$VKIT_PLATFORM_CONFIG_DIR/middleware.cfg" "$@" -DCMAKE_BUILD_TYPE="RelWithDebInfo"
    else
        _mm_for_cfg "$VKIT_PLATFORM_CONFIG_DIR/middleware.cfg" "$@"
    fi
}

function mm_app() {
    if [ "$1" != "clean" ] && [ "${VKIT_APP_RELWITHDEBINFO}" = "1" ]; then
        _mm_for_cfg "$VKIT_PLATFORM_CONFIG_DIR/app.cfg" "$@" -DCMAKE_BUILD_TYPE="RelWithDebInfo"
    else
        _mm_for_cfg "$VKIT_PLATFORM_CONFIG_DIR/app.cfg" "$@"
    fi
}

function mm_all() {
    local _has_component=0
    if [ -f "$VKIT_PLATFORM_CONFIG_DIR/thirdparty.cfg" ]; then
        _has_component=1
        mm_thirdparty "$@"
        [ $? -ne 0 ] && return 1
    fi
    if [ -f "$VKIT_PLATFORM_CONFIG_DIR/vendor.cfg" ]; then
        _has_component=1
        mm_vendor "$@"
        [ $? -ne 0 ] && return 1
    fi
    if [ -f "$VKIT_PLATFORM_CONFIG_DIR/middleware.cfg" ]; then
        _has_component=1
        mm_middleware "$@"
        [ $? -ne 0 ] && return 1
    fi
    if [ -f "$VKIT_PLATFORM_CONFIG_DIR/app.cfg" ]; then
        _has_component=1
        mm_app "$@"
        [ $? -ne 0 ] && return 1
    fi
    if [ $_has_component -eq 0 ]; then
        echo -e "\033[1m\033[31mError: Can not find any project to build!\033[0m" && return 1
    fi
    return 0
}

function mmm() {
    local _project_dir="$(pwd)"
    local __cache_mmm_cfg=
    _mmm_ll_cfg "$_project_dir"
    [ $? -ne 0 ] && echo -e "\033[1m\033[31mError: Can not mmm project [$_project_dir]!\033[0m" && return 1
    if [ "$1" = "clean" ]; then
        mm clean
    else
        mm $(echo $__cache_mmm_cfg) "$@"
    fi
    [ $? -ne 0 ] && return 1
    return 0
}

function mmc() {
    if [ "$1" = "fix" ]; then
        mm "${@:2}" -DCMAKE_CXX_CLANG_TIDY="clang-tidy;-fix;-fix-errors"
    else
        mm "$@" -DCMAKE_CXX_CLANG_TIDY="clang-tidy"
    fi
}

function mmmc() {
    if [ "$1" = "fix" ]; then
        mmm "${@:2}" -DCMAKE_CXX_CLANG_TIDY="clang-tidy;-fix;-fix-errors"
    else
        mmm "$@" -DCMAKE_CXX_CLANG_TIDY="clang-tidy"
    fi
}

function llcfg() {
    local _project_dir="$(pwd)"
    _mmm_ll_cfg "$_project_dir"
    [ $? -ne 0 ] && echo -e "\033[1m\033[31mError: Can not find cfg [$_project_dir]!\033[0m" && return 1
    local _print_result=$(echo -e "$__cache_mmm_cfg" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
    local _print_result=$(echo -e "$_print_result" | sed -E 's/[[:space:]]+/\ \\\n\ \ \ /g')
    echo "mm $_print_result"
    return 0
}

function rdb() {
    if [ "$VKIT_PLATFORM" = "qnx-aarch64" ]; then
        ntoaarch64-gdb -ex "set solib-search-path $VKIT_PREBUILT_DIR/lib" "$@"
    elif [ "$VKIT_PLATFORM" = "qnx-x86_64" ]; then
        ntox86_64-gdb -ex "set solib-search-path $VKIT_PREBUILT_DIR/lib" "$@"
    elif [ "$VKIT_PLATFORM" != "linux-aarch64" ] && [ "$VKIT_PLATFORM" != "linux-x86_64" ]; then
        gdb -ex "set solib-search-path $VKIT_PREBUILT_DIR/lib" "$@"
    fi
}

function _import_repo() {
    local _repo="$1"
    local _shallow="$2"
    if [ -f "$_repo" ] && [ -s "$_repo" ]; then
        "$VKIT_VCS_TOOL" import --input "$_repo" --workers "$VKIT_BUILD_CPU_CORE" $_shallow
    fi
}

function build() {
    if [ "$1" = "thirdparty" ] || [ "$1" = "3rd" ]; then
        mm_thirdparty "${@:2}"
        [ $? -ne 0 ] && return 1
    elif [ "$1" = "vendor" ] || [ "$1" = "ven" ]; then
        mm_vendor "${@:2}"
        [ $? -ne 0 ] && return 1
    elif [ "$1" = "middleware" ] || [ "$1" = "mid" ]; then
        mm_middleware "${@:2}"
        [ $? -ne 0 ] && return 1
    elif [ "$1" = "app" ]; then
        mm_app "${@:2}"
        [ $? -ne 0 ] && return 1
    elif [ "$1" = "deploy" ]; then
        "$VKIT_ROOT_DIR/deploy/vkit-deploy.sh"
        [ $? -ne 0 ] && return 1
    elif [ "$1" = "deploy_sdk" ] || [ "$1" = "sdk" ]; then
        VKIT_PACKUP_SDK=1 "$VKIT_ROOT_DIR/deploy/vkit-deploy.sh"
        [ $? -ne 0 ] && return 1
    else
        echo -e "\033[1m\033[31mError: Unsupported command!\033[0m"
        return 1
    fi
    return 0
}

if [ "$0" != "$BASH_SOURCE" ]; then
    echo -e -n "\033[2J\033[H"
    echo -e "Setup VKIT build environment..."
    echo -e -n "\033[1;32m"
    echo -e "╔═════════════════════════════════════╗"
    echo -e "║  _    __   __      _           __   ║"
    echo -e "║ | |  / /  / /     (_) ____    / /__ ║"
    echo -e "║ | | / /  / /     / / / __ \\  / //_/ ║"
    echo -e "║ | |/ /  / /___  / / / / / / / ,<    ║"
    echo -e "║ |___/  /_____/ /_/ /_/ /_/ /_/|_|   ║"
    echo -e "║                                     ║"
    echo -e "╚═════════════════════════════════════╝"
    echo -e -n "\033[0m"
    echo -e "Platform: $VKIT_PLATFORM"
    echo -e "Device: $VKIT_DEVICE"
    echo -e ""
    echo -e "Note: You can run the following command:"
    echo -e "      mmm            Build a component with config compile flags"
    echo -e "      mm             [ '-D{CMAKE_FLAG}' | clean ]   \"Build a component\""
    echo -e "      mm_thirdparty  [ '-D{CMAKE_FLAG}' | clean ]   \"Build thirdparty\""
    echo -e "      mm_vendor      [ '-D{CMAKE_FLAG}' | clean ]   \"Build vendor\""
    echo -e "      mm_middleware  [ '-D{CMAKE_FLAG}' | clean ]   \"Build middleware\""
    echo -e "      mm_app         [ '-D{CMAKE_FLAG}' | clean ]   \"Build app\""
    echo -e "      mm_all         [ '-D{CMAKE_FLAG}' | clean ]   \"Build ALL\""
    echo -e ""
    if [ "$VKIT_PLATFORM" = "$VKIT_HOST_PLATFORM" ]; then
        [[ "$PATH" != *"$VKIT_PREBUILT_DIR/bin"* ]] && export PATH="$VKIT_PREBUILT_DIR/bin:$PATH"
        [[ "$LD_LIBRARY_PATH" != *"$VKIT_PREBUILT_DIR/lib"* ]] && export LD_LIBRARY_PATH="$VKIT_PREBUILT_DIR/lib:$LD_LIBRARY_PATH"
        if [ -n "$BASH" ]; then
            if [ -f "$VLINK_COMPLETIONS" ]; then
                . "$VLINK_COMPLETIONS"
            fi
            if [ -d "$VKIT_CODE_COMPLETE_DIR" ]; then
                for code_script in "$VKIT_CODE_COMPLETE_DIR"/*.sh; do
                    [ -f "$code_script" ] && . "$code_script"
                done
            fi
        fi
    fi
    return 0
fi

if [ "$1" = "import" ]; then
    if [ -z "$2" ]; then
        echo -e "\033[1m\033[31mError: 'import' requires a repo set name (e.g. 'make import dev')!\033[0m"
        exit 1
    fi
    if ! command -v git-lfs &> /dev/null; then
        echo -e "\033[33mWarning: git-lfs is not installed.\033[0m"
    fi
    if ! command -v "$VKIT_VCS_TOOL" &> /dev/null; then
        echo -e "\033[1m\033[31mError: Can not find $VKIT_VCS_TOOL command!\033[0m"
        exit 1
    fi
    if [ ! -d "$VKIT_ROOT_DIR/repos/$2" ]; then
        echo -e "\033[1m\033[31mError: Can not find repo [$VKIT_ROOT_DIR/repos/$2]!\033[0m"
        exit 1
    fi
    echo -e "Please wait..."
    _import_repo "$VKIT_ROOT_DIR/repos/$2/setup.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/$2/prebuilt.repos" --shallow
    _import_repo "$VKIT_ROOT_DIR/repos/$2/thirdparty.repos" --shallow
    _import_repo "$VKIT_ROOT_DIR/repos/$2/vendor.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/$2/middleware.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/$2/app.repos"
    exit 0
elif [ "$1" = "import_dev" ]; then
    if ! command -v git-lfs &> /dev/null; then
        echo -e "\033[33mWarning: git-lfs is not installed.\033[0m"
    fi
    if ! command -v "$VKIT_VCS_TOOL" &> /dev/null; then
        echo -e "\033[1m\033[31mError: Can not find $VKIT_VCS_TOOL command!\033[0m"
        exit 1
    fi
    if [ ! -d "$VKIT_ROOT_DIR/repos/dev" ]; then
        echo -e "\033[1m\033[31mError: Can not find repo [$VKIT_ROOT_DIR/repos/dev]!\033[0m"
        exit 1
    fi
    echo -e "Please wait..."
    _import_repo "$VKIT_ROOT_DIR/repos/dev/setup.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/dev/prebuilt.repos" --shallow
    _import_repo "$VKIT_ROOT_DIR/repos/dev/thirdparty.repos" --shallow
    _import_repo "$VKIT_ROOT_DIR/repos/dev/vendor.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/dev/middleware.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/dev/app.repos"
    exit 0
elif [ "$1" = "import_full" ]; then
    if ! command -v git-lfs &> /dev/null; then
        echo -e "\033[33mWarning: git-lfs is not installed.\033[0m"
    fi
    if ! command -v "$VKIT_VCS_TOOL" &> /dev/null; then
        echo -e "\033[1m\033[31mError: Can not find $VKIT_VCS_TOOL command!\033[0m"
        exit 1
    fi
    if [ ! -d "$VKIT_ROOT_DIR/repos/full" ]; then
        echo -e "\033[1m\033[31mError: Can not find repo [$VKIT_ROOT_DIR/repos/full]!\033[0m"
        exit 1
    fi
    echo -e "Please wait..."
    _import_repo "$VKIT_ROOT_DIR/repos/full/setup.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/full/prebuilt.repos" --shallow
    _import_repo "$VKIT_ROOT_DIR/repos/full/thirdparty.repos" --shallow
    _import_repo "$VKIT_ROOT_DIR/repos/full/vendor.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/full/middleware.repos"
    _import_repo "$VKIT_ROOT_DIR/repos/full/app.repos"
    exit 0
elif [ "$1" = "pull" ]; then
    if ! command -v git-lfs &> /dev/null; then
        echo -e "\033[33mWarning: git-lfs is not installed.\033[0m"
    fi
    if ! command -v "$VKIT_VCS_TOOL" &> /dev/null; then
        echo -e "\033[1m\033[31mError: Can not find $VKIT_VCS_TOOL command!\033[0m"
        exit 1
    fi
    echo -e "Please wait..."
    _pull_list=("$VKIT_ROOT_DIR")
    [ -d "$VKIT_ROOT_DIR/setup" ] && _pull_list+=("$VKIT_ROOT_DIR/setup")
    [ -d "$VKIT_ROOT_DIR/prebuilt" ] && _pull_list+=("$VKIT_ROOT_DIR/prebuilt")
    [ -d "$VKIT_ROOT_DIR/prebuilt-private" ] && _pull_list+=("$VKIT_ROOT_DIR/prebuilt-private")
    [ -d "$VKIT_ROOT_DIR/thirdparty" ] && _pull_list+=("$VKIT_ROOT_DIR/thirdparty")
    [ -d "$VKIT_ROOT_DIR/vendor" ] && _pull_list+=("$VKIT_ROOT_DIR/vendor")
    [ -d "$VKIT_ROOT_DIR/middleware" ] && _pull_list+=("$VKIT_ROOT_DIR/middleware")
    [ -d "$VKIT_ROOT_DIR/app" ] && _pull_list+=("$VKIT_ROOT_DIR/app")
    "$VKIT_VCS_TOOL" pull "${_pull_list[@]}" --workers "$VKIT_BUILD_CPU_CORE"
    unset _pull_list
    exit 0
elif [ "$1" = "install" ]; then
    mm_all
    exit $?
elif [ "$1" = "clean" ]; then
    mm_all clean
    exit $?
elif [ "$1" = "rclean" ]; then
    [ -d "$VKIT_BUILD_DIR" ] && rm -rf "$VKIT_BUILD_DIR"/*
    [ -d "$VKIT_PACKUP_DIR" ] && rm -rf "$VKIT_PACKUP_DIR"/*
    [ -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-sdk.tgz" ] && rm -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-sdk.tgz"
    [ -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-runtime.tgz" ] && rm -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-runtime.tgz"
    if [ -d "$VKIT_ROOT_DIR/prebuilt/.git" ]; then
        if [ -d "$VKIT_PREBUILT_DIR" ]; then
            git -C "$VKIT_PREBUILT_DIR" clean -fdx .
            git -C "$VKIT_PREBUILT_DIR" checkout HEAD .
        elif [ -d "$VKIT_ROOT_DIR/prebuilt" ]; then
            git -C "$VKIT_ROOT_DIR/prebuilt" checkout HEAD "$VKIT_DEVICE_PLATFORM"
        fi
    else
        [ -d "$VKIT_PREBUILT_DIR" ] && rm -rf "$VKIT_PREBUILT_DIR"/*
    fi
    if [ -d "$VKIT_ROOT_DIR/prebuilt-private/.git" ]; then
        if [ -d "$VKIT_PREBUILT_PRIVATE_DIR" ]; then
            git -C "$VKIT_PREBUILT_PRIVATE_DIR" clean -fdx .
            git -C "$VKIT_PREBUILT_PRIVATE_DIR" checkout HEAD .
        elif [ -d "$VKIT_ROOT_DIR/prebuilt-private" ]; then
            git -C "$VKIT_ROOT_DIR/prebuilt-private" checkout HEAD "$VKIT_DEVICE_PLATFORM"
        fi
    else
        [ -d "$VKIT_PREBUILT_PRIVATE_DIR" ] && rm -rf "$VKIT_PREBUILT_PRIVATE_DIR"/*
    fi
    exit 0
elif [ "$1" = "dclean" ]; then
    [ -d "$VKIT_PREBUILT_DIR" ] && rm -rf "$VKIT_PREBUILT_DIR"/*
    [ -d "$VKIT_PREBUILT_PRIVATE_DIR" ] && rm -rf "$VKIT_PREBUILT_PRIVATE_DIR"/*
    [ -d "$VKIT_BUILD_DIR" ] && rm -rf "$VKIT_BUILD_DIR"/*
    [ -d "$VKIT_PACKUP_DIR" ] && rm -rf "$VKIT_PACKUP_DIR"/*
    [ -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-sdk.tgz" ] && rm -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-sdk.tgz"
    [ -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-runtime.tgz" ] && rm -f "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-runtime.tgz"
    exit 0
elif [ "$1" = "aclean" ]; then
    [ -d "$VKIT_ROOT_DIR/build" ] && rm -rf "$VKIT_ROOT_DIR/build"/*
    [ -d "$VKIT_ROOT_DIR/prebuilt" ] && rm -rf "$VKIT_ROOT_DIR/prebuilt"/*
    [ -d "$VKIT_ROOT_DIR/prebuilt-private" ] && rm -rf "$VKIT_ROOT_DIR/prebuilt-private"/*
    [ -d "$VKIT_ROOT_DIR/packup" ] && rm -rf "$VKIT_ROOT_DIR/packup"/*
    exit 0
elif [ "$1" = "deploy" ]; then
    "$VKIT_ROOT_DIR/deploy/vkit-deploy.sh"
    exit $?
elif [ "$1" = "deploy_sdk" ]; then
    VKIT_PACKUP_SDK=1 "$VKIT_ROOT_DIR/deploy/vkit-deploy.sh"
    exit $?
else
    echo -e "Usage:"
    echo -e "        source vkit-setup.sh"
    echo -e "        vkit-setup.sh import [component]"
    echo -e "        vkit-setup.sh import_dev"
    echo -e "        vkit-setup.sh import_full"
    echo -e "        vkit-setup.sh pull"
    echo -e "        vkit-setup.sh install"
    echo -e "        vkit-setup.sh clean"
    echo -e "        vkit-setup.sh rclean"
    echo -e "        vkit-setup.sh dclean"
    echo -e "        vkit-setup.sh aclean"
    echo -e "        vkit-setup.sh deploy"
    echo -e "        vkit-setup.sh deploy_sdk"
    exit 0
fi
