# Kola — Feature Strategy & Market Differentiation

Research snapshot: September 2026.

This document decides **which features Kola should build, why they matter, and in what order**. It is not a brainstorm backlog. Features are ranked against Kola's product thesis: local-first ownership, universal reading, excellent annotation, adaptive-native UX, and cross-device continuity without mandatory proprietary cloud infrastructure.

## 1. Strategic product position

Kola should not compete as "another PDF reader" or "another ebook reader".

The target position is:

> **Kola is the local-first home for a person's entire reading life: read almost anything, understand it, annotate it, remember it, track it, and carry it across devices without surrendering ownership.**

This combines capabilities that are currently fragmented across several product categories:

- ebook readers;
- PDF/research readers;
- annotation and study tools;
- read-it-later systems;
- reading trackers;
- knowledge-management tools;
- e-reader ecosystems;
- cloud-sync services.

Kola should win by making those workflows coherent, not by maximizing raw feature count.

## 2. Research signals from the current market

### Cross-platform modern readers

Readest demonstrates strong demand for a free/open modern cross-platform reader. Its current feature set includes EPUB/PDF/MOBI/AZW3/FB2/CBZ/TXT, annotations, TTS, translation, parallel reading, OPDS/Calibre, cross-device sync, KOReader sync, accessibility, and visual/focus aids. Its GitHub repository has reached substantial community adoption.

Product lesson: cross-platform polish + openness + interoperability has real pull.

References:
- https://readest.com/
- https://readest.com/docs
- https://github.com/readest/readest

### Research/PDF workflows

Zotero 10 introduced a source-linked reflow Reading Mode for PDFs where highlights and notes remain interoperable with the original PDF view.

Product lesson: source-linked Flow Mode is now a validated high-value direction, but Kola can extend it across more formats.

Reference:
- https://www.zotero.org/blog/zotero-10/

### Study workflows

MarginNote 4 integrates excerpts, mind maps, flashcards, backlinks, auto-linking, spaced repetition, and AI-assisted breakdown. Goodnotes provides study sets and spaced-repetition learning.

Product lesson: students value turning reading into reusable study material without copying information between separate apps.

References:
- https://manual.marginnote.com.cn/mn4/en/
- https://support.goodnotes.com/hc/en-us/articles/7353756529551-Getting-Started-with-Study-Sets-and-Smart-Learn

### Capture and knowledge export

Readwise Reader succeeds by collecting articles, newsletters, EPUBs, PDFs, video/podcast transcripts, highlights, and exports into tools such as Obsidian and Notion. Its browser extension makes capture extremely low friction.

Product lesson: acquisition is not only about what Kola can open; it is also about how effortlessly content enters and leaves Kola.

References:
- https://docs.readwise.io/reader/docs/saving-content
- https://docs.readwise.io/reader/docs/faqs/exporting

### Reading analytics and social tracking

Apple Books, StoryGraph, Fable, Bookly, BookFusion, and KOReader all show sustained demand for reading statistics, goals, streaks, lists, challenges, and completion history. Fable and StoryGraph additionally emphasize social reading, buddy reads, clubs, sharable lists, and reading wraps.

Product lesson: reading identity and progress are strong retention loops. Kola should provide the useful personal layer without requiring a social network.

References:
- https://www.apple.com/in/apple-books/
- https://play.google.com/store/apps/details?id=com.thestorygraph.thestorygraph
- https://fable.co/
- https://getbookly.com/
- https://www.bookfusion.com/reading/cloud-library

### E-reader interoperability

Readest and BookFusion both invest heavily in KOReader integration. KOReader users care about progress, highlights, statistics, OPDS/Calibre, and keeping data when moving between devices.

Product lesson: interoperability with e-ink devices is a meaningful acquisition wedge because serious readers often use more than one device.

References:
- https://readest.com/docs/sync
- https://www.blog.bookfusion.com/your-books-highlights-progress-onevery-e-reader-bookfusion-for-koreader-is-here/
- https://github-wiki-see.page/m/koreader/koreader/wiki/OPDS-support

### Community feature requests

Reader communities repeatedly ask for practical quality-of-life features: cross-page highlighting, image/diagram annotation, better fonts, width controls, reliable sync, file-move resilience, code/Markdown support, and interoperability.

Product lesson: reliability and annotation quality create loyalty more reliably than novelty alone.

Examples:
- https://www.reddit.com/r/BookFusion/comments/1pqhjwf/
- https://www.reddit.com/r/readwise/comments/1lq7v7s/
- https://www.reddit.com/r/koreader/comments/1ujrrx8/

## 3. Feature scoring model

Each proposed feature is judged on five factors, 1–5 each:

- **User Value** — how often/how strongly it improves real reading.
- **Differentiation** — whether it meaningfully separates Kola from common readers.
- **Retention** — whether it gives users a reason to return regularly.
- **Acquisition/Virality** — whether it helps new users discover or adopt Kola.
- **Engineering Cost** — 1 = cheap, 5 = expensive/risky.

Priority should favor high value/differentiation/retention with manageable cost.

## 4. Tier A — must-have foundation

These are not marketing features. Without them, Kola cannot be trusted.

### A1. Best-in-class reading + annotation

Required:

- excellent PDF/ebook text selection;
- highlights, underline, strikeout, notes;
- freehand ink and shapes;
- cross-page highlighting;
- image/diagram/area annotations;
- undo/redo;
- annotations panel + filtering;
- exact jump-to-source;
- fast keyboard/touch/stylus paths;
- durable source-linked anchors.

Priority: **highest**.

### A2. Universal Flow Mode

Kola's flagship technical feature.

- Flow Mode for PDF, EPUB, DOCX, PPTX, spreadsheets, HTML/text, OCR content, and future supported formats;
- source preservation;
- reversible jump to original/fidelity view;
- annotations interoperable between views;
- figures/tables represented safely;
- reading position retained across view switches.

Differentiator: **very high**.

### A3. Beautiful adaptive-native UI

- platform-native navigation and behavior;
- Kola visual identity inside the workspace;
- themes/backgrounds;
- excellent typography;
- fluid animation only at useful moments;
- phone/tablet/desktop layouts designed separately from shared semantics.

Acquisition impact: **high**, because first impressions matter.

### A4. Local library + universal search

- fast library management;
- collections/tags/favorites/status;
- metadata editing;
- cover management;
- full-text search across documents;
- search annotations and notes;
- OCR text search;
- saved/smart filters.

### A5. Reliable local persistence

- no lost progress;
- no lost annotations;
- local backups;
- export/import;
- crash-safe database handling;
- file rename/move recovery via content identity.

## 5. Tier B — features that should make Kola distinctly better

### B1. Reading Intelligence

Already specified in `READING_ANALYTICS.md`.

Add:

- active reading time;
- per-document time;
- sessions;
- coverage vs current position;
- estimated time remaining;
- daily/weekly/monthly/yearly insights;
- Want to Read / Next Up / Reading / Paused / Completed / DNF;
- flexible reading goals;
- optional gentle streaks;
- personal reading history.

Why it matters: strong retention without requiring social infrastructure.

### B2. Parallel Read / Compare Mode

Allow two sources side by side.

Use cases:

- original + translation;
- textbook + notes;
- two research papers;
- old vs revised document;
- code documentation + reference;
- slide deck + source document.

Useful options:

- independent or synchronized scroll;
- linked annotations;
- one-click cross-document quote linking.

This is proven by Readest and highly useful for students/researchers.

### B3. Read Aloud + synchronized text

Start with local/platform TTS.

- sentence/paragraph highlighting while speaking;
- speed/voice control;
- background playback;
- sleep timer;
- resume position shared with visual reading;
- optional EPUB media-overlay support;
- later audiobook pairing.

Retention value: **high** because it extends reading into commuting/walking/accessibility contexts.

### B4. Dictionary, lookup, translation

Selection menu actions:

- define locally/OS dictionary where available;
- Wikipedia/reference lookup;
- translate selected sentence;
- optional full-section translation;
- save vocabulary as annotation/card.

Keep online services optional. Use platform/on-device capabilities where practical.

### B5. Interoperability hub

Kola should be unusually easy to migrate into and out of.

Import targets:

- Calibre libraries;
- OPDS catalogs;
- Kindle highlight exports where technically/legal feasible;
- KOReader progress/highlights/statistics;
- Goodreads/StoryGraph/Fable-style CSV reading lists;
- Readwise/Markdown/CSV highlights;
- existing folder libraries.

Export targets:

- Markdown;
- JSON;
- CSV;
- annotated PDF;
- Obsidian-compatible Markdown;
- generic folder export;
- configurable templates.

Acquisition impact: **very high**. Migration friction kills switching; importers reduce that friction.

### B6. KOReader/e-ink integration

Long-term:

- progress sync;
- highlights/notes sync;
- reading-time sync;
- library metadata;
- optional file transfer;
- OPDS/Kola library endpoint or compatible plugin.

This can attract serious e-reader users who currently stitch together multiple tools.

## 6. Tier C — learning and knowledge features

These should build on annotations instead of creating parallel silos.

### C1. One annotation, many views

A single excerpt can appear as:

- source highlight;
- note;
- knowledge card;
- flashcard;
- mind-map node;
- study-sheet entry.

Do **not** duplicate content into separate databases when one domain object can be projected into several views.

This is one of the strongest lessons from MarginNote's Card Axis model.

### C2. Backlinks + knowledge graph

- link one highlight/note to another;
- cross-document backlinks;
- related-concept panel;
- graph view optional, not mandatory;
- keyword/title auto-linking later;
- source always one click away.

Target users: students, researchers, technical readers.

### C3. Flashcards + spaced repetition

- turn highlight/note into card instantly;
- cloze deletion;
- image occlusion later;
- FSRS or another well-established spaced-repetition scheduler;
- source context visible during review;
- deck generated by tag/document/collection.

Important: this should remain optional. Kola is a reader first.

### C4. Mind maps / concept boards

- create nodes from annotations;
- drag multiple excerpts into a concept map;
- backlinks to source;
- hand-drawn connections on stylus devices;
- export map.

This is high differentiation for students but should come after annotation quality is mature.

### C5. Recall Mode

A low-complexity active-recall reading mode:

- hide selected highlights;
- blur/reveal answers;
- quiz a chapter from manually created study cards;
- mark concepts "known / unsure";
- no mandatory AI.

## 7. Tier D — capture features that broaden the audience

### D1. Browser extension / web clipper

This can materially expand Kola beyond local files.

Actions:

- Save article locally to Kola;
- capture clean reader-mode HTML;
- save PDF from current tab;
- preserve title/author/source URL/date;
- highlight an open webpage and send annotation to Kola;
- choose collection/tag on save.

Important privacy rule: capture should write to local Kola or user BYOC, not require Kola servers.

### D2. Mobile share-sheet capture

From any app:

- share URL -> save readable article;
- share PDF/file -> import;
- share selected text -> add to reading inbox or note.

### D3. RSS / Reading Inbox

Optional later feature:

- subscribe to feeds;
- local feed polling when app is active/background platform permits;
- save selected entries permanently;
- Flow Mode reading;
- no algorithmic feed required.

This broadens Kola into read-it-later territory without building a content network.

### D4. Transcript documents

Import locally accessible transcripts from:

- pasted text;
- subtitle files;
- video/podcast transcript files;
- optionally URLs through user-triggered connectors later.

Treat transcript as a first-class readable document with highlights and notes.

## 8. Tier E — optional private intelligence

Kola should not become dependent on AI, but optional intelligence can attract modern users.

### E1. Bring Your Own AI / Local AI

Possible backends:

- platform on-device AI APIs when present;
- local model runtime;
- local Ollama-compatible endpoint on desktop;
- optional user-supplied API endpoint/key in the future.

Kola itself should not require a paid AI service.

### E2. Source-grounded AI actions

Useful actions only:

- explain selected passage;
- summarize current chapter/section;
- generate outline/TOC suggestions;
- create glossary;
- ask questions over selected documents;
- generate flashcard drafts;
- generate quiz drafts;
- translate/rewrite difficult text;
- compare two documents;
- find contradictions/related passages;
- OCR cleanup suggestions.

Every answer should cite source locations where technically possible.

### E3. Local semantic search

Optional embedding index for:

- "where did I read about eventual consistency?";
- related passages across books;
- related annotations;
- concept resurfacing.

Prefer local embeddings when practical. Classic full-text search remains available regardless.

## 9. Tier F — acquisition and viral features

These are important specifically for making Kola visible beyond existing users.

### F1. Beautiful quote-card generator

From any highlight:

- generate a polished image card;
- select theme/background;
- include or omit book/source metadata;
- export/share without uploading content to Kola.

Why: organic sharing exposes Kola branding without requiring a social network.

### F2. Monthly / yearly Reading Wrap

Generate locally:

- books/documents completed;
- reading time;
- favorite genres/tags;
- top authors;
- most-highlighted books;
- favorite quote selected by user;
- reading streak/longest session if enabled;
- beautiful shareable story/card layouts.

This creates a natural recurring sharing moment similar to modern reading/social apps while preserving privacy.

### F3. Home/lock-screen widgets

Examples:

- Continue Reading;
- Today's reading goal;
- current book progress;
- Next Up;
- reading timer;
- random saved highlight.

Widgets reduce re-entry friction and keep Kola visually present every day.

### F4. Shareable theme packs

Kola themes/background presets can be exported as small files.

Potential community loop:

- users create themes;
- share files/GitHub links;
- import with one click;
- no mandatory marketplace server.

### F5. Public open-source/plugin ecosystem

If product/business strategy permits, an open extension surface can be a major growth lever.

Potential plugin categories:

- format adapters;
- exporters;
- metadata providers;
- dictionaries;
- sync backends;
- theme packs;
- commands;
- study tools.

Do not expose a plugin SDK before core domain boundaries stabilize.

## 10. Tier G — later social features

Full social networking is **not** an early Kola priority because it conflicts with local-first simplicity and requires moderation/server infrastructure.

Prefer lightweight sharing first.

Possible later concepts:

### Reading Rooms

- private invite-based shared reading session;
- optional BYOC/peer-hosted coordination;
- shared milestones;
- spoiler-safe chapter discussions;
- optional shared annotations.

### Buddy Read package

A simpler non-real-time alternative:

- export selected annotations/questions as a `.kola-share` bundle;
- friend imports it;
- both retain source references where compatible.

Only explore after the single-user product is excellent.

## 11. Features that are deliberately NOT priorities

Avoid early investment in:

- built-in public social feed;
- proprietary ebook store;
- mandatory Kola account;
- cloud-only AI assistant;
- badges/coins/XP systems;
- excessive streak pressure;
- live collaboration before annotation stability;
- plugin ecosystem before domain APIs stabilize;
- dozens of obscure format adapters before major formats are excellent.

These can distract from Kola's strongest product wedge.

## 12. Recommended product wedges

Kola should market around five memorable promises.

### 1. Read anything beautifully

Universal formats + Fidelity View + Flow Mode.

### 2. Your highlights actually belong to you

Portable annotations, local-first storage, BYOC, strong exports.

### 3. Read on every device without losing your place

Desktop/mobile first, then e-ink interoperability.

### 4. Turn reading into knowledge

Annotations -> links -> flashcards -> mind maps -> study sheets.

### 5. Understand your reading life

Active reading time, real coverage, goals, lists, analytics, wraps.

## 13. Recommended release sequence

### Kola 0.x — Trust the reader

Ship first:

- adaptive visual shell;
- PDF + EPUB excellence;
- local library;
- annotations;
- Flow Mode foundation;
- themes;
- progress/coverage;
- local search;
- backup/export.

Success criterion: users choose Kola because reading itself feels better.

### Kola 1.0 — The complete local reader

Add:

- major ebook/text formats;
- DOCX viewing/Flow where practical;
- Reading Intelligence;
- Want to Read / Next Up;
- local/platform TTS;
- dictionary/lookup;
- BYOC state sync;
- annotation export templates;
- migration/import tools.

Success criterion: users can realistically switch from their current reader.

### Kola 1.x — The power-reader release

Add:

- Parallel Read;
- OPDS/Calibre;
- KOReader interoperability;
- advanced search/smart collections;
- image/diagram annotation;
- spreadsheet/presentation support maturation;
- widgets;
- quote cards;
- reading wraps.

Success criterion: Kola gains strong organic recommendation among serious readers.

### Kola 2.0 — Reading becomes knowledge

Add:

- backlinking;
- one-annotation-many-views;
- flashcards + spaced repetition;
- mind maps/concept boards;
- Recall Mode;
- browser clipper/read-later capture;
- optional transcript reading.

Success criterion: students/researchers can replace multiple separate tools.

### Kola 2.x+ — Optional intelligence and ecosystem

Add only after the core is mature:

- local/BYO AI;
- source-grounded document Q&A;
- semantic search;
- plugin/extension APIs;
- shareable theme ecosystem;
- experimental private reading rooms.

## 14. Highest-impact feature ranking

Approximate strategic ranking, not engineering estimates.

| Rank | Feature | User Value | Differentiation | Retention | Acquisition | Cost |
|---|---|---:|---:|---:|---:|---:|
| 1 | Universal source-linked Flow Mode | 5 | 5 | 5 | 5 | 5 |
| 2 | Best-in-class annotations | 5 | 4 | 5 | 4 | 4 |
| 3 | Adaptive premium UI/themes | 5 | 4 | 4 | 5 | 4 |
| 4 | Local-first + BYOC sync | 5 | 5 | 5 | 5 | 4 |
| 5 | Reading Intelligence + lists | 5 | 4 | 5 | 4 | 3 |
| 6 | Migration/import/export hub | 5 | 4 | 4 | 5 | 3 |
| 7 | Universal search | 5 | 4 | 5 | 4 | 4 |
| 8 | TTS / Read Aloud | 5 | 3 | 5 | 4 | 3 |
| 9 | Parallel Read | 4 | 4 | 4 | 4 | 3 |
| 10 | KOReader/OPDS/Calibre interoperability | 4 | 5 | 5 | 4 | 4 |
| 11 | Quote cards + Reading Wrap | 3 | 3 | 4 | 5 | 2 |
| 12 | Widgets | 4 | 3 | 5 | 3 | 3 |
| 13 | One annotation -> note/card/map | 5 | 5 | 5 | 4 | 4 |
| 14 | Flashcards + spaced repetition | 4 | 4 | 5 | 4 | 3 |
| 15 | Browser clipper / reading inbox | 4 | 4 | 5 | 5 | 4 |
| 16 | Optional local/BYO AI | 4 | 4 | 4 | 5 | 4 |
| 17 | Full social/book clubs | 3 | 2 | 4 | 4 | 5 |

## 15. Product rule for new feature proposals

Before adding a new feature, answer:

1. Does it make reading, understanding, remembering, organizing, or continuing easier?
2. Does it strengthen Kola's five product promises?
3. Can it remain local-first or explicitly optional-network?
4. Can it reuse Kola's existing document/annotation models instead of creating a silo?
5. Is there evidence users need it?
6. Will users notice/care about it enough to justify its complexity?
7. What current feature will be delayed or made harder by adding it?

If a feature has no strong answer to these questions, it should remain outside the committed roadmap.

## 16. Recommended focus

Kola should not try to ship every item at once.

The near-term product identity should be built around:

```text
Beautiful universal reader
+ source-linked Flow Mode
+ excellent annotations
+ local-first/BYOC ownership
+ real reading intelligence
+ effortless migration/interoperability
```

Then layer study/knowledge and optional intelligence on top.

That combination has a clearer market story than "reader with hundreds of features" and leaves room for Kola to grow into a much broader reading platform later.