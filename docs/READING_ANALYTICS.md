# Kola — Reading Intelligence & Reading List

This specification defines Kola's local-first reading analytics, session tracking, goals, history, and planned-reading system.

The product goal is not to turn reading into a compulsive scoreboard. Analytics should help users understand their habits, remember what they read, plan what to read next, and sustain intentional reading.

## 1. Product principles

1. **Useful, not addictive.** Analytics inform; they do not punish users for missing streaks.
2. **Active time, not open-app time.** Kola tracks meaningful reading activity rather than simply counting how long a document window exists.
3. **Private by default.** Reading history and analytics stay local unless explicitly included in BYOC sync.
4. **Cross-format.** Books, PDFs, papers, DOCX, presentations, comics, and other documents use the same high-level analytics model.
5. **Explainable metrics.** Users should understand what a number means and how Kola calculated it.
6. **Correctness before gamification.** Never present false precision from weak tracking data.

## 2. Reading Dashboard

The dashboard provides a compact overview of reading behavior.

### Primary overview

Suggested cards:

```text
Today
42 min

This week
4 h 18 min

Books/documents read
6

Current streak
4 days
```

Streaks are optional and visually secondary.

### Continue Reading

Each item may display:

- cover/thumbnail;
- title;
- position progress;
- actual reading coverage;
- time spent reading;
- last read date;
- estimated time remaining when confidence is sufficient.

Example:

```text
Deep Work
63% position · 48% actually read
3 h 42 min read
~2 h remaining
```

## 3. Per-document analytics

Every document can expose a `Reading Insights` view.

Metrics may include:

- total active reading time;
- number of reading sessions;
- average session duration;
- longest session;
- first opened date;
- last read date;
- position progress;
- reading coverage;
- completion date;
- number of highlights;
- number of notes;
- bookmarks;
- pages/chapters/slides/semantic units covered;
- estimated reading pace when meaningful;
- estimated remaining time;
- timeline of progress over time.

### Example

```text
The Design of Everyday Things

Progress             68%
Actually read         61%
Reading time          5 h 24 min
Sessions              11
Average session       29 min
Highlights            38
Notes                 12
Started               Sep 3
Last read              Today
```

## 4. Active reading time

Kola must not equate `document open duration` with `reading duration`.

### Reading session lifecycle

A session begins when:

- a readable document is visible;
- the app/window is active;
- the user interacts or content meaningfully enters the viewport.

A session becomes idle when signals indicate the user is probably not actively reading.

Potential signals:

- application moves to background;
- device locks/sleeps;
- reader loses foreground focus for a sustained period;
- no scrolling/page turning/selection/navigation for an idle threshold;
- pointer/keyboard/touch inactivity combined with unchanged viewport;
- media/presentation modes may use format-specific rules.

Do not terminate active reading immediately merely because the user does not interact: a person may legitimately read one page for several minutes.

### Recommended model

Use state rather than one simple timeout:

```text
Inactive
  -> ActiveReading
  -> PassiveReadingCandidate
  -> Idle
```

`ActiveReading` accumulates time.

`PassiveReadingCandidate` may continue accumulating for a bounded dwell period if a readable viewport remains visible.

`Idle` does not accumulate reading time.

### User correction

Users should be able to correct obviously wrong sessions later:

- edit session duration;
- delete session;
- mark a session as not reading.

## 5. Reading sessions

Each session is stored independently.

```text
ReadingSession
- id
- documentId
- startedAt
- endedAt
- activeDurationMs
- passiveDurationMs optional
- startLocator
- endLocator
- coverageDelta
- platform/device id optional
- source (`automatic`, `manual`, `imported`)
```

Sessions power analytics without mutating source documents.

## 6. Time views

Users should be able to inspect reading time by:

- today;
- yesterday;
- this week;
- last 7 days;
- this month;
- last 30 days;
- year;
- custom date range.

Breakdowns:

- by document;
- by collection;
- by format;
- by tag;
- by day/week/month.

Example:

```text
This week — 4 h 18 min

Deep Work                  1 h 42 m
Research papers            1 h 08 m
Rust Book                    54 m
Other                        34 m
```

## 7. Reading history

Kola maintains a private timeline:

```text
Today
21:10  Deep Work               24 min
18:42  GPU Architecture.pdf    38 min

Yesterday
22:05  Rust Book               46 min
```

Users may disable history tracking or delete history without deleting documents/annotations.

## 8. Reading calendar / heatmap

Optional calendar view shows days with reading activity.

Use intensity to represent active time, but never make missed days visually punitive.

Selecting a date shows:

- total reading time;
- documents read;
- sessions;
- highlights/notes created;
- coverage gained.

## 9. Reading List / Want to Read

Kola needs a first-class planned-reading system rather than forcing users to misuse Favorites.

Default reading-list states:

- Want to Read
- Next Up
- Reading
- Paused
- Completed
- Abandoned / Not for Me (optional)

These are user organization states; they do not delete or alter documents.

### Add to list

A user can add:

- an imported local document;
- a document already in the library;
- a lightweight planned-book entry that does not yet have a local file.

A planned entry may contain:

```text
PlannedReadingItem
- id
- title
- author optional
- cover optional local image
- notes optional
- status
- priority
- addedAt
- targetDate optional
- linkedDocumentId optional
- tags
```

This allows users to plan books before obtaining/importing their file.

## 10. Reading Queue

`Next Up` can be manually ordered.

Example:

```text
NEXT UP
1. Designing Data-Intensive Applications
2. The Rust Programming Language
3. Atomic Habits
4. Research Paper — Transformers
```

Support drag/reorder on desktop and touch reorder on mobile.

Do not algorithmically rearrange the queue without explicit user action.

## 11. Reading goals

Goals are optional.

Supported goal types may include:

- minutes per day;
- hours per week;
- documents/books completed per month/year;
- custom reading target.

Examples:

```text
20 minutes per day
5 hours per week
12 books this year
```

Goals should use neutral language:

- `18 / 20 min today`
- `4.2 / 5 h this week`

Avoid guilt-heavy warnings such as `You broke your streak!`.

## 12. Streaks

Streaks can exist, but are secondary and optional.

Rules:

- user can hide streaks;
- no push notification pressure by default;
- a streak is derived from a configurable minimum active-reading threshold;
- historical edits recalculate streaks deterministically.

## 13. Completion analytics

Useful summaries:

- completed this month/year;
- completion rate of started items;
- average days from start to completion;
- total active reading time per completed document;
- abandoned/paused counts, if user uses those states.

Never imply that completing more books is inherently better.

## 14. Reading pace and estimated time remaining

For sequential text-heavy documents, Kola may estimate pace using observed active reading time and covered semantic weight.

Conceptually:

```text
pace = covered_content_weight / trusted_active_time
remaining_time = uncovered_weight / recent_smoothed_pace
```

Rules:

- require enough history before showing an estimate;
- prefer recent smoothed sessions over lifetime pace;
- suppress estimates for formats where the metric is misleading;
- label estimates (`~2 h remaining`) rather than false precision (`1h 53m 12s`).

## 15. Annotation analytics

Useful, non-competitive metrics:

- highlights created;
- notes written;
- bookmarks created;
- semantic highlight distribution;
- annotations per chapter/section;
- recently annotated documents.

These should support review workflows, not merely produce numbers.

## 16. Collections and subject analytics

If documents use tags/collections, users can answer questions such as:

- How much time did I spend on Rust this month?
- Which course PDFs did I read this week?
- What percentage of my `AI` collection have I actually covered?
- Which unfinished documents have I not opened recently?

All queries operate locally over Kola's database.

## 17. Dashboard information hierarchy

Analytics must not dominate Kola's Home screen.

Recommended Home hierarchy:

1. Continue Reading
2. Next Up / Reading List
3. Recent documents
4. Compact reading insight
5. Optional goals/streak card

A dedicated `Insights` / `Reading Stats` destination provides deeper charts.

## 18. Visual design

Analytics should match Kola's evidence-based visual system.

Use:

- restrained charts;
- strong typography;
- generous whitespace;
- progressive disclosure;
- meaningful animation only when data changes;
- accessible labels in addition to color;
- calm progress rings/bars rather than arcade-style badges.

Avoid:

- excessive badges;
- confetti for routine actions;
- aggressive red failure states for missed goals;
- leaderboard-like patterns;
- dopamine-oriented notification loops.

## 19. Privacy controls

Users can independently control:

- reading-session tracking;
- history retention;
- goals/streaks;
- analytics dashboard;
- inclusion of analytics in BYOC sync.

Provide:

- delete all reading history;
- delete analytics for one document;
- export analytics/history;
- disable tracking while keeping existing data.

No analytics leave the device unless the user explicitly opts into BYOC synchronization of this state.

## 20. BYOC sync

Syncable analytics data may include:

- reading sessions;
- goals;
- planned reading items;
- reading-list status/order;
- completion events;
- aggregate state where appropriate.

Prefer syncing raw durable session/state records and deriving analytics locally rather than syncing fragile precomputed chart aggregates.

## 21. Database model

### reading_sessions

- id UUID
- document_id
- started_at
- ended_at
- active_ms
- passive_ms nullable
- start_locator_json
- end_locator_json
- coverage_delta_blob optional
- source
- revision
- updated_at

### reading_goals

- id UUID
- type
- target_value
- period
- enabled
- starts_at
- ends_at nullable
- revision
- updated_at

### planned_reading_items

- id UUID
- linked_document_id nullable
- title
- author nullable
- cover_path nullable
- notes nullable
- status
- priority
- queue_position nullable
- target_date nullable
- added_at
- revision
- updated_at

### completion_events

- id UUID
- document_id
- completed_at
- method (`automatic`, `manual`)
- coverage_at_completion
- revision

Aggregates such as weekly totals should generally be computed from durable records or maintained as rebuildable caches.

## 22. Analytics service boundary

Suggested domain services:

```text
ReadingActivityTracker
ReadingSessionRepository
ReadingInsightsService
ReadingGoalService
ReadingListService
ReadingEstimateService
```

Feature code should request semantic metrics such as `activeTimeFor(range)` rather than issue ad-hoc SQL throughout the UI.

## 23. Core questions Kola should answer

The analytics system should make these questions easy:

- What did I read today?
- How long did I read this week?
- How much time have I spent on this book?
- How much have I actually covered?
- When did I last read this document?
- How many sessions have I spent on it?
- What should I read next?
- What books/documents are on my reading list?
- What did I complete this month/year?
- Which subjects/collections receive most of my reading time?
- How many notes/highlights did I create?
- How much reading time is estimated to remain?

## 24. Testing requirements

Test active-time tracking against:

- continuous scrolling;
- long static-page reading;
- switching apps/windows;
- device sleep/lock;
- leaving a document open unattended;
- rapid page flipping;
- audio/TTS reading when introduced;
- multi-device sessions merged through BYOC.

Tests must specifically guard against inflated reading-time totals.

## 25. Definition of done

Reading Intelligence is successful when a user can accurately understand what they read, how long they meaningfully spent reading, how much content they covered, what they intend to read next, and how their habits change over time—without Kola becoming invasive, competitive, or dependent on cloud analytics.