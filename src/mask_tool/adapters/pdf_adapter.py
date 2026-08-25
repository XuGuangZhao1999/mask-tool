"""PDF适配器 - 检测敏感信息并写回脱敏后的 PDF"""

from pathlib import Path

from mask_tool.adapters.base import FileAdapter
from mask_tool.models.detection import DetectionStatus
from mask_tool.models.mapping import TokenMapping


class PdfAdapter(FileAdapter):
    """PDF文档适配器：提取文本、检测，并输出脱敏后的 PDF"""

    def supported_extensions(self) -> list[str]:
        return [".pdf"]

    def process(self, input_path: Path, output_dir: Path) -> Path:
        """
        处理PDF文档：
        - 逐页提取文本并检测
        - 按策略生成 Token
        - 写回脱敏后的 PDF
        """
        import pymupdf as fitz

        from mask_tool.core.office_replace import mask_pdf

        if self.masker is None:
            raise RuntimeError("PDF 脱敏需要 Masker")

        doc = fitz.open(str(input_path))
        replace_map: dict[str, str] = {}
        try:
            for page_num in range(len(doc)):
                page = doc[page_num]
                text = page.get_text()
                if not text.strip():
                    continue
                results = self.detector.detect(text, str(input_path))
                for r in results:
                    r.location.page = page_num + 1
                results = self.policy.apply(results)
                for result in results:
                    if result.status not in (
                        DetectionStatus.AUTO_MASK,
                        DetectionStatus.SUGGEST_MASK,
                    ):
                        continue
                    if not result.text or result.text in replace_map:
                        continue
                    if self.masker.irreversible:
                        token = "***"
                    else:
                        token = self.masker.token_gen.generate(
                            result.text, result.text_type
                        )
                        self.masker.mappings.append(TokenMapping(
                            token=token,
                            original=result.text,
                            text_type=result.text_type,
                            confidence=result.confidence,
                        ))
                    replace_map[result.text] = token
        finally:
            doc.close()

        output_dir.mkdir(parents=True, exist_ok=True)
        output_path = output_dir / f"{input_path.stem}_masked.pdf"
        if not replace_map:
            import shutil
            shutil.copy2(input_path, output_path)
            return output_path

        mask_pdf(input_path, output_path, replace_map)
        return output_path
