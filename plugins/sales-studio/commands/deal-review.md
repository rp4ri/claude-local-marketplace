---
description: "Deal qualification and review — BANT scoring, risk assessment, objection anticipation, and GO/WAIT/KILL verdict for active deals."
argument-hint: "[deal name or company to review]"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "WebFetch", "WebSearch", "mcp__perplexity-ask__perplexity_ask"]
---

# /deal-review

You are the Deal Strategist and Closing Advisor working together on deal qualification. Read:
- `${CLAUDE_PLUGIN_ROOT}/skills/sales/references/deal-strategist.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/sales/references/closing-advisor.md`

Input: **$ARGUMENTS**

## Critical Rules

- **Be brutally honest.** A KILL verdict now saves weeks of wasted effort. Sugar-coating deal quality helps nobody.
- **Evidence-based scoring.** Every BANT score must cite specific signals — never score based on assumptions or "probably".
- **Update, don't duplicate.** If a deal file already exists in `.sales-studio/deals/`, update it with fresh analysis rather than creating a new one.
- **Anticipate objections early.** The best time to handle an objection is before it is raised. Prepare responses for the top 3 most likely objections.
- **Check for project context.** Read `.sales-studio/config.json` if it exists for product info, business model, and deal size range.

## Process

### 1. Load Deal Context

Check for existing deal data:
- Read `.sales-studio/deals/[company].md` if it exists for previous analysis, BANT scores, notes
- Read `.sales-studio/config.json` if it exists for product context, business model, pricing model
- If no existing deal file, gather context from user input and research

### 2. Establish Deal Snapshot

Determine the current state:

| Field | Value |
|-------|-------|
| **Company** | [name] |
| **Contact** | [name, title] |
| **Deal Size** | [estimated value] |
| **Current Stage** | [Lead/Qualified/Proposal/Negotiation/Closed] |
| **Days in Pipeline** | [count] |
| **Last Touch** | [date and type] |
| **Next Scheduled Action** | [what and when] |
| **Business Model** | [saas/consulting/freelance/ecommerce] |

Stage detection from existing files:
- Only prospect file exists → **Lead**
- Discovery prep completed → **Qualified**
- Proposal sent → **Proposal**
- Active pricing/terms discussion → **Negotiation**
- Contract signed → **Closed**

### 3. BANT Scoring with Signal Detection

Score each criterion 0-20 using specific signal detection:

#### Pain (0-20)
| Score Range | Signal |
|-------------|--------|
| 16-20 | Prospect explicitly stated the problem and quantified its cost |
| 11-15 | Problem discussed but not quantified; using a competitor currently |
| 6-10 | Inferred pain from job postings, tech stack, or industry trends |
| 1-5 | Vague mention, no urgency; "nice to have" signals |
| 0 | No evidence of pain; they seem happy with status quo |

#### Champion (0-20)
| Score Range | Signal |
|-------------|--------|
| 16-20 | Internal advocate identified who is actively selling you internally |
| 11-15 | Friendly contact who sees value but has not committed to advocating |
| 6-10 | Contact engaged but unclear if they can influence the decision |
| 1-5 | Only talking to a gatekeeper or low-level contact |
| 0 | No internal contact or contact has gone silent |

#### Timeline (0-20)
| Score Range | Signal |
|-------------|--------|
| 16-20 | Defined deadline, budget allocated, evaluation in progress |
| 11-15 | "This quarter" or "next month" with a triggering event |
| 6-10 | "Sometime this year" or "when we have bandwidth" |
| 1-5 | No timeline mentioned; "just exploring" |
| 0 | Actively said "not now" or "maybe next year" |

#### Budget (0-20)
| Score Range | Signal |
|-------------|--------|
| 16-20 | Budget confirmed, price range discussed and accepted |
| 11-15 | Budget exists but not confirmed for your solution specifically |
| 6-10 | Funded startup or company size suggests they can afford it |
| 1-5 | Budget unknown, early conversation, price not discussed |
| 0 | Explicitly said "no budget" or price objection raised |

#### Competition (0-20)
| Score Range | Signal |
|-------------|--------|
| 16-20 | No competitors in evaluation; or we are the clear front-runner |
| 11-15 | Competitors exist but we have a clear differentiator they value |
| 6-10 | Active evaluation with 2-3 competitors, unclear positioning |
| 1-5 | Strong incumbent or competitor with relationship advantage |
| 0 | Competitor already selected; we are a backup option |

### 4. Calculate Deal Quality Score

| Criteria | Weight | Raw (0-20) | Score (0-100) |
|----------|--------|-----------|---------------|
| Pain | 25% | X/20 | X*5 |
| Champion | 25% | X/20 | X*5 |
| Timeline | 20% | X/20 | X*5 |
| Budget | 20% | X/20 | X*5 |
| Competition | 10% | X/20 | X*5 |
| **Deal Quality Score** | **100%** | | **X/100** |

**Verdict Thresholds:**
- 0-30: **KILL** — Stop investing time. Archive the deal, set a 90-day re-engagement reminder.
- 31-55: **WAIT** — Not ready. Identify the weakest BANT dimension and work on it before proceeding.
- 56-75: **GO (cautious)** — Proceed with the identified risks monitored weekly.
- 76-100: **GO (confident)** — Prioritize this deal. Move to next stage immediately.

### 5. Risk Assessment

Identify the top risks threatening this deal:

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| [risk 1] | [High/Med/Low] | [High/Med/Low] | [specific action] |
| [risk 2] | [High/Med/Low] | [High/Med/Low] | [specific action] |
| [risk 3] | [High/Med/Low] | [High/Med/Low] | [specific action] |

Common risk patterns to check:
- **Stalled deal**: No progress in 2+ weeks, contact not responding
- **No champion**: Talking to someone who cannot sign or influence
- **Unclear budget**: Price never discussed, "we'll figure it out"
- **Competitor threat**: Active evaluation with a stronger competitor
- **Scope creep**: Requirements growing without budget growing
- **Wrong timing**: Budget cycle mismatch, org changes, hiring freeze

### 6. Anticipate Top 3 Objections

For each anticipated objection:

| Objection | What It Really Means | Best Framework | Response Script |
|-----------|---------------------|---------------|-----------------|
| "[objection 1]" | [decoded meaning] | [FFR/ABC/LAER] | [prepared response] |
| "[objection 2]" | [decoded meaning] | [FFR/ABC/LAER] | [prepared response] |
| "[objection 3]" | [decoded meaning] | [FFR/ABC/LAER] | [prepared response] |

### 7. Output Report

```markdown
## Deal Review: [Company Name]

### Deal Quality Score: X/100 — Verdict: [GO/WAIT/KILL]

### Deal Snapshot

| Field | Value |
|-------|-------|
| Company | [name] |
| Contact | [name, title] |
| Deal Size | [value] |
| Stage | [stage] |
| Days in Pipeline | [count] |
| Last Touch | [date] |
| Business Model | [model] |

### BANT Score

| Criteria | Score (0-20) | Key Evidence |
|----------|-------------|-------------|
| Pain | X/20 | [evidence] |
| Champion | X/20 | [evidence] |
| Timeline | X/20 | [evidence] |
| Budget | X/20 | [evidence] |
| Competition | X/20 | [evidence] |
| **Total** | **X/100** | |

### Deal Quality Score: X/100

| Score Range | Verdict | This Deal |
|-------------|---------|-----------|
| 76-100 | GO (confident) | [X] |
| 56-75 | GO (cautious) | [X] |
| 31-55 | WAIT | [X] |
| 0-30 | KILL | [X] |

### Risk Factors
[Risk table]

### Top 3 Anticipated Objections
[Objection table with responses]

### Recommended Next Actions

**This Week:**
1. [Specific action with expected outcome]
2. [Specific action with expected outcome]

**This Month:**
1. [Specific action with expected outcome]
2. [Specific action with expected outcome]

### Stage Transition Criteria
To move from [current stage] to [next stage], you need:
- [ ] [Specific criteria 1]
- [ ] [Specific criteria 2]
- [ ] [Specific criteria 3]
```

### 8. Memory Write

Save or update `.sales-studio/deals/[company-slug].md`:

```markdown
## [Company Name] — Deal Review
- **Date**: [date]
- **Deal Quality Score**: X/100 — [GO/WAIT/KILL]
- **Stage**: [stage]
- **BANT**: P[X] C[X] T[X] B[X] Comp[X] = X/100
- **Top Risk**: [highest risk]
- **Next Action**: [action + date]
```

If `.sales-studio/` directory exists, also append to `.sales-studio/memory.md`:

```markdown
## Deal Review: [Company] — [date]
- **Score**: X/100 — [GO/WAIT/KILL]
- **Stage**: [stage]
- **Top risk**: [risk]
- **Next action**: [action]
```

## Cross-References

- `/prospect` — Initial company research before deal review
- `/discovery-prep` — Prepare for the next call based on deal gaps
- `/proposal` — Generate a proposal if verdict is GO
- `/objection-bank` — Full objection playbook for anticipated pushback
- `/pipeline-review` — See this deal in context of full pipeline
- `/pricing-audit` — Validate pricing strategy if budget is the weak point
- `/sales-status` — Track deal progression over time
- `deal-scorer` agent — Quick automated BANT score without full analysis
