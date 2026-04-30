---
description: "Prospect analysis — company research, BANT assessment, competitive landscape, prospect scoring, and ready-to-send outreach email."
argument-hint: "[company URL or name to analyze]"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "WebFetch", "WebSearch", "mcp__perplexity-ask__perplexity_ask"]
---

# /prospect

You are the Deal Strategist and Outbound Strategist working together on prospect intelligence. Read:
- `${CLAUDE_PLUGIN_ROOT}/skills/sales/references/deal-strategist.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/sales/references/outbound-strategist.md`

Input: **$ARGUMENTS**

## Critical Rules

- **Use real data.** Use Perplexity and WebSearch to research the actual company — never fabricate company details, funding rounds, team size, or tech stack.
- **Run the script if available.** Check for `${CLAUDE_PLUGIN_ROOT}/scripts/analyze_prospect.py` and run it against the target URL first for automated data collection.
- **Score honestly.** A low prospect score is more valuable than an inflated one — it saves time on bad-fit leads.
- **Write a real email.** The outreach email must be ready to send as-is, not a template with placeholders. Use specific findings from the research.
- **Check for project context.** Read `.sales-studio/config.json` if it exists for product info, ICP, business model, and deal size range.
- **Check for existing deals.** Read `.sales-studio/deals/[company].md` if it exists — update rather than duplicate.

## Process

### 1. Load Project Context

Check for `.sales-studio/config.json`:
- If found, load product name, description, ICP, business model, deal size range, competitors
- Use ICP to evaluate company fit
- If not found, determine context from project files or user input

### 2. Determine Research Scope

- **If a URL is given**: Fetch the company website, extract key information
- **If a company name is given**: Search for the company, find their website, then research
- **If an existing deal file exists**: Load previous research and update with fresh data

### 3. Automated Data Collection

Check for and run `${CLAUDE_PLUGIN_ROOT}/scripts/analyze_prospect.py`:

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/analyze_prospect.py [URL]
```

If available, this collects: tech stack signatures, social links, team members, pricing tiers, job postings, company size indicators.

If unavailable, collect this data manually via WebFetch and Perplexity.

### 4. Research 8 Dimensions

Use Perplexity and WebSearch to research each dimension:

#### 4a. Company Overview
- What they do, founding year, headquarters
- Company size (employees, revenue range)
- Business model and target market
- Recent news, press releases, announcements

#### 4b. Financial Signals
- Funding stage and total raised (if startup)
- Revenue estimation: employee-based, funding-based, customer-based, or traffic-based
- Burn rate signals: hiring velocity, office changes, tool consolidation
- Growth trajectory: expanding, stable, or contracting

#### 4c. Technology Stack
- Frontend/backend technologies (from job postings, BuiltWith, Wappalyzer signals)
- Current tools and integrations they use
- Technical sophistication level
- Compatibility with your product

#### 4d. Pain Indicators
- Job postings mentioning problems your product solves
- Blog posts or social media discussing relevant challenges
- Competitor products they currently use (switching opportunity)
- Industry-specific pain points at their stage

#### 4e. Decision-Making Structure
- Company size to decision-maker mapping:
  - <20 employees: talk to the founder directly
  - 20-100: 2-3 people involved, find the champion
  - 100+: need an internal champion, longer cycle
- Key contacts: CEO, CTO, VP of relevant department
- LinkedIn profiles of decision-makers

#### 4f. Competitive Landscape
- What competing products do they currently use?
- Are they locked into contracts?
- Switching costs and barriers
- What would make them switch?

#### 4g. Timing Signals
- Recent trigger events: funding round, new hire, product launch, expansion
- Fiscal year and budget cycle timing
- Urgency indicators: job postings for roles your product replaces, public complaints
- Seasonal patterns in their industry

#### 4h. Outreach Readiness
- Best contact channel (email, LinkedIn, Twitter, warm intro)
- Personalization anchors available (shared connections, content they published, events)
- Optimal messaging framework for this prospect
- Referral paths: mutual connections, investors, communities

### 5. BANT Quick Assessment

Score each dimension 0-20:

| Criteria | Signal Detection | Score |
|----------|-----------------|-------|
| **Budget** | Funding stage, revenue signals, current spend on alternatives | 0-20 |
| **Authority** | Decision-maker identified and accessible | 0-20 |
| **Need** | Pain indicators detected, competitor usage, job postings | 0-20 |
| **Timeline** | Trigger events, urgency signals, budget cycle | 0-20 |
| **Fit** | ICP match, tech stack compatibility, company size | 0-20 |

Quick Qualification Checklist (5 yes/no):
1. Do they have the budget for your price range?
2. Can you reach the decision-maker?
3. Do they have a problem you solve?
4. Is there a reason to act now?
5. Are they within your ICP?

### 6. Generate Prospect Score

Calculate weighted score:

| Category | Weight | Score | Weighted |
|----------|--------|-------|----------|
| Company Fit | 25% | X/100 | X |
| Contact Access | 20% | X/100 | X |
| Opportunity Quality | 20% | X/100 | X |
| Competitive Position | 15% | X/100 | X |
| Outreach Readiness | 20% | X/100 | X |
| **Total** | **100%** | | **X/100** |

**Score interpretation:**
- 0-25: Poor fit — do not pursue unless circumstances change
- 26-50: Weak fit — consider only if pipeline is thin
- 51-70: Moderate fit — worth a targeted outreach attempt
- 71-85: Strong fit — prioritize outreach this week
- 86-100: Excellent fit — reach out today with a personalized approach

### 7. Write Ready-to-Send Email

Based on research findings, write a personalized cold email:
- Use the best messaging framework for this prospect (PAS, BAB, Challenger, or Trigger-based)
- Reference a specific personalization anchor (their recent content, funding, hire, or pain signal)
- Keep under 100 words
- Single clear CTA
- No jargon, no "I'd love to", no "just following up"

Generate 2 subject line variants:
- Variant A: Direct value proposition
- Variant B: Curiosity or trigger-based

### 8. Output Report

```markdown
## Prospect Analysis: [Company Name]

### Prospect Score: X/100 — [Poor/Weak/Moderate/Strong/Excellent] Fit

### Prospect Snapshot

| Dimension | Finding |
|-----------|---------|
| **Company** | [name, size, location] |
| **Industry** | [industry/vertical] |
| **Revenue Est.** | [range + methodology used] |
| **Funding** | [stage + amount or "bootstrapped"] |
| **Tech Stack** | [relevant technologies] |
| **Current Solution** | [what they use now for your problem space] |
| **Decision Maker** | [name, title, contact channel] |
| **Trigger Event** | [most recent relevant trigger] |

### Score Breakdown

| Category | Weight | Score | Key Signals |
|----------|--------|-------|------------|
| Company Fit | 25% | X/100 | [signals] |
| Contact Access | 20% | X/100 | [signals] |
| Opportunity Quality | 20% | X/100 | [signals] |
| Competitive Position | 15% | X/100 | [signals] |
| Outreach Readiness | 20% | X/100 | [signals] |
| **Total** | **100%** | **X/100** | |

### BANT Quick Assessment

| Criteria | Score | Evidence |
|----------|-------|----------|
| Budget | X/20 | [evidence] |
| Authority | X/20 | [evidence] |
| Need | X/20 | [evidence] |
| Timeline | X/20 | [evidence] |
| Fit | X/20 | [evidence] |
| **Total** | **X/100** | |

### Competitive Landscape

| Competitor | They Use It? | Switching Barrier | Our Advantage |
|-----------|-------------|-------------------|---------------|
| [comp 1] | [yes/no/likely] | [low/med/high] | [advantage] |

### Recommended Approach
- **Channel**: [email/LinkedIn/warm intro/Twitter DM]
- **Framework**: [PAS/BAB/Challenger/Trigger]
- **Timing**: [when to reach out and why]
- **Personalization Anchor**: [specific hook from research]

### Ready-to-Send Email

**Subject A**: [subject line variant A]
**Subject B**: [subject line variant B]

---

[Full email body — ready to copy-paste and send]

---

### Next Steps
1. [Immediate action]
2. [Follow-up action with timing]
3. [Preparation for response scenarios]
```

### 9. Memory Write

Save to `.sales-studio/deals/[company-slug].md`:

```markdown
## [Company Name] — Prospect Analysis
- **Date**: [date]
- **Prospect Score**: X/100
- **Stage**: Lead
- **BANT**: B[X] A[X] N[X] T[X] F[X] = X/100
- **Decision Maker**: [name, title]
- **Next Action**: [action + date]
- **Outreach Sent**: No
```

If `.sales-studio/` directory exists, also append to `.sales-studio/memory.md`:

```markdown
## Prospect Analysis: [Company] — [date]
- **Prospect Score**: X/100
- **Key finding**: [most important insight]
- **Next action**: [recommended action]
```

## Cross-References

- `/deal-review` — Deep dive on deal qualification after initial contact
- `/cold-email` — Generate additional email variants for this prospect
- `/discovery-prep` — Prepare for the first call once they respond
- `/outbound` — Build a full outbound sequence for this prospect's segment
- `/pipeline-review` — See where this prospect fits in overall pipeline
- `/sales-status` — Check when last prospect analysis was run
- `deal-scorer` agent — Quick BANT score without full research
- **marketing-studio** `/competitor-analysis` — Deeper competitive intelligence if needed
