@echo off
chcp 65001 >nul 2>&1
title mask-tool 文件脱敏工具

cd /d "%~dp0"

if not exist "pyproject.toml" (
    echo 错误：请在 mask-tool 项目目录中运行此脚本
    pause
    exit /b 1
)

:: 优先使用项目虚拟环境
if exist ".venv\Scripts\activate.bat" (
    call .venv\Scripts\activate.bat
) else if exist "venv\Scripts\activate.bat" (
    call venv\Scripts\activate.bat
) else (
    echo 未找到虚拟环境（.venv）。请先运行 install-windows.bat 完成安装。
    pause
    exit /b 1
)

:: 确保用户词库存在
if not exist "config\lexicon.yaml" (
    if exist "config\sample_lexicon.yaml" (
        copy "config\sample_lexicon.yaml" "config\lexicon.yaml" >nul
    )
)

if not exist "%USERPROFILE%\.mask-tool" mkdir "%USERPROFILE%\.mask-tool"

set PORT=8501
echo.
echo 正在启动 mask-tool Web 界面...
echo 浏览器将打开 http://localhost:%PORT%
echo 关闭此窗口即可停止服务
echo.

where mask-tool-web >nul 2>&1
if %errorlevel% equ 0 (
    mask-tool-web --server.port %PORT%
    goto :after_run
)

python -c "import streamlit" >nul 2>&1
if %errorlevel% equ 0 (
    python -m streamlit run src\mask_tool\web\app.py --server.port %PORT%
    goto :after_run
)

echo 错误：未找到 mask-tool-web / streamlit。
echo 请重新运行 install-windows.bat 安装依赖。
pause
exit /b 1

:after_run
echo.
pause
