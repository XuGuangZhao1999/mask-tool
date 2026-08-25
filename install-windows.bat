@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title mask-tool 文件脱敏工具 - 安装程序

echo.
echo ============================================
echo    mask-tool 文件脱敏工具 - 安装程序
echo ============================================
echo.

:: 获取脚本所在目录
cd /d "%~dp0"
set "PROJECT_DIR=%cd%"

:: 1. 检查 Python 3.9+
echo [1/4] 检查 Python...
set "PYTHON="
where python >nul 2>&1
if %errorlevel% equ 0 set "PYTHON=python"
if not defined PYTHON (
    where python3 >nul 2>&1
    if %errorlevel% equ 0 set "PYTHON=python3"
)
if not defined PYTHON (
    echo   [X] 未找到 Python
    echo.
    echo   请先安装 Python 3.9+：
    echo   1. 访问 https://www.python.org/downloads/
    echo   2. 下载 Windows 安装包
    echo   3. 安装时勾选 "Add Python to PATH"
    echo   4. 重新运行此脚本
    echo.
    pause
    exit /b 1
)

%PYTHON% -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo   [X] Python 版本过低（需要 3.9+）
    %PYTHON% --version
    pause
    exit /b 1
)

for /f "tokens=*" %%v in ('%PYTHON% --version 2^>^&1') do set "PY_VER=%%v"
echo   [OK] 找到 %PY_VER%

:: 2. 创建虚拟环境
echo.
echo [2/4] 创建虚拟环境...
if exist ".venv\Scripts\activate.bat" (
    echo   [!] 虚拟环境已存在，跳过创建
) else (
    %PYTHON% -m venv .venv
    if %errorlevel% neq 0 (
        echo   [X] 虚拟环境创建失败
        pause
        exit /b 1
    )
    echo   [OK] 虚拟环境创建成功
)

call .venv\Scripts\activate.bat

:: 3. 安装依赖
echo.
echo [3/4] 安装依赖（可能需要几分钟）...
python -m pip install --upgrade pip --quiet
python -m pip install -e ".[web]"
if %errorlevel% neq 0 (
    echo   [!] 安装失败，正在重试...
    python -m pip install -e ".[web]"
    if %errorlevel% neq 0 (
        echo   [X] 依赖安装失败
        pause
        exit /b 1
    )
)

where mask-tool-web >nul 2>&1
if %errorlevel% neq 0 (
    echo   [X] 安装后未找到 mask-tool-web 命令
    pause
    exit /b 1
)
echo   [OK] 依赖安装完成（mask-tool / mask-tool-web 可用）

:: 4. 初始化配置
echo.
echo [4/4] 初始化配置...
if not exist "config\lexicon.yaml" (
    if exist "config\sample_lexicon.yaml" (
        copy "config\sample_lexicon.yaml" "config\lexicon.yaml" >nul
        echo   [OK] 已创建用户词库 config\lexicon.yaml
    ) else (
        echo   [!] 未找到示例词库，请稍后手动配置
    )
) else (
    echo   [OK] 配置已就绪
)

if not exist "%USERPROFILE%\.mask-tool" mkdir "%USERPROFILE%\.mask-tool"

:: 桌面快捷方式：写入项目绝对路径，委托给 start-windows.bat
echo.
echo 创建桌面快捷方式...
set "DESKTOP=%USERPROFILE%\Desktop"
if not exist "%DESKTOP%" if exist "%USERPROFILE%\桌面" set "DESKTOP=%USERPROFILE%\桌面"

set "START_SCRIPT=%DESKTOP%\mask-tool启动.bat"
if exist "%DESKTOP%" (
    (
        echo @echo off
        echo chcp 65001 ^>nul 2^>^&1
        echo title mask-tool 文件脱敏工具
        echo cd /d "%PROJECT_DIR%"
        echo if not exist "start-windows.bat" ^(
        echo     echo 错误：找不到项目目录：%PROJECT_DIR%
        echo     pause
        echo     exit /b 1
        echo ^)
        echo call start-windows.bat
    ) > "%START_SCRIPT%"
    echo   [OK] 桌面快捷方式已创建：%START_SCRIPT%
) else (
    echo   [!] 未找到桌面目录，请直接双击项目内的 start-windows.bat
)

echo.
echo ============================================
echo   [OK] 安装完成！
echo ============================================
echo.
echo   使用方式：
echo   1. 双击桌面上的「mask-tool启动.bat」
echo      或双击项目内的 start-windows.bat
echo   2. 浏览器会自动打开 http://localhost:8501
echo   3. 关闭命令行窗口即可停止服务
echo.
echo   CLI 示例：
echo     .venv\Scripts\activate
echo     mask-tool --help
echo.
echo   如需卸载，删除项目文件夹即可。
echo.
pause
endlocal
