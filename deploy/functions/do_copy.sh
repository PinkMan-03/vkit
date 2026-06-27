#!/usr/bin/env bash

function _ndk_host_tag() {
    case "$VKIT_HOST_PLATFORM" in
        linux-x86_64)         echo "linux-x86_64" ;;
        darwin-x86_64)        echo "darwin-x86_64" ;;
        darwin-arm64|darwin-aarch64)
                              [ -d "$ANDROID_NDK/toolchains/llvm/prebuilt/darwin-arm64" ] \
                                  && echo "darwin-arm64" \
                                  || echo "darwin-x86_64" ;;
        win32-x86_64)         echo "windows-x86_64" ;;
        *)                    echo "linux-x86_64" ;;
    esac
}

function do_copy() {
    echo -e "[ do_copy ]"
    mkdir -p "$VKIT_PREBUILT_DIR"/{bin,lib,etc}
    if [ -n "$VKIT_PLATFORM_DEPLOY_DIR" ] && [ -d "$VKIT_PLATFORM_DEPLOY_DIR" ]; then
        cp -rf "$VKIT_PLATFORM_DEPLOY_DIR"/* "$VKIT_PREBUILT_DIR/"
    fi
    if [ -n "$VKIT_SETUP_DIR" ] && [ -d "$VKIT_SETUP_DIR" ]; then
        cp -rf "$VKIT_SETUP_DIR"/* "$VKIT_PREBUILT_DIR/etc/"
    fi
    if [ "$VKIT_PLATFORM" = "qnx-aarch64" ]; then
        cp -rf "$QNX_TARGET"/aarch64le/usr/lib/libsqlite3.so* "$VKIT_PREBUILT_DIR/lib/"
        cp -rf "$QNX_TARGET"/aarch64le/usr/lib/libicui18n.so* "$VKIT_PREBUILT_DIR/lib/"
        cp -rf "$QNX_TARGET"/aarch64le/usr/lib/libicuuc.so*  "$VKIT_PREBUILT_DIR/lib/"
        cp -rf "$QNX_TARGET"/aarch64le/usr/lib/libicudata.so* "$VKIT_PREBUILT_DIR/lib/"
        rm -rf "$VKIT_PREBUILT_DIR"/lib/*.sym
    elif [ "$VKIT_PLATFORM" = "qnx-x86_64" ]; then
        cp -rf "$QNX_TARGET"/x86_64/usr/lib/libsqlite3.so* "$VKIT_PREBUILT_DIR/lib/"
        cp -rf "$QNX_TARGET"/x86_64/usr/lib/libicui18n.so* "$VKIT_PREBUILT_DIR/lib/"
        cp -rf "$QNX_TARGET"/x86_64/usr/lib/libicuuc.so*  "$VKIT_PREBUILT_DIR/lib/"
        cp -rf "$QNX_TARGET"/x86_64/usr/lib/libicudata.so* "$VKIT_PREBUILT_DIR/lib/"
        rm -rf "$VKIT_PREBUILT_DIR"/lib/*.sym
    elif [ "$VKIT_PLATFORM" = "android-aarch64" ]; then
        local _ndk_host; _ndk_host="$(_ndk_host_tag)"
        cp -rf "$ANDROID_NDK/toolchains/llvm/prebuilt/$_ndk_host/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" \
            "$VKIT_PREBUILT_DIR/lib/"
    elif [ "$VKIT_PLATFORM" = "android-x86_64" ]; then
        local _ndk_host; _ndk_host="$(_ndk_host_tag)"
        cp -rf "$ANDROID_NDK/toolchains/llvm/prebuilt/$_ndk_host/sysroot/usr/lib/x86_64-linux-android/libc++_shared.so" \
            "$VKIT_PREBUILT_DIR/lib/"
    fi
    [ -f "$VKIT_PREBUILT_PRIVATE_DIR/bin/iox-roudi" ] && cp -rf "$VKIT_PREBUILT_PRIVATE_DIR/bin/iox-roudi" "$VKIT_PREBUILT_DIR/bin/"
    [ -f "$VKIT_PREBUILT_PRIVATE_DIR/bin/iox-introspection-client" ] && cp -rf "$VKIT_PREBUILT_PRIVATE_DIR/bin/iox-introspection-client" "$VKIT_PREBUILT_DIR/bin/"
    [ -L "$VKIT_PREBUILT_PRIVATE_DIR/bin/fast-discovery-server" ] && cp -rf "$VKIT_PREBUILT_PRIVATE_DIR"/bin/fast-discovery-server-* "$VKIT_PREBUILT_DIR/bin/fast-discovery-server"
}
