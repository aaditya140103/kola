# Kola — Scientific UX Validation Protocol

This document defines how Kola should test interface decisions instead of relying only on taste, screenshots, or designer preference.

## 1. Core principle

Kola's UX process should follow a lightweight human-centered experimental loop:

```text
Observe problem
 -> define user/task/context
 -> form design hypothesis
 -> prototype competing solutions
 -> test with users
 -> collect behavioral + subjective data
 -> compare against success criteria
 -> keep/revise/reject
 -> document result
```

The objective is not academic publication. The objective is to make design decisions falsifiable and measurable.

Reference framework:

- ISO 9241-210 human-centered design: https://www.iso.org/standard/77520.html

## 2. Never evaluate aesthetics alone

Every important design test should measure at least two dimensions:

### Behavioral/pragmatic

- task completion;
- time on task;
- errors/misclicks;
- backtracking;
- discoverability;
- learning time;
- retention after a delay where important.

### Experiential/hedonic

- attractiveness;
- perceived ease;
- confidence;
- stimulation/novelty;
- comfort;
- perceived craftsmanship;
- willingness to continue/revisit.

A visually preferred design that materially harms task performance is not automatically accepted.

## 3. Standard Kola UX metrics

### Task success

Binary or graded completion of a realistic task.

Examples:

- open a book and find chapter 8;
- highlight a sentence and add a note;
- switch to Flow Mode and return to original source;
- find an old annotation;
- change the reading background;
- connect BYOC sync;
- resolve a sync conflict.

### Time on task

Measure from task start until correct completion. Compare designs using the same task definition.

### Error rate

Count observable errors such as:

- wrong command;
- unintended navigation;
- accidental annotation;
- losing reading location;
- opening wrong panel;
- failed recovery.

### Interaction cost

Track:

- number of taps/clicks;
- pointer travel where relevant;
- unnecessary modal transitions;
- repeated menu openings;
- keyboard/mouse switching for desktop workflows.

### Reading performance

For reader-specific experiments:

- comprehension question accuracy;
- reading time;
- navigation interruptions;
- accidental scroll position loss;
- annotation completion time;
- subjective eye/reading comfort.

Do not optimize reading speed at the expense of comprehension unless the tested mode explicitly targets skimming.

## 4. Standardized questionnaires

Use validated instruments instead of inventing a new survey for every test.

### UEQ-S — primary short UX measure

8 items covering:

- pragmatic quality;
- hedonic quality.

Useful because Kola needs to be both efficient and emotionally attractive.

Official resources:

- https://ueq-online.org/

### SUS — periodic overall usability benchmark

10-item System Usability Scale.

Use after stable interactive prototypes or releases, not after every tiny component test.

Reference:

- Brooke, J. (1996), SUS: A Quick and Dirty Usability Scale.

### VisAWI-S — visual aesthetic evaluation

4-item short aesthetic measure representing:

- simplicity;
- diversity;
- colorfulness;
- craftsmanship.

Use when comparing visual directions/screens rather than interaction mechanics.

Reference:

- https://doi.org/10.1080/0144929X.2012.694910

### NASA-TLX — only for cognitively demanding workflows

Use for complex tasks such as:

- multi-document research;
- resolving conflicts;
- dense annotation workflows;
- advanced spreadsheet/document navigation.

Do not burden routine tests with TLX unnecessarily.

Official source:

- https://www.nasa.gov/human-systems-integration-division/nasa-task-load-index-tlx/

## 5. Four required kinds of UX studies

### A. First-impression study

Purpose: determine whether Kola immediately feels attractive, clear, and trustworthy.

Method:

1. show candidate screen very briefly;
2. remove it;
3. ask for immediate visual appeal and perceived purpose;
4. repeat using randomized design variants;
5. later show normal-duration screens and collect deeper ratings.

Measure:

- visual appeal;
- perceived complexity;
- perceived professionalism;
- what users believe the primary action/content is.

Use on:

- library home;
- reader chrome;
- theme system;
- onboarding;
- empty state.

### B. Task usability study

Purpose: determine whether users can actually perform common work.

Representative tasks:

1. import a document;
2. resume reading;
3. highlight text;
4. add note;
5. switch view mode;
6. search document;
7. find annotation;
8. change theme;
9. export note;
10. sync state to another device.

Measure success, time, errors, assistance, and confidence.

### C. Long-reading study

Purpose: test the experience after the novelty disappears.

Minimum session target for meaningful prototypes: 20–40 minutes of real reading.

Observe:

- toolbar distraction;
- fatigue;
- accidental UI reveals;
- typography comfort;
- annotation interruption cost;
- position retention;
- theme/background comfort.

Short five-minute usability tests cannot validate a serious reading interface on their own.

### D. Longitudinal retention study

Purpose: test whether people still like/use Kola after repeated exposure.

Suggested cadence:

- day 1;
- day 3–4;
- week 1;
- week 2+ for beta users.

Measure:

- voluntary sessions;
- reading duration;
- documents resumed;
- annotation usage;
- customization usage;
- feature abandonment;
- qualitative reasons for returning/not returning.

A novelty-driven interface can score well on first impression and poorly after a week; Kola must survive both tests.

## 6. Design experiment template

Every major UX experiment should be recorded in this format:

```markdown
### Experiment: <name>

Hypothesis:
Users will <behavior> because <design rationale>.

Variants:
- A: ...
- B: ...

Primary metric:
- ...

Secondary metrics:
- ...

Participants/context:
- ...

Tasks:
1. ...

Success criterion:
- ...

Result:
- pending / supported / mixed / rejected

Decision:
- ...
```

## 7. Prototype fidelity ladder

Do not build production UI before answering questions cheaply.

### Level 1 — structure sketch

Test:

- information architecture;
- feature grouping;
- layout hierarchy.

### Level 2 — static visual prototype

Test:

- first impression;
- visual hierarchy;
- typography;
- color;
- spacing;
- themes.

### Level 3 — interactive prototype

Test:

- navigation;
- discoverability;
- gestures;
- animation;
- task completion.

### Level 4 — real Flutter implementation

Test:

- native behavior;
- performance;
- selection;
- keyboard;
- accessibility;
- touch/stylus;
- realistic reading sessions.

Do not use a static Figma-style mockup to claim that a gesture, scrolling, annotation, or performance design works.

## 8. Participant strategy

Kola should test with distinct reader profiles rather than one generic "user" group.

Minimum recurring profiles:

- university/student reader;
- casual ebook reader;
- researcher/academic PDF reader;
- heavy annotator;
- keyboard-first desktop user;
- touch-first mobile user;
- stylus/tablet user;
- accessibility users where specific features are being validated.

Avoid drawing conclusions about all users from only technically experienced contributors.

## 9. Device matrix

For each major reader interaction, validate at least:

### Compact touch

- small Android phone;
- modern iPhone-sized viewport.

### Large touch

- tablet/iPad class;
- foldable/large Android window when practical.

### Desktop

- Linux GNOME/KDE representative environment;
- Windows;
- macOS.

### Input

- touch;
- mouse/trackpad;
- keyboard-only;
- stylus where feature-relevant.

A feature is not cross-platform complete because it renders at all sizes.

## 10. Accessibility validation gate

Before design approval, verify:

- text/UI contrast;
- 200% text scaling or equivalent platform accessibility scaling;
- visible keyboard focus;
- screen-reader labels/semantics;
- color-independent status meaning;
- touch target size;
- reduced motion;
- high contrast where platform supports it;
- reader usability with enlarged fonts;
- RTL layout where relevant;
- critical actions accessible without precision dragging.

Reference:

- https://www.w3.org/TR/WCAG22/

## 11. Visual regression protocol

Every stable design-system component should eventually have golden/snapshot tests for:

- light;
- dark;
- high contrast where feasible;
- compact;
- medium;
- expanded;
- large text;
- RTL where relevant;
- selected/focused/disabled/error states.

Golden tests detect accidental visual drift; they do not replace user research.

## 12. Motion validation

For each non-trivial animation, answer:

1. What state change does this explain?
2. Would the transition still be understandable without it?
3. Does it delay interaction?
4. Does it remain legible under fast repeated actions?
5. Is there a reduced-motion alternative?
6. Does it match native platform behavior where expected?

If no meaningful answer exists for question 1, remove the animation.

## 13. A/B testing rules

Use A/B tests only when:

- there are two plausible alternatives;
- success can be measured clearly;
- enough observations exist;
- novelty effects are considered.

Do not A/B test foundational accessibility or platform-convention requirements merely to see whether users "prefer" violating them.

For early development, moderated tests with fewer users often reveal more actionable interaction failures than premature production telemetry.

## 14. Privacy rule for product analytics

Kola is privacy-first. UX research must not silently introduce permanent analytics into the application.

Preferred order:

1. dedicated prototype/usability sessions;
2. explicit opt-in beta diagnostics;
3. locally inspectable research logs;
4. only later consider minimal opt-in aggregate analytics if product policy explicitly changes.

Core reading remains telemetry-free by default.

## 15. Design release gates

### Gate 1 — Concept

- clear user problem;
- explicit hypothesis;
- no conflict with product invariants.

### Gate 2 — Visual

- first-impression review;
- hierarchy/complexity review;
- contrast/accessibility check;
- native-convention check.

### Gate 3 — Interactive

- representative task test;
- no severe discoverability failures;
- acceptable error rate;
- motion and input behavior validated.

### Gate 4 — Reader endurance

Required for core reader changes:

- real document;
- extended reading session;
- annotation workflow;
- resume/recovery test.

### Gate 5 — Cross-platform

- adaptive layout;
- native interactions;
- keyboard/touch differences;
- accessibility settings.

A major UI feature is not done until the applicable gates pass.

## 16. Target quality direction

Kola should optimize for a balanced UX profile rather than a single vanity score.

Desired outcome:

```text
High pragmatic quality
        +
High hedonic quality
        +
High visual craftsmanship
        +
Low cognitive workload
        +
Strong accessibility
        +
Long-session reading comfort
```

We should prefer measured improvement over arbitrary numerical targets until Kola has its own baseline data.

## 17. Agent protocol for UX changes

When an agent makes a meaningful visual/interaction change, it must:

1. read `UX_RESEARCH.md` and the relevant section of `UX_SPEC.md`/`DESIGN_SYSTEM.md`;
2. state the rationale in code/PR context;
3. identify whether the rationale is evidence, accessibility, platform convention, or deliberate experimentation;
4. preserve the design tokens/components instead of creating one-off styling;
5. add/update tests where technically possible;
6. update `PROJECT_STATE.md`;
7. update this document only when the validation methodology itself changes.

## 18. Final rule

**Taste proposes. Evidence filters. Testing decides.**

Kola should have a strong visual point of view, but no visual preference is above reader performance, accessibility, or measured user behavior.


## Reader repair validation — 2026-09-12

Rationale: platform convention (push/pop continuity), accessibility (reachable Back and non-overflowing controls), and measured widget failures (PDF viewport collapsed to toolbar height). No visual hypothesis is being selected or locked.

Automated regressions cover Home/Library return paths, system Back, direct route fallback, loading/missing/resume-error states, failed saves, full-height source layout, persistent Back after a content tap, and 320-pixel-wide controls. Native PDF tests exercise managed-source opening, rendered pixels, text geometry and viewer rebuilds.

Physical follow-up remains: Linux and Android import -> open -> scroll/zoom/select -> return -> reopen, predictive Back, 200% text scaling, keyboard focus traversal, and rotated/cropped/scanned/password-protected PDFs. Widget/native-engine tests are not a physical-device usability study.
