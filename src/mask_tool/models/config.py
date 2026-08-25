"""配置数据模型"""

from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


def find_config_dir() -> Optional[Path]:
    """定位项目 config/ 目录，不依赖当前工作目录。"""
    names = ("default.yaml", "lexicon.yaml", "sample_lexicon.yaml")

    def is_config(d: Path) -> bool:
        return d.is_dir() and any((d / n).exists() for n in names)

    candidates = []
    cwd = Path.cwd().resolve()
    for p in [cwd, *cwd.parents]:
        candidates.append(p / "config")
        candidates.append(p / "mask-tool-main" / "config")

    here = Path(__file__).resolve()
    for i in range(min(6, len(here.parents))):
        candidates.append(here.parents[i] / "config")
        candidates.append(here.parents[i] / "mask-tool-main" / "config")

    seen = set()
    for d in candidates:
        key = str(d)
        if key in seen:
            continue
        seen.add(key)
        if is_config(d):
            return d
    return None


def resolve_data_path(path_value: str, config_file: Optional[Path] = None) -> str:
    """将配置中的相对路径解析为绝对路径。

    优先相对配置文件所在项目根目录（config/ 的上一级），
    再回退到 find_config_dir()，避免因启动目录不同而读不到词库。
    """
    if not path_value:
        return path_value
    p = Path(path_value)
    if p.is_absolute():
        return str(p)

    candidates = []
    if config_file is not None:
        cfg_file = Path(config_file).resolve()
        project_root = (
            cfg_file.parent.parent
            if cfg_file.parent.name == "config"
            else cfg_file.parent
        )
        candidates.append(project_root / p)
        candidates.append(cfg_file.parent / p.name)

    cfg_dir = find_config_dir()
    if cfg_dir is not None:
        candidates.append(cfg_dir.parent / p)
        candidates.append(cfg_dir / p.name)

    candidates.append(Path.cwd() / p)

    for cand in candidates:
        if cand.exists():
            return str(cand.resolve())

    # 文件尚不存在时，仍返回最可能的目标路径，便于后续创建
    if cfg_dir is not None:
        return str((cfg_dir.parent / p).resolve())
    return str(p)


@dataclass
class Thresholds:
    """置信度阈值配置"""
    auto_mask: float = 0.85
    suggest_mask: float = 0.6


@dataclass
class OCRConfig:
    """OCR配置"""
    enabled: bool = False
    engine: str = "paddleocr"


@dataclass
class NERConfig:
    """NER配置"""
    enabled: bool = False
    engine: str = "hanlp"


@dataclass
class StorageConfig:
    """存储配置"""
    mapping_format: str = "json"
    encrypt_mapping: bool = False


@dataclass
class PerformanceConfig:
    """性能配置"""
    workers: int = 4
    max_file_mb: int = 500


@dataclass
class MaskConfig:
    """全局配置"""
    mode: str = "smart"                          # strict / smart / aggressive
    thresholds: Thresholds = field(default_factory=Thresholds)
    ocr: OCRConfig = field(default_factory=OCRConfig)
    ner: NERConfig = field(default_factory=NERConfig)
    storage: StorageConfig = field(default_factory=StorageConfig)
    performance: PerformanceConfig = field(default_factory=PerformanceConfig)
    lexicon_path: str = "config/sample_lexicon.yaml"
    whitelist_path: str = "config/whitelist.yaml"
    categories: list = field(default_factory=lambda: [
        "company", "government", "person", "project",
        "subject", "location", "amount", "custom",
    ])

    @classmethod
    def from_yaml(cls, path: Path) -> "MaskConfig":
        """从YAML文件加载配置"""
        import yaml
        with open(path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}

        thresholds = Thresholds(**data.get("thresholds", {}))
        ocr = OCRConfig(**data.get("ocr", {}))
        ner = NERConfig(**data.get("ner", {}))
        storage = StorageConfig(**data.get("storage", {}))
        performance = PerformanceConfig(**data.get("performance", {}))

        cfg = cls(
            mode=data.get("mode", "smart"),
            thresholds=thresholds,
            ocr=ocr,
            ner=ner,
            storage=storage,
            performance=performance,
            lexicon_path=data.get("lexicon_path", "config/sample_lexicon.yaml"),
            whitelist_path=data.get("whitelist_path", "config/whitelist.yaml"),
            categories=data.get("categories", cls().categories),
        )
        cfg.resolve_paths(config_file=path)
        return cfg

    def resolve_paths(self, config_file: Optional[Path] = None) -> None:
        """把词库/白名单相对路径解析为绝对路径。"""
        self.lexicon_path = resolve_data_path(self.lexicon_path, config_file)
        self.whitelist_path = resolve_data_path(self.whitelist_path, config_file)
