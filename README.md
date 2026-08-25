# mask-tool

本地文件脱敏工具（CLI + Web），用于在将文件提交给 AI 或外部系统前进行敏感信息脱敏，并支持后续还原（可逆脱敏）。所有处理均在本地完成，不调用外部 API。

## 特性

- **可逆脱敏**：敏感信息替换为唯一 Token（如 `[COMPANY_001]`），支持反脱敏还原
- **不可逆脱敏**：替换为 `***` 等不可逆形式
- **多格式支持**：Word (`.docx`)、Excel (`.xlsx`)、PowerPoint (`.pptx`)、PDF
- **智能识别**：词典匹配 + 正则规则 + NER（jieba，可选 HanLP）
- **四种运行模式**：`focused` / `strict` / `smart` / `aggressive`
- **双入口**：命令行 (`mask-tool`) 与 Streamlit Web 界面 (`mask-tool-web`)
- **交互确认与词库学习**：确认脱敏项，可将新词写入本地词库
- **本地运行**：处理与映射表均在本机，默认不联网

## 环境要求

- Python 3.9+
- macOS / Windows / Linux

## 快速开始

### 一键安装（推荐）

**macOS**：双击 `install-mac.command`  
**Windows**：双击 `install-windows.bat`

安装完成后：

- macOS：双击 `start-mac.command`，或使用桌面快捷方式
- Windows：双击 `start-windows.bat`

浏览器会打开 `http://localhost:8501`。

### 手动安装

```bash
# 安装（含 Web 依赖）
pip install -e ".[web]"

# 首次使用：生成配置与示例词库（可选）
mask-tool config

# 将示例词库复制为用户词库并按需编辑
cp config/sample_lexicon.yaml config/lexicon.yaml
```

若用户词库 `config/lexicon.yaml` 不存在，安装脚本 / Web 启动时会从 `sample_lexicon.yaml` 自动创建。

### Web 界面

```bash
mask-tool-web
# 或指定端口
mask-tool-web --server.port 8080
# 或
streamlit run src/mask_tool/web/app.py --server.port 8501
```

Web 功能概览：上传文件 → 检测敏感信息 → 交互确认 → 下载脱敏结果与映射表；支持词库管理、历史批次还原。

### CLI

```bash
# 脱敏处理
mask-tool mask input.docx --mode smart --output ./output/

# 查看检测结果（不执行脱敏）
mask-tool inspect input.docx

# 反脱敏（还原原文）
mask-tool unmask masked.docx --mapping mapping.json --output ./restored/

# 交互确认 + 学习新词
mask-tool mask input.docx --confirm --learn

# 不可逆脱敏
mask-tool mask input.docx --irreversible

# 版本
mask-tool version
```

## 运行模式

| 模式 | 说明 |
|------|------|
| `focused` | 仅自动脱敏高置信度词典匹配（≥0.95），其余仅提示 |
| `strict` | 高置信度自动脱敏，中高置信度建议脱敏 |
| `smart`（默认） | 按配置阈值平衡自动 / 建议 / 提示，适合大多数场景 |
| `aggressive` | 降低阈值、高召回，适合 AI 前处理 |

## 脱敏对象

- 公司名称（我方 / 对方 / 关联方）
- 政府机构
- 人名
- 地名
- 项目名称
- 标的物 / 主题
- 金额（支持模糊化，如 `1.2亿` → `1亿+`）
- 自定义关键词

## 配置

| 文件 | 说明 |
|------|------|
| `config/default.yaml` | 模式、阈值、NER、词库/白名单路径等 |
| `config/sample_lexicon.yaml` | 随项目分发的示例词库 |
| `config/lexicon.yaml` | 用户词库（本地使用，通常不提交仓库） |
| `config/whitelist.yaml` | 白名单（匹配项跳过脱敏） |

编辑 `config/default.yaml` 自定义默认行为，或通过 CLI 参数 / Web 侧边栏覆盖。

可选 NER 高精度引擎：

```bash
pip install -e ".[ner-hanlp]"
```

并在 `default.yaml` 中将 `ner.engine` 设为 `hanlp`。

## 项目结构

```
mask-tool/
├── src/mask_tool/
│   ├── cli/              # CLI 入口
│   ├── web/              # Streamlit Web 界面
│   ├── models/           # 配置、检测结果、映射、报告模型
│   ├── core/             # 检测 / 脱敏 / 策略 / 流水线 / NER
│   ├── adapters/         # docx / xlsx / pptx / pdf 适配器
│   ├── store/            # 词库等持久化
│   └── utils/            # 工具函数
├── config/               # 默认配置、词库、白名单
├── tests/                # 测试
├── install-mac.command   # macOS 一键安装
├── install-windows.bat   # Windows 一键安装
├── start-mac.command     # macOS 启动 Web
└── start-windows.bat     # Windows 启动 Web
```

## 开发

```bash
# 安装开发依赖
pip install -e ".[dev]"

# 运行测试
pytest
```

## License

MIT
