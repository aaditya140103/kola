#!/usr/bin/env python3
"""Generate sample PDFs and library metadata for the Kola web preview harness.

Creates two small realistic books with fpdf2 and writes site/data/books.json
describing a seeded demo library. The harness renders the PDFs in the browser
with pdf.js, mirroring the Flutter app's reader experience.

Dev-only tool for tool/web_preview; not part of the Kola product.
"""

from __future__ import annotations

import json
import subprocess
import sys
import venv
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SITE = ROOT / "site"
DATA = SITE / "data"
REQUIREMENTS = ("pypdfium2", "fpdf2")

PAGE_W, PAGE_H = 152.64, 228.96  # 6in x 9in, in millimetres (fpdf unit)
M_L, M_R, M_T, M_B = 19, 19, 20, 19
LINE_H = 5.4


def ensure_venv() -> Path:
    venv_dir = ROOT / ".venv"
    if not (venv_dir / "bin" / "python").exists():
        print("Creating virtualenv…")
        venv.create(venv_dir, with_pip=True)
        subprocess.run(
            [str(venv_dir / "bin" / "pip"), "install", "--quiet", *REQUIREMENTS],
            check=True,
        )
    return venv_dir / "bin" / "python"


def latin(text: str) -> str:
    """Map typographic punctuation onto latin-1 (core fonts only)."""
    return (
        text.replace("\u2014", "--")
        .replace("\u2013", "-")
        .replace("\u2018", "'")
        .replace("\u2019", "'")
        .replace("\u201c", '"')
        .replace("\u201d", '"')
        .replace("\u2026", "...")
    )


class Book:
    def __init__(self, pdf, title: str, author: str):
        self.pdf = pdf
        self.title = title
        self.author = author
        self.outline: list[dict[str, object]] = []
        self.paragraph_gap_pending = False

    # -- page helpers -----------------------------------------------------
    def heading(self, label: str, title: str, level: int = 0) -> None:
        self.outline.append(
            {"title": f"{label}: {title}", "page": self.pdf.page, "level": level}
        )
        try:
            self.pdf.add_outline_entry(f"{label}: {title}", level=level)
        except Exception:
            pass
        pdf = self.pdf
        if pdf.y > M_T + 40:
            pdf.add_page()
        pdf.ln(26 if pdf.page > 1 else 8)
        pdf.set_font("times", "I", 13)
        pdf.set_text_color(90, 90, 90)
        pdf.cell(0, 7, label.upper(), new_x="LMARGIN", new_y="NEXT")
        pdf.ln(5)
        pdf.set_font("times", "B", 21)
        pdf.set_text_color(20, 20, 20)
        pdf.multi_cell(0, 10, latin(title), new_x="LMARGIN", new_y="NEXT")
        pdf.ln(8)
        self.paragraph_gap_pending = False

    def paragraph(self, text: str, italic: bool = False) -> None:
        pdf = self.pdf
        style = "I" if italic else ""
        pdf.set_font("times", style, 11.5)
        pdf.set_text_color(30, 30, 30)
        if self.paragraph_gap_pending:
            pdf.ln(4)
        pdf.multi_cell(0, LINE_H, latin(text), align="J", new_x="LMARGIN", new_y="NEXT")
        if pdf.y > PAGE_H - M_B - 4 * LINE_H:
            pdf.add_page()
        self.paragraph_gap_pending = True


def build_reading_with_intention(pdf, chapter_pages=None) -> Book:
    book = Book(pdf, "Reading With Intention", "Mira Havel")

    # Title page
    pdf.add_page()
    pdf.set_font("times", "", 14)
    pdf.set_text_color(110, 110, 110)
    with pdf.local_context():
        pdf.set_y(70)
        pdf.cell(0, 8, "KOLA SAMPLE EDITION", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(38)
    pdf.set_font("times", "B", 30)
    pdf.set_text_color(20, 20, 20)
    pdf.multi_cell(0, 13, latin("Reading With Intention"), align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(10)
    pdf.set_font("times", "", 15)
    pdf.multi_cell(0, 8, latin("Notes on Deep Reading, Attention,"), align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.multi_cell(0, 8, latin("and the Craft of Marginalia"), align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(24)
    pdf.set_font("times", "I", 13)
    pdf.multi_cell(0, 7, "Mira Havel", align="C", new_x="LMARGIN", new_y="NEXT")

    # Copyright page
    pdf.add_page()
    pdf.set_y(PAGE_H - M_B - 40)
    pdf.set_font("times", "", 8.5)
    pdf.set_text_color(120, 120, 120)
    pdf.multi_cell(
        0, 4.2,
        latin(
            "Sample edition assembled for the Kola reader preview. The text is original and\n"
            "exists only to exercise reading, search, and annotation. No part of this sample\n"
            "implies publication."
        ),
        align="C", new_x="LMARGIN", new_y="NEXT",
    )
    pdf.ln(6)
    pdf.multi_cell(0, 4.2, latin("Set in Times - 152.64 x 228.96 mm - First printing, 2026"), align="C", new_x="LMARGIN", new_y="NEXT")

    # Contents
    pdf.add_page()
    try:
        pdf.add_outline_entry("Contents", level=0)
    except Exception:
        pass
    pdf.ln(18)
    pdf.set_font("times", "B", 19)
    pdf.set_text_color(20, 20, 20)
    pdf.cell(0, 9, "Contents", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(10)
    chapters = [
        ("The Practice of Deep Reading", 4),
        ("Marginalia as Conversation", 7),
        ("Building a Reading System", 10),
        ("Keeping What Matters", 13),
    ]
    if chapter_pages is not None:
        chapters = [
            (title, page)
            for (title, _), page in zip(chapters, chapter_pages)
        ]
    book.outline.append({"title": "Contents", "page": 3, "level": 0})
    for index, (title, page) in enumerate(chapters, start=1):
        pdf.set_font("times", "", 12)
        pdf.set_text_color(30, 30, 30)
        label = latin(f"{index}  -  {title}")
        pdf.cell(0, 8.5, label, new_x="LMARGIN", new_y="NEXT")
        pdf.set_font("times", "", 10)
        pdf.set_text_color(120, 120, 120)
        pdf.cell(0, 5, f"page {page}", new_x="LMARGIN", new_y="NEXT")
        pdf.ln(2.5)

    # Chapter 1
    pdf.add_page()
    book.heading("Chapter One", "The Practice of Deep Reading")
    book.paragraph(
        "A book read slowly is a different object from a book read quickly. The slow "
        "reader notices the seams of an argument: where the author pauses, where a "
        "claim is repeated in new clothing, where a quiet qualification undoes half "
        "of what came before. Speed flattens these textures. Attention restores them."
    )
    book.paragraph(
        "Deep reading is not a mood but a practice, and like every practice it has a "
        "posture. You sit with the book rather than over it. You let the paragraph "
        "finish its sentence before you argue. The mind that reads well is a mind "
        "willing to be changed in small ways, paragraph by paragraph, without "
        "surrendering the right to disagree at the end."
    )
    book.paragraph(
        "The physical page helps more than we admit. A fixed page is a unit of "
        "attention. When the text stops at the corner of the sheet, the reader stops "
        "too, briefly, and in that pause comprehension catches up with the eyes. "
        "Screens that scroll forever remove these natural rests, and the reading "
        "becomes a current that carries you rather than a path you walk."
    )
    book.paragraph(
        "None of this means paper is virtuous and screens are corrupt. It means a "
        "good reader is deliberate about the container. Read the long argument in "
        "whatever form lets you linger, mark, and return. The container matters only "
        "insofar as it protects the reader's right to pause."
    )
    book.paragraph(
        "Begin, then, with a simple commitment: one book at a time, read at the "
        "speed of understanding. You will read fewer books this year. You will own "
        "more of what you read."
    )

    # Chapter 2
    pdf.add_page()
    book.heading("Chapter Two", "Marginalia as Conversation")
    book.paragraph(
        "A margin is a room the printer left empty so the reader could live in it. "
        "The habit of writing in that room is older than the printed book itself; "
        "medieval scribes complained, in the margins they were annotating, about the "
        "drudgery of copying. Annotation is not a violation of the text. It is the "
        "text's reply."
    )
    book.paragraph(
        "There is a grammar to good marginalia. A check is agreement; a question "
        "mark is an open door; a single line under a sentence is an invitation to "
        "return. The codes are private, but they are not arbitrary — they settle, "
        "over years, into a language you speak fluently to your future self."
    )
    book.paragraph(
        "The best annotations are arguments with dates attached. When you disagree "
        "with an author, write the objection down and let it stand. Returning to the "
        "page five years later, you will meet two people you no longer are: the "
        "author, and the reader who answered him. Sometimes the older objection "
        "embarrasses you. That embarrassment is the tuition of a reading life."
    )
    book.paragraph(
        "Highlighting has a bad reputation it does not entirely deserve. A "
        "highlight is a promise to think again, and like all promises it is cheap "
        "to make and expensive to keep. The failure mode is accumulation: a page "
        "painted yellow is a page that was skimmed with the hands. Highlight the "
        "sentence, not the paragraph; and if you highlight a claim, write beside it "
        "why it mattered on the day you met it."
    )
    book.paragraph(
        "Treat the book as a correspondent who writes slowly and never answers "
        "back. The margin is where you keep your half of the exchange."
    )

    # Chapter 3
    pdf.add_page()
    book.heading("Chapter Three", "Building a Reading System")
    book.paragraph(
        "Readers drift without a system, and systems collapse without a reader. The "
        "trick is to build the smallest structure that survives a bad month. A list "
        "of books you intend to read, kept separate from the books you are reading, "
        "is enough to begin. Order the list by appetite, not by duty; a reading "
        "queue you dread is a queue you will abandon."
    )
    book.paragraph(
        "Keep the reading list honest. When a book stops earning its place, move it "
        "to a shelf called paused, or finished, or simply not for me. A list that "
        "only grows becomes a monument to guilt, and guilt is the enemy of the "
        "long reading life. The finished list, read backward, is one of the few "
        "honest diaries a person keeps."
    )
    book.paragraph(
        "Time, not lists, is the scarce resource. Measure reading in sessions of "
        "attention rather than pages conquered: twenty minutes with a difficult "
        "chapter counts for more than an hour of drifting. Most readers can find "
        "twenty minutes; the ones who cannot have usually mistaken reading for a "
        "task that requires a table, a lamp, and an evening. It requires none of "
        "these. It requires only the book and the decision."
    )
    book.paragraph(
        "Record the sessions if you like, but record them kindly. A chart that "
        "nags is a chart that gets hidden. Let the numbers describe the habit, "
        "never command it, and let a quiet week remain visible without comment. "
        "The purpose of a reading system is not productivity. The purpose is "
        "continuity: to arrive at the end of the year still reading."
    )

    # Chapter 4
    pdf.add_page()
    book.heading("Chapter Four", "Keeping What Matters")
    book.paragraph(
        "What survives of a book is rarely its summary. Summaries are the ash of "
        "reading: they preserve the shape of the fire and none of its heat. What "
        "survives instead are fragments — a sentence that reorganized a doubt, a "
        "metaphor you have quietly used for a decade, an argument that lost on the "
        "day you read it and won three years later."
    )
    book.paragraph(
        "Collect the fragments deliberately. A note that quotes exactly, cites "
        "where the quote lives, and adds one honest sentence of your own will "
        "outvalue any quantity of paraphrase. Precision is a form of respect: for "
        "the author's phrasing, and for the future reader of the note, who is you."
    )
    book.paragraph(
        "Keep the collection small enough to revisit. A common-place book of a "
        "thousand entries is a library; a common-place book of a hundred is a "
        "companion. Reread your own margins on a slow Sunday, prune what no longer "
        "speaks, and notice which quotes have begun to mean something different. "
        "That change is the only proof of growth a reader ever gets."
    )
    book.paragraph(
        "And when a book is done, let it be done. Close it, record the date if you "
        "keep such records, and carry one sentence of it into the week. Reading "
        "ends; the reader continues."
    )
    return book


def build_field_guide(pdf) -> Book:
    book = Book(pdf, "A Field Guide to Marginalia", "Tomas Reiner")

    pdf.add_page()
    pdf.set_font("times", "", 12)
    pdf.set_text_color(110, 110, 110)
    pdf.set_y(84)
    pdf.cell(0, 8, "A SHORT FIELD GUIDE", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(26)
    pdf.set_font("times", "B", 26)
    pdf.set_text_color(20, 20, 20)
    pdf.multi_cell(0, 11, latin("A Field Guide to Marginalia"), align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(8)
    pdf.set_font("times", "", 13)
    pdf.multi_cell(0, 7, "Tomas Reiner", align="C", new_x="LMARGIN", new_y="NEXT")

    pdf.add_page()
    book.heading("Section One", "Marks and Their Meanings")
    book.paragraph(
        "Every reader invents a private alphabet, but the letters descend from a "
        "shared stock. The underline marks possession: this sentence is mine now. "
        "The vertical line in the margin marks a passage that will be wanted again. "
        "The asterisk, humble and portable, marks a claim to be checked against "
        "another book."
    )
    book.paragraph(
        "Learn the stock marks before inventing new ones. A mark whose meaning you "
        "cannot reconstruct a year later is noise, and noise in the margin is worse "
        "than silence, because it promises meaning and refuses it."
    )
    book.paragraph(
        "The question mark is the most valuable mark in the set and the least used. "
        "Placed beside a confident sentence, it says: I am not convinced, and I "
        "will return. Readers who annotate only agreement produce archives of "
        "flattery. Readers who annotate doubt produce arguments, and arguments, "
        "kept long enough, ripen into judgment."
    )

    pdf.add_page()
    book.heading("Section Two", "Instruments")
    book.paragraph(
        "Pencil, above all. Ink argues for permanence the note has not earned; the "
        "eraser keeps the margin a draft, which is what a margin should be. A soft "
        "line laid at a shallow angle will not emboss the page beneath, a kindness "
        "to whoever reads the copy after you."
    )
    book.paragraph(
        "On screens the instrument is the selection, and the discipline is the "
        "same. A selection is a pencil line that cannot be sharpened: it goes down "
        "exactly and forever. Choose ranges the way you would choose words in a "
        "letter, not the way you would clear a field."
    )

    pdf.add_page()
    book.heading("Section Three", "The Etiquette of Borrowed Books")
    book.paragraph(
        "Library books are common ground; annotate them only in your own copy of "
        "your memory. The borrowed book you return should carry no trace of your "
        "visit, with one exception: the repair of a torn page, performed quietly "
        "and without confession."
    )
    book.paragraph(
        "Books you lend are yours still. Lend them gladly and write nothing in "
        "them afterward; a margin that replies to a reader you will not meet is a "
        "letter without an address."
    )
    book.paragraph(
        "Books you give are books that have finished their work with you. On the "
        "flyleaf, one line and a date. The date is the gift's receipt; the line is "
        "its reason. If you cannot find the line, give the book unwritten and let "
        "the new owner begin clean."
    )

    pdf.add_page()
    book.heading("Section Four", "On Rereading")
    book.paragraph(
        "The annotated book is a palimpsest of your successive selves. Read it again "
        "with the earlier marks in view and the margins become a conversation across "
        "years: the reader who underlined everything, the reader who doubted, the "
        "reader who finally agreed on different grounds. Rereading is the only way "
        "to audit your own judgment."
    )
    book.paragraph(
        "Do not reread everything; reread the books that changed their behavior in "
        "your memory. A book you remember as difficult that now reads easily is a "
        "book that taught you something you have forgotten learning. A book you "
        "remember as decisive that now seems thin deserves its demotion, recorded "
        "in the margin with the date, so the verdict is honest."
    )
    book.paragraph(
        "Mark the date of every reread on the flyleaf. The list becomes a ledger of "
        "the friendship between you and the book, and like every ledger kept in "
        "good faith, it repays inspection: some entries compound, some depreciate, "
        "and the pattern of the whole is the closest thing a reader has to "
        "self-knowledge."
    )
    return book


def main() -> None:
    venv_python = ensure_venv()
    # fpdf2 must run inside the venv; re-exec ourselves there.
    if Path(sys.executable).resolve() != venv_python.resolve():
        subprocess.run([str(venv_python), str(Path(__file__).resolve())], check=True)
        return

    from fpdf import FPDF

    DATA.mkdir(parents=True, exist_ok=True)

    # Pass 1: discover real chapter start pages; pass 2: print accurate Contents.
    pdf = FPDF(format=(PAGE_W, PAGE_H))
    pdf.set_auto_page_break(False)
    pdf.set_margins(M_L, M_T, M_R)
    probe = build_reading_with_intention(pdf)
    chapter_pages = [
        entry["page"] for entry in probe.outline if entry["title"].startswith("Chapter")
    ]

    pdf = FPDF(format=(PAGE_W, PAGE_H))
    pdf.set_auto_page_break(False)
    pdf.set_margins(M_L, M_T, M_R)
    book1 = build_reading_with_intention(pdf, chapter_pages)
    path1 = DATA / "reading-with-intention.pdf"
    pdf.output(path1)

    pdf2 = FPDF(format=(PAGE_W, PAGE_H))
    pdf2.set_auto_page_break(False)
    pdf2.set_margins(M_L, M_T, M_R)
    book2 = build_field_guide(pdf2)
    path2 = DATA / "field-guide-to-marginalia.pdf"
    pdf2.output(path2)

    library = {
        "documents": [
            {
                "id": "doc-reading-intention",
                "title": "Reading With Intention",
                "authors": ["Mira Havel"],
                "format": "pdf",
                "file": "data/reading-with-intention.pdf",
                "pageCount": pdf.page,
                "outline": book1.outline,
                "lastOpenedHoursAgo": 26,
                "seedPage": 5,
            },
            {
                "id": "doc-field-guide",
                "title": "A Field Guide to Marginalia",
                "authors": ["Tomas Reiner"],
                "format": "pdf",
                "file": "data/field-guide-to-marginalia.pdf",
                "pageCount": pdf2.page,
                "outline": book2.outline,
                "lastOpenedHoursAgo": 73,
                "seedPage": 2,
            },
            {
                "id": "doc-sound-function",
                "title": "The Sound and the Function",
                "authors": ["Amos Tarden"],
                "format": "epub",
            },
            {
                "id": "doc-quarterly-notes",
                "title": "Quarterly Notes — Field Reports",
                "authors": ["June Okafor"],
                "format": "docx",
            },
            {
                "id": "doc-reading-systems",
                "title": "Reading Systems — Slide Deck",
                "authors": [],
                "format": "pptx",
            },
            {
                "id": "doc-reading-log",
                "title": "Reading Log 2026",
                "authors": [],
                "format": "xlsx",
            },
        ],
        "readingList": [
            {"title": "The Sound and the Function", "status": "nextUp"},
            {"title": "Quarterly Notes — Field Reports", "status": "wantToRead"},
            {"title": "A Field Guide to Marginalia", "status": "reading"},
            {"title": "Reading Systems — Slide Deck", "status": "paused"},
            {"title": "The Boxwood Almanac", "status": "wantToRead"},
            {"title": "Letters to a Young Cartographer", "status": "completed"},
        ],
        "sessions": [
            {"documentId": "doc-reading-intention", "hoursAgo": 5, "minutes": 18},
            {"documentId": "doc-reading-intention", "hoursAgo": 27, "minutes": 42},
            {"documentId": "doc-reading-intention", "hoursAgo": 51, "minutes": 65},
            {"documentId": "doc-reading-intention", "hoursAgo": 99, "minutes": 26},
            {"documentId": "doc-field-guide", "hoursAgo": 34, "minutes": 35},
            {"documentId": "doc-field-guide", "hoursAgo": 78, "minutes": 50},
            {"documentId": "doc-field-guide", "hoursAgo": 145, "minutes": 80},
        ],
    }
    (DATA / "books.json").write_text(json.dumps(library, indent=2) + "\n")
    print(f"Wrote {path1.name} ({pdf.page} pages), {path2.name} ({pdf2.page} pages)")
    print(f"Wrote {DATA / 'books.json'}")


if __name__ == "__main__":
    main()
