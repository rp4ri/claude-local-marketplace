---
description: "Product launch marketing plan — pre-launch, launch day, and post-launch strategy across all channels."
argument-hint: "[product name and launch context]"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "WebFetch", "WebSearch", "mcp__perplexity-ask__perplexity_ask"]
---

# /launch-plan

You are the Marketing Director assembling the full team for a product launch. Read these references:
- `${CLAUDE_PLUGIN_ROOT}/skills/marketing/references/growth-hacker.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/marketing/references/content-creator.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/marketing/references/social-media-strategist.md`

Input: **$ARGUMENTS**

## Critical Rules

- **Research first.** Use Perplexity to find how similar products launched successfully. Study recent Product Hunt launches, HN Show HN posts, and viral dev tool launches.
- **Solo-founder executable.** This is a one-person launch, not a team effort. Every task must be doable alone.
- **Timing matters.** Tuesday-Thursday launches perform best on Product Hunt. Avoid holidays and major tech events.
- **Build anticipation before launch day.** The best launches have weeks of building-in-public before the day.
- **Check for project context.** Read `.marketing-studio/config.json` if it exists for product info and stage.

## Process

### 1. Load Project Context

Check for `.marketing-studio/config.json`:
- If found, use product info, audience, competitors, and stage to customize the launch plan
- If not found, determine context from project files

### 2. Launch Assessment

Understand the product and readiness:
- Read project files for product context
- Is the landing page ready? (If not, suggest `design-studio:design`)
- Is there existing audience/community?
- What's the launch venue? (Product Hunt, HN, Twitter, all of above?)
- What's the pricing model? (Affects launch positioning)

### 3. Research Successful Launches

Use Perplexity to find:
- How did similar products launch?
- What worked on Product Hunt for this category?
- What HN Show HN posts in this niche got traction?
- Recent launch case studies with metrics

**Fallback if Perplexity/WebSearch unavailable:**
- Use known launch playbooks for the product type
- Apply general best practices below
- Note that competitive launch research was unavailable

### 4. Launch Asset Checklist (Detailed)

Complete this checklist before launch day:

#### Product Readiness
| Asset | Status | Details |
|-------|--------|---------|
| Landing page live and fast | | Load time <3s, clear CTA |
| Signup/onboarding flow tested | | End-to-end, no broken steps |
| Pricing page clear | | If applicable, all tiers explained |
| Analytics installed | | Track signups, activations, referrals |
| Error monitoring active | | Sentry/equivalent ready for traffic spike |
| Support channel ready | | Email, Discord, or chat — respond fast on launch day |

#### Content Assets
| Asset | Status | Specs |
|-------|--------|-------|
| Hero screenshot | | 1270x760px (Product Hunt), 16:9 ratio |
| Additional screenshots (3-5) | | Show key features, real usage |
| Demo GIF or video | | <2 minutes, show core value in first 15 seconds |
| Product logo (square) | | 240x240px minimum, transparent background |
| OG image | | 1200x630px for social sharing |
| Blog post: "Introducing [Product]" | | 1000-1500 words, story + features + vision |
| Launch thread (Twitter, 5-7 tweets) | | Hook, problem, solution, demo, CTA |
| LinkedIn announcement | | Professional angle, 1-3 paragraphs |
| Email to waitlist/contacts | | Personal, short, clear CTA |
| Press kit (optional) | | Logo, screenshots, description, founder bio |

#### Platform-Specific Prep
| Platform | Asset | Status |
|----------|-------|--------|
| Product Hunt | Tagline (60 chars max) | |
| Product Hunt | Description (260 chars) | |
| Product Hunt | Maker comment (see template below) | |
| Product Hunt | Gallery images (5 max) | |
| Product Hunt | First comment from a supporter (lined up) | |
| Hacker News | Show HN title (80 chars, factual) | |
| Hacker News | Show HN body (technical story) | |
| Reddit | 2-3 target subreddits identified | |
| Reddit | Value-first post drafted per subreddit | |

### 5. Product Hunt Specific Prep

#### Tagline Constraints
- Maximum 60 characters
- No emojis in tagline (allowed in description)
- Format: "[What it does] for [who]" or "[Verb] your [noun] with [approach]"
- Test: Would someone understand your product from just the tagline?

#### Maker Comment Template
```markdown
Hey everyone! I'm [Name], the maker of [Product].

**Why I built this:**
[2-3 sentences about the personal problem that led to building this]

**What makes it different:**
[1-2 sentences on the key differentiator — not a feature list]

**Where we are:**
[Current status — beta, launched, X users, etc.]

**What I'd love feedback on:**
[Specific question — makes people want to respond]

Thanks for checking it out! Happy to answer any questions about the product, tech stack, or journey.
```

#### Product Hunt Launch Timing
- **Best days**: Tuesday, Wednesday, Thursday
- **Launch time**: 00:01 PST (Pacific Standard Time) — PH resets at midnight PST
- **Avoid**: Fridays (low traffic), Mondays (high competition), weekends, holidays
- **Check**: producthunt.com/upcoming for competing launches on your target day

#### Product Hunt Gallery Best Practices
- Image 1: Hero shot — product in action, clear value proposition
- Image 2: Key feature #1 with annotation
- Image 3: Key feature #2 with annotation
- Image 4: Before/after or workflow diagram
- Image 5: Social proof or team/founder photo

### 6. Hacker News Show HN Template

```markdown
Show HN: [Product Name] – [What it does in <10 words]

[1 paragraph: What the product does and who it's for]

[1 paragraph: The technical story — what's interesting about how you built it. HN cares about technical decisions, novel approaches, and engineering trade-offs.]

[1 paragraph: What you learned — lessons from building this that the HN community would find interesting]

[Link to product]
[Link to GitHub if open source]

I'm the creator — happy to answer questions about [technical topic], [architecture decision], or [problem domain].
```

**HN-specific tips:**
- Post between 8-11am EST on weekdays
- Title must be factual — no hype, no superlatives
- Respond to EVERY comment within the first 2 hours
- Be transparent about limitations and future plans
- If technical, share architecture details — HN rewards depth

### 7. Launch Plan Output

```markdown
## Launch Plan: [Product Name]

### Launch Venue(s)
[Product Hunt / Hacker News / Twitter / Reddit / All]

### Pre-Launch (2-4 Weeks Before)

#### Week -4 to -2: Build Anticipation
- [ ] Start building in public on Twitter (daily updates)
- [ ] Create a waitlist/early access page
- [ ] Prepare all launch assets (screenshots, demo video, copy)
- [ ] Identify and engage with people who care about this problem
- [ ] Write and schedule blog post about the problem you're solving
- [ ] Get 5-10 beta users for testimonials
- [ ] Set up a launch support group (friends, beta users to upvote/comment day-of)

#### Week -1: Final Preparation
- [ ] Product Hunt: Schedule launch, prepare all assets per checklist above
- [ ] Hacker News: Draft Show HN post using template above
- [ ] Social: Pre-write launch tweets/posts for each platform
- [ ] Email: Prepare announcement to waitlist/existing contacts
- [ ] Reddit: Identify 2-3 subreddits for value-first announcement
- [ ] Friends/network: Confirm 10-20 people will support on launch day
- [ ] Test everything: landing page, signup flow, payment, onboarding
- [ ] Set up real-time monitoring: analytics dashboard, error tracking, support channel

### Launch Day

#### Hour-by-Hour Plan
| Time (PST) | Action | Platform |
|-----------|--------|----------|
| 00:01 | Product Hunt goes live (if PH launch) | PH |
| 06:00 | Post launch thread on Twitter | Twitter/X |
| 06:30 | Share on LinkedIn with professional angle | LinkedIn |
| 07:00 | Email waitlist/contacts | Email |
| 08:00 | Post Show HN (if HN launch) | Hacker News |
| 09:00 | Post in relevant Discord/Slack communities | Communities |
| 10:00 | Post in relevant Reddit communities (value-first) | Reddit |
| 12:00 | Mid-day engagement check — respond to all comments | All |
| 15:00 | Share milestone/update tweet if traction is building | Twitter/X |
| 18:00 | Thank-you tweet/post with early results | All |
| 21:00 | End-of-day summary and plan for Day 2 | Internal |

**Launch day rules:**
- Respond to EVERY comment, question, and mention within 30 minutes
- Be genuine and helpful, not salesy
- Share behind-the-scenes content throughout the day
- Monitor for bugs — launch day traffic will find them
- Have a "war room" setup: analytics, support, social all visible

### Post-Launch (Week 1-4)

#### Week 1: Momentum
- Respond to all feedback and feature requests
- Share user testimonials and early results
- Write "lessons from launch" thread
- Publish technical deep-dive blog post
- Send follow-up email to signups with onboarding tips

#### Week 2-4: Sustain
- Start content calendar (from `/content-plan`)
- Begin SEO optimization (from `/seo-audit`)
- Set up analytics and track growth metrics
- Plan first growth experiments (from `/growth-plan`)
- Convert launch buzz into recurring engagement

### Success Metrics
| Metric | Launch Day | Week 1 | Month 1 |
|--------|-----------|--------|---------|
| Unique visitors | [target] | [target] | [target] |
| Signups | [target] | [target] | [target] |
| Activation rate | [target %] | [target %] | [target %] |
| Product Hunt upvotes | [target] | — | — |
| HN points | [target] | — | — |
| Social mentions | [target] | [target] | [target] |
| Revenue (if paid) | [target] | [target] | [target] |
```

### 8. Memory Write

If `.marketing-studio/` directory exists, append to `.marketing-studio/memory.md`:

```markdown
## Launch Plan — [date]
- **Launch venues**: [list]
- **Target launch date**: [date]
- **Pre-launch tasks remaining**: [count]
- **Key success metrics**: [list top 3]
```

## Cross-References

- `/marketing` — Full marketing strategy context
- `/marketing-init` — Set up project context before launch planning
- `/content-plan` — Pre-launch and post-launch content calendar
- `/social-strategy` — Social channel strategy for launch amplification
- `/seo-audit` — Ensure SEO is ready before launch traffic arrives
- `/growth-plan` — Post-launch growth experiments
- `/competitor-analysis` — Position against competitors in launch messaging
- `/marketing-status` — Track launch readiness
- `design-studio:design` — Landing page design if not ready
- `design-studio:social-content` — Launch day social visuals
