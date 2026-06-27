@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "VSLANG=1033"
set "DOTNET_CLI_UI_LANGUAGE=en"

set "VKIT_ROOT_DIR=%~dp0"
if "%VKIT_ROOT_DIR:~-1%"=="\" set "VKIT_ROOT_DIR=%VKIT_ROOT_DIR:~0,-1%"
set "VKIT_HOST_OS=win32"
set "VKIT_HOST_TYPE="
set "VKIT_HOST_ARCH=x86_64"
set "VKIT_HOST_PLATFORM=%VKIT_HOST_OS%-%VKIT_HOST_ARCH%"
set "VKIT_PLATFORM=%VKIT_HOST_PLATFORM%"
set "VKIT_DEVICE_PLATFORM=%VKIT_PLATFORM%"
set "VKIT_PLATFORM_CONFIG_DIR="
if exist "%VKIT_ROOT_DIR%\config\%VKIT_DEVICE_PLATFORM%" (
    set "VKIT_PLATFORM_CONFIG_DIR=%VKIT_ROOT_DIR%\config\%VKIT_DEVICE_PLATFORM%"
) else if exist "%VKIT_ROOT_DIR%\config\%VKIT_PLATFORM%" (
    set "VKIT_PLATFORM_CONFIG_DIR=%VKIT_ROOT_DIR%\config\%VKIT_PLATFORM%"
)
set "VKIT_PLATFORM_DEPLOY_DIR="
if exist "%VKIT_ROOT_DIR%\deploy\%VKIT_DEVICE_PLATFORM%" (
    set "VKIT_PLATFORM_DEPLOY_DIR=%VKIT_ROOT_DIR%\deploy\%VKIT_DEVICE_PLATFORM%"
) else if exist "%VKIT_ROOT_DIR%\deploy\%VKIT_PLATFORM%" (
    set "VKIT_PLATFORM_DEPLOY_DIR=%VKIT_ROOT_DIR%\deploy\%VKIT_PLATFORM%"
)
if not defined VKIT_PLATFORM_CONFIG_DIR (
    echo Error: Can not find platform config!
    exit /b 1
)
set "VKIT_HOST_TOOL_DIR=%VKIT_ROOT_DIR%\tools\%VKIT_HOST_PLATFORM%"
set "VKIT_BUILD_DIR=%VKIT_ROOT_DIR%\build\%VKIT_DEVICE_PLATFORM%"
set "VKIT_PREBUILT_DIR=%VKIT_ROOT_DIR%\prebuilt\%VKIT_DEVICE_PLATFORM%"
set "VKIT_PREBUILT_PRIVATE_DIR=%VKIT_ROOT_DIR%\prebuilt-private\%VKIT_DEVICE_PLATFORM%"
set "VKIT_PACKUP_DIR=%VKIT_ROOT_DIR%\packup\%VKIT_DEVICE_PLATFORM%"
set "VKIT_ETC_DIR=%VKIT_PREBUILT_DIR%\etc"
set "VKIT_CODE_COMPLETE_DIR=%VKIT_ETC_DIR%\vkit-completions"
set "VKIT_VCS_TOOL=ripvcs"
set "CMAKE_TOOLCHAIN_FILE=%VKIT_ROOT_DIR%\cmake\toolchain.cmake"
set "CMAKE_INSTALL_PREFIX=%VKIT_PREBUILT_DIR%"

set "VLINK_ROOT_DIR=%VKIT_PREBUILT_DIR%"
set "VLINK_ETC_DIR=%VKIT_ETC_DIR%"

call :_prepend_path "%VKIT_HOST_TOOL_DIR%\bin"
where /q %VKIT_VCS_TOOL%
if errorlevel 1 (
    set "VKIT_VCS_TOOL=vcs"
)
if exist "%VKIT_ROOT_DIR%\build" (
    if not exist "%VKIT_BUILD_DIR%" mkdir "%VKIT_BUILD_DIR%"
)
if exist "%VKIT_ROOT_DIR%\prebuilt" (
    if not exist "%VKIT_PREBUILT_DIR%" mkdir "%VKIT_PREBUILT_DIR%"
)
if exist "%VKIT_ROOT_DIR%\prebuilt-private" (
    if not exist "%VKIT_PREBUILT_PRIVATE_DIR%" mkdir "%VKIT_PREBUILT_PRIVATE_DIR%"
)
if exist "%VKIT_ROOT_DIR%\middleware\vmsgs\schemas" (
    if not defined VLINK_PROTO_DIR set "VLINK_PROTO_DIR=%VKIT_ROOT_DIR%\middleware\vmsgs\schemas"
    if not defined VLINK_FBS_DIR set "VLINK_FBS_DIR=%VKIT_ROOT_DIR%\middleware\vmsgs\schemas"
    set "VLINK_SCHEMA_PLUGIN=vmsgs"
)

if not defined VKIT_BUILD_CPU_CORE (
    set "VKIT_BUILD_CPU_CORE=%NUMBER_OF_PROCESSORS%"
)
set "MAKEFLAGS="
set "MAKELEVEL="
set "USER_ARGS="
set "__cache_mm_project="
set "__cache_mm_dir="
set "__cache_mmm_cfg="

if "%~1"=="" (
    cls
    echo Setup VKIT build environment...
    echo +--------------------------------------+
    echo ^|  _    __   __      _           __    ^|
    echo ^| ^| ^|  / /  / /     ^(_^) ____    / /__  ^|
    echo ^| ^| ^| / /  / /     / / / __ \  / //_ / ^|
    echo ^| ^| ^|/ /  / /___  / / / / / / / ,^<     ^|
    echo ^| ^|___/  /_____/ /_/ /_/ /_/ /_/^|_^|    ^|
    echo ^|                                      ^|
    echo +--------------------------------------+
    echo Platform: %VKIT_PLATFORM%
    echo Device: %VKIT_DEVICE%
    echo.
    echo Note: You can run the following command:
    echo       mmm            Build a component with config compile flags
    echo       mm             [ "-D{CMAKE_FLAG}" ^| clean ]   "Build a component"
    echo       mm_thirdparty  [ "-D{CMAKE_FLAG}" ^| clean ]   "Build thirdparty"
    echo       mm_vendor      [ "-D{CMAKE_FLAG}" ^| clean ]   "Build vendor"
    echo       mm_middleware  [ "-D{CMAKE_FLAG}" ^| clean ]   "Build middleware"
    echo       mm_app         [ "-D{CMAKE_FLAG}" ^| clean ]   "Build app"
    echo       mm_all         [ "-D{CMAKE_FLAG}" ^| clean ]   "Build ALL"
    echo.

    if /I "%VKIT_PLATFORM%"=="%VKIT_HOST_PLATFORM%" (
        call :_prepend_path "%VKIT_PREBUILT_DIR%\bin"
        endlocal & set "PATH=%PATH%"
        if exist "%VKIT_CODE_COMPLETE_DIR%" (
            for %%F in ("%VKIT_CODE_COMPLETE_DIR%\*.cmd") do (
                if exist "%%~fF" call "%%~fF"
            )
        )
    )
    doskey mm=call "%~f0" :mm $*
    doskey mmm=call "%~f0" :mmm $*
    doskey llcfg=call "%~f0" :llcfg $*
    doskey mm_thirdparty=call "%~f0" :mm_thirdparty $*
    doskey mm_vendor=call "%~f0" :mm_vendor $*
    doskey mm_middleware=call "%~f0" :mm_middleware $*
    doskey mm_app=call "%~f0" :mm_app $*
    doskey mm_all=call "%~f0" :mm_all $*
    exit /b 0
) else (
    set "ALL_ARGS=%*"
    if defined ALL_ARGS (
        for /f "tokens=1* delims= " %%a in ("!ALL_ARGS!") do (
            set "ALL_ARGS=%%b"
        )
    )
    if defined ALL_ARGS (
        :loop
        for /f "tokens=1* delims= " %%a in ("!ALL_ARGS!") do (
            set "USER_ARGS=!USER_ARGS! %%a"
            set "ALL_ARGS=%%b"
        )
        if defined ALL_ARGS goto loop
    )
    if /I "%~1"==":mm" (
        call :mm !USER_ARGS!
        exit /b %ERRORLEVEL%
    )
    if /I "%~1"==":mmm" (
        call :mmm !USER_ARGS!
        exit /b %ERRORLEVEL%
    )
    if /I "%~1"==":llcfg" (
        call :llcfg !USER_ARGS!
        exit /b %ERRORLEVEL%
    )
    if /I "%~1"==":mm_thirdparty" (
        call :mm_thirdparty !USER_ARGS!
        exit /b %ERRORLEVEL%
    )
    if /I "%~1"==":mm_vendor" (
        call :mm_vendor !USER_ARGS!
        exit /b %ERRORLEVEL%
    )
    if /I "%~1"==":mm_middleware" (
        call :mm_middleware !USER_ARGS!
        exit /b %ERRORLEVEL%
    )
    if /I "%~1"==":mm_app" (
        call :mm_app !USER_ARGS!
        exit /b %ERRORLEVEL%
    )
    if /I "%~1"==":mm_all" (
        call :mm_all !USER_ARGS!
        exit /b %ERRORLEVEL%
    )
    if /I "%~1"=="import" (
        call :_require_tool git-lfs "Warning: git-lfs is not installed."
        call :_require_tool %VKIT_VCS_TOOL% "Error: Can not find %VKIT_VCS_TOOL% command!"
        if errorlevel 1 exit /b 1
        if not exist "%VKIT_ROOT_DIR%\repos\%~2" (
            echo Error: Can not find repo [%VKIT_ROOT_DIR%\repos\%~2]!
            exit /b 1
        )
        echo Please wait...
        call :_import_repo "%VKIT_ROOT_DIR%\repos\%~2\setup.repos"
        call :_import_repo "%VKIT_ROOT_DIR%\repos\%~2\prebuilt.repos" --shallow
        call :_import_repo "%VKIT_ROOT_DIR%\repos\%~2\thirdparty.repos" --shallow
        call :_import_repo "%VKIT_ROOT_DIR%\repos\%~2\vendor.repos"
        call :_import_repo "%VKIT_ROOT_DIR%\repos\%~2\middleware.repos"
        call :_import_repo "%VKIT_ROOT_DIR%\repos\%~2\app.repos"
        exit /b 0
    )
    if /I "%~1"=="import_dev" (
        call :_require_tool git-lfs "Warning: git-lfs is not installed."
        call :_require_tool %VKIT_VCS_TOOL% "Error: Can not find %VKIT_VCS_TOOL% command!"
        if errorlevel 1 exit /b 1
        if not exist "%VKIT_ROOT_DIR%\repos\dev" (
            echo Error: Can not find repo [%VKIT_ROOT_DIR%\repos\dev]!
            exit /b 1
        )
        echo Please wait...
        call :_import_repo "%VKIT_ROOT_DIR%\repos\dev\setup.repos"
        call :_import_repo "%VKIT_ROOT_DIR%\repos\dev\prebuilt.repos" --shallow
        call :_import_repo "%VKIT_ROOT_DIR%\repos\dev\thirdparty.repos" --shallow
        call :_import_repo "%VKIT_ROOT_DIR%\repos\dev\vendor.repos"
        call :_import_repo "%VKIT_ROOT_DIR%\repos\dev\middleware.repos"
        call :_import_repo "%VKIT_ROOT_DIR%\repos\dev\app.repos"
        exit /b 0
    )
    if /I "%~1"=="import_full" (
        call :_require_tool git-lfs "Warning: git-lfs is not installed."
        call :_require_tool %VKIT_VCS_TOOL% "Error: Can not find %VKIT_VCS_TOOL% command!"
        if errorlevel 1 exit /b 1
        if not exist "%VKIT_ROOT_DIR%\repos\full" (
            echo Error: Can not find repo [%VKIT_ROOT_DIR%\repos\full]!
            exit /b 1
        )
        echo Please wait...
        call :_import_repo "%VKIT_ROOT_DIR%\repos\full\setup.repos"
        call :_import_repo "%VKIT_ROOT_DIR%\repos\full\prebuilt.repos" --shallow
        call :_import_repo "%VKIT_ROOT_DIR%\repos\full\thirdparty.repos" --shallow
        call :_import_repo "%VKIT_ROOT_DIR%\repos\full\vendor.repos"
        call :_import_repo "%VKIT_ROOT_DIR%\repos\full\middleware.repos"
        call :_import_repo "%VKIT_ROOT_DIR%\repos\full\app.repos"
        exit /b 0
    )
    if /I "%~1"=="pull" (
        call :_require_tool git-lfs "Warning: git-lfs is not installed."
        call :_require_tool %VKIT_VCS_TOOL% "Error: Can not find %VKIT_VCS_TOOL% command!"
        if errorlevel 1 exit /b 1
        echo Please wait...
        set "_pull_list=%VKIT_ROOT_DIR%"
        if exist "%VKIT_ROOT_DIR%\setup" set "_pull_list=!_pull_list! %VKIT_ROOT_DIR%\setup"
        if exist "%VKIT_ROOT_DIR%\prebuilt" set "_pull_list=!_pull_list! %VKIT_ROOT_DIR%\prebuilt"
        if exist "%VKIT_ROOT_DIR%\prebuilt-private" set "_pull_list=!_pull_list! %VKIT_ROOT_DIR%\prebuilt-private"
        if exist "%VKIT_ROOT_DIR%\thirdparty" set "_pull_list=!_pull_list! %VKIT_ROOT_DIR%\thirdparty"
        if exist "%VKIT_ROOT_DIR%\vendor" set "_pull_list=!_pull_list! %VKIT_ROOT_DIR%\vendor"
        if exist "%VKIT_ROOT_DIR%\middleware" set "_pull_list=!_pull_list! %VKIT_ROOT_DIR%\middleware"
        if exist "%VKIT_ROOT_DIR%\app" set "_pull_list=!_pull_list! %VKIT_ROOT_DIR%\app"
        %VKIT_VCS_TOOL% pull !_pull_list!
        set "_pull_list="
        exit /b 0
    )
    if /I "%~1"=="install" (
        call :mm_all
        exit /b %ERRORLEVEL%
    )
    if /I "%~1"=="clean" (
        call :mm_all clean
        exit /b %ERRORLEVEL%
    )
    if /I "%~1"=="rclean" (
        if exist "%VKIT_BUILD_DIR%" rmdir /s /q "%VKIT_BUILD_DIR%"
        if exist "%VKIT_PACKUP_DIR%" rmdir /s /q "%VKIT_PACKUP_DIR%"
        if exist "%VKIT_ROOT_DIR%\prebuilt\.git" (
            if exist "%VKIT_PREBUILT_DIR%" (
                pushd "%VKIT_PREBUILT_DIR%"
                git clean -fdx .
                git checkout HEAD .
                popd
            ) else if exist "%VKIT_ROOT_DIR%\prebuilt" (
                pushd "%VKIT_ROOT_DIR%\prebuilt"
                git checkout HEAD "%VKIT_DEVICE_PLATFORM%"
                popd
            )
        ) else (
            if exist "%VKIT_PREBUILT_DIR%" rmdir /s /q "%VKIT_PREBUILT_DIR%"
        )
        if exist "%VKIT_ROOT_DIR%\prebuilt-private\.git" (
            if exist "%VKIT_PREBUILT_PRIVATE_DIR%" (
                pushd "%VKIT_PREBUILT_PRIVATE_DIR%"
                git clean -fdx .
                git checkout HEAD .
                popd
            ) else if exist "%VKIT_ROOT_DIR%\prebuilt-private" (
                pushd "%VKIT_ROOT_DIR%\prebuilt-private"
                git checkout HEAD "%VKIT_DEVICE_PLATFORM%"
                popd
            )
        ) else (
            if exist "%VKIT_PREBUILT_PRIVATE_DIR%" rmdir /s /q "%VKIT_PREBUILT_PRIVATE_DIR%"
        )
        exit /b 0
    )
    if /I "%~1"=="dclean" (
        if exist "%VKIT_PREBUILT_DIR%" rmdir /s /q "%VKIT_PREBUILT_DIR%"
        if exist "%VKIT_PREBUILT_PRIVATE_DIR%" rmdir /s /q "%VKIT_PREBUILT_PRIVATE_DIR%"
        if exist "%VKIT_BUILD_DIR%" rmdir /s /q "%VKIT_BUILD_DIR%"
        if exist "%VKIT_PACKUP_DIR%" rmdir /s /q "%VKIT_PACKUP_DIR%"
        exit /b 0
    )
    if /I "%~1"=="aclean" (
        if exist "%VKIT_ROOT_DIR%\build" rmdir /s /q "%VKIT_ROOT_DIR%\build"
        if exist "%VKIT_ROOT_DIR%\prebuilt" rmdir /s /q "%VKIT_ROOT_DIR%\prebuilt"
        if exist "%VKIT_ROOT_DIR%\prebuilt-private" rmdir /s /q "%VKIT_ROOT_DIR%\prebuilt-private"
        if exist "%VKIT_ROOT_DIR%\packup" rmdir /s /q "%VKIT_ROOT_DIR%\packup"
        exit /b 0
    )
    if /I "%~1"=="deploy" (
        if exist "%VKIT_ROOT_DIR%\deploy\vkit-deploy.cmd" (
            call "%VKIT_ROOT_DIR%\deploy\vkit-deploy.cmd"
            exit /b %ERRORLEVEL%
        ) else if exist "%VKIT_ROOT_DIR%\deploy\vkit-deploy.bat" (
            call "%VKIT_ROOT_DIR%\deploy\vkit-deploy.bat"
            exit /b %ERRORLEVEL%
        ) else (
            echo.
            echo Skip deploy.
            exit /b 0
        )
    )
)

:llcfg
set "_PWD=%CD%"
call :_mmm_ll_cfg "%_PWD%" _CFG_FOUND _CFG_FLAGS
if not "%_CFG_FOUND%"=="1" (
    echo Error: Can not find cfg [%_PWD%]!
    exit /b 1
)
set "_PRINT_FLAGS=%_CFG_FLAGS%"
set "_PRINT_FLAGS=%_PRINT_FLAGS:  = %"
echo mm %_PRINT_FLAGS%
exit /b 0

:mm_thirdparty
set "_MM_USER_ARGS=%*"
call :_mm_for_cfg "%VKIT_PLATFORM_CONFIG_DIR%\thirdparty.cfg" %*
exit /b %ERRORLEVEL%

:mm_vendor
set "_MM_USER_ARGS=%*"
call :_mm_for_cfg "%VKIT_PLATFORM_CONFIG_DIR%\vendor.cfg" %*
exit /b %ERRORLEVEL%

:mm_middleware
set "_MM_USER_ARGS=%*"
if /I not "%~1"=="clean" if /I "%VKIT_MIDDLEWARE_RELWITHDEBINFO%"=="1" set "_MM_USER_ARGS=%* -DCMAKE_BUILD_TYPE=RelWithDebInfo"
call :_mm_for_cfg "%VKIT_PLATFORM_CONFIG_DIR%\middleware.cfg" %*
exit /b %ERRORLEVEL%

:mm_app
set "_MM_USER_ARGS=%*"
if /I not "%~1"=="clean" if /I "%VKIT_APP_RELWITHDEBINFO%"=="1" set "_MM_USER_ARGS=%* -DCMAKE_BUILD_TYPE=RelWithDebInfo"
call :_mm_for_cfg "%VKIT_PLATFORM_CONFIG_DIR%\app.cfg" %*
exit /b %ERRORLEVEL%

:mm_all
set "_MM_USER_ARGS=%*"
set "_HAS_COMPONENT=0"
if exist "%VKIT_PLATFORM_CONFIG_DIR%\thirdparty.cfg" (
    set "_HAS_COMPONENT=1"
    call :mm_thirdparty %*
    if errorlevel 1 exit /b 1
)
if exist "%VKIT_PLATFORM_CONFIG_DIR%\vendor.cfg" (
    set "_HAS_COMPONENT=1"
    call :mm_vendor %*
    if errorlevel 1 exit /b 1
)
if exist "%VKIT_PLATFORM_CONFIG_DIR%\middleware.cfg" (
    set "_HAS_COMPONENT=1"
    call :mm_middleware %*
    if errorlevel 1 exit /b 1
)
if exist "%VKIT_PLATFORM_CONFIG_DIR%\app.cfg" (
    set "_HAS_COMPONENT=1"
    call :mm_app %*
    if errorlevel 1 exit /b 1
)
if /I "!_HAS_COMPONENT!"=="0" (
    echo Error: Can not find any project to build!
    exit /b 1
)
exit /b 0

:mm
if /I "%~1"=="-h"  goto :mm_help
if /I "%~1"=="--help" goto :mm_help
set "__cache_mm_project=%__cache_mm_project%"
set "__cache_mm_dir=%__cache_mm_dir%"
if defined __cache_mm_dir (
    set "_project_dir=%__cache_mm_dir%"
) else (
    set "_project_dir=%CD%"
)
if defined __cache_mm_project (
    set "_project=!__cache_mm_project!"
) else if /i not "!_project_dir:%VKIT_ROOT_DIR%\=!"=="!_project_dir!" (
    set "_project=!_project_dir:%VKIT_ROOT_DIR%\=!"
) else (
    for %%i in ("!_project_dir!") do set "_project=%%~nxi"
)
set "_build_type="
if exist "%_project_dir%\CMakeLists.txt" (
    set "_build_type=cmake"
) else if exist "%_project_dir%\cmake\CMakeLists.txt" (
    set "_build_type=cmake"
    set "_project_dir=%_project_dir%\cmake"
) else if exist "%_project_dir%\build.cmd" (
    set "_build_type=script"
) else if exist "%_project_dir%\build.bat" (
    set "_build_type=script"
) else if exist "%_project_dir%\Makefile" (
    set "_build_type=make"
    if /I "%CD%"=="%VKIT_ROOT_DIR%" (
        echo Error: Can not mm project [%_project_dir%]!
        exit /b 1
    )
) else (
    dir /b "%_project_dir%" >nul 2>&1
    if errorlevel 1 (
        echo === Note: Skip [%_project%] ===
        exit /b 0
    )
    echo Error: Can not mm project [%_project_dir%]!
    exit /b 1
)
if /I "%~1"=="clean" (
    if exist "%VKIT_BUILD_DIR%\%_project%" (
        echo === Clean [%_project%] ===
        if /I "%_build_type%"=="make" (
            make -C "%_project_dir%" clean
        )
        rmdir /s /q "%VKIT_BUILD_DIR%\%_project%"
    )
    exit /b 0
) else if /I "%~1"=="dclean" (
    if exist "%VKIT_BUILD_DIR%\%_project%" (
        echo === Clean [%_project%] ===
        if /I "%_build_type%"=="cmake" (
            cmake --build "%VKIT_BUILD_DIR%\%_project%" --target __uninstall
        ) else if /I "%_build_type%"=="make" (
            make -C "%_project_dir%" clean
        )
        rmdir /s /q "%VKIT_BUILD_DIR%\%_project%"
    )
    exit /b 0
)
echo.
echo === Build [%_project%] ===
if /I "%_build_type%"=="cmake" (
    set "_has_target="
    for %%A in (%*) do (
        echo %%~A| findstr /b /c:"--target" >nul && set "_has_target=1"
    )
    if defined _has_target (
        if /I "%VKIT_DEBUG%"=="1" (
            cmake --build "%VKIT_BUILD_DIR%\%_project%" --config Debug -j%VKIT_BUILD_CPU_CORE% %*
        ) else (
            cmake --build "%VKIT_BUILD_DIR%\%_project%" --config Release -j%VKIT_BUILD_CPU_CORE% %*
        )
        if errorlevel 1 goto :mm_fail
        echo.
        exit /b 0
    )
    if not exist "%VKIT_BUILD_DIR%\%_project%\CMakeCache.txt" (
        if not exist "%VKIT_BUILD_DIR%\%_project%" mkdir "%VKIT_BUILD_DIR%\%_project%"
        cmake -S "%_project_dir%" -B "%VKIT_BUILD_DIR%\%_project%" -DCMAKE_TOOLCHAIN_FILE="%CMAKE_TOOLCHAIN_FILE%" %*
        if errorlevel 1 goto :mm_fail
    )
    if /I "%VKIT_DEBUG%"=="1" (
        cmake --build "%VKIT_BUILD_DIR%\%_project%" --config Debug -j%VKIT_BUILD_CPU_CORE%
    ) else (
        cmake --build "%VKIT_BUILD_DIR%\%_project%" --config Release -j%VKIT_BUILD_CPU_CORE%
    )
    if errorlevel 1 goto :mm_fail
    if "%VKIT_STRIP%"=="1" (
        cmake --install "%VKIT_BUILD_DIR%\%_project%" --strip 1>nul
    ) else (
        cmake --install "%VKIT_BUILD_DIR%\%_project%" 1>nul
    )
) else if /I "%_build_type%"=="script" (
    if not exist "%VKIT_BUILD_DIR%\%_project%" mkdir "%VKIT_BUILD_DIR%\%_project%"
    xcopy /e /i /y "%_project_dir%\*" "%VKIT_BUILD_DIR%\%_project%\*" >nul
    if exist "%VKIT_BUILD_DIR%\%_project%\build.cmd" (
        call "%VKIT_BUILD_DIR%\%_project%\build.cmd" %*
    ) else (
        call "%VKIT_BUILD_DIR%\%_project%\build.bat" %*
    )
) else if /I "%_build_type%"=="make" (
    make -C "%_project_dir%" %* -j%VKIT_BUILD_CPU_CORE%
)
if errorlevel 1 goto :mm_fail
echo.
exit /b 0

:mmm
set "_PWD=%CD%"
call :_mmm_ll_cfg "%_PWD%" _CFG_FOUND _CFG_FLAGS
if not "%_CFG_FOUND%"=="1" (
    echo Error: Can not mmm project [%_PWD%]!
    exit /b 1
)
if /I "%~1"=="clean" (
    call :mm clean
) else (
    if "%~1"=="" (
        call :mm %_CFG_FLAGS%
    ) else (
        call :mm %_CFG_FLAGS% %*
    )
)
exit /b %ERRORLEVEL%

:mm_help
echo Usage:
echo        mm
echo        mm "-D{CMAKE_FLAG}"
echo        mm clean
exit /b 0

:mm_fail
echo.
echo === Build [%_project%] failed ===
exit /b 1


:_mm_for_cfg
set "_cfg_path=%~1"
if not exist "%_cfg_path%" (
    echo Error: Path [%_cfg_path%] not exists!
    exit /b 1
)
set "_logical_line="
for /f "usebackq tokens=* delims=" %%L in ("%_cfg_path%") do (
    set "_current_line=%%L"
    if "!_current_line:~-1!" == "\" (
        set "_logical_line=!_logical_line!!_current_line:~0,-1!"
    ) else (
        set "_logical_line=!_logical_line!!_current_line!"
        call :_process_logical_line "!_logical_line!" %*
        if errorlevel 1 (
            exit /b 1
        )
        set "_logical_line="
    )
)
if defined _logical_line (
    if not "!_logical_line!"=="" (
        call :_process_logical_line "!_logical_line!" %*
        if errorlevel 1 (
            exit /b 1
        )
    )
)

exit /b 0

:_process_logical_line
set "_line=%~1"
if not "!_line!"=="" (
    (
        echo !_line! | findstr /r /c:"^[    ]*[#;]" >nul
    ) || (
        echo !_line! | findstr /r /c:"^[    ]*//" >nul
    )
    if errorlevel 1 (
        for /f "tokens=1,2 delims=;" %%A in ("!_line!") do (
            set "_project=%%~A"
            for /f "tokens=* delims= " %%P in ("%%~A") do set "_project=%%P"
            set "_project=!_project:/=\!"
            set "_cfg_arg=%%~B"
            set "__cache_mm_project=!_project!"
            set "__cache_mm_dir=%VKIT_ROOT_DIR%\!_project!"
            if not "!_project!"=="" (
                if exist "!__cache_mm_dir!" (
                    if /I "%~3"=="clean" (
                        call :mm clean
                    ) else (
                        call :mm !_cfg_arg! %_MM_USER_ARGS%
                    )
                    if errorlevel 1 (
                        exit /b 1
                    )
                ) else (
                    echo === Note: Skip [!_project!] ===
                )
            ) else (
                echo Warning: Split line [!_line!] failed!
            )
        )
    )
)
exit /b 0


:_mmm_get_cfg
set "__cache_mmm_cfg="
set "_cfg_path=%~1"
set "_pwd=%~2"
if not exist "%_cfg_path%" (
    exit /b 1
)
set "_logical_line="
for /f "usebackq tokens=* delims=" %%L in ("%_cfg_path%") do (
    set "_current_line=%%L"
    if "!_current_line:~-1!" == "\" (
        set "_logical_line=!_logical_line!!_current_line:~0,-1!"
    ) else (
        set "_logical_line=!_logical_line!!_current_line!"
        call :_mmm_process_logical_line "!_logical_line!" "%_pwd%"
        if not errorlevel 1 (
            exit /b 0
        )
        set "_logical_line="
    )
)
if defined _logical_line (
    if not "!_logical_line!"=="" (
        call :_mmm_process_logical_line "!_logical_line!" "%_pwd%"
        if not errorlevel 1 (
            exit /b 0
        )
    )
)
goto :eof

:_mmm_process_logical_line
setlocal EnableDelayedExpansion
set "_line=%~1"
set "_pwd=%~2"
if not "!_line!"=="" (
    (
                echo !_line! | findstr /r /c:"^[    ]*[#;]" >nul
        ) || (
                echo !_line! | findstr /r /c:"^[    ]*//" >nul
        )
    if errorlevel 1 (
        for /f "tokens=1,2 delims=;" %%A in ("!_line!") do (
            set "_project=%%~A"
            for /f "tokens=* delims= " %%P in ("%%~A") do set "_project=%%P"
            set "_cfg_arg=%%~B"
            set "__cache_mm_project=!_project!"
            set "__cache_mm_dir=%VKIT_ROOT_DIR%\!_project!"
            if not "!_project!"=="" (
                if exist "!__cache_mm_dir!" (
                    set "_tail=!_pwd:~-1!"
                    if "!_tail!"=="\" (
                        set "_pwd2=!_pwd:~0,-1!"
                    ) else (
                        set "_pwd2=!_pwd!"
                    )
                    set "_pwd_norm=!_pwd2:\=/!"
                    set "_proj_norm=%VKIT_ROOT_DIR%/!_project:\=/!"
                    set "_proj_norm=!_proj_norm:\=/!"
                    if /I "!_pwd_norm!"=="!_proj_norm!" (
                        endlocal & set "__cache_mmm_cfg=!_cfg_arg!" & exit /b 0
                    )
                )
            )
        )
    )
)
endlocal & exit /b 1

:_mmm_ll_cfg
set "_project_dir=%~1"
set "_skip_app=0"
set "_skip_middleware=0"
set "_skip_vendor=0"
set "_skip_thirdparty=0"
set "__cache_mmm_cfg="
set "_FOUND=0"
call :_starts_with "%_project_dir%" "%VKIT_ROOT_DIR%\app\" && set "_skip_app=1" && call :_mmm_get_cfg "%VKIT_PLATFORM_CONFIG_DIR%\app.cfg" "%_project_dir%" && set "_FOUND=1"
if "%_FOUND%"=="1" set "%~2=%_FOUND%" && set "%~3=%__cache_mmm_cfg%" && exit /b 0
call :_starts_with "%_project_dir%" "%VKIT_ROOT_DIR%\middleware\" && set "_skip_middleware=1" && call :_mmm_get_cfg "%VKIT_PLATFORM_CONFIG_DIR%\middleware.cfg" "%_project_dir%" && set "_FOUND=1"
if "%_FOUND%"=="1" set "%~2=%_FOUND%" && set "%~3=%__cache_mmm_cfg%" && exit /b 0
call :_starts_with "%_project_dir%" "%VKIT_ROOT_DIR%\vendor\" && set "_skip_vendor=1" && call :_mmm_get_cfg "%VKIT_PLATFORM_CONFIG_DIR%\vendor.cfg" "%_project_dir%" && set "_FOUND=1"
if "%_FOUND%"=="1" set "%~2=%_FOUND%" && set "%~3=%__cache_mmm_cfg%" && exit /b 0
call :_starts_with "%_project_dir%" "%VKIT_ROOT_DIR%\thirdparty\" && set "_skip_thirdparty=1" && call :_mmm_get_cfg "%VKIT_PLATFORM_CONFIG_DIR%\thirdparty.cfg" "%_project_dir%" && set "_FOUND=1"
if "%_FOUND%"=="1" set "%~2=%_FOUND%" && set "%~3=%__cache_mmm_cfg%" && exit /b 0
if not "%_skip_app%"=="1" call :_mmm_get_cfg "%VKIT_PLATFORM_CONFIG_DIR%\app.cfg" "%_project_dir%" && set "_FOUND=1"
if "%_FOUND%"=="1" set "%~2=%_FOUND%" && set "%~3=%__cache_mmm_cfg%" && exit /b 0
if not "%_skip_middleware%"=="1" call :_mmm_get_cfg "%VKIT_PLATFORM_CONFIG_DIR%\middleware.cfg" "%_project_dir%" && set "_FOUND=1"
if "%_FOUND%"=="1" set "%~2=%_FOUND%" && set "%~3=%__cache_mmm_cfg%" && exit /b 0
if not "%_skip_vendor%"=="1" call :_mmm_get_cfg "%VKIT_PLATFORM_CONFIG_DIR%\vendor.cfg" "%_project_dir%" && set "_FOUND=1"
if "%_FOUND%"=="1" set "%~2=%_FOUND%" && set "%~3=%__cache_mmm_cfg%" && exit /b 0
if not "%_skip_thirdparty%"=="1" call :_mmm_get_cfg "%VKIT_PLATFORM_CONFIG_DIR%\thirdparty.cfg" "%_project_dir%" && set "_FOUND=1"
if "%_FOUND%"=="1" set "%~2=%_FOUND%" && set "%~3=%__cache_mmm_cfg%" && exit /b 0
exit /b 1

:_import_repo
set "_REPO=%~1"
set "_SHALLOW=%~2"
set "_FILE_EMPTY=1"
if exist "%_REPO%" (
    for %%A in ("%_REPO%") do if not %%~zA==0 set "_FILE_EMPTY=0"
)
if "%_FILE_EMPTY%"=="0" (
    %VKIT_VCS_TOOL% import --input "%_REPO%" --workers %VKIT_BUILD_CPU_CORE% %_SHALLOW%
)
exit /b 0

:_prepend_path
set "_pp=%~1"
if not defined _pp exit /b 0
echo %PATH%| find /I "%_pp%" >nul
if errorlevel 1 (
    set "PATH=%_pp%;%PATH%"
)
exit /b 0

:_starts_with
set "_hay=%~1"
set "_needle=%~2"
if not defined _needle exit /b 0
if not defined _hay exit /b 1
set "_n=!_needle!"
set "_n_len=0"
:_sw_count
if defined _n (
    set "_n=!_n:~1!"
    set /a _n_len+=1
    goto :_sw_count
)
set "_prefix=!_hay:~0,%_n_len%!"
if /I "!_prefix!"=="!_needle!" exit /b 0
exit /b 1

:_require_tool
where /q %~1
if errorlevel 1 (
    echo %~2
    exit /b 1
)
exit /b 0
