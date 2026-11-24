"""Genera el DOCX editable a partir del informe Markdown del proyecto."""

from pathlib import Path
import re

from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "informe" / "informe_tecnico.md"
OUTPUT = ROOT / "informe" / "Informe_Tecnico_Farmacia.docx"

NAVY = "17365D"
TEAL = "117C83"
PALE = "EAF2F5"
LIGHT = "F3F6F8"
TEXT = "263238"


def shade(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), fill)
    tc_pr.append(shd)


def set_table_borders(table, color="D9D9D9"):
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.find(qn("w:tblBorders"))
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = qn(f"w:{edge}")
        border = borders.find(tag)
        if border is None:
            border = OxmlElement(f"w:{edge}")
            borders.append(border)
        border.set(qn("w:val"), "single")
        border.set(qn("w:sz"), "4")
        border.set(qn("w:space"), "0")
        border.set(qn("w:color"), color)
    margins = tbl_pr.find(qn("w:tblCellMar"))
    if margins is None:
        margins = OxmlElement("w:tblCellMar")
        tbl_pr.append(margins)
    for edge in ("top", "start", "bottom", "end"):
        item = OxmlElement(f"w:{edge}")
        item.set(qn("w:w"), "100")
        item.set(qn("w:type"), "dxa")
        margins.append(item)


def set_cell_text(cell, text, bold=False, color=TEXT, size=9):
    cell.text = ""
    paragraph = cell.paragraphs[0]
    paragraph.paragraph_format.space_after = Pt(2)
    run = paragraph.add_run(text)
    run.bold = bold
    run.font.name = "Aptos"
    run.font.size = Pt(size)
    run.font.color.rgb = RGBColor.from_string(color)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER


def add_page_field(paragraph):
    run = paragraph.add_run()
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instruction = OxmlElement("w:instrText")
    instruction.set(qn("xml:space"), "preserve")
    instruction.text = " PAGE "
    separate = OxmlElement("w:fldChar")
    separate.set(qn("w:fldCharType"), "separate")
    text = OxmlElement("w:t")
    text.text = "1"
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    for element in (begin, instruction, separate, text, end):
        run._r.append(element)


def clean_inline(text):
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"\1 (\2)", text)
    text = text.replace("**", "").replace("`", "")
    return text.strip()


def add_markdown_table(document, lines):
    rows = [[clean_inline(part.strip()) for part in line.strip().strip("|").split("|")] for line in lines]
    if len(rows) > 1 and all(set(part.replace(":", "").replace("-", "").strip()) == set() for part in rows[1]):
        rows.pop(1)
    width = max(len(row) for row in rows)
    table = document.add_table(rows=0, cols=width)
    table.style = "Table Grid"
    set_table_borders(table)
    for row_index, values in enumerate(rows):
        cells = table.add_row().cells
        for col_index in range(width):
            value = values[col_index] if col_index < len(values) else ""
            if row_index == 0:
                shade(cells[col_index], NAVY)
                set_cell_text(cells[col_index], value, bold=True, color="FFFFFF", size=8.5)
            else:
                if row_index % 2 == 0:
                    shade(cells[col_index], LIGHT)
                set_cell_text(cells[col_index], value, size=8.5)
        row = table.rows[-1]
        row._tr.get_or_add_trPr().append(OxmlElement("w:cantSplit"))
    if table.rows:
        header_marker = OxmlElement("w:tblHeader")
        header_marker.set(qn("w:val"), "true")
        table.rows[0]._tr.get_or_add_trPr().append(header_marker)
    document.add_paragraph().paragraph_format.space_after = Pt(1)


def add_architecture_diagram(document):
    title = document.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = title.add_run("PERSONAL DE SUCURSAL A                     PERSONAL DE SUCURSAL B")
    run.bold = True
    run.font.size = Pt(9)
    run.font.color.rgb = RGBColor.from_string(TEAL)

    table = document.add_table(rows=1, cols=3)
    table.style = "Table Grid"
    set_table_borders(table)
    set_cell_text(table.cell(0, 0), "NODO A\nPostgreSQL 18.6\nPuerto local 5433", bold=True, color=NAVY, size=10)
    shade(table.cell(0, 0), PALE)
    set_cell_text(table.cell(0, 1), "Publicación  ⇄  Suscripción\nReplicación lógica\nOrigen = none", bold=True, color=TEAL, size=9)
    set_cell_text(table.cell(0, 2), "NODO B\nPostgreSQL 18.6\nPuerto local 5434", bold=True, color=NAVY, size=10)
    shade(table.cell(0, 2), PALE)

    caption = document.add_paragraph()
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    caption.paragraph_format.space_after = Pt(1)
    run = caption.add_run("pgAdmin 4 administra ambos nodos; no ejecuta la replicación.")
    run.italic = True
    run.font.size = Pt(9)


def add_body_paragraph(document, text, style=None):
    paragraph = document.add_paragraph(style=style)
    paragraph.paragraph_format.space_after = Pt(6)
    paragraph.paragraph_format.line_spacing = 1.08
    paragraph.add_run(clean_inline(text))
    return paragraph


def render_report():
    content = SOURCE.read_text(encoding="utf-8").splitlines()
    document = Document()
    section = document.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.72)
    section.bottom_margin = Inches(0.72)
    section.left_margin = Inches(0.82)
    section.right_margin = Inches(0.82)

    normal = document.styles["Normal"]
    normal.font.name = "Aptos"
    normal.font.size = Pt(10.5)
    normal.font.color.rgb = RGBColor.from_string(TEXT)
    normal.paragraph_format.space_after = Pt(6)
    for name, size in (("Heading 1", 17), ("Heading 2", 13), ("Heading 3", 11)):
        style = document.styles[name]
        style.font.name = "Aptos Display"
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor.from_string("000000")
        style.paragraph_format.space_before = Pt(12)
        style.paragraph_format.space_after = Pt(5)
        style.paragraph_format.keep_with_next = True
    title_style = document.styles["Title"]
    title_style.font.name = "Aptos Display"
    title_style.font.size = Pt(25)
    title_style.font.bold = True
    title_style.font.color.rgb = RGBColor.from_string("000000")
    title_properties = title_style._element.pPr
    if title_properties is not None:
        title_border = title_properties.find(qn("w:pBdr"))
        if title_border is not None:
            title_properties.remove(title_border)

    header = section.header.paragraphs[0]
    header.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    header_run = header.add_run("INFRAESTRUCTURA DE TI  |  SISTEMA DE FARMACIAS")
    header_run.font.name = "Aptos"
    header_run.font.size = Pt(8)
    header_run.font.color.rgb = RGBColor.from_string("000000")
    footer = section.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    footer.add_run("Informe técnico  •  ")
    add_page_field(footer)

    kicker = document.add_paragraph()
    kicker.paragraph_format.space_before = Pt(65)
    kicker.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = kicker.add_run("TRABAJO DE FIN DE SEMESTRE")
    run.bold = True
    run.font.size = Pt(12)
    run.font.color.rgb = RGBColor.from_string("000000")

    title = document.add_paragraph(style="Title")
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title.paragraph_format.space_before = Pt(20)
    title.paragraph_format.space_after = Pt(12)
    run = title.add_run("Replicación bidireccional de PostgreSQL para una cadena de farmacias")
    run.bold = True
    run.font.name = "Aptos Display"
    run.font.size = Pt(25)
    run.font.color.rgb = RGBColor.from_string("000000")

    subtitle = document.add_paragraph()
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = subtitle.add_run("Informe técnico")
    run.font.size = Pt(15)
    run.font.color.rgb = RGBColor.from_string(TEAL)

    document.add_paragraph()
    cover = document.add_table(rows=5, cols=2)
    cover.style = "Table Grid"
    cover_values = [
        ("Curso", "Infraestructura de Tecnología de Información"),
        ("Escuela", "Ingeniería de Sistemas"),
        ("Integrantes", "Completar con los nombres del grupo"),
        ("Docente", "Completar"),
        ("Fecha", "Completar"),
    ]
    for row, (label, value) in zip(cover.rows, cover_values):
        shade(row.cells[0], PALE)
        set_cell_text(row.cells[0], label, bold=True, color=NAVY, size=10)
        set_cell_text(row.cells[1], value, size=10)
    set_table_borders(cover)

    document.add_page_break()

    index = 0
    while index < len(content):
        line = content[index].strip()
        if not line or line.startswith("# ") or line == "## Sistema de replicación para una cadena de farmacias" or line.startswith("**Curso:**") or line.startswith("**Escuela Profesional:**") or line.startswith("**Integrantes:**") or line.startswith("**Docente:**") or line.startswith("**Fecha"):
            index += 1
            continue
        if line.startswith("> "):
            paragraph = document.add_paragraph()
            paragraph.paragraph_format.left_indent = Inches(0.18)
            paragraph.paragraph_format.right_indent = Inches(0.18)
            paragraph.paragraph_format.space_before = Pt(3)
            paragraph.paragraph_format.space_after = Pt(8)
            run = paragraph.add_run(clean_inline(line[2:]))
            run.italic = True
            run.font.size = Pt(9)
            shade_paragraph = OxmlElement("w:shd")
            shade_paragraph.set(qn("w:fill"), PALE)
            paragraph._p.get_or_add_pPr().append(shade_paragraph)
            index += 1
            continue
        if line.startswith("```mermaid"):
            index += 1
            while index < len(content) and not content[index].strip().startswith("```"):
                index += 1
            add_architecture_diagram(document)
            index += 1
            continue
        if line.startswith("```"):
            index += 1
            code = []
            while index < len(content) and not content[index].strip().startswith("```"):
                code.append(content[index])
                index += 1
            paragraph = document.add_paragraph()
            paragraph.paragraph_format.left_indent = Inches(0.16)
            paragraph.paragraph_format.space_after = Pt(7)
            run = paragraph.add_run("\n".join(code))
            run.font.name = "Consolas"
            run.font.size = Pt(8)
            index += 1
            continue
        if line.startswith("|"):
            table_lines = []
            while index < len(content) and content[index].strip().startswith("|"):
                table_lines.append(content[index])
                index += 1
            add_markdown_table(document, table_lines)
            continue
        if line.startswith("### "):
            document.add_heading(clean_inline(line[4:]), level=2)
            index += 1
            continue
        if line.startswith("## "):
            document.add_heading(clean_inline(line[3:]), level=1)
            index += 1
            continue
        if line.startswith("- "):
            add_body_paragraph(document, clean_inline(line[2:]), "List Bullet")
            index += 1
            continue
        if re.match(r"^\d+\. ", line):
            add_body_paragraph(document, re.sub(r"^\d+\. ", "", line), "List Number")
            index += 1
            continue
        add_body_paragraph(document, line)
        index += 1

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    document.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    render_report()
