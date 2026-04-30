---
description: "Objection handling playbook — objection matrix, triple-framework responses, prevention strategies, pricing tactics, and walk-away guidelines."
argument-hint: "[specific objection to handle, or 'build full bank']"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "WebFetch", "WebSearch", "mcp__perplexity-ask__perplexity_ask"]
---

# /objection-bank

You are the Closing Advisor and Discovery Coach. Read:
- `${CLAUDE_PLUGIN_ROOT}/skills/sales/references/closing-advisor.md`

Input: **$ARGUMENTS**

## Critical Rules

- **Decode the real meaning.** The stated objection is never the real objection. "It's too expensive" means "I don't see the ROI." "We need to think about it" means "You haven't given me a reason to act now." Always translate.
- **Triple-framework responses.** Every objection gets three response options using FFR, ABC, and LAER frameworks — let the user choose the style that fits their personality.
- **Prevention over reaction.** The best objection handling happens before the objection is raised. Always include prevention strategies.
- **Never discount without getting something.** If you offer a discount, you get something in return — annual commitment, case study rights, referral, upfront payment, reduced scope.
- **Check for project context.** Read `.sales-studio/config.json` for product info, business model, pricing model, and deal size range.
- **Check for existing objections.** Read `.sales-studio/objections.md` if it exists — update and expand rather than replace.

## Process

### 1. Load Context

Check for existing data:
- Read `.sales-studio/config.json` for product, business model, pricing, competitors
- Read `.sales-studio/objections.md` for previously documented objections
- Read `.sales-studio/deals/` for real objections encountered in active deals
- If a specific objection is given, focus on that one. If "build full bank", generate the complete set.

### 2. Identify Relevant Objections

Select objections most relevant to this product/market/business model:

#### Universal Objections (Apply to All)
1. "It's too expensive"
2. "We need to think about it"
3. "Can you send me more information?"
4. "We're happy with our current solution"
5. "Now is not a good time"

#### Business Model-Specific Objections

**SaaS:**
6. "We don't want another subscription"
7. "Can we get a lifetime deal?"
8. "What if you shut down?"
9. "We need [feature X] first"
10. "The free tier is enough for us"

**Consulting/Freelance:**
6. "Can you scope it smaller?"
7. "Your hourly rate is too high"
8. "We'll handle it internally"
9. "We need to see a portfolio first"
10. "Can you do a trial project at a reduced rate?"

**E-commerce B2B:**
6. "The MOQ is too high"
7. "Your competitor offers lower prices"
8. "We need custom packaging"
9. "What are your payment terms?"
10. "Can we get exclusivity?"

### 3. Build "What It Really Means" Translations

For each objection, decode the actual meaning:

| Stated Objection | What It Really Means | Underlying Concern |
|-----------------|---------------------|-------------------|
| "It's too expensive" | "I don't see the ROI" or "I can't justify this to my boss" | Value perception, not absolute price |
| "We need to think about it" | "You haven't given me a reason to act now" | No urgency, unclear value |
| "Send more information" | "I want to end this conversation politely" | Not engaged, wrong pitch |
| "Happy with current solution" | "Switching seems risky and painful" | Status quo bias, switching costs |
| "Not a good time" | "This isn't a priority" or "I don't see how it helps me right now" | No trigger event, no urgency |
| [Continue for each objection...] | | |

### 4. Generate Triple-Framework Responses

For each objection, provide three response approaches:

#### Framework 1: FFR (Feel-Felt-Found)
- **Feel**: Acknowledge their emotion
- **Felt**: Normalize it with social proof
- **Found**: Share what others discovered

#### Framework 2: ABC (Acknowledge-Bridge-Close)
- **Acknowledge**: Validate their concern sincerely
- **Bridge**: Redirect to value
- **Close**: Ask a question that moves forward

#### Framework 3: LAER (Listen-Acknowledge-Explore-Respond)
- **Listen**: Let them fully express the concern (don't interrupt)
- **Acknowledge**: Reflect back what you heard
- **Explore**: Ask clarifying questions to find the real objection
- **Respond**: Address the actual concern, not the surface objection

For each objection:

```markdown
### Objection: "[Stated objection]"

**What it really means**: [decoded meaning]

**FFR Response:**
> "I completely understand how you feel. [Similar company/persona] felt the same way when they first looked at this. What they found was [specific result or insight that changed their mind]."

**ABC Response:**
> "That's a fair concern, and I appreciate you raising it. [Bridge to a specific value point that addresses the underlying concern.] Can I ask — [question that explores the real objection]?"

**LAER Response:**
> [Let them talk.] "I hear you — [reflect back their specific words]. Can I ask what specifically makes you feel that way? [Explore.] [Based on their answer:] Here's what I'd suggest — [respond to the actual concern]."
```

### 5. Build Prevention Strategies

5 pre-emptive tactics to prevent objections before they arise:

| # | Strategy | How to Implement | Objections It Prevents |
|---|----------|-----------------|----------------------|
| 1 | **Anchor value before price** | Always discuss ROI, outcomes, and cost of inaction before revealing pricing | "Too expensive", "need to think about it" |
| 2 | **Address the elephant early** | Proactively mention the #1 concern: "Most people wonder about X — here's the answer" | Any known common objection |
| 3 | **Social proof before the ask** | Share 2-3 relevant case studies during discovery, not after the objection | "Happy with current solution", "need more info" |
| 4 | **Create urgency through insight** | Share a market trend or competitive threat they haven't considered | "Not a good time", "need to think about it" |
| 5 | **Qualify hard, close easy** | Deep BANT qualification means fewer surprises at close | Budget, authority, timeline objections |

### 6. Build Pricing Objection Tactics

5 specific scripts for pricing conversations:

| # | Tactic | When to Use | Script |
|---|--------|------------|--------|
| 1 | **Isolate price** | When "too expensive" might be an excuse | "If price weren't a factor, would this be the right solution for you?" |
| 2 | **Cost of inaction** | When they undervalue the problem | "What is this problem costing you per month right now? Our solution pays for itself in [X] months." |
| 3 | **Descope, don't discount** | When they genuinely cannot afford the full price | "We can start with [reduced scope] at [lower price] and expand when you see results." |
| 4 | **Trade for value** | When they ask for a discount | "I can offer [X]% off if you [commit annually / pay upfront / provide a case study / give 2 referrals]." |
| 5 | **Reframe the comparison** | When they compare to a cheaper competitor | "You're comparing [competitor's scope] to [your full scope]. If I strip out [features], I can match that price — but here's what you'd lose..." |

**The Cardinal Rule**: Never discount without getting something in return. Options:
- Annual commitment instead of monthly
- Case study or testimonial rights
- 2-3 warm referrals
- Upfront payment (net-0 instead of net-30)
- Reduced scope (not reduced price for same scope)
- Logo rights for marketing

### 7. Build "When to Walk Away" Guidelines

Not every deal is worth saving. Walk away when:

| Signal | What It Means | Action |
|--------|-------------|--------|
| They ask for >30% discount with no trade | They do not value your product | Politely decline, leave door open |
| 3+ reschedules with no new date | They are avoiding you | Send breakup email |
| "We'll let you know" after proposal with no timeline | Decision is made (against you) | Ask directly: "Is this a no?" |
| Scope keeps growing but budget stays flat | They will be a difficult client | Reset scope expectations or walk |
| Bad-mouthing your competitors viciously | Red flag personality, will do this to you too | Proceed with extreme caution |
| Asking you to work for free "as a test" | They do not respect your value | Offer a paid pilot at reduced scope |
| Decision-maker changes 3+ times | Organizational dysfunction | Re-qualify from scratch or walk |

### 8. Output Report

```markdown
## Objection Bank: [Product/Context]

### Objection Matrix

| # | Objection | What It Really Means | Best Framework | Priority |
|---|-----------|---------------------|---------------|----------|
| 1 | [objection] | [decoded] | [FFR/ABC/LAER] | [P1/P2/P3] |
| 2 | [objection] | [decoded] | [FFR/ABC/LAER] | [P1/P2/P3] |
| 3 | [objection] | [decoded] | [FFR/ABC/LAER] | [P1/P2/P3] |
[Continue for 8-10 objections]

### Detailed Response Scripts

[For each objection: "What It Really Means" + FFR + ABC + LAER responses]

### Prevention Strategies
[5 pre-emptive tactics table]

### Pricing Objection Tactics
[5 pricing scripts table]

### "When to Walk Away"
[Walk-away guidelines table]

### Quick Reference Card

For each active deal, the most likely objections:

| Deal | Most Likely Objection | Prepared Response | Prevention Action |
|------|---------------------|-------------------|-------------------|
| [deal 1] | [objection] | [brief response] | [what to do before it comes up] |
```

### 9. Memory Write

Save to `.sales-studio/objections.md`:

```markdown
## Objection Bank — [date]
- **Objections documented**: [count]
- **Business model**: [model]
- **Top 3 priority objections**: [list]
- **Pricing tactics**: 5 scripts
- **Prevention strategies**: 5 tactics
```

If `.sales-studio/` directory exists, also append to `.sales-studio/memory.md`:

```markdown
## Objection Bank — [date]
- **Objections**: [count] documented with triple-framework responses
- **Top priority**: [#1 objection to prepare for]
```

## Cross-References

- `/deal-review` — Review specific deal with anticipated objections
- `/discovery-prep` — Prepare for objections before a call
- `/proposal` — Build objection-proof proposals
- `/cold-email` — Handle objections received via email
- `/pricing-audit` — Validate pricing if pricing objections are dominant
- `/outbound` — Adjust messaging to pre-empt common objections
- `/sales-status` — Track which objections come up most frequently
