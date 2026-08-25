#!/bin/bash
# ============================================================
#  mask-tool 启动脚本 (macOS)
#  用法：双击 start-mac.command，或在终端中运行
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f "pyproject.toml" ]; then
    echo "错误：请在 mask-tool 项目目录中运行此脚本"
    read -p "按回车键退出..."
    exit 1
fi

# 优先使用项目虚拟环境
if [ -f ".venv/bin/activate" ]; then
    # shellcheck source=/dev/null
    source .venv/bin/activate
elif [ -f "venv/bin/activate" ]; then
    # shellcheck source=/dev/null
    source venv/bin/activate
else
    echo "未找到虚拟环境（.venv）。请先运行 install-mac.command 完成安装。"
    read -p "按回车键退出..."
    exit 1
fi

# 确保用户词库存在
if [ ! -f "config/lexicon.yaml" ] && [ -f "config/sample_lexicon.yaml" ]; then
    cp "config/sample_lexicon.yaml" "config/lexicon.yaml"
fi

mkdir -p "$HOME/.mask-tool"

PORT=8501
URL="http://localhost:${PORT}"

echo ""
echo "正在启动 mask-tool Web 界面..."
echo "浏览器将打开 ${URL}"
echo "关闭此终端窗口即可停止服务"
echo ""

# 优先使用入口命令，回退到 streamlit 模块
if command -v mask-tool-web >/dev/null 2>&1; then
    exec mask-tool-web --server.port "$PORT"
elif python -c "import streamlit" >/dev/null 2>&1; then
    exec python -m streamlit run src/mask_tool/web/app.py --server.port "$PORT"
else
    echo "错误：未找到 mask-tool-web / streamlit。"
    echo "请重新运行 install-mac.command 安装依赖。"
    read -p "按回车键退出..."
    exit 1
fi
