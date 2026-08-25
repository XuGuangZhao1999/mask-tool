#!/bin/bash
# ============================================================
#  mask-tool 一键安装脚本 (macOS)
#  用法：双击 install-mac.command 或在终端中运行
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "============================================"
echo "   mask-tool 文件脱敏工具 - 安装程序"
echo "============================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 1. 检查 Python 3.9+
echo "📦 [1/4] 检查 Python..."
if command -v python3 >/dev/null 2>&1; then
    PYTHON=python3
elif command -v python >/dev/null 2>&1; then
    PYTHON=python
else
    echo -e "  ${RED}✗${NC} 未找到 Python"
    echo ""
    echo "  请先安装 Python 3.9+："
    echo "  1. 访问 https://www.python.org/downloads/"
    echo "  2. 下载 macOS 安装包并安装"
    echo "  3. 重新运行此脚本"
    echo ""
    read -p "按回车键退出..."
    exit 1
fi

PY_VERSION="$($PYTHON --version 2>&1)"
PY_MAJOR="$($PYTHON -c 'import sys; print(sys.version_info.major)')"
PY_MINOR="$($PYTHON -c 'import sys; print(sys.version_info.minor)')"

if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 9 ]; }; then
    echo -e "  ${RED}✗${NC} Python 版本过低（需要 3.9+，当前 ${PY_MAJOR}.${PY_MINOR}）"
    read -p "按回车键退出..."
    exit 1
fi
echo -e "  ${GREEN}✓${NC} 找到 $PY_VERSION"

# 2. 创建虚拟环境
echo ""
echo "📦 [2/4] 创建虚拟环境..."
if [ -d ".venv" ]; then
    echo -e "  ${YELLOW}!${NC} 虚拟环境已存在，跳过创建"
else
    $PYTHON -m venv .venv
    echo -e "  ${GREEN}✓${NC} 虚拟环境创建成功"
fi

# shellcheck source=/dev/null
source .venv/bin/activate

# 3. 安装依赖
echo ""
echo "📦 [3/4] 安装依赖（可能需要几分钟）..."
pip install --upgrade pip --quiet || true
if pip install -e ".[web]" --quiet; then
    echo -e "  ${GREEN}✓${NC} 依赖安装成功"
else
    echo -e "  ${YELLOW}!${NC} 静默安装失败，正在显示错误并重试..."
    pip install -e ".[web]"
    echo -e "  ${GREEN}✓${NC} 依赖安装成功"
fi

# 验证入口可用
if ! command -v mask-tool-web >/dev/null 2>&1; then
    echo -e "  ${RED}✗${NC} 安装后未找到 mask-tool-web 命令"
    read -p "按回车键退出..."
    exit 1
fi
echo -e "  ${GREEN}✓${NC} 已注册命令：mask-tool / mask-tool-web"

# 4. 初始化配置
echo ""
echo "📦 [4/4] 初始化配置..."
if [ ! -f "config/lexicon.yaml" ] && [ -f "config/sample_lexicon.yaml" ]; then
    cp config/sample_lexicon.yaml config/lexicon.yaml
    echo -e "  ${GREEN}✓${NC} 已创建用户词库 config/lexicon.yaml"
else
    echo -e "  ${GREEN}✓${NC} 配置已就绪"
fi

mkdir -p "$HOME/.mask-tool"
chmod +x "$SCRIPT_DIR/start-mac.command" "$SCRIPT_DIR/install-mac.command" 2>/dev/null || true

# 桌面快捷方式：写入项目绝对路径，避免搜索失败
echo ""
echo "🚀 创建桌面快捷方式..."
DESKTOP_DIR="$HOME/Desktop"
if [ ! -d "$DESKTOP_DIR" ] && [ -d "$HOME/桌面" ]; then
    DESKTOP_DIR="$HOME/桌面"
fi

if [ -d "$DESKTOP_DIR" ]; then
    START_SCRIPT="$DESKTOP_DIR/mask-tool启动.command"
    cat > "$START_SCRIPT" << EOF
#!/bin/bash
# 由 install-mac.command 生成，指向项目目录
cd "$SCRIPT_DIR" || {
    echo "错误：找不到项目目录：$SCRIPT_DIR"
    read -p "按回车键退出..."
    exit 1
}
exec ./start-mac.command
EOF
    chmod +x "$START_SCRIPT"
    echo -e "  ${GREEN}✓${NC} 桌面快捷方式已创建：$START_SCRIPT"
else
    echo -e "  ${YELLOW}!${NC} 未找到桌面目录，请直接双击项目内的 start-mac.command"
fi

echo ""
echo "============================================"
echo -e "  ${GREEN}✅ 安装完成！${NC}"
echo "============================================"
echo ""
echo "  使用方式："
echo "  1. 双击桌面上的「mask-tool启动.command」"
echo "     或双击项目内的 start-mac.command"
echo "  2. 浏览器会自动打开 http://localhost:8501"
echo "  3. 关闭终端窗口即可停止服务"
echo ""
echo "  CLI 示例："
echo "    source .venv/bin/activate"
echo "    mask-tool --help"
echo ""
echo "  如需卸载，删除项目文件夹即可。"
echo ""
read -p "按回车键退出..."
