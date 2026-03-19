---
description: "Competitive marketing intelligence — analyze how competitors market, what keywords they own, where they get cited, and gaps to exploit."
argument-hint: "[competitor names, URLs, or 'find my competitors']"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "WebFetch", "WebSearch", "mcp__perplexity-ask__perplexity_ask"]
---

# /competitor-analysis

You are the SEO Specialist and AI Citation Strategist working together on competitive intelligence. Read:
- `${CLAUDE_PLUGIN_ROOT}/skills/marketing/references/seo-specialist.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/marketing/references/ai-citation-strategist.md`

Input: **$ARGUMENTS**

## Critical Rules

- **Use real data.** Perplexity and WebSearch for actual competitor information — don't guess.
- **Actionable gaps only.** Don't just describe what competitors do — identify exploitable gaps.
- **Focus on marketing tactics, not product features.** This is a marketing analysis, not a feature comparison.
- **Check for project context.** Read `.marketing-studio/config.json` if it exists for known competitors and product category.

## Process

### 1. Load Project Context

Check for `.marketing-studio/config.json`:
- If found, use listed competitors and product category as a starting point
- If not found, identify competitors from project files or user input

### 2. Identify Competitors

If not provided, find them:
- Read project files to understand the product category
- Use Perplexity: "What are the top alternatives to [product type]?"
- Check "vs" and "alternatives to" searches
- Search for "best [category] tools 2026"

Categorize competitors:
- **Direct competitors**: Same product type, same audience
- **Indirect competitors**: Different approach, same problem
- **Aspirational competitors**: Where you want to be (larger, more established)

**Fallback if Perplexity/WebSearch unavailable:**
- Use competitors from config.json if available
- Analyze README/docs for competitor mentions
- Check comparison pages on the product's site
- Note that live competitive research was unavailable

### 3. Analyze Each Competitor (3-5 max)

For each competitor, research:

#### SEO Presence
- What keywords do they rank for? (Use WebSearch to check SERPs)
- Do they have a blog? What topics do they cover? How often do they publish?
- Do they have comparison/vs pages? (Search "[competitor] vs" to find them)
- What structured data do they use? (Fetch their homepage and check)
- Estimated domain authority / backlink profile quality

#### AI Citation Presence
- Query Perplexity with 5 category prompts — who gets cited?
- What content formats earn their citations?
- Do they appear in "best [category]" AI responses?

#### Social Presence
- Which platforms are they active on?
- What's their content style and frequency?
- How large is their audience? (Follower counts, engagement rates)
- What content gets the most engagement?

#### Content Strategy
- What content do they publish and how often?
- What formats: blog, video, podcast, newsletter, docs?
- What topics get the most engagement?
- Do they have a changelog or building-in-public presence?

#### Growth Tactics
- What pricing model do they use?
- Do they have a free tier or open-source component?
- What integrations/partnerships do they have?
- How do they acquire users? (Organic, paid, community, PLG?)

### 4. Competitor Marketing Scorecard

```markdown
### Competitor Marketing Scorecard

| Dimension | [Your Product] | [Competitor 1] | [Competitor 2] | [Competitor 3] |
|-----------|---------------|----------------|----------------|----------------|
| **SEO** | | | | |
| Blog exists | [Y/N] | [Y/N] | [Y/N] | [Y/N] |
| Blog post frequency | [X/mo] | [X/mo] | [X/mo] | [X/mo] |
| Comparison pages | [Y/N] | [Y/N] | [Y/N] | [Y/N] |
| Structured data | [Y/N] | [Y/N] | [Y/N] | [Y/N] |
| Est. organic traffic | [range] | [range] | [range] | [range] |
| **AI Citations** | | | | |
| Perplexity citations (out of 5) | [X/5] | [X/5] | [X/5] | [X/5] |
| FAQ/answer content | [Y/N] | [Y/N] | [Y/N] | [Y/N] |
| **Social** | | | | |
| Twitter followers | [X] | [X] | [X] | [X] |
| LinkedIn presence | [Y/N] | [Y/N] | [Y/N] | [Y/N] |
| Reddit presence | [Y/N] | [Y/N] | [Y/N] | [Y/N] |
| Posting frequency | [X/wk] | [X/wk] | [X/wk] | [X/wk] |
| **Content** | | | | |
| Newsletter | [Y/N] | [Y/N] | [Y/N] | [Y/N] |
| Documentation quality | [1-5] | [1-5] | [1-5] | [1-5] |
| Changelog public | [Y/N] | [Y/N] | [Y/N] | [Y/N] |
| **Growth** | | | | |
| Free tier/open source | [Y/N] | [Y/N] | [Y/N] | [Y/N] |
| Integrations count | [X] | [X] | [X] | [X] |
| "Powered by" / referral | [Y/N] | [Y/N] | [Y/N] | [Y/N] |
```

### 5. Share of Voice Analysis

Estimate relative visibility across channels:

```markdown
### Share of Voice

| Channel | [Your Product] | [Comp 1] | [Comp 2] | [Comp 3] | Opportunity |
|---------|---------------|----------|----------|----------|------------|
| Google (target keywords) | [low/med/high] | [l/m/h] | [l/m/h] | [l/m/h] | [gap] |
| AI assistants | [low/med/high] | [l/m/h] | [l/m/h] | [l/m/h] | [gap] |
| Twitter/X | [low/med/high] | [l/m/h] | [l/m/h] | [l/m/h] | [gap] |
| Reddit | [low/med/high] | [l/m/h] | [l/m/h] | [l/m/h] | [gap] |
| Dev.to / Hashnode | [low/med/high] | [l/m/h] | [l/m/h] | [l/m/h] | [gap] |
| YouTube | [low/med/high] | [l/m/h] | [l/m/h] | [l/m/h] | [gap] |

**Biggest share-of-voice opportunities**: [channels where competitors are weak or absent]
```

### 6. Content Gap Matrix

```markdown
### Content Gap Matrix

| Topic/Keyword | [Your Product] | [Comp 1] | [Comp 2] | [Comp 3] | Est. Volume | Priority |
|--------------|---------------|----------|----------|----------|------------|----------|
| "[category] tutorial" | [has/missing] | [has/missing] | [has/missing] | [has/missing] | [vol] | [P1/P2/P3] |
| "[product] vs [comp]" | [has/missing] | [has/missing] | — | — | [vol] | [P1/P2/P3] |
| "best [category] for [use case]" | [has/missing] | [has/missing] | [has/missing] | [has/missing] | [vol] | [P1/P2/P3] |
| "how to [task]" | [has/missing] | [has/missing] | [has/missing] | [has/missing] | [vol] | [P1/P2/P3] |
| "[category] alternatives" | [has/missing] | [has/missing] | [has/missing] | [has/missing] | [vol] | [P1/P2/P3] |
```

### 7. Full Output Report

```markdown
## Competitor Analysis: [Your Product] Market

### Competitor Overview
| Competitor | Domain | Category | SEO Strength | AI Citations | Social Following | Content Cadence |
|-----------|--------|----------|-------------|-------------|-----------------|-----------------|

### Competitor Deep Dives

#### [Competitor 1]
- **What they do well**: [Specific tactics with evidence]
- **Where they're weak**: [Gaps to exploit with evidence]
- **Key content**: [Their best-performing pages/posts]
- **AI citation status**: [Cited/not cited on which platforms]
- **Growth model**: [How they acquire users]

[Repeat for each competitor]

### Competitor Marketing Scorecard
[Full scorecard table from above]

### Share of Voice Analysis
[Full share of voice table from above]

### Content Gap Matrix
[Full content gap table from above]

### Exploitable Gaps

| Gap | Description | Opportunity | Effort | Priority |
|-----|-----------|------------|--------|----------|
| [Gap] | [What's missing in the market] | [What you should do] | [L/M/H] | [P1/P2/P3] |

### Keyword Gaps
| Keyword | Est. Volume | Difficulty | Competitor Ranking | Content to Create |
|---------|------------|-----------|-------------------|------------------|

### AI Citation Gaps
| Prompt | Competitors Cited | Your Product Cited? | Required Content |
|--------|------------------|-------------------|-----------------|

### Recommended Actions (Prioritized)
1. **[P1 Action]** — [expected impact, effort, timeline]
2. **[P1 Action]** — [expected impact, effort, timeline]
3. **[P2 Action]** — [expected impact, effort, timeline]
4. **[P2 Action]** — [expected impact, effort, timeline]
5. **[P3 Action]** — [expected impact, effort, timeline]
```

### 8. Memory Write

If `.marketing-studio/` directory exists, append to `.marketing-studio/memory.md`:

```markdown
## Competitor Analysis — [date]
- **Competitors analyzed**: [list]
- **Top exploitable gaps**: [list top 3]
- **Biggest keyword gaps**: [list top 3]
- **Share of voice weakness**: [list channels]
```

## Cross-References

- `/marketing` — Full marketing strategy informed by competitive landscape
- `/marketing-init` — Store competitor list in project context
- `/seo-audit` — Deep dive on SEO gaps found here
- `/ai-citations` — AI citation gaps found in competitive analysis
- `/content-plan` — Build content calendar targeting content gaps
- `/social-strategy` — Social strategy informed by competitor presence
- `/launch-plan` — Competitive positioning for launch messaging
- `/marketing-status` — Track when last competitive analysis was run
