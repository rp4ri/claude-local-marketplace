---
description: "Show current sales context — product info, pipeline state, health scores, deal tracking, and stale strategy detection."
argument-hint: ""
allowed-tools: ["Read", "Bash", "Glob"]
---

# /sales-status

Display the current sales context, pipeline health, and deal status for this project.

## Process

### 1. Check for Sales Config

Look for `.sales-studio/config.json` in the current directory (up to 3 levels).

If found, display:
- Product name and description
- Business model
- ICP summary
- Deal size range and pricing model
- Sales cycle length
- Current channels and tools
- Competitors

If not found, display:
```
No sales context found.
Run `/sales-init` to set up your project's sales context.
This creates `.sales-studio/config.json` with your product info, ICP, pricing, and competitors.
```

### 2. Check for Existing Strategies

Look for any files in `.sales-studio/` directory:

| File | Description | Expected |
|------|------------|----------|
| `config.json` | Project sales context | Created by `/sales-init` |
| `memory.md` | Running log of sales decisions | Appended by all commands |
| `strategy.md` | Overall sales strategy | Created by `/sales` |
| `outbound-plan.md` | Outbound prospecting plan | Created by `/outbound` |
| `pricing-audit.md` | Pricing analysis | Created by `/pricing-audit` |
| `pipeline-review.md` | Pipeline scorecard | Created by `/pipeline-review` |
| `objection-bank.md` | Objection playbook | Created by `/objection-bank` |
| `discovery-prep.md` | Discovery call scripts | Created by `/discovery-prep` |

List what exists and when it was last modified.

### 3. Sales Health Check

Score the overall sales health based on what exists and how fresh it is:

```markdown
## Sales Health Check

### Overall Health Score: X/100

| Category | Score | Status | Details |
|----------|-------|--------|---------|
| **Project Context** | X/15 | [OK/Warning/Missing] | config.json [exists/missing], last updated [date] |
| **Sales Strategy** | X/15 | [OK/Warning/Missing] | strategy.md [exists/missing/stale] |
| **Outbound** | X/15 | [OK/Warning/Missing] | outbound-plan.md [exists/missing/stale] |
| **Pricing** | X/15 | [OK/Warning/Missing] | pricing-audit.md [exists/missing/stale] |
| **Pipeline** | X/10 | [OK/Warning/Missing] | pipeline-review.md [exists/missing/stale] |
| **Discovery** | X/10 | [OK/Warning/Missing] | discovery-prep.md [exists/missing/stale] |
| **Objections** | X/10 | [OK/Warning/Missing] | objection-bank.md [exists/missing/stale] |
| **Active Deals** | X/10 | [OK/Warning/Missing] | deals/ directory [X deals tracked] |

**Score interpretation:**
- 0-25: No sales foundation — run `/sales-init` then `/sales`
- 26-50: Partial setup — key strategies missing or outdated
- 51-75: Active selling — keep strategies fresh and execute
- 76-100: Strong — executing across channels with up-to-date pipeline
```

### 4. Staleness Detection

Flag strategies that need refreshing:

| Strategy | Last Updated | Stale Threshold | Status |
|----------|-------------|----------------|--------|
| Outbound Plan | [date] | 14 days | [Fresh/Stale/Missing] |
| Pricing Audit | [date] | 30 days | [Fresh/Stale/Missing] |
| Pipeline Review | [date] | 7 days | [Fresh/Stale/Missing] |
| Active Deals | [date] | 14 days | [Fresh/Stale/Missing] |
| Discovery Prep | [date] | 30 days | [Fresh/Stale/Missing] |
| Objection Bank | [date] | 30 days | [Fresh/Stale/Missing] |

**Staleness rules:**
- **Outbound Plan**: Stale after 14 days — prospecting lists and outreach need constant refresh
- **Pricing Audit**: Stale after 30 days — competitor pricing and market conditions shift
- **Pipeline Review**: Stale after 7 days — pipeline should be reviewed weekly minimum
- **Active Deals**: Stale after 14 days — deals go cold without regular follow-up
- **Discovery Prep**: Stale after 30 days — update as product and ICP evolve
- **Objection Bank**: Stale after 30 days — new objections emerge as market changes

### 5. Active Deals Summary

Scan `.sales-studio/deals/` directory for deal files:

```markdown
### Active Deals

| Company | Stage | Deal Size | Last Updated | Status |
|---------|-------|-----------|-------------|--------|
| [company] | [stage] | [size] | [date] | [Active/Stale/Won/Lost] |

**Pipeline Summary:**
- Total pipeline value: $X
- Deals in pipeline: X
- Avg deal size: $X
- Avg days in pipeline: X
- Stale deals (>14 days no update): X
```

If no deals directory or no deal files exist:
> "No deals tracked yet. Use `/prospect` to analyze a company or `/deal-review` to qualify an opportunity. Deal files are saved to `.sales-studio/deals/`."

### 6. Recommended Next Actions

Based on the health check, suggest the most impactful next action:

```markdown
### Recommended Next Actions

1. **[Highest priority action]** — Run `/[command]` because [reason]
2. **[Second priority]** — Run `/[command]` because [reason]
3. **[Third priority]** — Run `/[command]` because [reason]
```

**Priority logic:**
- If no config.json: recommend `/sales-init` first
- If no strategy.md: recommend `/sales` second
- If outbound plan stale/missing: recommend `/outbound`
- If pipeline review stale/missing: recommend `/pipeline-review`
- If pricing audit stale/missing: recommend `/pricing-audit`
- If no active deals: recommend `/prospect` or `/outbound`
- If deals are stale: recommend `/deal-review` on stale deals
- If everything is fresh: recommend reviewing pipeline metrics and running outbound

### 7. Pipeline Status

Check if any pipelines are partially complete:

| Pipeline | Steps Completed | Next Step | Status |
|----------|----------------|-----------|--------|
| `first-sale` | [X/5] | [next command] | [In Progress/Not Started/Complete] |
| `deal-cycle` | [X/5] | [next command] | [In Progress/Not Started/Complete] |
| `monthly-review` | [X/3] | [next command] | [In Progress/Not Started/Complete] |

Determine pipeline progress by checking which strategy files exist and their dates. If multiple pipeline steps have been run in sequence within a short window (same day or consecutive days), the pipeline is likely in progress.

### 8. Agent Quick-Check Recommendations

Based on staleness, suggest running lightweight agent checks:

- **If deals exist but no recent scoring**: "Run the `deal-scorer` agent for a quick BANT triage of your active deals"
- **If outreach is active but no email grading**: "Run the `email-grader` agent for a quick quality check on your latest email drafts"
- **If both outbound and deals are stale (> 30 days)**: "Run full `/outbound` and `/pipeline-review` commands for a comprehensive refresh"

### 9. Memory Log

If `.sales-studio/memory.md` exists, display the last 5 entries as a timeline:

```markdown
### Recent Sales Activity

| Date | Action | Key Outcome |
|------|--------|------------|
| [date] | [command run] | [key finding or decision] |
```

If memory.md has more than 5 entries, show the last 5 and note:
> "Showing last 5 of [X] entries. Read `.sales-studio/memory.md` for full history."

### 10. Quick Actions

Display a quick-reference action menu based on current state:

```markdown
### Quick Actions

| Action | Command | Why |
|--------|---------|-----|
| Set up sales | `/sales-init` | [if config missing] |
| Full strategy | `/sales` | [if strategy missing] |
| Find prospects | `/outbound` | [if outbound plan stale/missing] |
| Quick deal score | `deal-scorer` agent | [if deals need triage] |
| Quick email grade | `email-grader` agent | [if outreach active] |
| First sale sequence | `first-sale` pipeline | [if no deals yet] |
| Monthly refresh | `monthly-review` pipeline | [if established pipeline] |
| Review pricing | `/pricing-audit` | [if pricing stale] |
```

## Cross-References

- `/sales-init` — Set up project context (recommended first step)
- `/sales` — Full sales strategy
- `/prospect` — Analyze a specific prospect
- `/outbound` — Build prospecting lists
- `/cold-email` — Write outreach sequences
- `/deal-review` — Qualify a deal opportunity
- `/discovery-prep` — Prepare for sales calls
- `/proposal` — Generate proposals
- `/pricing-audit` — Analyze pricing strategy
- `/pipeline-review` — Pipeline health and forecasting
- `/objection-bank` — Handle objections
