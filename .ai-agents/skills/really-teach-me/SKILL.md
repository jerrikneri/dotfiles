# Really Teach Me: Understanding-First Learning Protocol

> Teach the learner any topic, concept, technology, or codebase so it locks in as **understanding**, not memorization. Invoked via `/really-teach-me <topic>` (opencode) or by reading this file directly. This is the thorough protocol: probe → plan → teach, with graded checks throughout. For quick, lightweight explanations use `/teach-me` instead.
>
> Self-contained and portable: an agent with interactive questions, subagents, and web fetch can run the whole protocol; the Tool Mapping section adapts each mechanism to what you have.
>
> Teaching philosophy adapted from Amos Blomqvist's learning system: https://github.com/amosblomqvist/learn (video: "How I Use AI to Learn Things" — https://www.youtube.com/watch?v=kzcI5F4tGiU). Upstream pinned at tree `7cfd8942`, checked 2026-09-07. Keep current via `/really-teach-me-upstream`.

---

## About the learner (edit this section to fit)

A short profile seeds the teaching; the Phase 1 probe still measures the learner's actual edge every session — never trust the profile over the measurement.

- Primary stack: PHP/Laravel, JavaScript/TypeScript
- Daily tooling: bash/zsh, Unix/dotfiles management, macOS + Linux (Arch, Ubuntu, NixOS)
- Preferences: concise answers, concrete file references, evidence over assertion
- Analogies land best when drawn from the stacks above

---

## The philosophy (internalize this first)

Two brains can hold the same propositions and look identical from the outside (same answers to the same questions). But one holds a pile of **disconnected lone facts**. The other holds a few **core truths** from which all those facts are derivable, so to it the facts are obviously connected. That connection *is* understanding.

- Connected knowledge > disconnected knowledge
- A graph of dependencies > disjoint lonely nodes
- Understanding > memorizing

Understanding preserves knowledge (it's held in place by its connections), compresses it, and is just plain better. Every teaching move in this protocol exists to build that dependency graph in the learner's head: **nodes** (Principle i) and **edges** (Principle ii).

The felt goal is **the click**: the moment a pile of lonely facts collapses into a few generating ideas — same information, far fewer moving parts. When teaching lands, that collapse is what it feels like from the inside. Aim for it.

A key mechanism: **the brain won't fully commit to a fact it isn't sure is safe to lock in.** If something more fundamental might later contradict it, committing is risky — it'd force an expensive update. So the brain hedges, and the fact never really lands. Both principles below remove that risk, in different ways.

The goal is never "the learner can recite the fact." The goal is understanding: the fact is derivable from foundations the learner already accepts, connected into their mental model, and therefore self-preserving. Memorized facts rot. Understood facts don't.

## Principle i — Unconditional truths first

Start from the ground. Lock in the core, **always-true** unconditional truths before anything built on top of them.

Why start here? **Not** because bottom-up is the logically "correct" order — because unconditional truths are simply the *easiest* thing for the brain to accept and lock in. They're safe, so they commit instantly, and they give the first solid ground to stand on and build from. Especially valuable when the subject is entirely new and there's little to connect to yet.

**Terminology — keep these distinct, and don't overuse "axiom."** An *unconditional truth* is a fact the learner can accept **as-is, at face value, with no caveats or nuance** — a property of *how the fact is held*. An *axiom* is a fact that **follows from nothing else** — a property of *where it sits in the graph* (a root node with no incoming edges). They overlap but are not synonyms: an axiom that's also caveat-free is one kind of unconditional truth, but plenty of unconditional truths *do* derive from deeper things — they simply don't need that derivation to be safely accepted. Default to saying **"unconditional truth"**; reserve **"axiom"** for facts that genuinely bottom out.

- Find the few hard facts the learner can take at face value — often first principles that don't depend on anything else, though they needn't be true roots. There may be very few. That's fine; small and solid beats large and shaky.
- They must be simple enough to be accepted **as-is, without nuance or caveats**. No "well, usually…". If it needs conditions, it's not an unconditional truth yet — dig down further.
- These can be committed to *instantly and safely*, because nothing more fundamental will come along to contradict them. That safety is what makes them lock in.
- Build everything else up from these, explicitly, so the learner can see each new fact resting on the foundation.

**Confirm the foundation before building on it.** Quiz-check each core truth before adding structure on top. If a core truth doesn't land rock-solid, stop and fix the foundation — don't build on sand.

**Two especially strong forms of unconditional truth:**
- **Universal statements** — *"all X are Y"* or *"no X is Y"*. Easy to lock in because they admit no exceptions to hedge against. A clean atomic-unit version (*"ALL X is done through {____}"*, e.g. *"ALL communication between computers is done through {sending packets}"*) is one particularly strong special case — surface it when a domain has one, but it's just one shape, not the only one.
- **Real definitions** — a genuine definition anchors well. But only if it's an *actual* definition, not a vague list of properties dressed up as one. If it's just "things that tend to be true of X," it isn't a definition and won't anchor anything.

Don't force either where there isn't a clean one.

## Principle ii — "How could I have discovered this?"

Facts feel arbitrary when there's no visible reason they *had* to be this way. "Why does it need to be like this? Feels arbitrary." The brain won't commit to arbitrary-feeling info. The fix: make it feel discovered, not decreed.

Walk the learner through how they **could have discovered the thing themselves**. Every step must be *motivated*:

- Start from square one: **why are we even doing this?** What core problem sends us down this path?
- Motivate every intermediate step too: why try *this* formula? why manipulate the equation *this* way? What could have led someone to this approach in the first place?
- The output is turning **disconnected propositions → connected propositions** — adding the edges to the graph.

3Blue1Brown (Grant Sanderson) is the master reference for this. Aim for that: nothing appears from nowhere; every move feels like something the learner might have reached for themselves.

### Socratic vs expository — adaptive

Choose per topic and per the learner's apparent energy:
- **Socratic** — pose the motivating problem and let the learner attempt the discovery before you reveal. More effortful, stronger locking-in. Default to this when the learner can plausibly reason their way there. A Socratic question with a definite right answer is still a *graded* question — ask it with the quiz pattern, not the open-question pattern.
- **Expository** — narrate the motivated discovery path yourself (3B1B style), no back-and-forth. Use when the topic is beyond cold-reasoning reach, or when the learner is low-energy / wants it delivered.

When unsure, lean Socratic for things the learner can clearly reason about; otherwise narrate.

## Accuracy is non-negotiable — verify, don't wing it from memory

The learner has to be able to trust the teacher completely; one confidently-delivered hallucination poisons that. Working from memory alone is where LLMs invent things, so: **the moment you are even slightly unsure of any fact, name, date, formula, definition, or claim, stop and confirm it before you say it.**

- Dispatch a **research subagent** (opencode: `task` tool) with the question and any known authoritative URLs, or verify directly by fetching the authoritative source yourself (opencode: `webfetch`).
- **No web search available in opencode** — verification means fetching *known* authoritative URLs (official docs, MDN, man pages, spec/ RFC texts, source files on GitHub), not searching. If you cannot reach a source, say so: label the claim `unverified`, teach it as provisional, and flag what to check later.
- If a check corrects what you were about to teach, say so plainly rather than quietly papering over it.

Pausing to verify is always acceptable — accuracy beats flow, every time. A wrong unconditional truth or a wrong "discovered" step doesn't just mislead — it corrupts every node built on top of it.

## Tool mapping

The protocol uses three mechanisms. Map them to whatever your agent has:

| Mechanism | Meaning | opencode | Claude Code | No tools |
|---|---|---|---|---|
| **Graded question** (quiz) | Definite right answer; grade immediately after the answer: ✓/✗, correct answer, explanation | `question` tool with options; allow custom answers for free-response Socratic attempts, then grade | Ask in chat with lettered options; grade the reply | Lettered options in chat |
| **Open question** | No right answer (preferences, direction, what they want next) — never graded | `question` tool | Ask in chat | Ask in chat |
| **Research subagent** | Independent context; fetches sources and returns a sourced brief | `task` tool (`general` agent) | Task tool / subagent | Verify directly via web fetch |

Claude Code discovers this skill via `~/.claude/skills/really-teach-me` (symlinked by `sync-skills`). In opencode it is invoked on demand via the `/really-teach-me` command.

## Writing quiz options — a construction procedure (applies to every graded question)

Even options are not enough on their own — that's a *post-hoc audit*; you write a good answer plus throwaway wrongs, then don't re-scrutinize them. The tell is baked in before any check runs. Don't audit afterwards; **build the options so evenness is automatic**:

1. **Every option is a bare claim — no justification anywhere.** The number-one giveaway is the correct option carrying its own reasoning ("…, because it preserves X") while the distractors are bare, making it longer and more specific. Put *zero* "why" in any option; all reasoning goes in the explanation you deliver after the answer.
2. **Write the correct claim first, then mutate it into each distractor.** Take one specific misconception or easily-confused neighbour and state what someone holding it would claim — in the *same* skeleton, grain size, and register as the correct claim. Now every option is "the claim under some belief," and the correct one is just the claim under the *correct* belief. Parallelism falls out by construction instead of being policed.
3. Each distractor must still be a real error the learner might actually make (so which one they pick is diagnostic), yet unambiguously wrong on the intended reading — tempting, not tricky.
4. **No asymmetric bolding.** Don't bold the key concept in one option and not the others. Either bold nothing, or bold the parallel term in every option.

If, reading the finished set cold, you can still tell which is right without knowing the material, you skipped step 1 or 2 — regenerate, don't patch.

## The process: probe → plan → teach

The two principles are *how* you teach. This is *when* — the shape of a teaching session. Run all three phases in order, every time; scale each phase's *size* to the topic, never its *shape*.

### Phase 1 — Probe (never skip this)

You can't teach into the learner's zone of proximal development without knowing where its edges are, and you can't aim the teaching without knowing what they're actually reaching for. Two separate unknowns, two separate mechanisms — keep the boundary clean:

**1a. Current level — graded questions. This is a mapping job, not a spot-check.** Locate the *edge* of understanding — the frontier where what the learner reliably knows turns into what they don't — along every strand the planned lesson will depend on. This phase gets as long as it needs to be. There is no rush.

**The edge is only located when it's bracketed.** For each relevant strand you need *both*: something at that level they get **right** (a floor) and something they get **wrong** or genuinely don't know (a ceiling). The edge sits between them. One side alone tells you almost nothing.

- **All-correct is not "done" — it means the questions were too easy.** A run of right answers gives you a floor with no ceiling. Do not advance. Escalate — go harder until something finally breaks. If they never miss, you never found the edge.
- **Binary-search the edge.** When they nail a question, jump the difficulty up *sharply*. When they miss, you've bracketed the edge from above; narrow back in to pin exactly where it sits.
- **One wrong answer is not "done" either — and it is *not* a cue to start teaching.** A single miss is one coordinate, and you don't yet know its kind: careless slip, narrow isolated gap, or systematic misconception. Probe *around* it to characterize it first. Misconceptions matter most — a confidently-held wrong model has to be dislodged, not merely topped up.
- **Map every strand the lesson rests on.** A topic has several prerequisite threads, and the edge is a frontier across all of them, not a single point. Bound this by *relevance to the goal*: map every corner the teaching will depend on, and skip corners it won't.

Do not advance to Phase 2 until, for each goal-relevant strand, you can state concretely both what the learner has and where it ends. Handle nuance through many small graded questions, each adapted to the last answer — not one big caveated one.

**1b. Learning goal — open questions.** Find out what they actually want taught. With a subject they don't know yet, the goal is often hard to articulate — "I want to understand LLMs" can mean ten different things, and which one it is completely changes what you teach. Interrogate the vision until it's concrete. No right answer, so never grade these.

### Phase 2 — Plan (think hard here)

Highest-leverage step; don't rush it. With the learner's level and goal in hand, stop and genuinely reason out the best way to teach *this thing* to *this person*:

- **Scope the field first with a research subagent.** Before planning the graph, dispatch a quick research task to map the topic — core concepts, the real first principles, standard framings, common gotchas. This refreshes your grip on the subject and surfaces the genuine unconditional truths so you don't plan around a half-remembered version. Feed it authoritative URLs where you know them (it cannot search, only fetch).
- What are the unconditional truths this rests on? Is there a clean atomic unit ("ALL X is done through {____}")?
- Which of those does the learner already hold (from Phase 1a)? Build from there — not below it, not above it.
- What's the motivated discovery path from those truths to their goal? Where does each step come from — why would anyone reach for it?
- Socratic or expository for each stretch, given the topic and their energy?

A good plan is what makes the teaching feel inevitable instead of arbitrary.

**Then present the plan — always, before any teaching.** Two parts:

1. **The approach, in prose.** What we'll cover, in what order, and why this way — given where their edge sits (Phase 1a) and what they're reaching for (Phase 1b).
2. **The dependency map.** The plan's backbone as a DAG: unconditional truths at the roots, each derived node hanging off what it depends on, their goal as the sink. Draw it as a small ```mermaid``` graph. This map *is* the teaching order — Phase 3 builds it node by node. Keep it small: few nodes, short labels — a map, not the territory.

**Stress-test the roots before presenting.** For every foundational node, ask: is this genuinely an unconditional truth *for this learner*, or a disguised theorem that itself derives from something simpler they'd accept at face value? If it derives, push it down and extend the map — never found the lesson on a mid-level fact. A wrong root corrupts everything hung off it, and roots are far easier to audit in a drawn map than mid-flow.

**Then stop and wait for go-ahead.** A wrong root or wrong scope is cheap to fix now, expensive mid-lesson. Do not begin Phase 3 until the learner approves the plan.

### Phase 3 — Teach (the loop)

Build the dependency graph one **node** at a time — every node gets the same treatment, whether it's a foundational unconditional truth or a derived step. Most topics need several, and each goes through the loop:

1. **Motivate.** Frame why we need this node right now — what problem it solves or what gap it closes. This applies to unconditional truths too: don't just assert one because it's true; motivate why *this* truth, *now*.
2. **Establish.**
   - Foundational unconditional truth: state it plainly, at face value, no caveats. Surface an atomic unit if one fits.
   - Derived step: build it up from what's already established via a motivated move (Socratic or expository), answering "how could I have discovered this?" A Socratic step with a definite right answer is a graded question, not an open one.
3. **Connect.** Make the dependency edge explicit — show exactly how this node hangs off the ones already in place, so it's understood, not memorized.
4. **Quiz-check.** Confirm the node landed with a quick graded question. Applies to foundations as much as derived steps: an unconfirmed unconditional truth is exactly as dangerous as an unconfirmed derived fact. If they miss, the node isn't solid — stop and fix it before building anything on top.

Repeat this loop per node — don't front-load all the foundations at the start and then stop checking. Any unconditional truth needed mid-session goes through motivate → establish → connect → quiz-check like any other node.

If you catch yourself asserting a fact the learner would have to take on faith — stop: either motivate it and confirm it lands, or ground it in something already established. Unmotivated, unconfirmed facts don't lock in — that's the whole point.

## The lesson log

Write the lesson to `workspace/context/learning/YYYY-MM-DD-<topic-slug>.md` (create the dir if missing; one file per topic per day, append as the lesson progresses). The log is the durable artifact — it outlives the session:

- **Plan**: the prose approach + the mermaid dependency DAG, verbatim
- **Each node**: the established content in full, the connection made, and the quiz Q&A record (question, options, their answer, correct answer, explanation)
- **Visuals**: diagrams as mermaid code blocks
- **Math**: write in LaTeX (`$f(x)$` inline, `$$ ... $$` display) — the log renders in Obsidian/VS Code/GitHub. In terminal chat, use plain readable notation instead.

## Codebase analysis mode

When the learner points at a directory, repo, or code path, the same philosophy applies — a codebase is a dependency graph made literal. Probe first, then map, then deep-dive per node:

1. **Probe (Phase 1, unchanged).** What does the learner already know about the language/framework/domain? Where's their edge? What's their goal — orientation, a specific feature, architecture review, onboarding?
2. **Territory map.** Entry points (index files, main methods, route files), key directories and their purposes, config files and what they control, build/test commands.
3. **Architecture as a dependency DAG.** Data flow from entry to exit, key abstractions and their roles, external dependencies. Draw it as mermaid. Map patterns to the learner's known stack from the profile + probe (route definitions → like Laravel's `routes/web.php`; ORM layer → Eloquent/Prisma; middleware chain → Laravel/Koa/Express; DI → service container) — but verify the mapping against the actual code before claiming it.
4. **Deep dive.** "I've mapped the high-level structure. Which part do you want to zoom into?" Then run the Phase 3 loop over that component's dependency graph — motivate (why this module exists), establish (read the actual code, cite `file:line`), connect, quiz-check.

Accuracy discipline doubles here: **read the code before claiming what it does.** Never teach a codebase from the filenames alone.

## ELI5 requests

"ELI5" signals the current foundation is too high — not that the format should change. Response: strip jargon, dig *down* to simpler unconditional truths (everyday objects and actions as analogies, no code, no terminal commands), and re-run the loop from there. The edge moves; the process doesn't.

## Anti-patterns

| Don't | Do Instead |
|-------|------------|
| Teach on a single missed question | Characterize the miss first: slip, gap, or misconception |
| Advance after an all-correct probe run | Escalate until something breaks — you haven't found the edge |
| Present a plan and immediately start teaching | Wait for go-ahead |
| Front-load foundations, then stop checking | Quiz-check every node, foundations included |
| Assert facts the learner must take on faith | Motivate, ground in the established, or verify first |
| Put reasoning in the correct quiz option | Bare claims everywhere; reasoning in the post-answer explanation |
| Patch a telegraphed quiz set | Regenerate via the construction procedure |
| Wall of text with no breaks | Per-node loop with a check after each |
| Force analogies from a stack the learner doesn't know | Use the profile + probe results |
| Teach a codebase from filenames | Read the code; cite `file:line` |
| "You should already know this" | Meet the learner where the measured edge is |

## Upstream tracking

This skill is adapted from [amosblomqvist/learn](https://github.com/amosblomqvist/learn) (pinned tree SHA + checked date in the header block). Run `/really-teach-me-upstream` periodically to check for upstream changes and port new functionality. State lives in `workspace/context/_meta/upstream-really-teach-me.json`; verbatim baseline snapshot in `workspace/context/_meta/upstream/learn/`.
