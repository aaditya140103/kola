// Kola web preview harness — a web mirror of the Kola Flutter app's current
// UI and reader behavior, driven by the same design tokens.
//
// Dev-only tool for tool/web_preview; not part of the Kola product.
// All data is local: seeded demo library + localStorage. No network beyond
// this static site's own assets.

import * as pdfjsLib from "./vendor/pdfjs/pdf.min.mjs";

pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
  "./vendor/pdfjs/pdf.worker.min.mjs",
  import.meta.url
).toString();

/* ------------------------------------------------------------------ utils */

const $app = document.getElementById("app");
const $overlay = document.getElementById("overlay-root");

// Independent stacking layers so dialogs can appear above open sheets.
const $sheetLayer = h("div", { style: "position:fixed;inset:0;z-index:41;pointer-events:none" });
const $dialogLayer = h("div", { style: "position:fixed;inset:0;z-index:50;pointer-events:none" });
const $menuLayer = h("div", { style: "position:fixed;inset:0;z-index:55;pointer-events:none" });
$overlay.append($sheetLayer, $dialogLayer, $menuLayer);

function h(tag, attrs = {}, ...children) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(attrs)) {
    if (value == null) continue;
    if (key === "class") node.className = value;
    else if (key === "html") node.innerHTML = value;
    else if (key.startsWith("on") && typeof value === "function")
      node.addEventListener(key.slice(2), value);
    else if (key === "dataset") Object.assign(node.dataset, value);
    else node.setAttribute(key, value);
  }
  for (const child of children.flat()) {
    if (child == null || child === false) continue;
    node.append(child.nodeType ? child : document.createTextNode(child));
  }
  return node;
}

function icon(name) {
  return h("span", { class: "mi", "aria-hidden": "true" }, name);
}

function formatDuration(minutes) {
  const total = Math.max(0, Math.round(minutes));
  if (total < 60) return `${total}m`;
  const hours = Math.floor(total / 60);
  const rem = total % 60;
  return rem === 0 ? `${hours}h` : `${hours}h ${rem}m`;
}

const HIGHLIGHT_COLORS = {
  "highlight.yellow": "#ffff00",
  "highlight.blue": "#448aff",
  "highlight.green": "#69f0ae",
  "highlight.pink": "#ff4081",
  "highlight.purple": "#e040fb",
  "highlight.orange": "#ffab40",
};
const HIGHLIGHT_NAMES = {
  "highlight.yellow": "Yellow",
  "highlight.blue": "Blue",
  "highlight.green": "Green",
  "highlight.pink": "Pink",
  "highlight.purple": "Purple",
  "highlight.orange": "Orange",
};

function highlightCss(token, alpha = 0.35) {
  const hex = HIGHLIGHT_COLORS[token] ?? HIGHLIGHT_COLORS["highlight.yellow"];
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

/* ------------------------------------------------------------------ state */

const LS_KEYS = {
  annotations: "kolaPreview:v1:annotations",
  states: "kolaPreview:v1:readingStates",
  lastOpened: "kolaPreview:v1:lastOpened",
};

function loadJson(key, fallback) {
  try {
    return JSON.parse(localStorage.getItem(key)) ?? fallback;
  } catch {
    return fallback;
  }
}

const state = {
  library: [],
  readingList: [],
  sessions: [],
  annotations: loadJson(LS_KEYS.annotations, {}),
  readingStates: loadJson(LS_KEYS.states, {}),
  lastOpened: loadJson(LS_KEYS.lastOpened, {}),
  importedBuffers: new Map(), // docId -> ArrayBuffer (session-only imports)
  docCache: new Map(), // docId -> { pdf, viewports, text: Map<page, items> }
  searchIndex: new Map(), // docId -> [{ page, text, items }] (disposable)
};

function saveAnnotations() {
  localStorage.setItem(LS_KEYS.annotations, JSON.stringify(state.annotations));
}
function saveReadingStates() {
  localStorage.setItem(LS_KEYS.states, JSON.stringify(state.readingStates));
}
function saveLastOpened() {
  localStorage.setItem(LS_KEYS.lastOpened, JSON.stringify(state.lastOpened));
}

function annotationsFor(docId) {
  return state.annotations[docId] ?? [];
}

async function bootData() {
  const response = await fetch("data/books.json");
  const data = await response.json();
  state.library = data.documents.map((doc) => ({ ...doc }));
  state.readingList = data.readingList;
  const now = Date.now();
  state.sessions = data.sessions.map((session, index) => ({
    id: `seed-${index}`,
    documentId: session.documentId,
    startedAt: now - session.hoursAgo * 3600_000,
    activeMinutes: session.minutes,
  }));
  for (const doc of state.library) {
    if (doc.lastOpenedHoursAgo != null && state.lastOpened[doc.id] == null) {
      state.lastOpened[doc.id] = now - doc.lastOpenedHoursAgo * 3600_000;
    }
  }
  // Seed a few highlights on first run so the annotation panel has content.
  if (!localStorage.getItem(LS_KEYS.annotations)) {
    const seeds = [
      {
        docId: "doc-reading-intention",
        quote:
          "Deep reading is not a mood but a practice, and like every practice it has a posture.",
        color: "highlight.yellow",
        note: "Posture, not mood — keep this.",
      },
      {
        docId: "doc-reading-intention",
        quote:
          "A highlight is a promise to think again, and like all promises it is cheap to make and expensive to keep.",
        color: "highlight.green",
        note: null,
      },
      {
        docId: "doc-field-guide",
        quote:
          "The question mark is the most valuable mark in the set and the least used.",
        color: "highlight.blue",
        note: null,
      },
    ];
    for (const [index, seed] of seeds.entries()) {
      const located = await locateQuote(seed.docId, seed.quote);
      if (!located) continue;
      const list = state.annotations[seed.docId] ?? (state.annotations[seed.docId] = []);
      list.push({
        id: `seed-annotation-${index}`,
        page: located.page,
        start: located.start,
        end: located.end,
        quote: located.text,
        note: seed.note,
        color: seed.color,
        createdAt: Date.now() - (index + 1) * 86400_000,
      });
    }
    saveAnnotations();
  }
}

/* ----------------------------------------------------------- pdf plumbing */

async function openDocument(doc) {
  if (state.docCache.has(doc.id)) return state.docCache.get(doc.id);
  let pdf;
  if (doc.file) {
    pdf = await pdfjsLib.getDocument({ url: doc.file }).promise;
  } else {
    const buffer = state.importedBuffers.get(doc.id);
    if (!buffer) throw new Error("Missing document bytes");
    pdf = await pdfjsLib.getDocument({ data: buffer.slice(0) }).promise;
  }
  const entry = { pdf, viewports: [], text: new Map() };
  for (let page = 1; page <= pdf.numPages; page += 1) {
    const pageProxy = await pdf.getPage(page);
    entry.viewports[page] = pageProxy.getViewport({ scale: 1 });
  }
  state.docCache.set(doc.id, entry);
  return entry;
}

async function pageTextItems(doc, pageNumber) {
  const entry = await openDocument(doc);
  const cached = entry.text.get(pageNumber);
  if (cached) return cached;
  const pageProxy = await entry.pdf.getPage(pageNumber);
  const content = await pageProxy.getTextContent();
  const items = [];
  let text = "";
  let previous = null;
  for (const raw of content.items) {
    if (!raw.str) continue;
    const item = {
      str: raw.str,
      left: raw.transform[4],
      baseline: raw.transform[5],
      width: raw.width,
      height: Math.hypot(raw.transform[2], raw.transform[3]) || raw.height,
      offset: text.length,
    };
    if (previous) {
      const endsWithSpace = /\s$/.test(previous.str);
      const startsWithSpace = /^\s/.test(item.str);
      if (!endsWithSpace && !startsWithSpace) {
        const sameLine = Math.abs(item.baseline - previous.baseline) < 1.5;
        const gap = item.left - (previous.left + previous.width);
        if (!sameLine || gap > 0.8) text += " ";
        item.offset = text.length;
      }
    }
    items.push(item);
    text += item.str;
    previous = item;
  }
  const record = {
    items,
    text,
    pageHeight: entry.viewports[pageNumber].height,
  };
  entry.text.set(pageNumber, record);
  return record;
}

async function ensureIndexed(doc) {
  if (state.searchIndex.has(doc.id)) return state.searchIndex.get(doc.id);
  if (doc.format !== "pdf") return [];
  const entry = await openDocument(doc);
  const pages = [];
  for (let page = 1; page <= entry.pdf.numPages; page += 1) {
    const record = await pageTextItems(doc, page);
    pages.push({ page, text: record.text, items: record.items });
  }
  state.searchIndex.set(doc.id, pages);
  return pages;
}

async function locateQuote(docId, quote) {
  const doc = state.library.find((d) => d.id === docId);
  if (!doc || doc.format !== "pdf") return null;
  const pages = await ensureIndexed(doc);
  const needle = quote.trim();
  for (const record of pages) {
    const index = record.text.indexOf(needle);
    if (index === -1) continue;
    return {
      page: record.page,
      start: index,
      end: index + needle.length,
      text: record.text.slice(index, index + needle.length),
    };
  }
  return null;
}

/* ----------------------------------------------------------------- router */

const routes = {
  "/": renderHome,
  "/library": renderLibrary,
  "/search": renderSearch,
  "/insights": renderInsights,
};

function currentPath() {
  const hash = location.hash.replace(/^#/, "") || "/";
  return hash;
}

function navigate(path) {
  location.hash = path;
}

async function render() {
  const raw = currentPath();
  const [path] = raw.split("?");
  const readerMatch = path.match(/^\/reader\/(.+)$/);
  readerCleanup?.();
  readerCleanup = null;
  closeAllOverlays();
  window.getSelection()?.removeAllRanges();
  if (readerMatch) {
    const docId = decodeURIComponent(readerMatch[1]);
    await renderReader(docId);
    return;
  }
  const screen = routes[path] ?? renderHome;
  renderShell(path, screen);
}

window.addEventListener("hashchange", () => {
  render().catch((error) => console.error(error));
});

/* ------------------------------------------------------------------ shell */

const DESTINATIONS = [
  { label: "Home", icon: "home", path: "/" },
  { label: "Library", icon: "local_library", path: "/library" },
  { label: "Search", icon: "search", path: "/search" },
  { label: "Insights", icon: "insights", path: "/insights" },
];

function kolaMark(showWordmark) {
  return h(
    "div",
    { class: "kola-mark" },
    h("div", { class: "badge-box" }, icon("menu_book")),
    showWordmark ? h("div", { class: "t-title-large" }, "Kola") : null
  );
}

function renderShell(path, screen) {
  const selectedIndex = DESTINATIONS.findIndex(
    (d) => d.path === path || (d.path !== "/" && path.startsWith(d.path))
  );
  const compact = window.matchMedia("(max-width: 599px)").matches;
  const extended = window.matchMedia("(min-width: 1200px)").matches;

  const content = h("div", { class: "shell-content" }, screen());

  let shellInner;
  if (compact) {
    shellInner = [
      content,
      h(
        "nav",
        { class: "nav-bar" },
        DESTINATIONS.map((d, index) =>
          h(
            "button",
            {
              class: `nav-item${index === selectedIndex ? " selected" : ""}`,
              onclick: () => navigate(d.path),
              "aria-label": d.label,
            },
            h("div", { class: "nav-indicator" }, icon(d.icon)),
            d.label
          )
        )
      ),
    ];
  } else {
    shellInner = [
      h(
        "aside",
        { class: `rail${extended ? " extended" : ""}` },
        kolaMark(extended),
        h(
          "div",
          { class: "rail-dests" },
          DESTINATIONS.map((d, index) =>
            h(
              "button",
              {
                class: `rail-item${index === selectedIndex ? " selected" : ""}`,
                onclick: () => navigate(d.path),
              },
              extended
                ? [icon(d.icon), d.label]
                : [h("div", { class: "rail-indicator" }, icon(d.icon)), d.label]
            )
          )
        )
      ),
      h("div", { class: "rail-divider" }),
      content,
    ];
  }

  $app.replaceChildren(
    h("div", { class: "shell" }, ...shellInner),
    h("div", { class: "preview-chip", title: "Web preview harness mirroring the Kola Flutter app (dev tool)." }, "preview harness")
  );
}

function screenWithAppBar(title, actions, body) {
  const screen = h(
    "div",
    { class: "screen" },
    h(
      "div",
      { class: "app-bar-large" },
      h("div", { class: "app-bar-title" }, title),
      h("div", { class: "app-bar-actions" }, actions)
    ),
    h("div", { class: "screen-body" }, body)
  );
  return screen;
}

function importButton() {
  const input = h("input", {
    type: "file",
    accept: "application/pdf,.pdf",
    style: "display:none",
  });
  input.addEventListener("change", () => importPickedFile(input));
  const button = h(
    "button",
    {
      class: "icon-button",
      title: "Import document",
      onclick: () => input.click(),
    },
    icon("add")
  );
  return h("span", {}, button, input);
}

async function importPickedFile(input) {
  const file = input.files?.[0];
  input.value = "";
  if (!file) return;
  const isPdf =
    file.type === "application/pdf" || file.name.toLowerCase().endsWith(".pdf");
  if (!isPdf) {
    showSnackbar("Kola cannot identify this document format yet.");
    return;
  }
  try {
    const buffer = await file.arrayBuffer();
    const pdf = await pdfjsLib.getDocument({ data: buffer.slice(0) }).promise;
    const metadata = await pdf.getMetadata().catch(() => null);
    const info = metadata?.info ?? {};
    const id = `doc-imported-${Date.now()}`;
    const doc = {
      id,
      title: (info.Title && String(info.Title).trim()) || file.name.replace(/\.pdf$/i, ""),
      authors: info.Author ? [String(info.Author)] : [],
      format: "pdf",
      pageCount: pdf.numPages,
      imported: true,
    };
    state.library.unshift(doc);
    state.importedBuffers.set(id, buffer);
    state.lastOpened[id] = Date.now();
    saveLastOpened();
    showSnackbar(`${doc.title} was added to your library.`);
    if (currentPath() !== "/library") navigate("/library");
    else render().catch(() => {});
  } catch {
    showSnackbar("Kola could not import this document. The source was left unchanged.");
  }
}

/* ------------------------------------------------------------------- home */

function renderHome() {
  const documents = [...state.library].sort(
    (a, b) => (state.lastOpened[b.id] ?? 0) - (state.lastOpened[a.id] ?? 0)
  );
  const continueDoc = documents[0];
  const weekStart = startOfWeek(Date.now());
  const weekMinutes = state.sessions
    .filter((s) => s.startedAt >= weekStart)
    .reduce((sum, s) => sum + s.activeMinutes, 0);

  const continueCard = continueDoc
    ? continueReadingCard(continueDoc)
    : h(
        "div",
        { class: "card", style: "display:flex;gap:16px;padding:32px;align-items:center" },
        icon("library_add"),
        h(
          "div",
          {},
          h("div", { class: "t-title-medium" }, "Your library is empty"),
          h("div", {}, "Import a document to start building your reading space.")
        )
      );

  return screenWithAppBar(
    "Your reading space",
    [importButton()],
    [
      sectionHeader("Continue reading", "View library", () => navigate("/library")),
      continueCard,
      sectionHeader("Next up"),
      nextUpRow(),
      sectionHeader("This week"),
      h(
        "div",
        { class: "insight-strip" },
        insightCard("schedule", formatDuration(weekMinutes), "Reading time"),
        insightCard("local_library", `${state.library.length}`, "Documents"),
        insightCard("playlist_add_check", `${state.readingList.length}`, "Reading list")
      ),
    ]
  );
}

function continueReadingCard(doc) {
  const author = doc.authors.length ? doc.authors.join(", ") : doc.format.toUpperCase();
  return h(
    "div",
    { class: "card continue-card" },
    h("div", { class: "cover" }, icon("auto_stories")),
    h(
      "div",
      { style: "flex:1;min-width:0;display:flex;flex-direction:column;align-items:flex-start;gap:8px" },
      h("div", { class: "t-headline-small clamp-2", style: "font-weight:700" }, doc.title),
      h("div", { class: "t-body-large clamp-2 on-surface-variant" }, author),
      h("div", { class: "t-label-large" }, "Continue where you left off"),
      h(
        "button",
        {
          class: "filled-button",
          style: "margin-top:8px",
          onclick: () => navigate(`/reader/${encodeURIComponent(doc.id)}`),
        },
        icon("menu_book"),
        "Open"
      )
    )
  );
}

function nextUpRow() {
  const cells = state.readingList.slice(0, 6).map((item) =>
    h(
      "div",
      { class: "card next-up-card" },
      icon("book"),
      h("div", { style: "flex:1" }),
      h("div", { class: "t-title-small clamp-2" }, item.title),
      h("div", { class: "t-label-small on-surface-variant" }, readingListLabel(item.status))
    )
  );
  cells.push(
    h(
      "button",
      { class: "add-to-list", onclick: () => {} },
      icon("add"),
      h("div", { class: "t-label-large" }, "Add to list")
    )
  );
  return h("div", { class: "next-up-row" }, cells);
}

function readingListLabel(status) {
  return {
    wantToRead: "Want to read",
    nextUp: "Next up",
    reading: "Reading",
    paused: "Paused",
    completed: "Completed",
    abandoned: "Not for me",
  }[status] ?? status;
}

function insightCard(iconName, value, label) {
  return h(
    "div",
    { class: "card insight-card" },
    icon(iconName),
    h(
      "div",
      {},
      h("div", { class: "t-title-medium" }, value),
      h("div", { class: "t-body-small on-surface-variant" }, label)
    )
  );
}

function sectionHeader(title, action, onPressed) {
  return h(
    "div",
    { class: "section-header" },
    h("div", { class: "t-title-large" }, title),
    action
      ? h("button", { class: "text-button", onclick: onPressed }, action)
      : null
  );
}

/* ---------------------------------------------------------------- library */

function renderLibrary() {
  const grid = h(
    "div",
    { class: "library-grid" },
    state.library.map((doc) => bookTile(doc))
  );
  return screenWithAppBar(
    "Library",
    [
      h("button", { class: "icon-button", title: "Filter", onclick: () => {} }, icon("tune")),
      importButton(),
    ],
    [grid]
  );
}

function bookTile(doc) {
  const author = doc.authors.length ? doc.authors.join(", ") : doc.format.toUpperCase();
  const opened = state.lastOpened[doc.id] != null;
  return h(
    "button",
    {
      class: "book-tile",
      onclick: () => navigate(`/reader/${encodeURIComponent(doc.id)}`),
    },
    h("div", { class: "cover" }, icon("auto_stories")),
    h("div", { class: "t-title-small book-tile-title clamp-2" }, doc.title),
    h("div", { class: "t-body-small book-tile-author clamp-1" }, author),
    h("div", { class: "t-label-small on-surface-variant" }, opened ? "Recently opened" : "Not started")
  );
}

/* ----------------------------------------------------------------- search */

function renderSearch() {
  let results = [];
  let loading = false;
  let error = null;
  let query = "";
  let debounce = null;

  const statusArea = h("div", {});
  const countLabel = h("div", { class: "t-title-medium result-count", style: "display:none" });

  function refresh() {
    suffix.replaceChildren(loading ? h("div", { class: "spinner" }) : null);
    const children = [];
    if (!query) {
      children.push(
        h(
          "div",
          { class: "empty-state" },
          icon("manage_search"),
          h("div", { class: "t-title-large" }, "Search stays on your device"),
          h(
            "div",
            { class: "t-body-large on-surface-variant" },
            "Kola builds a private local index when a document is searched for the first time. Later searches reuse that index."
          )
        )
      );
    } else if (error != null) {
      children.push(
        h("div", { class: "empty-state", style: "color:var(--error)" }, `Search failed locally.\n${error}`)
      );
    } else if (!loading && results.length === 0) {
      children.push(
        h("div", { class: "empty-state" }, h("div", { class: "t-body-large" }, "No local matches found."))
      );
    } else if (results.length > 0) {
      countLabel.textContent = `${results.length} local ${results.length === 1 ? "result" : "results"}`;
      children.push(countLabel, ...results.map((hit) => resultCard(hit)));
    } else {
      children.push(h("div", { class: "empty-state" }, h("div", { class: "spinner large" })));
    }
    statusArea.replaceChildren(...children);
  }

  const input = h("input", {
    type: "text",
    placeholder: "Search document text, titles, and authors",
    "aria-label": "Search",
  });
  const suffix = h("span", {});
  input.addEventListener("input", () => {
    query = input.value.trim();
    clearTimeout(debounce);
    if (!query) {
      results = [];
      loading = false;
      error = null;
      refresh();
      return;
    }
    loading = true;
    refresh();
    debounce = setTimeout(async () => {
      try {
        results = await searchLibrary(query);
        loading = false;
      } catch (err) {
        results = [];
        loading = false;
        error = String(err);
      }
      refresh();
    }, 280);
  });

  refresh();
  return screenWithAppBar(
    "Search",
    [],
    [
      h("div", { class: "text-field" }, icon("search"), input, suffix),
      h("div", { style: "height:32px" }),
      statusArea,
    ]
  );
}

function snippetParts(record, index, needle, radius = 46) {
  const start = Math.max(0, index - radius);
  const end = Math.min(record.text.length, index + needle.length + radius);
  const prefix = start > 0 ? "…" : "";
  const suffix = end < record.text.length ? "…" : "";
  const before = record.text.slice(start, index);
  const match = record.text.slice(index, index + needle.length);
  const after = record.text.slice(index + needle.length, end);
  return {
    html:
      escapeHtml(prefix + before) +
      "<mark>" +
      escapeHtml(match) +
      "</mark>" +
      escapeHtml(after + suffix),
  };
}

async function searchLibrary(query) {
  const needle = query.toLowerCase();
  const hits = [];
  for (const doc of state.library) {
    const titleMatch = doc.title.toLowerCase().includes(needle);
    const authorMatch = doc.authors.some((a) => a.toLowerCase().includes(needle));
    if (titleMatch || authorMatch) {
      hits.push({
        kind: "metadata",
        documentId: doc.id,
        documentTitle: doc.title,
        label: "Document metadata",
        snippetHtml: null,
        page: null,
      });
    }
    if (doc.format === "pdf") {
      const pages = await ensureIndexed(doc);
      for (const record of pages) {
        const lower = record.text.toLowerCase();
        let index = lower.indexOf(needle);
        let perPage = 0;
        while (index !== -1 && perPage < 3) {
          hits.push({
            kind: "content",
            documentId: doc.id,
            documentTitle: doc.title,
            label: `Page ${record.page}`,
            snippetHtml: snippetParts(record, index, needle).html,
            page: record.page,
          });
          perPage += 1;
          index = lower.indexOf(needle, index + needle.length);
        }
      }
    }
  }
  return hits;
}

function resultCard(hit) {
  return h(
    "button",
    {
      class: "card result-card",
      onclick: () => navigate(`/reader/${encodeURIComponent(hit.documentId)}?page=${hit.page ?? ""}`),
    },
    h("span", { class: "leading" }, icon(hit.kind === "metadata" ? "menu_book" : "description")),
    h(
      "div",
      { class: "body" },
      h("div", { class: "t-title-medium clamp-1" }, hit.documentTitle),
      h("div", { class: "t-label-medium on-surface-variant", style: "margin:4px 0" }, hit.label),
      hit.snippetHtml
        ? h("div", {
            class: "t-body-medium snippet clamp-2 on-surface-variant",
            html: hit.snippetHtml,
          })
        : null
    ),
    h("span", { class: "trailing" }, icon("chevron_right"))
  );
}

function escapeHtml(text) {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

/* --------------------------------------------------------------- insights */

function startOfWeek(timestamp) {
  const date = new Date(timestamp);
  const day = (date.getDay() + 6) % 7; // Monday = 0
  date.setHours(0, 0, 0, 0);
  date.setDate(date.getDate() - day);
  return date.getTime();
}

function renderInsights() {
  const now = Date.now();
  const todayStart = new Date(new Date().setHours(0, 0, 0, 0)).getTime();
  const weekStart = startOfWeek(now);
  const todayMinutes = sumMinutes((s) => s.startedAt >= todayStart);
  const weekMinutes = sumMinutes((s) => s.startedAt >= weekStart);

  const metrics = [
    { label: "Today", value: formatDuration(todayMinutes), icon: "today" },
    { label: "This week", value: formatDuration(weekMinutes), icon: "date_range" },
    { label: "Sessions", value: `${state.sessions.length}`, icon: "timer" },
    { label: "Reading list", value: `${state.readingList.length}`, icon: "playlist_add_check" },
  ];

  const days = [];
  for (let i = 6; i >= 0; i -= 1) {
    const day = new Date(todayStart - i * 86400_000);
    const next = day.getTime() + 86400_000;
    const minutes = sumMinutes((s) => s.startedAt >= day.getTime() && s.startedAt < next);
    days.push({ label: "MTWTFSS"[day.getDay() === 0 ? 6 : day.getDay() - 1], minutes });
  }
  const maxMinutes = Math.max(...days.map((d) => d.minutes), 0);

  const totals = new Map();
  for (const session of state.sessions) {
    totals.set(
      session.documentId,
      (totals.get(session.documentId) ?? 0) + session.activeMinutes
    );
  }
  const ranked = [...totals.entries()].sort((a, b) => b[1] - a[1]).slice(0, 5);
  const byId = new Map(state.library.map((d) => [d.id, d]));

  return screenWithAppBar(
    "Reading insights",
    [],
    [
      h(
        "div",
        { class: "metric-grid" },
        metrics.map((m) =>
          h(
            "div",
            { class: "card metric-card" },
            icon(m.icon),
            h(
              "div",
              {},
              h("div", { class: "t-headline-small" }, m.value),
              h("div", { class: "t-body-small on-surface-variant" }, m.label)
            )
          )
        )
      ),
      h(
        "div",
        { class: "card week-chart" },
        days.map((d) =>
          h(
            "div",
            { class: "week-col" },
            h(
              "div",
              { class: "week-bar-area" },
              h("div", {
                class: "week-bar",
                style: `height:${Math.max(4, maxMinutes === 0 ? 4 : (d.minutes / maxMinutes) * 100)}%;${d.minutes === 0 ? "opacity:.4;" : ""}`,
              })
            ),
            h("div", { class: "t-label-medium on-surface-variant" }, d.label)
          )
        )
      ),
      ranked.length
        ? h(
            "div",
            { class: "card" },
            ranked.map(([docId, minutes], index) =>
              h(
                "div",
                { class: "most-read-row" },
                h("div", { class: "avatar" }, `${index + 1}`),
                h("div", { class: "t-body-large clamp-1", style: "flex:1" }, byId.get(docId)?.title ?? "Document"),
                h("div", { class: "t-body-medium on-surface-variant" }, formatDuration(minutes))
              )
            )
          )
        : h(
            "div",
            { class: "card", style: "padding:32px" },
            "Start reading and your most-read documents will appear here."
          ),
    ]
  );

  function sumMinutes(filter) {
    return state.sessions.filter(filter).reduce((sum, s) => sum + s.activeMinutes, 0);
  }
}

/* ----------------------------------------------------------------- reader */

let readerCleanup = null;

async function renderReader(docId) {
  readerCleanup?.();
  readerCleanup = null;
  const doc = state.library.find((d) => d.id === docId);
  if (!doc) {
    $app.replaceChildren(
      h("div", { class: "reader" },
        h("div", { class: "reader-topbar" },
          h("div", { class: "bar" },
            h("button", { class: "icon-button", title: "Back", onclick: () => navigate("/library") }, icon("arrow_back"))
          )
        ),
        readerNotice("error_outline", "Document not found", "This library item no longer exists.")
      )
    );
    return;
  }
  state.lastOpened[doc.id] = Date.now();
  saveLastOpened();

  if (doc.format !== "pdf") {
    $app.replaceChildren(
      h("div", { class: "reader" },
        readerTopBar(doc, { flowMode: false, annotationCount: 0, onSearch: null, onAnnotations: null }),
        readerNotice(
          "description",
          "Fidelity view is not available yet",
          `${doc.format.toUpperCase()} was imported successfully, but its renderer has not been integrated yet.`
        )
      )
    );
    return;
  }

  const initialPage = parseInitialPage();
  const reader = await buildPdfReader(doc, initialPage);
  $app.replaceChildren(reader.root);
  reader.onAttached();
  readerCleanup = reader.dispose;
}

function parseInitialPage() {
  const page = new URLSearchParams(location.hash.split("?")[1] ?? "").get("page");
  const value = page ? parseInt(page, 10) : NaN;
  return Number.isFinite(value) && value > 0 ? value : null;
}

function readerNotice(iconName, title, message) {
  return h(
    "div",
    { class: "reader-notice" },
    h(
      "div",
      { class: "inner" },
      icon(iconName),
      h("div", { class: "t-title-large" }, title),
      h("div", { class: "t-body-large on-surface-variant" }, message)
    )
  );
}

function readerTopBar(doc, options) {
  const subtitle = doc.authors.length ? doc.authors.join(", ") : doc.format.toUpperCase();
  return h(
    "div",
    { class: "reader-topbar" },
    h(
      "div",
      { class: "bar" },
      h("button", { class: "icon-button", title: "Back", onclick: () => leaveReader() }, icon("arrow_back")),
      h(
        "div",
        { class: "titles" },
        h("div", { class: "t-title-medium clamp-1" }, doc.title),
        h("div", { class: "t-body-small on-surface-variant clamp-1" }, subtitle)
      ),
      h(
        "div",
        { class: "actions" },
        h(
          "div",
          { class: "segmented", role: "tablist" },
          h("button", { class: "selected", title: "Fidelity" }, icon("description")),
          h("button", { disabled: true, title: "Flow not available yet" }, icon("auto_stories"))
        ),
        options.onSearch
          ? h("button", { class: "icon-button", title: "Search this document", onclick: options.onSearch }, icon("search"))
          : h("button", { class: "icon-button", disabled: true, title: "Search is not available for this format yet" }, icon("search")),
        options.onAnnotations
          ? h(
              "button",
              { class: "icon-button", title: "Annotations", onclick: options.onAnnotations },
              icon("format_quote"),
              options.annotationCount > 0
                ? h("span", { class: "badge-count" }, `${options.annotationCount}`)
                : null
            )
          : h("button", { class: "icon-button", disabled: true, title: "Annotations are not available for this format yet" }, icon("format_quote")),
        h("button", { class: "icon-button", title: "More", onclick: () => {} }, icon("more_horiz"))
      )
    )
  );
}

function leaveReader() {
  navigate("/library");
}

async function buildPdfReader(doc, initialPage) {
  const entry = await openDocument(doc);
  const pageCount = entry.pdf.numPages;
  const saved = state.readingStates[doc.id];

  const reader = {
    fitMode: saved?.fitMode === "page" || saved?.fitMode === "custom" ? saved.fitMode : "width",
    customScale: saved?.customScale ?? null,
    spread: false,
    currentPage: saved?.page ?? initialPage ?? doc.seedPage ?? 1,
    scale: 1,
    pages: [],
    observers: [],
    saveTimer: null,
    rendered: new Map(),
    rerenderTimer: null,
  };

  const surface = h("div", { class: "reader-surface" });
  const pagesEl = h("div", { class: "pages" });
  surface.append(pagesEl);

  const pageLabel = h("div", { class: "page-label" }, "Loading pages…");
  const navBar = buildReaderNavBar();
  const topBar = readerTopBar(doc, {
    onSearch: () =>
      openReaderSearchSheet(doc, (hit) => {
        jumpToPage(hit.page);
        flashRange(hit.page, hit.charStart, hit.charEnd);
      }),
    onAnnotations: () =>
      openAnnotationPanel(doc, onAnnotationsChanged, (page) => jumpToPage(page)),
    annotationCount: annotationsFor(doc.id).length,
  });

  function updateAnnotationBadge() {
    const count = annotationsFor(doc.id).length;
    const annotationsButton = [...topBar.querySelectorAll(".icon-button")].find(
      (b) => b.title === "Annotations"
    );
    if (!annotationsButton) return;
    let badge = annotationsButton.querySelector(".badge-count");
    if (count > 0) {
      if (!badge) {
        badge = h("span", { class: "badge-count" });
        annotationsButton.append(badge);
      }
      badge.textContent = `${count}`;
    } else {
      badge?.remove();
    }
  }

  function onAnnotationsChanged() {
    repaintHighlights();
    updateAnnotationBadge();
  }

  const root = h("div", { class: "reader" }, topBar, surface, navBar.root);

  function containerWidth() {
    return surface.clientWidth;
  }
  function containerHeight() {
    return surface.clientHeight;
  }

  function computeScale() {
    const viewport = entry.viewports[1] ?? entry.viewports[reader.currentPage];
    const spreadFactor = reader.spread ? 0.5 : 1;
    const widthScale =
      ((containerWidth() - 32) * spreadFactor - (reader.spread ? 12 : 0)) / viewport.width;
    if (reader.fitMode === "page") {
      const heightScale = (containerHeight() - 32) / viewport.height;
      return Math.min(widthScale, heightScale);
    }
    if (reader.fitMode === "custom" && reader.customScale) return reader.customScale;
    return widthScale;
  }

  function layout() {
    // Skip while the reader is detached: the container has no real width yet
    // and the first real layout happens in onAttached().
    if (!surface.isConnected || surface.clientWidth === 0) return;
    reader.scale = Math.min(6, Math.max(0.25, computeScale()));
    for (const page of reader.pages) {
      sizePage(page);
      if (page.built) relayoutTextLayer(page);
    }
    scheduleRerender();
    repaintHighlights();
  }

  function sizePage(page) {
    const viewport = entry.viewports[page.number];
    page.el.style.width = `${viewport.width * reader.scale}px`;
    page.el.style.height = `${viewport.height * reader.scale}px`;
  }

  function scheduleRerender() {
    clearTimeout(reader.rerenderTimer);
    reader.rerenderTimer = setTimeout(() => renderVisiblePages(), 60);
  }

  /* ---- page construction ---- */
  for (let number = 1; number <= pageCount; number += 1) {
    const el = h("div", { class: "pdf-page", dataset: { page: number } });
    const page = { number, el, built: false, canvas: null, textLayerEl: null, items: null, record: null };
    reader.pages.push(page);
    pagesEl.append(el);
    const observer = new IntersectionObserver(
      (records) => {
        for (const record of records) {
          if (record.isIntersecting) {
            renderPage(page);
          }
        }
      },
      { root: surface, threshold: [0] }
    );
    observer.observe(el);
    reader.observers.push(observer);
  }

  async function buildPage(page) {
    if (page.built || page.building) return;
    page.building = true;
    const record = await pageTextItems(doc, page.number);
    page.record = record;
    page.items = record.items;
    const canvas = document.createElement("canvas");
    const hlLayer = h("div", { class: "hl-layer" });
    const textLayer = h("div", { class: "text-layer" });
    for (const [index, item] of record.items.entries()) {
      const span = h("span", { dataset: { item: index } }, item.str);
      textLayer.append(span);
    }
    page.canvas = canvas;
    page.textLayerEl = textLayer;
    page.hlLayerEl = hlLayer;
    page.el.append(canvas, hlLayer, textLayer);
    sizePage(page);
    page.built = true;
    page.building = false;
    relayoutTextLayer(page);
    renderPage(page);
    paintPageHighlights(page);
  }

  function relayoutTextLayer(page) {
    if (!page.textLayerEl || !page.items) return;
    const spans = page.textLayerEl.children;
    for (let index = 0; index < page.items.length; index += 1) {
      const item = page.items[index];
      const span = spans[index];
      const fontSize = item.height * reader.scale;
      span.style.transform = "none";
      span.style.left = `${item.left * reader.scale}px`;
      span.style.top = `${(page.record.pageHeight - item.baseline) * reader.scale - fontSize * 0.78}px`;
      span.style.fontSize = `${fontSize}px`;
      const measured = span.getBoundingClientRect().width;
      const target = item.width * reader.scale;
      const ratio = measured > 0 && target > 0 ? target / measured : 1;
      span.style.transform = `scaleX(${ratio})`;
    }
  }

  async function renderPage(page) {
    if (!page.built) {
      buildPage(page);
      return;
    }
    const desired = reader.scale * Math.min(window.devicePixelRatio || 1, 1.5);
    const rounded = Math.round(desired * 20) / 20;
    if (reader.rendered.get(page.number) === rounded) return;
    if (page.renderTask) {
      try {
        page.renderTask.cancel();
        await page.renderTask.promise;
      } catch {
        // previous render cancelled or already done
      }
    }
    reader.rendered.set(page.number, rounded);
    const pageProxy = await entry.pdf.getPage(page.number);
    const viewport = pageProxy.getViewport({ scale: rounded });
    page.canvas.width = viewport.width;
    page.canvas.height = viewport.height;
    const task = pageProxy.render({
      canvasContext: page.canvas.getContext("2d"),
      viewport,
    });
    page.renderTask = task;
    try {
      await task.promise;
    } catch (error) {
      if (error?.name !== "RenderingCancelledException") {
        reader.rendered.delete(page.number);
        console.error("Kola preview: page render failed", error);
      }
    }
  }

  function renderVisiblePages() {
    const rect = surface.getBoundingClientRect();
    for (const page of reader.pages) {
      const box = page.el.getBoundingClientRect();
      const visible = box.bottom > rect.top - 400 && box.top < rect.bottom + 400;
      if (visible) renderPage(page);
    }
  }

  /* ---- highlights ---- */
  function repaintHighlights() {
    for (const page of reader.pages) {
      if (page.built) paintPageHighlights(page);
    }
  }

  function paintPageHighlights(page) {
    if (!page.hlLayerEl || !page.items) return;
    const annotations = annotationsFor(doc.id).filter((a) => a.page === page.number);
    page.hlLayerEl.replaceChildren();
    for (const annotation of annotations) {
      paintRange(page, annotation.start, annotation.end, highlightCss(annotation.color, 0.35));
    }
  }

  function paintRange(page, start, end, css, flash = false) {
    if (!page.items || !page.hlLayerEl) return;
    for (const item of page.items) {
      const itemStart = item.offset;
      const itemEnd = item.offset + item.str.length;
      if (itemEnd <= start || itemStart >= end) continue;
      const localStart = Math.max(0, start - itemStart);
      const localEnd = Math.min(item.str.length, end - itemStart);
      if (localEnd <= localStart) continue;
      const left = (item.left + (item.width * localStart) / item.str.length) * reader.scale;
      const width = ((item.width * (localEnd - localStart)) / item.str.length) * reader.scale;
      const fontSize = item.height * reader.scale;
      const top = (page.record.pageHeight - item.baseline) * reader.scale - fontSize * 0.78;
      page.hlLayerEl.append(
        h("div", {
          class: flash ? "hl hl-flash" : "hl",
          style: `left:${left}px;top:${top}px;width:${width}px;height:${fontSize + 1}px;background:${css}`,
        })
      );
    }
  }

  async function flashRange(pageNumber, start, end) {
    const page = reader.pages[pageNumber - 1];
    if (!page) return;
    if (!page.built) await buildPage(page);
    paintRange(page, start, end, "rgba(255, 235, 59, 0.65)", true);
  }

  /* ---- navigation / state ---- */
  let scrollSyncTimer = null;
  function syncCurrentPageFromScroll() {
    const surfaceRect = surface.getBoundingClientRect();
    const middle = surfaceRect.top + surfaceRect.height / 2;
    let best = reader.currentPage;
    for (const page of reader.pages) {
      const box = page.el.getBoundingClientRect();
      if (box.top <= middle && box.bottom >= middle) {
        best = page.number;
        break;
      }
    }
    if (best !== reader.currentPage) {
      reader.currentPage = best;
      updatePageLabel();
      scheduleStateSave();
    }
  }

  function updatePageLabel() {
    pageLabel.textContent = `Page ${reader.currentPage} of ${pageCount}`;
  }

  function jumpToPage(pageNumber) {
    const target = Math.min(pageCount, Math.max(1, pageNumber));
    const page = reader.pages[target - 1];
    if (!page) return;
    if (target !== reader.currentPage) {
      reader.currentPage = target;
      updatePageLabel();
      scheduleStateSave();
    }
    page.el.scrollIntoView({ block: "start", behavior: "auto" });
  }

  function scheduleStateSave() {
    clearTimeout(reader.saveTimer);
    reader.saveTimer = setTimeout(() => {
      state.readingStates[doc.id] = {
        page: reader.currentPage,
        fitMode: reader.fitMode,
        customScale: reader.fitMode === "custom" ? reader.scale : null,
        updatedAt: Date.now(),
      };
      saveReadingStates();
    }, 400);
  }

  /* ---- nav bar ---- */
  function buildReaderNavBar() {
    const pageLabelEl = pageLabel;
    const outlineBtn = h(
      "button",
      {
        class: "icon-button",
        title: "Contents",
        onclick: () => openOutlineSheet(doc, jumpToPage),
      },
      icon("menu_book")
    );
    const thumbsBtn = h(
      "button",
      { class: "icon-button", title: "Pages", onclick: () => openThumbnailsSheet(doc, reader, jumpToPage) },
      icon("grid_view")
    );
    const fitBtn = h(
      "button",
      {
        class: "icon-button",
        title: "Fit view",
        onclick: (event) =>
          openMenu(event.currentTarget, [
            {
              icon: "swap_horiz",
              label: "Fit width",
              onclick: () => setFit("width"),
            },
            { icon: "crop_free", label: "Fit page", onclick: () => setFit("page") },
          ]),
      },
      icon("fit_screen")
    );
    const layoutBtn = h(
      "button",
      {
        class: "icon-button",
        title: "Page layout",
        onclick: (event) =>
          openMenu(event.currentTarget, [
            {
              label: "Single page",
              checked: !reader.spread,
              onclick: () => setSpread(false),
            },
            {
              label: "Two-page spread",
              checked: reader.spread,
              onclick: () => setSpread(true),
            },
          ]),
      },
      icon("view_week")
    );

    const bar = h(
      "div",
      { class: "bar" },
      outlineBtn,
      thumbsBtn,
      fitBtn,
      layoutBtn,
      h("button", { class: "icon-button", title: "Previous page", onclick: () => jumpToPage(reader.currentPage - 1) }, icon("chevron_left")),
      pageLabelEl,
      h("button", { class: "icon-button", title: "Next page", onclick: () => jumpToPage(reader.currentPage + 1) }, icon("chevron_right")),
      h("span", { style: "width:8px" }),
      h("button", { class: "icon-button", title: "Zoom out", onclick: () => setZoom(reader.scale * 0.8) }, icon("remove")),
      h("button", { class: "icon-button", title: "Zoom in", onclick: () => setZoom(reader.scale * 1.25) }, icon("add"))
    );
    const root = h("div", { class: "reader-nav" }, bar);

    function refreshLayoutAvailability() {
      layoutBtn.style.display = containerWidth() >= 840 ? "" : "none";
      if (containerWidth() < 840 && reader.spread) setSpread(false);
    }

    return { root, refreshLayoutAvailability };
  }

  function setFit(mode) {
    reader.fitMode = mode;
    reader.customScale = null;
    layout();
    scheduleStateSave();
  }

  function setZoom(scale) {
    reader.fitMode = "custom";
    reader.customScale = Math.min(6, Math.max(0.25, scale));
    layout();
    scheduleStateSave();
  }

  function setSpread(enabled) {
    reader.spread = enabled;
    pagesEl.classList.toggle("spread", enabled);
    layout();
  }

  /* ---- selection → highlight ---- */
  let lastSelectionRange = null;
  const selectionButton = h(
    "button",
    {
      class: "filled-button selection-action",
      style: "display:none",
    },
    icon("highlight"),
    "Highlight"
  );
  // Prevent the click from collapsing the selection before it is read.
  selectionButton.addEventListener("pointerdown", (event) => event.preventDefault());
  selectionButton.addEventListener("click", () => createHighlightFromSelection());
  document.body.append(selectionButton);

  function hideSelectionButton() {
    selectionButton.style.display = "none";
  }

  function createHighlightFromSelection() {
    const range = lastSelectionRange;
    lastSelectionRange = null;
    hideSelectionButton();
    if (!range) return;
    const list = state.annotations[doc.id] ?? (state.annotations[doc.id] = []);
    const annotation = {
      id: `annotation-${Date.now()}`,
      page: range.page,
      start: range.start,
      end: range.end,
      quote: range.quote,
      note: null,
      color: "highlight.yellow",
      createdAt: Date.now(),
    };
    list.push(annotation);
    saveAnnotations();
    window.getSelection()?.removeAllRanges();
    const page = reader.pages[range.page - 1];
    if (page?.built) paintPageHighlights(page);
    updateAnnotationBadge();
    showSnackbar("Highlight saved.");
  }

  function currentSelectionRange() {
    const selection = window.getSelection();
    if (!selection || selection.isCollapsed || selection.rangeCount === 0) return null;
    const spanFor = (node) =>
      (node instanceof Element ? node : node?.parentElement)?.closest("span[data-item]");
    const anchorSpan = spanFor(selection.anchorNode);
    const focusSpan = spanFor(selection.focusNode);
    if (!anchorSpan || !focusSpan) return null;
    const pageEl = anchorSpan.closest(".pdf-page");
    if (!pageEl || pageEl !== focusSpan.closest(".pdf-page")) return null;
    const pageNumber = Number(pageEl.dataset.page);
    const page = reader.pages[pageNumber - 1];
    if (!page?.record) return null;
    const a = {
      item: Number(anchorSpan.dataset.item),
      off: selection.anchorOffset,
    };
    const f = { item: Number(focusSpan.dataset.item), off: selection.focusOffset };
    let start = a;
    let end = f;
    if (
      a.item > f.item ||
      (a.item === f.item && a.off > f.off)
    ) {
      start = f;
      end = a;
    }
    const items = page.record.items;
    const startItem = items[start.item];
    const endItem = items[end.item];
    if (!startItem || !endItem) return null;
    const charStart = startItem.offset + Math.min(start.off, startItem.str.length);
    const charEnd = endItem.offset + Math.min(end.off, endItem.str.length);
    if (charEnd <= charStart) return null;
    return {
      page: pageNumber,
      start: charStart,
      end: charEnd,
      quote: page.record.text.slice(charStart, charEnd).trim(),
    };
  }

  function onSelectionChange() {
    const selection = window.getSelection();
    if (!selection || selection.isCollapsed || selection.rangeCount === 0) {
      hideSelectionButton();
      return;
    }
    const range = currentSelectionRange();
    if (!range) {
      hideSelectionButton();
      return;
    }
    lastSelectionRange = range;
    const rect = selection.getRangeAt(0).getBoundingClientRect();
    selectionButton.style.display = "";
    selectionButton.style.left = `${Math.min(window.innerWidth - 90, Math.max(90, rect.left + rect.width / 2))}px`;
    selectionButton.style.top = `${Math.max(48, rect.top - 8)}px`;
  }

  const selectionHandler = () => onSelectionChange();
  document.addEventListener("selectionchange", selectionHandler);
  surface.addEventListener("scroll", hideSelectionButton);
  surface.addEventListener("scroll", () => {
    if (scrollSyncTimer) return;
    scrollSyncTimer = setTimeout(() => {
      scrollSyncTimer = null;
      syncCurrentPageFromScroll();
    }, 120);
  });

  /* ---- boot ---- */
  const resizeObserver = new ResizeObserver(() => {
    layout();
    navBar.refreshLayoutAvailability();
  });
  resizeObserver.observe(surface);

  updatePageLabel();

  // Must run after the reader is attached to the document, so the scroll
  // container has real geometry.
  function onAttached() {
    layout();
    navBar.refreshLayoutAvailability();
    const initialTarget = reader.pages[reader.currentPage - 1];
    initialTarget?.el.scrollIntoView({ block: "start" });
    syncCurrentPageFromScroll();
    renderVisiblePages();
  }

  function dispose() {
    reader.observers.forEach((o) => o.disconnect());
    resizeObserver.disconnect();
    document.removeEventListener("selectionchange", selectionHandler);
    clearTimeout(reader.saveTimer);
    clearTimeout(reader.rerenderTimer);
    clearTimeout(scrollSyncTimer);
    selectionButton.remove();
  }

  return { root, dispose, flashRange, onAttached };
}

/* ------------------------------------------------------- reader sub-sheets */

function openReaderSearchSheet(doc, onOpenHit) {
  let debounce = null;
  const listEl = h("div", { class: "sheet-body" });
  const statusEl = h(
    "div",
    { class: "t-body-large on-surface-variant", style: "text-align:center;margin:auto;padding:16px" },
    "Search is local. The document is indexed on this device when needed."
  );

  const input = h("input", { type: "text", placeholder: "Find words or phrases" });
  input.addEventListener("input", () => {
    clearTimeout(debounce);
    const query = input.value.trim();
    if (!query) {
      listEl.replaceChildren();
      listEl.append(statusEl);
      return;
    }
    listEl.replaceChildren(
      h("div", { class: "empty-state" }, h("div", { class: "spinner large" }))
    );
    debounce = setTimeout(async () => {
      try {
        const hits = await searchInDocument(doc, query);
        if (input.value.trim() !== query) return;
        if (hits.length === 0) {
          listEl.replaceChildren(
            h("div", { class: "empty-state" }, h("div", { class: "t-body-large" }, "No matches found."))
          );
          return;
        }
        listEl.replaceChildren(
          ...hits.map((hit) =>
            h(
              "button",
              {
                class: "search-hit-row",
                onclick: () => {
                  closeSheets();
                  onOpenHit(hit);
                },
              },
              h("div", { class: "avatar" }, `${hit.page}`),
              h(
                "div",
                { class: "search-hit-body" },
                h("div", { class: "t-title-small clamp-1" }, `Page ${hit.page}`),
                h("div", {
                  class: "t-body-medium snippet clamp-2 on-surface-variant",
                  html: hit.snippetHtml,
                })
              ),
              h("span", { class: "trailing on-surface-variant", style: "align-self:center" }, icon("chevron_right"))
            )
          )
        );
      } catch (error) {
        listEl.replaceChildren(
          h("div", { class: "empty-state", style: "color:var(--error)" }, `Kola could not index this document.\n${error}`)
        );
      }
    }, 250);
  });

  openSheet(
    h(
      "div",
      { class: "sheet" },
      h("div", { class: "sheet-handle" }),
      h("div", { class: "t-title-large clamp-1" }, `Search in ${doc.title}`),
      h("div", { style: "height:16px" }),
      h("div", { class: "text-field" }, icon("search"), input),
      h("div", { style: "height:16px" }),
      listEl
    ),
    () => setTimeout(() => input.focus(), 100)
  );
  listEl.append(statusEl);
}

async function searchInDocument(doc, query) {
  const pages = await ensureIndexed(doc);
  const needle = query.toLowerCase();
  const hits = [];
  for (const record of pages) {
    const lower = record.text.toLowerCase();
    let index = lower.indexOf(needle);
    let perPage = 0;
    while (index !== -1 && perPage < 4) {
      hits.push({
        page: record.page,
        snippetHtml: snippetParts(record, index, needle, 50).html,
        charStart: index,
        charEnd: index + needle.length,
      });
      perPage += 1;
      index = lower.indexOf(needle, index + needle.length);
    }
  }
  return hits.slice(0, 60);
}

function openAnnotationPanel(doc, onChange, goToPage) {
  const body = h("div", { class: "sheet-body" });

  function renderList() {
    const annotations = annotationsFor(doc.id);
    if (annotations.length === 0) {
      body.replaceChildren(
        h(
          "div",
          { class: "empty-state" },
          icon("format_quote"),
          h("div", { class: "t-title-medium" }, "No annotations yet"),
          h(
            "div",
            { class: "t-body-large on-surface-variant" },
            "Select text in the document and choose Highlight. Your annotations will appear here."
          )
        )
      );
      return;
    }
    body.replaceChildren(
      ...annotations.map((annotation) => annotationCard(annotation))
    );
  }

  function annotationCard(annotation) {
    return h(
      "div",
      { class: "annotation-card" },
      h(
        "div",
        { class: "annotation-head" },
        h("div", { class: "color-marker", style: `background:${highlightCss(annotation.color, 1)}` }),
        h("div", { class: "t-body-large clamp-4", style: "flex:1" }, annotation.quote || "Annotation"),
        h(
          "button",
          {
            class: "icon-button",
            title: "Annotation actions",
            onclick: (event) =>
              openMenu(event.currentTarget, [
                {
                  icon: "note_alt",
                  label: "Add or edit note",
                  onclick: () => editNote(annotation),
                },
                { icon: "delete", label: "Delete", onclick: () => confirmDelete(annotation) },
              ]),
          },
          icon("more_horiz")
        )
      ),
      h(
        "div",
        { class: "annotation-loc" },
        icon("location_on"),
        h("span", { class: "t-body-small on-surface-variant" }, `Page ${annotation.page}`),
        h("span", { style: "flex:1" }),
        h(
          "button",
          {
            class: "text-button",
            onclick: () => {
              closeSheets();
              goToPage(annotation.page);
            },
          },
          icon("arrow_forward"),
          "Go to"
        )
      ),
      annotation.note?.trim()
        ? h("div", { class: "annotation-note t-body-medium" }, annotation.note)
        : null,
      h(
        "div",
        { class: "swatches" },
        Object.entries(HIGHLIGHT_COLORS).map(([token, hex]) =>
          h(
            "button",
            {
              class: `swatch${annotation.color === token ? " selected" : ""}`,
              title: `${HIGHLIGHT_NAMES[token]} highlight`,
              "aria-label": `${HIGHLIGHT_NAMES[token]} highlight`,
              onclick: () => {
                annotation.color = token;
                saveAnnotations();
                onChange();
                renderList();
              },
            },
            h("div", { class: "dot", style: `background:${hex}` })
          )
        )
      )
    );
  }

  function editNote(annotation) {
    closeMenus();
    openDialog({
      title: "Annotation note",
      body: (actions) => {
        const textarea = h("textarea", { "aria-label": "Note" });
        textarea.value = annotation.note ?? "";
        setTimeout(() => textarea.focus(), 60);
        actions.push(
          h("button", { class: "text-button", onclick: closeDialogs }, "Cancel"),
          h(
            "button",
            {
              class: "filled-button",
              onclick: () => {
                annotation.note = textarea.value;
                saveAnnotations();
                closeDialogs();
                renderList();
                onChange();
              },
            },
            "Save"
          )
        );
        return textarea;
      },
    });
  }

  function confirmDelete(annotation) {
    closeMenus();
    openDialog({
      title: "Delete annotation?",
      body: (actions) => {
        actions.push(
          h("button", { class: "text-button", onclick: closeDialogs }, "Cancel"),
          h(
            "button",
            {
              class: "filled-button",
              style: "background:var(--error);color:#fff",
              onclick: () => {
                state.annotations[doc.id] = annotationsFor(doc.id).filter((a) => a.id !== annotation.id);
                saveAnnotations();
                closeDialogs();
                renderList();
                onChange();
              },
            },
            "Delete"
          )
        );
        return h(
          "div",
          { class: "t-body-medium" },
          "The highlight and its attached note will be removed from the reader."
        );
      },
    });
  }

  renderList();
  openSheet(
    h(
      "div",
      { class: "sheet tall" },
      h("div", { class: "sheet-handle" }),
      h(
        "div",
        { class: "sheet-header" },
        h("div", { class: "t-title-large", style: "flex:1" }, "Annotations"),
        h("div", { class: "t-label-large" }, `${annotationsFor(doc.id).length}`)
      ),
      body
    )
  );
}

function openOutlineSheet(doc, jumpToPage) {
  const outline = doc.outline ?? [];
  openSheet(
    h(
      "div",
      { class: "sheet" },
      h("div", { class: "sheet-handle" }),
      h("div", { class: "sheet-header" }, h("div", { class: "t-title-large", style: "flex:1" }, "Contents")),
      h(
        "div",
        { class: "sheet-body" },
        outline.length
          ? outline.map((entry) =>
              h(
                "button",
                {
                  class: "outline-row",
                  onclick: () => {
                    closeSheets();
                    jumpToPage(entry.page);
                  },
                },
                h("span", { class: "t-body-large", style: `padding-left:${(entry.level ?? 0) * 16}px;flex:1` }, entry.title),
                h("span", { class: "t-body-medium on-surface-variant" }, `Page ${entry.page}`)
              )
            )
          : h(
              "div",
              { class: "empty-state" },
              h("div", { class: "t-body-large" }, "This PDF has no contents outline.")
            )
      )
    )
  );
}

function openThumbnailsSheet(doc, reader, jumpToPage) {
  const entry = state.docCache.get(doc.id);
  const pageCount = entry?.pdf.numPages ?? 0;
  const grid = h("div", { class: "thumb-grid" });

  async function renderThumb(cell, number) {
    const pageProxy = await entry.pdf.getPage(number);
    const base = pageProxy.getViewport({ scale: 1 });
    const scale = 130 / base.width;
    const viewport = pageProxy.getViewport({ scale });
    const canvas = h("canvas", { width: viewport.width, height: viewport.height });
    await pageProxy.render({
      canvas,
      canvasContext: canvas.getContext("2d"),
      viewport,
    }).promise;
    cell.replaceChildren(canvas);
  }

  const cells = [];
  for (let number = 1; number <= pageCount; number += 1) {
    const frame = h("div", { class: "frame" }, h("div", { class: "spinner" }));
    const cell = h(
      "button",
      {
        class: `thumb-cell${reader.currentPage === number ? " current" : ""}`,
        onclick: () => {
          closeSheets();
          jumpToPage(number);
        },
      },
      frame,
      h("div", { class: "t-label-medium" }, `${number}`)
    );
    cells.push({ cell, frame, number });
    grid.append(cell);
  }

  const sheetBody = h("div", { class: "sheet-body" }, grid);
  const observer = new IntersectionObserver(
    (records, obs) => {
      for (const record of records) {
        if (!record.isIntersecting) continue;
        obs.unobserve(record.target);
        const match = cells.find((c) => c.cell === record.target);
        if (match) renderThumb(match.frame, match.number);
      }
    },
    { root: sheetBody, rootMargin: "200px" }
  );
  cells.forEach((c) => observer.observe(c.cell));

  openSheet(
    h(
      "div",
      { class: "sheet" },
      h("div", { class: "sheet-handle" }),
      h("div", { class: "sheet-header" }, h("div", { class: "t-title-large", style: "flex:1" }, "Pages")),
      sheetBody
    ),
    () => {},
    () => observer.disconnect()
  );
}

/* -------------------------------------------------------------- overlays */

let sheetOnClose = null;

function openSheet(sheet, onOpen, onClose) {
  closeSheets();
  closeMenus();
  closeDialogs();
  sheetOnClose = onClose ?? null;
  const scrim = h("div", {
    class: "scrim",
    style: "pointer-events:auto",
    onclick: () => closeSheets(),
  });
  const wrap = h("div", { class: "sheet-wrap" }, sheet);
  $sheetLayer.replaceChildren(scrim, wrap);
  onOpen?.();
}

function closeSheets() {
  if (!$sheetLayer.querySelector(".sheet-wrap")) return;
  sheetOnClose?.();
  sheetOnClose = null;
  $sheetLayer.replaceChildren();
}

function openDialog({ title, body }) {
  const actions = [];
  const content = body(actions);
  const wrap = h(
    "div",
    { class: "dialog-wrap", style: "pointer-events:auto" },
    h(
      "div",
      { class: "dialog", role: "dialog", "aria-label": title },
      h("div", { class: "t-headline-small" }, title),
      content,
      h("div", { class: "dialog-actions" }, actions)
    )
  );
  $dialogLayer.replaceChildren(wrap);
}

function closeDialogs() {
  $dialogLayer.replaceChildren();
}

function openMenu(anchor, items) {
  closeMenus();
  const menu = h(
    "div",
    { class: "menu", role: "menu", style: "pointer-events:auto" },
    items.map((item) =>
      h(
        "button",
        {
          class: "menu-item",
          role: "menuitem",
          onclick: () => {
            closeMenus();
            item.onclick?.();
          },
        },
        item.icon ? icon(item.icon) : h("span", { style: "width:20px" }),
        item.label,
        item.checked ? h("span", { class: "check" }, icon("check")) : null
      )
    )
  );
  const rect = anchor.getBoundingClientRect();
  $menuLayer.append(menu);
  const menuBox = menu.getBoundingClientRect();
  const left = Math.min(window.innerWidth - menuBox.width - 8, rect.left);
  const top = Math.min(window.innerHeight - menuBox.height - 8, rect.bottom + 4);
  menu.style.left = `${Math.max(8, left)}px`;
  menu.style.top = `${Math.max(8, top)}px`;
  setTimeout(() => {
    document.addEventListener("pointerdown", onDocPointerDown, { once: true });
  }, 0);
  function onDocPointerDown(event) {
    if (!menu.contains(event.target)) closeMenus();
    else document.addEventListener("pointerdown", onDocPointerDown, { once: true });
  }
}

function closeMenus() {
  $menuLayer.replaceChildren();
}

function closeAllOverlays() {
  closeSheets();
  closeDialogs();
  closeMenus();
  document.querySelectorAll(".selection-action").forEach((el) => el.remove());
}

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") closeAllOverlays();
});

let snackbarTimer = null;
function showSnackbar(message) {
  clearTimeout(snackbarTimer);
  const existing = document.querySelector(".snackbar");
  existing?.remove();
  const snackbar = h("div", { class: "snackbar" }, message);
  document.body.append(snackbar);
  snackbarTimer = setTimeout(() => snackbar.remove(), 4000);
}

/* ------------------------------------------------------------- responsive */

const mediaCompact = window.matchMedia("(max-width: 599px)");
const mediaExtended = window.matchMedia("(min-width: 1200px)");
for (const media of [mediaCompact, mediaExtended]) {
  media.addEventListener("change", () => {
    if (!currentPath().startsWith("/reader")) render().catch(() => {});
  });
}

/* --------------------------------------------------------------- start */

bootData()
  .then(() => render())
  .catch((error) => {
    console.error(error);
    $app.replaceChildren(
      h(
        "div",
        { style: "display:grid;place-items:center;height:100vh;padding:32px;text-align:center" },
        h("div", {}, `Preview harness failed to load: ${error}`)
      )
    );
  });
