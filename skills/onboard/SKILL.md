---
name: onboard
description: First-run onboarding interview for a new Claude Code platform install. Conversational 50-question intake that captures identity, voice, hard rules, projects, and external systems, then writes the user's starter memory files and per-project _wiki/ scaffolding. Use when the user is setting up the platform for the first time, or when they explicitly run /onboard or say "onboard me", "let's set up my memory", "interview me", "start the intake". Resumable — can pick up where a previous run left off.
---

# Onboard — first-run interview skill

## What this skill does

Conducts a conversational interview with a new user, then writes the foundation of their Claude Code memory system: built-in memory files in `~/.claude/projects/<encoded-cwd>/memory/`, and per-project `_wiki/` scaffolding in their vault.

The interview takes 20-40 minutes depending on depth. The user can pause anytime and resume later — this skill is idempotent and reads existing files before asking.

## When NOT to use this

- If `MEMORY.md` already has 5+ entries and the user hasn't asked to redo onboarding, ask what they want first
- If the user just wants to add ONE memory, don't run the full interview
- If the user is mid-task on something else, offer to schedule onboarding for later

## How to run this

### Phase 0 — Pre-flight

Before asking any interview questions:

1. **Confirm the vault location.** The current working directory is the vault. Tell the user "I'm about to set up your Claude Code memory system using this folder as your vault: `<cwd>`. Is that right?" If they want a different location, have them re-launch Claude Code from there.

2. **Compute the memory path.** It's `~/.claude/projects/<encoded-cwd>/memory/` where `<encoded-cwd>` replaces `/` with `-`. Confirm it exists or create it.

3. **Check for prior runs.** Read `MEMORY.md` and any existing memory files. If onboarding has been partially completed, summarize what's already captured and ask whether to continue from there or restart.

4. **Set expectations.** Tell the user:
   - This is ~50 questions across 9 sections
   - It's a conversation, not a form — they can give long or short answers, skip questions, or say "I don't know"
   - They can pause anytime by saying "pause" or "let's stop here"
   - At the end, you'll write their memory files and show them where everything went

5. **Ask for go-ahead** before starting Section 1.

### Phase 1 — The interview

Run the 9 sections in order. Within each section:

- Ask one question at a time, not the whole list at once
- If an answer is shallow ("I'm a developer"), probe gently: "What kind of development, and who's it for?"
- If they don't know, write `_unknown_` and move on — better than fabrication
- Track answers in a working scratchpad (in your head / context, not a file yet)
- After each section, give a one-line confirmation of what you captured and move to the next

**Tone:** warm but direct. You're a thoughtful colleague taking notes, not a chatbot running a survey.

---

## Section 1 — Identity

Writes to: `user_profile.md`

1. What's your full name, and what should I call you day-to-day?
2. Pronouns?
3. Where are you based — city and timezone?
4. What are your typical working hours, and what days do you take off?
5. What's your current role or title?
6. In one sentence, what do you actually do?
7. Walk me through your career arc in 3–5 beats — what shaped how you think about work?
8. Best email to reach you at. Phone or other channel if relevant.
9. Anything physical or cognitive that affects how you work? Dyslexia, ADHD, vision, energy patterns — only what's relevant for me to know.

*Don't ask about OS, paths, or machine specs — detect those from the environment.*

---

## Section 2 — How we work together

Writes to: `feedback_collaboration.md`

10. What do you want me to be — peer, senior advisor, fast junior, sparring partner, executor?
11. When I'm uncertain about something, do you want me to ask, or proceed with a reasonable guess?
12. How much should I explain my reasoning vs just do the thing?
13. How do you want me to surface mistakes — flag immediately, or wait for you to ask?
14. When you push back on me, do you want me to defend if I think I'm right, or defer?
15. Default response length — terse, medium, or thorough?
16. Should I always test my own work before reporting it done, or is shipping untested okay sometimes?

---

## Section 3 — Writing voice

Writes to: `feedback_writing_style.md`

17. Describe your writing voice in 3 adjectives.
18. Paste me something you wrote that sounds like you — an email, a post, a doc, anything.
19. Words or phrases you never want to see in your name?
20. Punctuation preferences — em dashes? semicolons? Oxford comma? Exclamation marks?
21. Default tone — declarative and confident, or curious and exploratory?
22. Does your voice change by audience? Customers vs team vs investors vs public posts — walk me through the differences.

*After Q18, analyze the sample. Pull out 3-5 patterns and confirm them: "I'm seeing X, Y, Z. Sound right?"*

---

## Section 4 — Hard rules

Writes to: `feedback_hard_rules.md`

23. Anything I'm flat-out forbidden from doing — sending email, deleting data, spending money, posting publicly?
24. Where do your credentials live, and what's the rule for handling them?
25. Email — drafts only, or can I send on your behalf?
26. Calendar — read only, or can I create and move events?
27. Code from outside sources — auto-run safely, or always review with you first?
28. Spending limits per action and per day, if any?
29. Topics I should never act on without explicit go — legal, medical, financial, HR, anything else?

---

## Section 5 — Projects

Writes to: `project_<slug>.md` (one per project) + `_wiki/` scaffolding in `<project-folder>/_wiki/`

30. List your active projects or initiatives. Just names for now — we'll loop through each.

**For each project, ask:**

31. One sentence — what's the mission?
32. Who's the customer or audience?
33. What stage is it in — idea, building, selling, scaling, maintaining?
34. Top 3 things you're trying to accomplish in the next 90 days?
35. Who else is involved — cofounders, team, contractors, advisors?
36. Anything project-specific I should never do or always do?
37. Does this project have its own voice that differs from your default?

*If they list 5+ projects, offer to do 2-3 in depth now and the rest as quick one-liners they can flesh out later.*

---

## Section 6 — External systems

Writes to: `reference_systems.md`

38. What tools do you use daily? Notion, Slack, Linear, GitHub, HubSpot, QBO, Notion, Obsidian, others?
39. For each, what's my access — read, write, none?
40. Where do you track tasks vs notes vs decisions vs files?
41. Any dashboards, repos, or external vaults I should know about?
42. Which calendar, and what's the rule for adding events?

---

## Section 7 — Decision style

Writes to: `feedback_decision_style.md`

43. When facing a 70/30 call, do you want a recommendation or a slate of options?
44. Reversible decisions — okay for me to make without asking?
45. Irreversible decisions — what's the bar for me to act?
46. Tell me about a recent decision you got wrong. What would you have wanted differently?
47. A recent one you got right. Why did it work?

---

## Section 8 — Memory and learning

Writes to: `feedback_memory_preferences.md`

48. Should I save memories freely as I learn things, or keep memory minimal?
49. When you correct me, should I always save a feedback memory, or only when you say so?
50. Anything from your past you want me to know but never bring up unprompted?
51. Anything you want me to actively forget if it comes up later?

---

## Section 9 — Wildcard

Writes to: `user_wildcard.md` (optional — only create if they have something)

52. Anything else I should know to act on your behalf with confidence? Quirks, principles, things people get wrong about you, things you wish you didn't have to explain?

---

### Phase 2 — Write the files

The installer already placed scaffold files at install time. Your job is to (a) substitute the user-specific `{{placeholders}}` in those files, (b) write the built-in memory files, and (c) generate per-project `_wiki/` folders.

Before writing anything:

1. **Summarize what you learned in 5-8 bullets.** Confirm with the user: "Before I write your files, here's what I heard. Anything wrong?"

2. **Show the file list** you're about to create or update. Get explicit go-ahead.

3. **Substitute user-specific placeholders in already-existing scaffold files:**
   - `<vault>/CLAUDE.md` — replace `{{user_preferred_name}}`, `{{user_full_name}}`, `{{user_timezone}}`, `{{project_list}}` (machine-detected placeholders are already filled by the installer)
   - `<vault>/_shared/_wiki/01-user-profile.md` — replace all `{{user_*}}` placeholders
   - `<vault>/_shared/_wiki/02-ai-operating-rules.md` — replace `{{user_preferred_name}}`
   - `<vault>/_shared/_wiki/03-writing-style.md` — replace voice-related placeholders, including pasting the user's writing sample verbatim into `{{user_writing_sample}}`

4. **Write the built-in memory files** to `<vault>/.claude/projects/<encoded-cwd>/memory/` (the path is already created by the installer). Use this format:

   ```markdown
   ---
   name: {title}
   description: {one-line hook}
   type: {user|feedback|project|reference}
   ---

   {content}
   ```

   Files to write (one per section, see section headers above for the target filename).

5. **Write `MEMORY.md`** index at the same path. Format:
   ```markdown
   - [Title](file.md) — one-line hook
   ```

6. **For each project from Section 5**, create `<vault>/<project-name>/_wiki/` populated from the stub templates at `<vault>/_shared/_wiki-project-stubs/`:
   - `01-user-profile.md`, `02-ai-operating-rules.md`, `03-writing-style.md` — copy or symlink from `<vault>/_shared/_wiki/`
   - `04-project-mission.md` — copy stub, fill `{{project_name}}`, `{{project_mission_sentence}}`, `{{project_stage}}`, `{{project_90_day_goals}}`
   - `05-project-business.md` — copy stub, fill `{{project_name}}`, `{{project_team}}`
   - `06-project-icp.md` — copy stub, fill `{{project_name}}`, `{{project_customer}}`
   - `07-project-offer.md` — copy stub as-is (no interview answers map here)
   - `08-project-voice.md` — copy stub, fill `{{project_name}}`, `{{project_voice_notes}}` (or write "Matches default voice in `03-writing-style.md`" if no differences)
   - `09-project-messaging.md`, `10-project-gtm.md` — copy stubs as-is
   - `11-project-dos-donts.md` — copy stub, fill `{{project_name}}`, `{{project_dos}}`, `{{project_donts}}`
   - `index.md` — copy stub, fill `{{project_name}}`
   - `log.md` — create empty with header `# Decision log`

### Phase 3 — Closing

Tell the user:

1. Where each file went (give exact paths)
2. That the foundation is set, but feedback memories build over time from corrections — they don't need to interview again
3. The `consolidate-memory` skill runs automatically and will keep adding to memory based on real session work
4. They can run `/onboard` again anytime to add or revise sections
5. Suggest one immediate test: ask Claude a question that requires what was just captured, and see if it lands

Keep the closing under 8 lines. Don't pad.

---

## Implementation notes for the executing Claude

- **Path encoding:** `/Users/jane/MyVault` → `-Users-jane-MyVault`. The memory dir is `~/.claude/projects/-Users-jane-MyVault/memory/`.

- **Resume logic:** Before Phase 1, read every file in the memory dir. Build a map of `{section → already_captured}`. Skip sections that are already substantively filled, but offer to revise them.

- **File naming:** Use snake_case for memory files. Group by type prefix (`user_`, `feedback_`, `project_`, `reference_`).

- **Don't fabricate.** If the user gave a thin answer and you can't ethically write a rich file from it, write a short file marked `<!-- thin — revise after more sessions -->` and tell the user.

- **Don't be a robot.** Acknowledge interesting answers. If they say something funny or sharp, react. This is a conversation.

- **Don't lecture about memory.** They don't need to learn the architecture. They just need to answer questions and trust the output.

- **Watch the clock.** If the user is clearly tiring (short answers, "sure", "next"), wrap up the section and offer to continue another time. Half-onboarded is fine — the system is designed to build over sessions.
