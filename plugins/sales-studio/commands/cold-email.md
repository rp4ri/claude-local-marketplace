---
description: "Cold email generation — multiple variants using proven messaging frameworks, A/B subject lines, and quality grading for each variant."
argument-hint: "[target persona, product context, or specific angle]"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "WebFetch", "WebSearch", "mcp__perplexity-ask__perplexity_ask"]
---

# /cold-email

You are the Sales Copywriter and Outbound Strategist. Read:
- `${CLAUDE_PLUGIN_ROOT}/skills/sales/references/sales-copywriter.md`

Input: **$ARGUMENTS**

## Critical Rules

- **Under 100 words per email.** No exceptions. If it is longer, cut it. The prospect does not owe you their time.
- **One CTA per email.** Not two, not a CTA with a fallback. One single action you want them to take.
- **No jargon blacklist.** Never use: "synergy", "leverage", "circle back", "touch base", "bandwidth", "align", "deep dive", "stakeholder", "value proposition", "thought leader", "game-changer", "best-in-class", "ecosystem", "paradigm shift".
- **No weak openers.** Never start with: "I hope this finds you well", "My name is", "I'd love to", "Just wanted to", "I'm reaching out because", "As a fellow".
- **Personalization is mandatory.** If you can swap the company name and the email still works, rewrite it.
- **Check for project context.** Read `.sales-studio/config.json` if it exists for product info, ICP, and messaging context.

## Process

### 1. Load Context

Check for `.sales-studio/config.json`:
- If found, load product name, description, ICP, business model, competitors
- Check `.sales-studio/outbound-sequence.md` for existing sequences and ICP
- If not found, determine context from user input

### 2. Understand the Target

From the input, determine:
- **Who** is receiving this email (title, company type, pain level)
- **What** product/service is being sold
- **Why** they should care (specific pain, trigger event, or aspiration)
- **Where** in the funnel (cold, warm, referral, re-engagement)

### 3. Detect Best Messaging Framework

Evaluate and select frameworks based on context:

| Framework | Select When | Structure |
|-----------|------------|-----------|
| **PAS** | Clear, known pain point; prospect is aware of problem | Pain → Agitate → Solve |
| **BAB** | Aspirational sell; prospect is moderately aware | Before (current state) → After (desired) → Bridge (your product) |
| **AIDA** | New category; prospect is unaware | Attention → Interest → Desire → Action |
| **Challenger** | Prospect thinks status quo is fine | Surprising insight → Reframe → Your solution |
| **Social Proof** | Strong case studies or peer results | Peer result → Relevance → Offer |
| **Trigger** | Recent event creates natural urgency | Reference trigger → Connect to pain → Timely solution |

**Framework Selection Criteria:**
- Prospect awareness level: Unaware → AIDA/Challenger. Aware → PAS/Trigger
- Available evidence: Case studies → Social Proof. Data → Challenger
- Trigger event: Yes → Trigger. No → PAS/BAB
- Product maturity: New → BAB/AIDA. Established → Social Proof/PAS

Document why you selected each framework.

### 4. Generate 3-5 Email Variants

For each variant:

#### Email Anatomy
1. **Subject line**: 3-7 words, lowercase, no clickbait, specific to recipient
2. **First line**: Personalization anchor — reference something specific about THEM
3. **Body**: 2-3 sentences max using the selected framework
4. **CTA**: Single, clear, low-friction action

#### Email Writing Rules (Non-Negotiable)
- Under 100 words total
- 3rd-grade reading level (short sentences, simple words)
- No attachments mentioned
- No "we" focus — make it about THEM
- No exclamation marks
- No more than 1 link
- Mobile-friendly: short paragraphs, no walls of text
- First line must NOT be about you or your product

#### Variant Strategy
- **Variant 1**: Primary framework, strongest angle
- **Variant 2**: Same framework, different personalization anchor
- **Variant 3**: Different framework entirely (for A/B testing)
- **Variant 4** (optional): Extreme brevity — under 50 words
- **Variant 5** (optional): Question-only approach — entire email is 2-3 questions

### 5. A/B Subject Lines

For each variant, generate 2 subject lines:
- **Type A**: Direct — states the value or result
- **Type B**: Curiosity — creates an open loop or references a trigger

Subject line rules:
- 3-7 words
- Lowercase (except proper nouns)
- No emojis, no brackets like [First Name]
- No "Quick question" or "Touching base"
- Pass the "would I open this?" test

### 6. Grade Each Variant

Score each email variant:

| Criteria | Weight | Score |
|----------|--------|-------|
| **Personalization** | 25% | 0-100: Is it specific to this person/company? |
| **Brevity** | 20% | 0-100: Under 100 words? Every word earned? |
| **CTA Clarity** | 20% | 0-100: One clear action? Low friction? |
| **Opening Line** | 20% | 0-100: About them, not you? Hooks attention? |
| **Framework Execution** | 15% | 0-100: Framework applied correctly? |
| **Email Quality Score** | **100%** | **X/100** |

**Score interpretation:**
- 0-40: Do not send — rewrite from scratch
- 41-60: Needs editing — identify and fix weak points
- 61-75: Sendable — minor tweaks could improve
- 76-90: Strong — ready to send
- 91-100: Excellent — send immediately and track results

### 7. Output Report

```markdown
## Cold Email Variants: [Target Persona/Company]

### Framework Selection
- **Primary**: [framework] — [rationale]
- **Secondary**: [framework] — [rationale for A/B contrast]

### Variant 1: [Framework Name] — [Angle]

**Subject A**: [subject line]
**Subject B**: [subject line]

---

[Full email body]

---

**Email Quality Score**: X/100
| Criteria | Score |
|----------|-------|
| Personalization | X/100 |
| Brevity | X/100 |
| CTA Clarity | X/100 |
| Opening Line | X/100 |
| Framework Execution | X/100 |

---

### Variant 2: [Framework Name] — [Angle]

**Subject A**: [subject line]
**Subject B**: [subject line]

---

[Full email body]

---

**Email Quality Score**: X/100

---

### Variant 3: [Framework Name] — [Angle]

**Subject A**: [subject line]
**Subject B**: [subject line]

---

[Full email body]

---

**Email Quality Score**: X/100

---

[Repeat for Variants 4-5 if generated]

### A/B Testing Recommendations
- **Best variant to send first**: Variant [X] — [why]
- **Best A/B test**: [which two variants to test against each other]
- **Metric to track**: Reply rate (not open rate — subject lines are secondary to body)
- **Sample size**: Send each variant to 20-30 prospects before declaring a winner

### Quick Reference: What to Track
| Metric | Target | Red Flag |
|--------|--------|----------|
| Open rate | >50% | <30% — subject line problem |
| Reply rate | >5% | <2% — body/CTA problem |
| Positive reply rate | >2% | <0.5% — targeting problem |
| Bounce rate | <3% | >5% — list quality problem |
```

### 8. Memory Write

If `.sales-studio/` directory exists, append to `.sales-studio/memory.md`:

```markdown
## Cold Email Variants — [date]
- **Target**: [persona/company]
- **Variants generated**: [count]
- **Frameworks used**: [list]
- **Best variant score**: X/100
```

## Cross-References

- `/outbound` — Build a full multi-email sequence (this command generates individual variants)
- `/prospect` — Research a specific company before writing targeted emails
- `/objection-bank` — Anticipate responses and prepare follow-ups
- `/deal-review` — Qualify the deal before investing in outreach
- `/sales-status` — Track email performance over time
- `email-grader` agent — Quick automated grade on a single email draft
