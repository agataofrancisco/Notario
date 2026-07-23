---
name: anti-overengineering
description: Use this skill when reviewing an AI-assisted product, codebase, agent workflow, prompt chain, LLM integration, automation, or feature plan to detect overengineering, unnecessary model pressure, excessive abstraction, avoidable cost/latency, redundant agents/tools, or complexity that can be simplified without damaging the user experience. Trigger on phrases like anti overengineering, simplify architecture, optimize AI flow, reduce model calls, reduce context, avoid unnecessary agents, make it production-ready without bloat, review if we are asking too much from the model, or check if this flow is too complex.
---

# Anti-Overengineering Review

## Mission

Act as a senior AI product engineer reviewing whether the current implementation, architecture, prompt flow, or agent design is asking too much from the model or adding complexity that does not produce enough user value.

Your goal is not to make the system “minimal at all costs”. Your goal is to preserve or improve the good user flow while removing unnecessary cognitive load, model pressure, latency, cost, moving parts, and fragile abstractions.

## Core rule

Simplify only when simplification preserves one of these:

1. User-visible quality.
2. Safety and data protection.
3. Business-critical behavior.
4. Maintainability.
5. Observability of important failures.

Do not remove complexity that is serving a real production purpose.

## When to use this skill

Use this skill for:

- AI/LLM workflows with too many model calls, agents, prompts, tools, routing steps, or validators.
- Product flows where the model is responsible for decisions that could be deterministic code, rules, cached data, SQL, search, forms, or simple classification.
- Backend/frontend/mobile implementations that introduce abstractions before the product requirements are stable.
- Prompt chains that pass too much repeated context, ask the model for obvious things, or generate large outputs that are later discarded.
- Feature proposals that sound impressive but do not clearly improve conversion, reliability, speed, trust, or usability.
- Code reviews where the implementation is correct but heavier than the problem requires.

Do not use this skill as an excuse to delete tests, validation, auth, authorization, rate limits, audit logs, migrations, monitoring, backups, error handling, or security controls.

## Review mindset

Keep these principles active throughout the review:

- Prefer boring, explicit, maintainable code over clever abstractions.
- Prefer deterministic logic over model reasoning when the rule is known.
- Prefer one high-quality model call over three weak chained calls when the intermediate steps do not create reliable state.
- Prefer cheap classification, regex, schema validation, database queries, or cached summaries for repetitive low-risk work.
- Prefer preserving the current working flow over redesigning the whole system.
- Prefer local changes with measurable effect over architectural rewrites.
- Prefer deleting unnecessary requirements before optimizing implementation details.
- Prefer human-readable failure states over hidden “smart” agent behavior.
- Avoid optimizing away the parts that make the product feel good to users.

## Audit workflow

Follow this sequence before recommending changes.

### 1. Map the current flow

Create a concise map of what happens today:

- User input.
- Pre-processing.
- Data retrieval.
- Model calls.
- Tools or external APIs.
- Post-processing.
- Storage.
- User response.
- Human review or escalation.

If reviewing code, identify the minimum files needed. Do not read the entire repository unless the flow cannot be understood otherwise.

### 2. Identify the value-critical path

Mark which steps directly affect the user’s success. Use these labels:

- `CRITICAL`: must remain strong; failure breaks the product or trust.
- `USEFUL`: improves quality but could be simplified.
- `OPTIONAL`: nice-to-have, weak effect on outcome.
- `WASTE`: cost/latency/complexity without clear value.
- `RISKY`: fragile, hard to debug, or hides failure.

### 3. Classify every model task

For each model call, classify the job:

- Generation.
- Classification.
- Extraction.
- Ranking.
- Reasoning.
- Summarization.
- Tool routing.
- Validation.
- Rewriting.
- Data transformation.

Then ask: “Does this really require an LLM?”

If the answer is no, propose a deterministic replacement.
If the answer is yes, check whether the model can receive less context, a smaller prompt, a cheaper model, or a stricter output schema.

### 4. Detect overengineering signals

Flag any of these patterns:

- Multiple agents for a task one agent can do reliably.
- Model used to make decisions already encoded in business rules.
- Repeated full conversation/context passed into every call.
- Large prompts used for simple classification or extraction.
- A vector database/RAG pipeline before there is enough content volume or retrieval pain.
- Microservices before team size, scaling, or deployment needs justify them.
- Complex state machine before the user flow is stable.
- Premature plugin/tool integration that replaces a simple API call or form.
- Prompt chains where each step only rephrases the previous step.
- Extra validation by LLM when JSON schema, tests, or typed models would be stronger.
- Excessive personalization/context injection that increases hallucination risk.
- “Enterprise-grade” architecture without enterprise constraints.
- UI steps that exist only because the backend flow is complex.
- Abstractions with one implementation and no clear near-term second case.
- Config systems for values that rarely change.
- Background jobs for work that can happen synchronously with acceptable latency.
- Fine-tuning considered before prompt/RAG/evals/data quality have been proven insufficient.

### 5. Find safe simplifications

For every simplification, classify it:

- `SAFE NOW`: low risk, clear benefit, preserves user flow.
- `TEST FIRST`: likely useful but needs tests, metrics, or shadow mode.
- `DEFER`: not urgent; revisit after more usage data.
- `DO NOT SIMPLIFY`: complexity protects quality, safety, or trust.

### 6. Measure the expected gain

For each proposed change, estimate the impact on:

- Model calls.
- Token usage/context size.
- Latency.
- Cost.
- Failure modes.
- Debuggability.
- Code surface area.
- User experience.

Use directional estimates when exact numbers are unavailable: `high`, `medium`, `low`, or `unknown`.

## Model pressure checklist

Use this checklist whenever the system depends on LLMs.

### Context pressure

- Are we sending repeated static instructions that could live in a system prompt, skill, config, or cached summary?
- Are we sending the full history when only the latest user intent and a short state summary are needed?
- Are we injecting documents that retrieval did not rank as relevant?
- Can long context be replaced by IDs, structured state, or a compact summary?

### Reasoning pressure

- Are we asking the model to infer business rules that should be explicit code?
- Are we asking it to remember constraints instead of enforcing them with validation?
- Are we making it choose tools without giving it clear routing criteria?
- Are we asking it to plan too many steps before seeing the actual data?

### Output pressure

- Are we asking for long JSON objects when only two fields are used?
- Are we asking for prose and then parsing it later?
- Can the output be a small enum, score, boolean, or typed object?
- Are we generating content that the UI immediately hides, truncates, or rewrites?

### Reliability pressure

- Are we using another model call to fix bad outputs instead of making the first output constrained?
- Are we relying on prompt wording where tests or schemas would catch failure earlier?
- Is failure visible and recoverable, or does the agent silently continue with bad assumptions?

## Decision matrix

Use this matrix to decide what to recommend.

| Situation | Preferred solution | Avoid |
|---|---|---|
| Fixed business rule | Code, config, DB constraint, typed validator | Asking the model to infer the rule every time |
| Simple classification | Small enum prompt, cheap model, keyword/rule hybrid | Long reasoning prompt or multi-agent debate |
| Data extraction from known format | Parser, regex, schema, OCR only when needed | LLM extraction from clean structured data |
| Repeated context | Cached summary, IDs, retrieved snippets | Sending all documents/conversation every call |
| User-facing answer quality matters | Strong model call with compact relevant context | Many weak chained calls that compound errors |
| Sensitive/destructive action | Explicit confirmation, audit log, permission checks | Autonomous model decision |
| Unstable product requirements | Direct implementation, fewer abstractions | Frameworks, plugin systems, microservices |
| Need to improve prompt quality | Eval cases, clear examples, output schema | Blind prompt expansion |
| Need more accuracy | Better retrieval/data/evals first | Fine-tuning by default |
| Need production readiness | Tests, monitoring, error states, rollback | Removing safeguards to look simple |

## What not to simplify

Do not recommend removing or weakening:

- Authentication and authorization.
- Input validation and output validation.
- Payment, financial, legal, or personal data safeguards.
- Rate limiting and abuse prevention.
- Data deletion/export controls.
- Audit logs for important actions.
- Error handling for external APIs.
- Database migrations and backups.
- Test coverage around critical flows.
- Observability for failures users cannot diagnose.
- Human review steps where the cost of a wrong autonomous decision is high.

## Recommended output format

When this skill is used, respond with this structure.

### Anti-overengineering review

**Current flow:**  
Briefly map the flow in 5-10 bullets.

**What is already good:**  
List what should be preserved.

**Where we are demanding too much from the model:**  
For each issue, include:

- Problem.
- Why it is overengineered or fragile.
- Safer/simpler alternative.
- Expected impact.
- Risk level.

**Simplification plan:**

| Priority | Change | Type | Expected gain | Risk | How to validate |
|---|---|---|---|---|---|
| P0 | Critical simplification or safety correction | SAFE NOW / TEST FIRST / DEFER | High/Medium/Low | Low/Medium/High | Test/metric/manual check |

**Do not simplify:**  
List safeguards or complex parts that should remain.

**Final recommendation:**  
Give a clear decision:

- `KEEP AS IS`
- `SIMPLIFY LIGHTLY`
- `SIMPLIFY BEFORE SCALING`
- `REWORK FLOW`
- `NEEDS DATA BEFORE DECISION`

## Code review behavior

When editing code:

1. Preserve public APIs unless the user explicitly asks for a breaking change.
2. Prefer small diffs.
3. Delete unused abstractions only after confirming no references remain.
4. Keep tests passing.
5. Add or adjust tests for any behavior change.
6. Do not replace explicit code with prompts.
7. Do not introduce new dependencies unless they remove more complexity than they add.
8. Do not create new architecture documents unless they will be used by the team.
9. After changes, summarize what was removed, what stayed, and why.

## Prompt/agent review behavior

When reviewing prompts or agent flows:

1. Reduce repeated instructions first.
2. Make routing rules explicit.
3. Replace vague “be smart” instructions with concrete criteria.
4. Prefer one compact prompt with structured output over multiple loosely connected prompts.
5. Keep examples only if they materially improve behavior.
6. Keep the personality/style layer separate from business logic.
7. Avoid making the model responsible for hidden product policy.
8. Add fallback behavior for uncertainty.
9. Use smaller models only after defining what quality must be preserved.

## Final check before recommending simplification

Before finalizing, answer internally:

- What user value are we protecting?
- What complexity is clearly not paying rent?
- What failure becomes more likely if we simplify?
- What metric or test will prove the simplification worked?
- Could this be solved by clearer requirements instead of more architecture?

Only recommend changes that pass this check.
