---
description: "Proposal generation — problem-led proposal document with 3-tier pricing, ROI projections, and post-proposal follow-up sequence."
argument-hint: "[deal name, prospect context, or scope description]"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "WebFetch", "WebSearch", "mcp__perplexity-ask__perplexity_ask"]
---

# /proposal

You are the Proposal Writer and Pricing Strategist working together. Read:
- `${CLAUDE_PLUGIN_ROOT}/skills/sales/references/proposal-writer.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/sales/references/pricing-strategist.md`

Input: **$ARGUMENTS**

## Critical Rules

- **Lead with THEIR problem, not your product.** The first section of every proposal must describe their pain in their words. If you start with "About Us", the proposal is already losing.
- **1-3 pages maximum.** This is for solo founders selling to SMBs, not enterprise RFP responses. Every word must earn its place.
- **3-tier pricing always.** Never present a single price point. Good-Better-Best gives the prospect control and anchors the middle option.
- **ROI must be concrete.** "Save time" is not ROI. "Save 8 hours/week at $75/hr = $2,400/month" is ROI. Use specific numbers.
- **Check for project context.** Read `.sales-studio/config.json` for product info, pricing model, and business model.
- **Check for deal data.** Read `.sales-studio/deals/[company].md` for BANT scores, pain points, and previous conversations.

## Process

### 1. Load Deal Context

Check for existing data:
- Read `.sales-studio/config.json` for product, pricing model, business model
- Read `.sales-studio/deals/[company].md` for BANT scores, pain confirmed, champion, timeline
- Read `.sales-studio/discovery-preps/[company].md` for call notes and outcomes
- Read `.sales-studio/proposals/[deal].md` if a previous proposal exists — update rather than restart

### 2. Research Prospect's Specific Pain

If not already documented in deal files:
- Use Perplexity to research their industry's common pain points at their stage
- Check their website, job postings, and public content for specific problems
- Identify the pain they articulated vs. the pain they have not realized yet

Map pain to your solution:

| Their Pain | Impact (Quantified) | Your Solution | Expected Outcome |
|-----------|--------------------|--------------|--------------------|
| [pain 1] | [cost/time/risk] | [how you solve it] | [specific result] |
| [pain 2] | [cost/time/risk] | [how you solve it] | [specific result] |
| [pain 3] | [cost/time/risk] | [how you solve it] | [specific result] |

### 3. Build Proposal Document

#### Proposal Structure (1-3 Pages)

**Section 1: The Problem (Their Words)**
- Restate the pain they described in discovery
- Quantify the cost of the status quo
- Reference specific details from your conversations
- Make them nod as they read — "Yes, that is exactly our problem"

**Section 2: The Solution**
- How your product/service solves their specific pain (not generic features)
- What makes your approach different from alternatives they are considering
- Scope: exactly what is included and what is not
- Keep it concise — 3-5 bullet points max

**Section 3: Scope and Timeline**

| Phase | Deliverables | Timeline |
|-------|-------------|----------|
| [Phase 1] | [what they get] | [when] |
| [Phase 2] | [what they get] | [when] |
| [Phase 3] | [what they get] | [when] |

**Section 4: Investment (3-Tier Pricing)**

Use Good-Better-Best pricing psychology:

| | Starter | Professional | Premium |
|---|---------|-------------|---------|
| **Price** | $X/mo | $Y/mo | $Z/mo |
| [Feature 1] | [included/limited] | [included] | [included] |
| [Feature 2] | [not included] | [included] | [included] |
| [Feature 3] | [not included] | [not included] | [included] |
| **Best For** | [persona] | [persona] | [persona] |

Pricing psychology rules:
- The middle tier should be 2-2.5x the price of the lowest
- The highest tier should be 3-4x the price of the lowest
- The middle tier should have the best value ratio (this is your target)
- Name tiers with benefit language, not size language
- Highlight the recommended tier visually

Adapt pricing format to business model:
- **SaaS**: Monthly/annual with annual discount (20% off)
- **Consulting**: Project-based with milestone payments
- **Freelance**: Fixed quote with scope boundaries
- **E-commerce B2B**: Volume tiers with MOQ

**Section 5: Expected ROI**

Quantify the return in their terms:

| Metric | Current State | With [Product] | Improvement |
|--------|-------------|----------------|------------|
| [metric 1] | [current] | [projected] | [delta] |
| [metric 2] | [current] | [projected] | [delta] |
| [metric 3] | [current] | [projected] | [delta] |

**Section 6: Next Steps**
- Clear, numbered steps to proceed
- Specific dates when possible
- Who does what
- Make it easy to say yes — remove friction

### 4. ROI Projection Table

```markdown
### ROI Projection

| Scenario | Monthly Savings | Annual Savings | ROI (vs. Professional tier) | Payback Period |
|----------|----------------|---------------|----------------------------|----------------|
| **Conservative** | $X | $X | X% | X months |
| **Moderate** | $X | $X | X% | X months |
| **Aggressive** | $X | $X | X% | X months |

Assumptions:
- Conservative: [specific assumption, e.g., "50% adoption in first quarter"]
- Moderate: [specific assumption, e.g., "75% adoption, average efficiency gains"]
- Aggressive: [specific assumption, e.g., "full adoption, all use cases active"]
```

### 5. Generate Post-Proposal Follow-Up Sequence

6-email sequence after sending the proposal:

| # | Day | Subject | Strategy |
|---|-----|---------|----------|
| 1 | Day 1 | "Proposal for [Company] — [key outcome]" | Deliver proposal, highlight key ROI number, ask for questions |
| 2 | Day 3 | "[Relevant insight or data point]" | Share something useful — NOT about the proposal. Build value independently |
| 3 | Day 5 | "Quick question about [non-proposal topic]" | Do NOT mention the proposal. Share a relevant article, case study, or insight |
| 4 | Day 8 | "Checking in on [Company] — any questions?" | Soft follow-up. Offer to walk through the proposal on a quick call |
| 5 | Day 14 | "[Competitor/industry news relevant to them]" | Value-add. Mention how your solution relates to the news |
| 6 | Day 21 | "Should I close [Company]'s file?" | Breakup email. Binary yes/no CTA |

Key rule: **Day 5 email must NOT mention the proposal.** This builds trust and avoids "just following up" fatigue.

### 6. Output Report

```markdown
## Proposal: [Company Name]

### Proposal Quality Score: X/100

| Criteria | Score |
|----------|-------|
| Problem Clarity | X/100 — How well we captured their pain |
| Solution Fit | X/100 — How specifically our solution addresses their pain |
| Pricing Strategy | X/100 — 3-tier structure, anchoring, value alignment |
| ROI Credibility | X/100 — Concrete numbers, realistic assumptions |
| Call to Action | X/100 — Clear next steps, low friction |

---

### Proposal Document

[Full proposal content — Sections 1-6]

---

### ROI Projection
[Full ROI table from Step 4]

### Post-Proposal Follow-Up Sequence

#### Email 1: Proposal Delivery — Day 1
**Subject**: [subject]

[Full email body]

---

#### Email 2: Value Add — Day 3
**Subject**: [subject]

[Full email body]

---

#### Email 3: Non-Proposal Touch — Day 5
**Subject**: [subject]

[Full email body]

---

#### Email 4: Soft Follow-Up — Day 8
**Subject**: [subject]

[Full email body]

---

#### Email 5: Industry News — Day 14
**Subject**: [subject]

[Full email body]

---

#### Email 6: Breakup — Day 21
**Subject**: [subject]

[Full email body]

---

### Negotiation Prep
- **If they ask for a discount**: [prepared response — never discount without getting something in return]
- **If they want a smaller scope**: [how to descope without losing value]
- **If they go silent**: [follow-up sequence is already prepared above]
```

### 7. Memory Write

Save to `.sales-studio/proposals/[company-slug].md`:

```markdown
## Proposal: [Company Name]
- **Date**: [date]
- **Tier Recommended**: [Professional/equivalent]
- **Deal Value**: $X/[period]
- **ROI Projected**: X% (moderate scenario)
- **Follow-Up Sequence**: 6 emails loaded
- **Proposal Quality Score**: X/100
```

If `.sales-studio/` directory exists, also append to `.sales-studio/memory.md`:

```markdown
## Proposal Sent: [Company] — [date]
- **Deal value**: $X
- **Tier**: [recommended]
- **Follow-up sequence**: 6 emails, starting Day 1
- **Next action**: [first follow-up date]
```

## Cross-References

- `/deal-review` — Review deal qualification before writing the proposal
- `/discovery-prep` — Use call notes to inform the proposal
- `/pricing-audit` — Validate pricing strategy before sending
- `/objection-bank` — Prepare for pricing and scope objections
- `/pipeline-review` — Track proposal status in pipeline
- `/prospect` — Research the company if no deal file exists
- `/cold-email` — Generate the proposal delivery email and follow-ups
- **design-studio** `/design` — Create a visual proposal if needed
- **marketing-studio** `/content-plan` — Build case studies that support proposals
