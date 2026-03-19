---
description: "Show current marketing context — product info, active strategies, health scores, and stale strategy detection."
argument-hint: ""
allowed-tools: ["Read", "Bash", "Glob"]
---

# /marketing-status

Display the current marketing context and health for this project.

## Process

### 1. Check for Marketing Config

Look for `.marketing-studio/config.json` in the current directory (up to 3 levels).

If found, display:
- Product name and description
- Target audience
- Active channels
- Current marketing stage
- Business model
- Competitors
- Recent decisions

If not found, display:
```
No marketing context found.
Run `/marketing-init` to set up your project's marketing context.
This creates `.marketing-studio/config.json` with your product info, audience, and competitors.
```

### 2. Check for Existing Strategies

Look for any files in `.marketing-studio/` directory:

| File | Description | Expected |
|------|------------|----------|
| `config.json` | Project marketing context | Created by `/marketing-init` |
| `memory.md` | Running log of marketing decisions | Appended by all commands |
| `strategy.md` | Overall marketing strategy | Created by `/marketing` |
| `content-calendar.md` | Content plan | Created by `/content-plan` |
| `seo-report.md` | Latest SEO audit | Created by `/seo-audit` |
| `competitor-analysis.md` | Latest competitive intel | Created by `/competitor-analysis` |
| `citation-audit.md` | Latest AI citation audit | Created by `/ai-citations` |
| `growth-plan.md` | Growth experiment backlog | Created by `/growth-plan` |
| `launch-plan.md` | Launch strategy | Created by `/launch-plan` |
| `social-strategy.md` | Social media plan | Created by `/social-strategy` |
| `reddit-strategy.md` | Reddit engagement plan | Created by `/reddit-strategy` |

List what exists and when it was last modified.

### 3. Marketing Health Check

Score the overall marketing health based on what exists and how fresh it is:

```markdown
## Marketing Health Check

### Overall Health Score: X/100

| Category | Score | Status | Details |
|----------|-------|--------|---------|
| **Project Context** | X/15 | [OK/Warning/Missing] | config.json [exists/missing], last updated [date] |
| **Marketing Strategy** | X/15 | [OK/Warning/Missing] | strategy.md [exists/missing/stale] |
| **SEO** | X/15 | [OK/Warning/Missing] | Last audit: [date or never] |
| **Content** | X/15 | [OK/Warning/Missing] | Content calendar [exists/missing/stale] |
| **Social** | X/10 | [OK/Warning/Missing] | Social strategy [exists/missing/stale] |
| **AI Citations** | X/10 | [OK/Warning/Missing] | Last audit: [date or never] |
| **Competitive Intel** | X/10 | [OK/Warning/Missing] | Last analysis: [date or never] |
| **Growth** | X/10 | [OK/Warning/Missing] | Growth plan [exists/missing/stale] |

**Score interpretation:**
- 0-25: No marketing foundation — run `/marketing-init` then `/marketing`
- 26-50: Partial setup — key strategies missing or outdated
- 51-75: Active marketing — keep strategies fresh and execute
- 76-100: Strong — executing across channels with up-to-date plans
```

### 4. Staleness Detection

Flag strategies that need refreshing:

| Strategy | Last Updated | Stale Threshold | Status |
|----------|-------------|----------------|--------|
| SEO Audit | [date] | 30 days | [Fresh/Stale/Missing] |
| Competitor Analysis | [date] | 14 days | [Fresh/Stale/Missing] |
| AI Citation Audit | [date] | 30 days | [Fresh/Stale/Missing] |
| Content Calendar | [date] | 7 days | [Fresh/Stale/Missing] |
| Social Strategy | [date] | 30 days | [Fresh/Stale/Missing] |
| Growth Experiments | [date] | 14 days | [Fresh/Stale/Missing] |

**Staleness rules:**
- **SEO Audit**: Stale after 30 days — search algorithms and rankings change
- **Competitor Analysis**: Stale after 14 days — competitors move fast
- **AI Citation Audit**: Stale after 30 days — AI models update frequently
- **Content Calendar**: Stale after 7 days — should be actively used and updated
- **Social Strategy**: Stale after 30 days — platform algorithms and trends shift
- **Growth Experiments**: Stale after 14 days — experiments should be running continuously

### 5. Recommended Next Actions

Based on the health check, suggest the most impactful next action:

```markdown
### Recommended Next Actions

1. **[Highest priority action]** — Run `/[command]` because [reason]
2. **[Second priority]** — Run `/[command]` because [reason]
3. **[Third priority]** — Run `/[command]` because [reason]
```

**Priority logic:**
- If no config.json: recommend `/marketing-init` first
- If no strategy.md: recommend `/marketing` second
- If SEO audit stale/missing: recommend `/seo-audit`
- If competitor analysis stale/missing: recommend `/competitor-analysis`
- If content calendar stale/missing: recommend `/content-plan`
- If citation audit missing: recommend `/ai-citations`
- If everything is fresh: recommend reviewing metrics and running growth experiments

### 6. Pipeline Status

Check if any pipelines are partially complete:

| Pipeline | Steps Completed | Next Step | Status |
|----------|----------------|-----------|--------|
| `product-launch` | [X/5] | [next command] | [In Progress/Not Started/Complete] |
| `competitive-intel` | [X/3] | [next command] | [In Progress/Not Started/Complete] |
| `content-cycle` | [X/3] | [next command] | [In Progress/Not Started/Complete] |

Determine pipeline progress by checking which strategy files exist and their dates. If multiple pipeline steps have been run in sequence within a short window (same day or consecutive days), the pipeline is likely in progress.

### 7. Agent Quick-Check Recommendations

Based on staleness, suggest running lightweight agent checks:

- **If SEO audit is stale but < 60 days**: "Run the `seo-scanner` agent for a quick health check before a full re-audit"
- **If citation audit is stale but < 60 days**: "Run the `citation-checker` agent for a quick spot-check"
- **If both are very stale (> 60 days)**: "Run full `/seo-audit` and `/ai-citations` commands"

### 8. Memory Log

If `.marketing-studio/memory.md` exists, display the last 5 entries as a timeline:

```markdown
### Recent Marketing Activity

| Date | Action | Key Outcome |
|------|--------|------------|
| [date] | [command run] | [key finding or decision] |
```

If memory.md has more than 5 entries, show the last 5 and note:
> "Showing last 5 of [X] entries. Read `.marketing-studio/memory.md` for full history."

### 9. Quick Actions

Display a quick-reference action menu based on current state:

```markdown
### Quick Actions

| Action | Command | Why |
|--------|---------|-----|
| Set up marketing | `/marketing-init` | [if config missing] |
| Full strategy | `/marketing` | [if strategy missing] |
| Quick SEO check | `seo-scanner` agent | [if audit stale] |
| Quick citation check | `citation-checker` agent | [if audit stale] |
| Full launch sequence | `product-launch` pipeline | [if pre-launch stage] |
| Monthly refresh | `content-cycle` pipeline | [if growing/established] |
```

## Cross-References

- `/marketing-init` — Set up project context (recommended first step)
- `/marketing` — Full marketing strategy
- `/seo-audit` — Refresh SEO audit
- `/ai-citations` — Refresh AI citation audit
- `/content-plan` — Update content calendar
- `/competitor-analysis` — Refresh competitive intel
- `/growth-plan` — Review and update growth experiments
- `/social-strategy` — Refresh social media plan
- `/reddit-strategy` — Review Reddit engagement progress
- `/launch-plan` — Launch planning and readiness
