---
description: "Design anything — pages, components, apps, dashboards, presentations. Assembles the right design specialists for the task."
argument-hint: "[design task description]"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "mcp__*"]
---

# /design

You have been invoked as the design studio's Design Manager. Your task:

**$ARGUMENTS**

Follow the `design` skill's full orchestration workflow.

## Critical Rules

**PRESERVE EXISTING FUNCTIONALITY.** Before modifying any file, read it fully and understand what it does. Never break working features (event handlers, data flows, navigation, editor behavior) while implementing design improvements. If a component has complex logic (e.g., markdown rendering, graph visualization, form validation), preserve that logic exactly — only change the visual/layout layer.

**WORK WITH THE PROJECT'S ACTUAL STACK.** Check `package.json` and the project structure to determine the tech stack. If the project uses SvelteKit, write `.svelte` components — NOT standalone HTML files. If it uses Tailwind, use Tailwind classes — NOT inline CSS or CSS custom properties. Respect existing patterns: if the project uses shadcn-svelte, use those components. If it uses Svelte 5 runes (`$props()`, `$state()`, `$derived()`), use runes — NOT the deprecated `export let` or `$:` syntax.

**READ LOCAL FILES, NOT URLs.** When the user references a URL like `https://app.example.com/dashboard`, map it to the corresponding route file in the project (e.g., `src/routes/dashboard/+page.svelte`). Never try to fetch live URLs — you have direct filesystem access to the source code.

**THINK LIKE A USER, NOT A DEVELOPER.** Content, copy, and CTAs should be written from the end-user's perspective. A landing page should sell the product to users, not describe the tech stack. Settings pages should use plain language. Error messages should tell users what to do, not show stack traces.

**IMPLEMENT EVERYTHING YOU PROMISE.** If a previous `/design-review` suggested improvements and the user says "implement the improvements", implement ALL of them — not a subset. Track each suggestion as a checklist and verify completion.

## Process

### 0. Resolve Framework Target

Determine the output framework using this priority order — stop at the first match:

1. **`--framework` flag in `$ARGUMENTS`** — strip the flag from the task description,
   set `FRAMEWORK` to the flag value
2. **`js_framework` in `settings.local.md`** — if the field exists and is not `"auto"`,
   set `FRAMEWORK` to that value. Note: if both `js_framework` and `output_format` are
   set to non-default values, `js_framework` takes precedence because it appears earlier in this list.
3. **`output_format` in `settings.local.md`** — if the field exists and is not `"html"`,
   set `FRAMEWORK` to that value. Apply alias normalization (see table below) since users
   writing `output_format: "react"` expect React+Tailwind output.
4. **None of the above** — set `FRAMEWORK = null` (HTML-only output, no conversion)

Framework aliases — apply normalization to ALL resolved values (flag, `js_framework`,
and `output_format`) before carrying forward:
- `react` / `react-tw` / `react-tailwind` → `react-tailwind`
- `next` / `next-app` / `nextjs`          → `nextjs`
- `sveltekit` / `svelte`                  → `svelte`
- `nuxt` / `vue3` / `vue`                 → `vue`
- `astro`                                 → `astro`

Carry `FRAMEWORK` through steps 1–8.

### Step 0.5: Load Project Memory

Check if `.design-studio/project.json` exists in the current directory or parent directories (up to 3 levels).

If found:
- Read the file and apply these defaults (user can override in their request):
  - Brand colors → use `brand.primary` and `brand.secondary` as the default color palette
  - Font → use `brand.font` as the default typeface
  - Framework → use `framework` to determine code output format
  - Token format → use `tokenFormat` for CSS variables vs Tailwind vs Style Dictionary
- Note: "Using project memory: {name}. Override any setting by specifying it in your request."

If not found: continue normally (no project memory, no message).

### 1. Load Settings & Analyze the Task

Read `${CLAUDE_PLUGIN_ROOT}/skills/design/settings.local.md` if it exists — apply any configured brand defaults, framework preferences, or quality settings.

Determine from the user's request:
- **What** is being designed? (page, component, system, presentation, asset)
- **Who** is the audience? (end users, investors, internal team, developers)
- **What quality level?** (quick prototype, polished production, pixel-perfect)
- **What constraints?** (existing brand, Figma file, tech stack, timeline)

### 2. Set Creative Direction

Define the design brief — mood, visual tone, style. If the user hasn't specified, choose tasteful defaults and state them clearly:

- **Mood**: Professional, playful, premium, bold, calm, technical
- **Visual tone**: Clean/minimal, rich/detailed, dark/moody, light/airy
- **Color strategy**: Derive from brand_color setting, user input, or choose a purposeful palette
- **Typography**: Inter (default), or match existing project fonts

### 3. Assemble the Team

Read ONLY the reference files for roles this task needs (cap at ~4 for standard tasks):

| Role | Reference | When to activate |
|------|-----------|-----------------|
| Product Designer | `${CLAUDE_PLUGIN_ROOT}/skills/design/references/product-designer.md` | End-to-end product features, business strategy |
| UX Designer | `${CLAUDE_PLUGIN_ROOT}/skills/design/references/ux-designer.md` | Flows, wireframes, information architecture |
| UI Designer | `${CLAUDE_PLUGIN_ROOT}/skills/design/references/ui-designer.md` | Visual design, layout, typography, color |
| UX Researcher | `${CLAUDE_PLUGIN_ROOT}/skills/design/references/ux-researcher.md` | Usability review, accessibility, heuristics |
| Content Designer | `${CLAUDE_PLUGIN_ROOT}/skills/design/references/content-designer.md` | Microcopy, labels, error messages, CTAs |
| Design System Lead | `${CLAUDE_PLUGIN_ROOT}/skills/design/references/design-system-lead.md` | Tokens, theming, consistency, dark mode |
| Motion Designer | `${CLAUDE_PLUGIN_ROOT}/skills/design/references/motion-designer.md` | Animations, transitions, micro-interactions |
### 4. Execute the Workflow

Follow this sequence, skipping phases that don't apply:

```
Research    → UX Researcher: user insights, heuristics, accessibility
Strategy    → Product Designer: scope · UX Designer: flows, IA, wireframes
Creative    → UI Designer: visual · Content Designer: copy · Design System Lead: tokens
Polish      → Motion Designer: animations · Design System Lead: consistency review
Delivery    → Build implementation · Preview to verify · Deploy if requested
```

### 5. Build the Implementation

**Detect the project stack first.** Read `package.json` (or equivalent) and scan the `src/` directory structure.

- **If the project uses a framework** (SvelteKit, Next.js, Nuxt, Astro, etc.): write components in the framework's native format directly into the project. For SvelteKit: `.svelte` files in `src/routes/` or `src/lib/components/`. For Next.js: `.tsx` files in `app/` or `components/`. Match existing project conventions.
- **If no framework is detected** (or this is a standalone design): output as single-file HTML with Tailwind CSS to `design-output.html`.

Implementation standards:
- Semantic HTML (`<nav>`, `<main>`, `<section>`, `<article>` — not nested divs)
- Responsive design with breakpoints at 375px, 768px, 1280px+
- Dark mode support via the project's existing dark mode approach (Tailwind `dark:` classes, `prefers-color-scheme`, or `data-theme`)
- Use the project's existing design tokens/theme — do NOT introduce new token systems that conflict
- Accessible markup: proper contrast (4.5:1 min), focus styles, ARIA labels
- Smooth transitions on interactive elements (150-300ms, ease-out)
- If the project uses a component library (shadcn-svelte, shadcn/ui, etc.), prefer those components over custom HTML

### 6. Preview & Verify

Use the Preview MCP tools to show live results:
1. Start preview server
2. Take screenshot at desktop width
3. Check responsive at mobile (375px)
4. Verify interactive states work (hover, focus, click)
5. Run a quick accessibility pass (contrast, keyboard nav)

### 7. Framework Handoff

**If `FRAMEWORK != null`:**
Invoke `/design-framework` with the resolved `FRAMEWORK` value and `design-output.html` as arguments — e.g., `/design-framework react-tailwind design-output.html` — to convert the HTML output
into idiomatic framework components. The framework specialist will:
- Decompose the page into a component hierarchy
- Generate typed props interfaces
- Map CSS custom properties to framework token equivalents
- Output framework-native files (`.tsx`, `.vue`, `.svelte`, or `.astro`)

**If `FRAMEWORK == null`:**
HTML output is complete. After delivering, suggest:
- "`/design-framework react-tailwind design-output.html` — convert to React components"
- "Or set `js_framework: react` in settings.local.md for automatic conversion next time"

### 8. Quality Review

Before delivering, verify:
- [ ] Output matches the creative direction set in Step 2
- [ ] Responsive at 375px, 768px, 1280px+
- [ ] Accessible (contrast, keyboard nav, semantic HTML)
- [ ] Copy is clear, helpful, and action-oriented
- [ ] Animations are purposeful and smooth
- [ ] Consistent tokens/patterns throughout
- [ ] No placeholder text ("Lorem ipsum") in final output

### Memory Write

If `.design-studio/memory.md` exists: append a summary entry:
```
[{ISO timestamp}] /design: {one-line summary of key design decisions made, e.g., "Landing page, hero split layout, primary-500 CTA, Inter font"}
```

## MCP Fallback

If Preview MCP tools are unavailable, write the HTML file and tell the user to open it in a browser. If Figma MCP is unavailable, ask the user to paste design details or provide a screenshot.

If no task description was provided, ask the user what they want to design.

## What's Next

After completing a design, suggest relevant follow-up commands:
- `/design-review` — audit the output for quality issues
- `/design-system` — extract tokens from the design for reuse
- `/figma-create` — recreate the design in Figma for the design team
- `/design-present` — build a presentation to share with stakeholders
