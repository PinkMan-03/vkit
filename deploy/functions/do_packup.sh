#!/usr/bin/env bash

VKIT_COMMON_ENV_CONFIGSTR=\
"\
# =================================\n\
\n\
export VLINK_ROOT_DIR=\$VKIT_PREBUILT_DIR\n\
export VLINK_ETC_DIR=\$VKIT_ETC_DIR\n\
if [ -z \"\$PATH\" ] || [[ \$PATH != *\$VLINK_ROOT_DIR/bin* ]];then\n\
\texport PATH=\$VLINK_ROOT_DIR/bin:\$PATH\n\
fi\n\
if [ -z \"\$LD_LIBRARY_PATH\" ] || [[ \$LD_LIBRARY_PATH != *\$VLINK_ROOT_DIR/lib* ]];then\n\
\texport LD_LIBRARY_PATH=\$VLINK_ROOT_DIR/lib:\$LD_LIBRARY_PATH\n\
fi\n\
[ -e \$VLINK_ROOT_DIR/bin/vlink-info ] && export VKIT_VERSION=\$(\$VLINK_ROOT_DIR/bin/vlink-info -v)\n\
if [ -n \"\$BASH\" ];then\n\
\t[ -e \$VLINK_ETC_DIR/vlink/vlink-completions.sh ] && . \$VLINK_ETC_DIR/vlink/vlink-completions.sh\n\
\tif [ -d \$VKIT_CODE_COMPLETE_DIR ];then\n\
\t\tfor code_script in \$VKIT_CODE_COMPLETE_DIR/*.sh;do\n\
\t\t\t[ -f \$code_script ] && . \$code_script\n\
\t\tdone\n\
\tfi\n\
fi\n\
[ -e \$VLINK_ETC_DIR/oem-runtime-setup.sh ] && . \$VLINK_ETC_DIR/oem-runtime-setup.sh\n\
export VLINK_TMP_DIR=\${VLINK_TMP_DIR:-\$VLINK_ROOT_DIR/data}\n\
export VLINK_LOG_DIR=\${VLINK_LOG_DIR:-\$VLINK_ROOT_DIR/data/vlink-log}\n\
export VLINK_LOCK_DIR=\${VLINK_LOCK_DIR:-\$VLINK_ROOT_DIR/data/vlink-lock}\n\
[ -d \$VLINK_TMP_DIR ]  || mkdir -p \$VLINK_TMP_DIR\n\
[ -d \$VLINK_LOG_DIR ]  || mkdir -p \$VLINK_LOG_DIR\n\
[ -d \$VLINK_LOCK_DIR ] || mkdir -p \$VLINK_LOCK_DIR\n\
if [ -z \"\$VLINK_SCHEMA_PLUGIN\" ];then\n\
\tfor vmsgs_lib in \$VLINK_ROOT_DIR/lib/libvmsgs.*;do\n\
\t\t[ -f \$vmsgs_lib ] && export VLINK_SCHEMA_PLUGIN=\$vmsgs_lib && break\n\
\tdone\n\
fi\n\
[ -d \$VLINK_ETC_DIR/vmsgs/schemas ] && export VLINK_PROTO_DIR=\${VLINK_PROTO_DIR:-\$VLINK_ETC_DIR/vmsgs/schemas}\n\
[ -n \"\$VLINK_PROTO_DIR\" ] && export VLINK_FBS_DIR=\$VLINK_PROTO_DIR\n\
\n\
"

VKIT_SDK_ENV_CONFIGSTR=\
"\
#!/bin/sh\n\
\n\
if [ -n \"\$BASH_SOURCE\" ] && [ \"\$0\" = \"\$BASH_SOURCE\" ];then\n\
\techo \"Error: This script must be sourced, not executed directly.\"\n\
\texit 1\n\
fi\n\
\n\
echo -e -n \"\\\033[2J\\\033[H\"\n\
echo -e \"Setup VKIT sdk environment...\"\n\
echo -e -n \"\\\033[1;32m\"\n\
echo -e \"╔═════════════════════════════════════╗\"\n\
echo -e \"║  _    __   __      _           __   ║\"\n\
echo -e \"║ | |  / /  / /     (_) ____    / /__ ║\"\n\
echo -e \"║ | | / /  / /     / / / __ \\\\\\\\  / //_/ ║\"\n\
echo -e \"║ | |/ /  / /___  / / / / / / / ,<    ║\"\n\
echo -e \"║ |___/  /_____/ /_/ /_/ /_/ /_/|_|   ║\"\n\
echo -e \"║                                     ║\"\n\
echo -e \"╚═════════════════════════════════════╝\"\n\
echo -e -n \"\\\033[0m\"\n\
echo -e \"Platform: $VKIT_PLATFORM\"\n\
echo -e \"Device: $VKIT_DEVICE\"\n\
echo -e \"\"\n\
\n\
export VKIT_PLATFORM=\"$VKIT_PLATFORM\"\n\
export VKIT_DEVICE=\"$VKIT_DEVICE\"\n\
export VKIT_HOST_PLATFORM=\"\$(uname -s | tr '[:upper:]' '[:lower:]')-\$(uname -m | tr '[:upper:]' '[:lower:]')\"\n\
export VKIT_ROOT_DIR=\$(cd \$(dirname \${BASH_SOURCE:-\$0}) && pwd)\n\
export VKIT_HOST_DIR=\$VKIT_ROOT_DIR/host/\$VKIT_HOST_PLATFORM\n\
export VKIT_PREBUILT_DIR=\$VKIT_ROOT_DIR/target\n\
export VKIT_ETC_DIR=\$VKIT_PREBUILT_DIR/etc\n\
export VKIT_CODE_COMPLETE_DIR=\$VKIT_ETC_DIR/vkit-completions\n\
if [ -z \"\$PATH\" ] || [[ \$PATH != *\$VKIT_HOST_DIR/bin* ]];then\n\
\texport PATH=\$VKIT_HOST_DIR/bin:\$PATH\n\
fi\n\
if [ -z \"\$LD_LIBRARY_PATH\" ] || [[ \$LD_LIBRARY_PATH != *\$VKIT_HOST_DIR/lib* ]];then\n\
\texport LD_LIBRARY_PATH=\$VKIT_HOST_DIR/lib:\$LD_LIBRARY_PATH\n\
fi\n\
export CMAKE_TOOLCHAIN_FILE=\$VKIT_ROOT_DIR/cmake/toolchain.cmake\n\
if [ \"\$0\" != \"\$BASH_SOURCE\" ] && [ -n \"\$1\" ];then\n\
\tif [ -f \$VKIT_ROOT_DIR/vkit-toolchains/\$1/\$1_setup.sh ];then\n\
\t\t. \$VKIT_ROOT_DIR/vkit-toolchains/\$1/\$1_setup.sh\n\
\telif [ -f ~/vkit-toolchains/\$1/\$1_setup.sh ];then\n\
\t\t. ~/vkit-toolchains/\$1/\$1_setup.sh\n\
\telif [ -f /opt/vkit-toolchains/\$1/\$1_setup.sh ];then\n\
\t\t. /opt/vkit-toolchains/\$1/\$1_setup.sh\n\
\telif [ -f /opt/\$1/\$1_setup.sh ];then\n\
\t\t. /opt/\$1/\$1_setup.sh\n\
\telse\n\
\t\techo -e \"Error: Can not find \$1_setup.sh!\"\n\
\t\treturn 1\n\
\tfi\n\
fi\n\
if [ \"\$VKIT_PLATFORM\" != \"\$VKIT_HOST_PLATFORM\" ];then\n\
\treturn 0\n\
fi\n\
\n\
${VKIT_COMMON_ENV_CONFIGSTR}\n\
"


VKIT_RUNTIME_ENV_CONFIGSTR=\
"\
#!/bin/sh\n\
\n\
if [ -n \"\$BASH_SOURCE\" ] && [ \"\$0\" = \"\$BASH_SOURCE\" ];then\n\
\techo \"Error: This script must be sourced, not executed directly.\"\n\
\texit 1\n\
fi\n\
\n\
echo -e -n \"\\\033[2J\\\033[H\"\n\
echo -e \"Setup VKIT runtime environment...\"\n\
echo -e -n \"\\\033[1;32m\"\n\
echo -e \"╔═════════════════════════════════════╗\"\n\
echo -e \"║  _    __   __      _           __   ║\"\n\
echo -e \"║ | |  / /  / /     (_) ____    / /__ ║\"\n\
echo -e \"║ | | / /  / /     / / / __ \\\\\\\\  / //_/ ║\"\n\
echo -e \"║ | |/ /  / /___  / / / / / / / ,<    ║\"\n\
echo -e \"║ |___/  /_____/ /_/ /_/ /_/ /_/|_|   ║\"\n\
echo -e \"║                                     ║\"\n\
echo -e \"╚═════════════════════════════════════╝\"\n\
echo -e -n \"\\\033[0m\"\n\
echo -e \"Platform: $VKIT_PLATFORM\"\n\
echo -e \"Device: $VKIT_DEVICE\"\n\
echo -e \"\"\n\
\n\
export VKIT_PLATFORM=\"$VKIT_PLATFORM\"\n\
export VKIT_DEVICE=\"$VKIT_DEVICE\"\n\
if [ -n \"\$BASH_VERSION\" ] || [ -n \"\$ZSH_VERSION\" ];then\n\
\texport VKIT_ROOT_DIR=\$(cd \$(dirname \${BASH_SOURCE:-\$0}) && pwd)\n\
else\n\
\texport VKIT_ROOT_DIR=\$(pwd)\n\
fi\n\
export VKIT_PREBUILT_DIR=\$VKIT_ROOT_DIR\n\
export VKIT_ETC_DIR=\$VKIT_PREBUILT_DIR/etc\n\
export VKIT_CODE_COMPLETE_DIR=\$VKIT_ETC_DIR/vkit-completions\n\
\n\
${VKIT_COMMON_ENV_CONFIGSTR}\n\
"

function do_packup_runtime() {
    echo -e "[ do_packup_runtime ]"
    if tar --version 2>&1 | grep -qi 'gnu'; then
        tar -czf "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-runtime.tgz" -C "$VKIT_PACKUP_DIR/target" \
            --transform="flags=r;s|./|./vkit-${VKIT_DEVICE_PLATFORM}-runtime/|" \
            --exclude='include' \
            --exclude='share' \
            --exclude='ssl' \
            --exclude='usr' \
            --exclude='lib/include' \
            --exclude='lib/python' \
            --exclude='lib/cmake' \
            --exclude='lib/pkgconfig' \
            --exclude='lib/src' \
            --exclude='lib/source' \
            --exclude='lib/sources' \
            --exclude='lib/test' \
            --exclude='lib/tests' \
            --exclude='lib/example' \
            --exclude='lib/examples' \
            --exclude='*.a' \
            --exclude='*.la' \
            --exclude='*.sym' \
            --exclude='*.o' \
            --exclude='*.in' \
            --exclude='*.cmake' \
            --exclude='*.pc' \
            --exclude-from="$SHELL_DIR/vkit.ignore" \
            ./
    else
        tar -czf "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-runtime.tgz" -C "$VKIT_PACKUP_DIR/target" \
            -s "|^./|./vkit-${VKIT_DEVICE_PLATFORM}-runtime/|" \
            --exclude='include' \
            --exclude='share' \
            --exclude='ssl' \
            --exclude='usr' \
            --exclude='lib/include' \
            --exclude='lib/python' \
            --exclude='lib/cmake' \
            --exclude='lib/pkgconfig' \
            --exclude='lib/src' \
            --exclude='lib/source' \
            --exclude='lib/sources' \
            --exclude='lib/test' \
            --exclude='lib/tests' \
            --exclude='lib/example' \
            --exclude='lib/examples' \
            --exclude='*.a' \
            --exclude='*.la' \
            --exclude='*.sym' \
            --exclude='*.o' \
            --exclude='*.in' \
            --exclude='*.cmake' \
            --exclude='*.pc' \
            --exclude-from="$SHELL_DIR/vkit.ignore" \
            ./
    fi
}

function do_packup_sdk() {
    echo -e "[ do_packup_sdk ]"
    if tar --version 2>&1 | grep -qi 'gnu'; then
        tar -czf "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-sdk.tgz" -C "$VKIT_PACKUP_DIR" \
            --transform="flags=r;s|./|./vkit-${VKIT_DEVICE_PLATFORM}-sdk/|" \
            ./
    else
        tar -czf "$VKIT_ROOT_DIR/packup/vkit-${VKIT_DEVICE_PLATFORM}-sdk.tgz" -C "$VKIT_PACKUP_DIR" \
            -s "|^./|./vkit-${VKIT_DEVICE_PLATFORM}-sdk/|" \
            ./
    fi
}

function do_packup() {
    mkdir -p "$VKIT_PACKUP_DIR/cmake"
    mkdir -p "$VKIT_PACKUP_DIR/host"
    mkdir -p "$VKIT_PACKUP_DIR/target"
    if command -v rsync &> /dev/null; then
        [ -d "$VKIT_ROOT_DIR/cmake" ] && rsync -a --delete "$VKIT_ROOT_DIR/cmake/" "$VKIT_PACKUP_DIR/cmake/"
        [ -d "$VKIT_ROOT_DIR/tools" ] && rsync -a --delete "$VKIT_ROOT_DIR/tools/" "$VKIT_PACKUP_DIR/host/"
        [ -d "$VKIT_PREBUILT_DIR" ] && rsync -a --delete "$VKIT_PREBUILT_DIR/" "$VKIT_PACKUP_DIR/target/"
    else
        rm -rf "$VKIT_PACKUP_DIR/cmake"/*
        [ -d "$VKIT_ROOT_DIR/cmake" ] && [ -n "$(ls -A "$VKIT_ROOT_DIR/cmake" 2>/dev/null)" ] && cp -rf "$VKIT_ROOT_DIR/cmake"/* "$VKIT_PACKUP_DIR/cmake/"
        rm -rf "$VKIT_PACKUP_DIR/host"/*
        [ -d "$VKIT_ROOT_DIR/tools" ] && [ -n "$(ls -A "$VKIT_ROOT_DIR/tools" 2>/dev/null)" ] && cp -rf "$VKIT_ROOT_DIR/tools"/* "$VKIT_PACKUP_DIR/host/"
        rm -rf "$VKIT_PACKUP_DIR/target"/*
        [ -d "$VKIT_PREBUILT_DIR" ] && [ -n "$(ls -A "$VKIT_PREBUILT_DIR" 2>/dev/null)" ] && cp -rf "$VKIT_PREBUILT_DIR"/* "$VKIT_PACKUP_DIR/target/"
    fi
    rm -rf "$VKIT_PACKUP_DIR"/target/lib/engines-*
    echo -e "$VKIT_SDK_ENV_CONFIGSTR" > "$VKIT_PACKUP_DIR/vkit-sdk-setup.sh" && chmod +x "$VKIT_PACKUP_DIR/vkit-sdk-setup.sh"
    echo -e "$VKIT_RUNTIME_ENV_CONFIGSTR" > "$VKIT_PACKUP_DIR/target/vkit-runtime-setup.sh" && chmod +x "$VKIT_PACKUP_DIR/target/vkit-runtime-setup.sh"
    mkdir -p "$VKIT_PACKUP_DIR/target/data"
    if [ "$VKIT_PACKUP_RUNTIME" = "1" ]; then
        do_packup_runtime
    fi
    if [ "$VKIT_PACKUP_SDK" = "1" ]; then
        do_packup_sdk
    fi
}
