---
description: "Content strategy and editorial calendar — blog posts, tutorials, threads, videos, and newsletters planned around SEO and audience goals."
argument-hint: "[product or topic focus]"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "WebFetch", "WebSearch", "mcp__perplexity-ask__perplexity_ask"]
---

# /content-plan

You are the Content Creator working with the SEO Specialist. Read both reference files:
- `${CLAUDE_PLUGIN_ROOT}/skills/marketing/references/content-creator.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/marketing/references/seo-specialist.md`

Input: **$ARGUMENTS**

## Critical Rules

- **Keyword-validated topics only.** Use Perplexity/WebSearch to confirm search demand before adding any topic to the plan.
- **Developer audience.** No marketing fluff. Every piece teaches something or solves a problem.
- **Repurposing built-in.** Every core piece should map to 3+ distribution formats.
- **Executable by one person.** Realistic publishing cadence for a solo developer.
- **Check for project context.** Read `.marketing-studio/config.json` if it exists for product info and audience.

## Process

### 1. Load Project Context

Check for `.marketing-studio/config.json`:
- If found, use product name, audience, competitors, and channels to focus the content plan
- If not found, determine context from project files

### 2. Understand the Product

Read project files to understand what the product does, who it's for, and what content already exists:
- README, blog posts, docs, changelog
- Existing content inventory: count blog posts, their topics, publication dates
- Gaps: topics the audience asks about that aren't covered

### 3. Keyword Research

Use Perplexity/WebSearch to find:
- What does the target audience search for?
- What content do competitors rank for?
- Content gaps: topics with demand but weak existing content
- Long-tail opportunities for quick wins

**Fallback if Perplexity/WebSearch unavailable:**
- Analyze competitor content directly via WebFetch
- Infer keyword targets from the product's features and category
- Use common keyword patterns: "how to [task]", "best [category] for [use case]", "[product] vs [alternative]"
- Note that live keyword data was unavailable

### 4. Define Content Pillars

Identify 3-4 content pillars based on the product and audience:

Example for a dev tool:
1. **Tutorials**: How to use the product, integrations, advanced use cases
2. **Industry insights**: Trends, analysis, opinions in the product's domain
3. **Building in public**: Progress, decisions, lessons, roadmap
4. **Comparisons**: Product vs alternatives, honest evaluations

### 5. Developer Content Quality Checklist

Every piece of content must pass this checklist before publishing:

| Check | Requirement |
|-------|------------|
| **Teaches something** | Reader learns a skill, concept, or technique |
| **Has code examples** | Working code snippets they can copy (for technical content) |
| **Solves a real problem** | Addresses a specific pain point, not a manufactured one |
| **Honest about limitations** | Acknowledges when the product isn't the best fit |
| **Scannable** | Headers, code blocks, bullet points — not walls of text |
| **Actionable conclusion** | Reader knows exactly what to do next |
| **No jargon without explanation** | Technical terms are defined or linked |
| **Unique angle** | Says something the top 5 results for this keyword don't |
| **Updated** | Date visible, content reflects current product version |
| **Has meta tags** | Title, description, OG tags optimized for the target keyword |

### 6. Content Repurposing Map

Every core content piece should map to multiple distribution formats:

```
Blog Post (1500-2500 words)
  |
  +-- Twitter/X Thread (5-7 tweets, key insights)
  +-- LinkedIn Post (professional angle, 1-3 paragraphs)
  +-- Dev.to Cross-post (full article, reformatted)
  +-- Hashnode Cross-post (full article, canonical to original)
  +-- Reddit Comment/Post (value-first excerpt for relevant subreddit)
  +-- Newsletter Section (summary + link)
  +-- YouTube Script (5-10 min video version)
  +-- Hacker News Submission (if newsworthy/technical enough)
```

**Repurposing rules:**
- Blog post is always the canonical source
- Cross-posts on Dev.to/Hashnode set canonical URL to your blog
- Twitter threads extract the 5 most interesting insights, not a summary
- LinkedIn adapts the angle for a professional/business audience
- Reddit posts provide genuine value — never just link drops
- Newsletter adds personal context and behind-the-scenes

### 7. Newsletter Framework

If the product should have a newsletter:

| Element | Recommendation |
|---------|---------------|
| **Platform** | Buttondown (developer-friendly, markdown) or Substack (discovery) |
| **Frequency** | Biweekly or monthly (sustainable for solo dev) |
| **Format** | 3-section: Product update + Industry insight + Resource roundup |
| **Name** | [Product]-adjacent topic name, not "[Product] Newsletter" |
| **CTA** | Embedded in product, blog sidebar, and social bios |
| **Growth target** | 100 subscribers in month 1 (realistic cold start) |

**Newsletter template:**
```markdown
# [Newsletter Name] — Issue #X

## What's New in [Product]
[1-2 paragraphs on recent updates, with screenshots]

## [Industry Topic of the Week]
[Analysis, opinion, or tutorial — the main value piece]

## Resources & Links
- [Useful link 1] — [why it matters]
- [Useful link 2] — [why it matters]
- [Useful link 3] — [why it matters]

---
[Product] is [one-line description]. [CTA to try it].
```

### 8. Changelog-as-Content Guide

Turn every product update into marketing content:

| Update Type | Content Output | Distribution |
|-------------|---------------|-------------|
| **Major feature** | Blog post + Twitter thread + changelog entry | All channels |
| **Minor improvement** | Changelog entry + tweet | Twitter + changelog |
| **Bug fix** | Changelog entry only | Changelog page |
| **Integration** | Blog post (tutorial) + partner cross-promo | Blog + social + partner |
| **Milestone** | Building-in-public post (metrics, lessons) | Twitter + LinkedIn + blog |

**Changelog page best practices:**
- Public at `/changelog` or `/updates`
- RSS feed enabled
- Each entry has a date, title, and description
- Major entries link to full blog posts
- Add structured data (Article schema) for each entry

### 9. Generate Editorial Calendar

```markdown
## Content Plan: [Product Name]

### Content Pillars
1. [Pillar] — [Goal: traffic / authority / conversion]
2. [Pillar] — [Goal]
3. [Pillar] — [Goal]
4. [Pillar] — [Goal]

### Monthly Calendar (4 Weeks)

#### Week 1
- **Blog**: [Topic] — target keyword: [keyword] (vol: X, KD: Y)
  - Repurpose: Twitter thread + Dev.to cross-post
  - Quality check: [which checklist items are most important for this piece]
- **Social**: [Topic snippet for LinkedIn/Twitter]
- **Newsletter**: [If applicable — section content]

#### Week 2
- **Blog**: [Topic] — target keyword: [keyword] (vol: X, KD: Y)
  - Repurpose: Reddit post (r/[subreddit]) + newsletter section
- **Social**: [Topic snippet]
- **Changelog**: [If any updates this week]

#### Week 3
- **Blog**: [Topic] — target keyword: [keyword]
  - Repurpose: YouTube video script + carousel
- **Social**: Building in public update
- **Newsletter**: [If biweekly — send this week]

#### Week 4
- **Pillar piece**: [Comprehensive guide on topic] — target keyword: [keyword]
  - Repurpose: 5-tweet thread + LinkedIn article + Dev.to
- **Social**: Case study or comparison snippet
- **Changelog**: Monthly summary

### Topic Backlog (Prioritized by Keyword Potential)
| # | Topic | Keyword | Est. Volume | KD | Pillar | Format | Priority |
|---|-------|---------|------------|----|----|--------|----------|
| 1 | [Topic] | [keyword] | [vol] | [kd] | [pillar] | [blog/guide/comparison] | P1 |

### Content Repurposing Schedule
| Core Piece | Day 1 | Day 2 | Day 3 | Day 7 | Day 14 |
|-----------|-------|-------|-------|-------|--------|
| [Blog post] | Publish + tweet | LinkedIn post | Dev.to cross-post | Reddit post (if relevant) | Newsletter mention |

### Publishing Cadence
- Blog posts: [X]/month (realistic for solo developer)
- Social posts: [X]/week
- Newsletter: [frequency]
- Changelog updates: As shipped
- Cross-posts: Within 3 days of blog publication
```

### 10. Memory Write

If `.marketing-studio/` directory exists, append to `.marketing-studio/memory.md`:

```markdown
## Content Plan — [date]
- **Content pillars**: [list]
- **Publishing cadence**: [X posts/month]
- **Top keyword targets**: [list top 5]
- **Newsletter**: [yes/no, platform, frequency]
```

## Cross-References

- `/marketing` — Full marketing strategy with content as one pillar
- `/marketing-init` — Set up project context for focused content planning
- `/seo-audit` — Keyword research informs content topics
- `/social-strategy` — Social distribution for content pieces
- `/ai-citations` — Content specifically targeting AI citation gaps
- `/competitor-analysis` — Content gaps identified through competitive analysis
- `/launch-plan` — Pre-launch and launch content timeline
- `/marketing-status` — Track content calendar progress
