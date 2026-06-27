#!/usr/bin/env bash

function do_fileset() {
    local BUILD_FILE="$VKIT_PREBUILT_DIR/vkit.build"
    local FILESET_IGNORE_FILE="$SHELL_DIR/vkit.ignore"
    local FILESET_ROOT="../vkit-ware/prebuilt/$VKIT_PLATFORM"
    local FILESET_LIB_NAME=lib64

    if [ "$VKIT_PLATFORM" != "qnx-aarch64" ] && [ "$VKIT_PLATFORM" != "qnx-x86_64" ]; then
        return
    fi
    echo -e "[ do_fileset ]"
    echo -e "# Auto fileset generate.\n" > "$BUILD_FILE"
    local _ignore_list=
    while IFS= read -r _line || [ -n "$_line" ]; do
        ([ -z "$_line" ] || [[ "$_line" == \#* ]]) && continue
        _ignore_list="$_ignore_list$_line "
    done < "$FILESET_IGNORE_FILE"
    while IFS= read -r _path; do
        local _target_name="${_path:${#VKIT_PREBUILT_DIR}+1}"
        local _sys_name="${_target_name/"lib/"/"$FILESET_LIB_NAME/"}"
        local _ignore=0
        for _ignore_str in $_ignore_list; do
            [[ "$_target_name" == ${_ignore_str} ]] && _ignore=1 && break
            [[ "$_target_name" == ${_ignore_str}/* ]] && _ignore=1 && break
            [[ "$_sys_name" == ${_ignore_str} ]] && _ignore=1 && break
            [[ "$_sys_name" == ${_ignore_str}/* ]] && _ignore=1 && break
        done
        if [ $_ignore -eq 1 ]; then
            continue
        elif [[ "$_sys_name" != bin/* ]] && [[ "$_sys_name" != sbin/* ]] && [[ "$_sys_name" != "$FILESET_LIB_NAME"/* ]] && [[ "$_sys_name" != etc/* ]] && [[ "$_sys_name" != scripts/* ]]; then
            continue
        elif [[ "$_sys_name" == *.a ]] || [[ "$_sys_name" == *.la ]] || [[ "$_sys_name" == *.sym ]] || [[ "$_sys_name" == *.o ]] || [[ "$_sys_name" == *.in ]]; then
            continue
        elif [[ "$_sys_name" == *.cmake ]] || [[ "$_sys_name" == *.pc ]]; then
            continue
        elif [[ "$_sys_name" == "$FILESET_LIB_NAME"/include/* ]] || [[ "$_sys_name" == "$FILESET_LIB_NAME"/python/* ]]; then
            continue
        elif [[ "$_sys_name" == "$FILESET_LIB_NAME"/cmake/* ]] || [[ "$_sys_name" == "$FILESET_LIB_NAME"/pkgconfig/* ]]; then
            continue
        elif [[ "$_sys_name" == "$FILESET_LIB_NAME"/src/* ]] || [[ "$_sys_name" == "$FILESET_LIB_NAME"/source/* ]] || [[ "$_sys_name" == "$FILESET_LIB_NAME"/sources/* ]]; then
            continue
        elif [[ "$_sys_name" == "$FILESET_LIB_NAME"/test/* ]] || [[ "$_sys_name" == "$FILESET_LIB_NAME"/tests/* ]]; then
            continue
        elif [[ "$_sys_name" == "$FILESET_LIB_NAME"/example/* ]] || [[ "$_sys_name" == "$FILESET_LIB_NAME"/examples/* ]]; then
            continue
        fi
        if [ "$VERSION_REL" = "QHS_SDP220" ]; then
            if [[ "$_sys_name" == bin/* ]] || [[ "$_sys_name" == scripts/* ]]; then
                local _str="PERM_BIN $_sys_name = $FILESET_ROOT/$_target_name"
            else
                local _str="[uid=ROOT_UID gid=ROOT_GID perms=0555] $_sys_name = $FILESET_ROOT/$_target_name"
            fi
        else
            local _str="$_sys_name = $FILESET_ROOT/$_target_name"
        fi
        echo "$_str"
        echo "$_str" >> "$BUILD_FILE"
    done < <(find "$VKIT_PREBUILT_DIR" -type f)
    echo -e "" >> "$BUILD_FILE"
    while IFS= read -r _path; do
        local _target_name="${_path:${#VKIT_PREBUILT_DIR}+1}"
        local _sys_name="${_target_name/"lib/"/"$FILESET_LIB_NAME/"}"
        local _ignore=0
        for _ignore_str in $_ignore_list; do
            [[ "$_target_name" == ${_ignore_str} ]] && _ignore=1 && break
            [[ "$_target_name" == ${_ignore_str}/* ]] && _ignore=1 && break
            [[ "$_sys_name" == ${_ignore_str} ]] && _ignore=1 && break
            [[ "$_sys_name" == ${_ignore_str}/* ]] && _ignore=1 && break
        done
        if [ $_ignore -eq 1 ]; then
            continue
        elif [[ "$_sys_name" != bin/* ]] && [[ "$_sys_name" != sbin/* ]] && [[ "$_sys_name" != "$FILESET_LIB_NAME"/* ]] && [[ "$_sys_name" != etc/* ]] && [[ "$_sys_name" != scripts/* ]]; then
            continue
        elif [ ! -f "$(dirname "$_path")/$(readlink "$_path")" ]; then
            continue
        fi
        local _str="[type=link]$_sys_name = $(readlink "$_path")"
        echo "$_str"
        echo "$_str" >> "$BUILD_FILE"
    done < <(find "$VKIT_PREBUILT_DIR" -type l)
    unset _ignore_str
    unset _path
}
