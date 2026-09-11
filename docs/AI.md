# Kola — Bring Your Own AI

This document defines Kola's optional AI layer.

Kola is a reader first. AI must improve understanding of user-selected reading material without becoming a mandatory service, a proprietary cloud dependency, or a replacement for source-grounded reading.

## 1. Core principle

> **Bring your own intelligence. Keep the document as the source of truth.**

Kola should work completely without AI. When AI is configured, it operates on the same document graph, source maps, local search, annotations, and reading state already owned by Kola.

## 2. Supported backend model

AI providers live behind an app-owned abstraction such as `AiBackend`.

Potential backend families:

- operating-system/on-device AI APIs;
- bundled/local model runtime where practical;
- Ollama-compatible local endpoint;
- user-configured OpenAI-compatible endpoint;
- provider-specific adapters with user-supplied credentials only when justified later.

The application/domain layer must not depend on a specific AI vendor.

Conceptual contract:

```text
AiBackend
 ├─ capabilities
 ├─ health/status
 ├─ generate(request)
 ├─ stream(request)
 └─ optional embeddings/retrieval capability
```

## 3. AI context scopes

Every request visibly declares its scope.

Supported scopes:

- current selection;
- nearby paragraph/context;
- current page/slide/sheet region;
- current section/chapter;
- current document;
- explicitly selected documents;
- explicitly selected local library subset;
- Reading Intelligence data when separately permitted.

Never silently send the entire library to a remote provider.

## 4. Explain

AI can:

- explain selected text;
- explain difficult terminology;
- simplify complex prose;
- explain concepts at different depths;
- explain equations when sufficient extracted context exists;
- answer “what does this sentence refer to?” using nearby source context.

## 5. Summarize

AI can summarize:

- a selection;
- current page/slide;
- current section/chapter;
- whole document;
- multiple selected documents;
- content read so far.

Output modes may include:

- very short;
- concise;
- detailed;
- key points;
- structured outline.

## 6. Source-grounded document Q&A

Users can ask questions about:

- the current document;
- multiple explicitly selected documents;
- a selected local collection/scope.

Requirements:

- answers cite Kola source locations whenever technically possible;
- clicking a citation returns to the source;
- the UI shows which documents were used;
- generated claims without source support should be distinguishable from grounded claims;
- classic local search remains available independently of AI.

## 7. Compare and synthesize

AI can:

- compare two documents;
- compare document versions;
- compare arguments or definitions;
- identify agreements;
- identify contradictions;
- compare evidence;
- synthesize selected sources into a source-cited explanation.

This is a reader/research capability, not a persistent knowledge-graph system.

## 8. Translation and rewriting

AI actions may include:

- translate selection;
- translate section;
- explain idioms/context;
- simplify wording;
- rewrite dense text for clarity;
- change explanation level.

The original text always remains accessible beside generated output.

## 9. Structure and glossary assistance

AI can help with weakly structured documents by proposing:

- outline/TOC suggestions;
- heading grouping;
- key points;
- important terminology;
- glossary definitions;
- named entities/concepts;
- document metadata cleanup suggestions.

These are suggestions. Kola must not silently mutate the source file.

## 10. Reading companion actions

Useful contextual actions include:

- “Explain this”;
- “Summarize this section”;
- “What did I just read?”;
- “Recap since my last session”;
- “What changed since this earlier version?”;
- “Show the evidence for this claim”;
- “Where else in these selected documents is this discussed?”;
- “Give me a brief before I start this long document.”

## 11. Research assistance

AI can:

- extract claims and evidence;
- identify referenced works present in text;
- compare supporting evidence across selected sources;
- locate passages relevant to a question using AI-assisted retrieval;
- produce source-grounded synthesis;
- identify possible contradictions that the user can inspect in the source.

Do not present AI interpretation as document fact without citations/context.

## 12. OCR and Flow diagnostics assistance

AI may assist—not silently control—document cleanup:

- suggest OCR corrections;
- flag suspicious OCR output;
- propose reading-order corrections;
- classify ambiguous blocks;
- suggest heading/table/caption structure;
- help diagnose poor Flow Mode reconstruction.

Corrections require deterministic validation or explicit user acceptance before becoming durable derived data.

## 13. Reading Intelligence assistance

When the user explicitly permits analytics context, AI can answer questions such as:

- what did I read most this month?
- which books/documents received the most time?
- summarize what I completed recently;
- what has been sitting unfinished for a long time?
- choose among items in my Next Up list using criteria I provide;
- summarize my recent reading topics from local metadata/annotations.

This data remains local unless a remote AI request explicitly includes it.

## 14. Temporary comprehension generation

AI may generate temporary user-requested learning aids such as:

- comprehension questions;
- discussion questions;
- quick self-check prompts;
- example explanations.

Kola does **not** implement a persistent flashcard deck, spaced-repetition scheduler, Recall Mode, mind-map system, backlinks graph, or knowledge-card subsystem.

Generated temporary content is discarded or saved only as an ordinary note when the user explicitly chooses to save it.

## 15. Privacy model

### Local/on-device backend

Source content stays on device except for any explicit local-network endpoint the user configures.

### Remote BYO backend

Before content leaves the device:

- the provider must be explicitly configured;
- the request scope must be clear;
- Kola sends only the context needed for the action where practical;
- secrets are stored through platform secure storage;
- Kola should provide a setting to disable all remote AI actions;
- sensitive/private documents can be marked local-AI-only.

## 16. Grounding and citation model

AI requests should carry Kola source identifiers rather than plain untraceable text where practical.

Conceptually:

```text
User request
  -> Context Resolver
  -> KDG/Search chunks + source locators
  -> AI backend
  -> generated response + cited chunk ids
  -> Citation Resolver
  -> clickable source locations
```

The generated response is not itself the source of truth.

## 17. AI UX

AI should appear as contextual capability rather than a permanent chat panel occupying reading space.

Entry points may include:

- selection menu;
- command palette;
- compact Ask button;
- document menu;
- optional collapsible AI panel on wide layouts.

Principles:

- document remains visually dominant;
- show request scope;
- show active backend/local-vs-remote state;
- support stop/cancel while streaming;
- source citations are interactive;
- generated output is visually differentiated;
- no unsolicited AI popups while reading;
- no automatic document upload.

## 18. Persistence

Persist only what is useful and user-controlled.

Potential durable data:

- provider configuration metadata (never plaintext secret);
- user-pinned/saved AI response;
- user-created prompt presets;
- explicit conversation history if enabled;
- local retrieval/index metadata where required.

Default behavior should avoid accumulating huge hidden AI chat histories.

## 19. What BYO AI does not change

Even with no AI backend configured, Kola must retain:

- document reading;
- Flow/Fidelity views;
- annotations;
- local full-text search;
- Reading Intelligence;
- TTS;
- dictionary where available;
- library organization;
- export/import;
- BYOC sync.

## 20. Implementation order

1. Finish trustworthy document graph/source mapping/search.
2. Define `AiBackend` and request/context contracts.
3. Implement one local/Ollama-compatible backend first where practical.
4. Implement source-grounded Explain/Summarize/Q&A.
5. Add remote BYO provider abstraction with explicit privacy UX.
6. Add multi-document compare/synthesis.
7. Add translation/structure/OCR/analytics helpers.
8. Validate hallucination/citation failure modes with an adversarial test corpus.

AI should build on Kola's reader architecture—not dictate it.
