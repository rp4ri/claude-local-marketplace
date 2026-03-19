---
description: "Audit UX across an entire app or Figma file — systematically reviews every page/route for usability, consistency, loading states, pagination, and user flow coherence."
argument-hint: "[app description, route path, Figma URL, or 'audit all pages']"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "mcp__*"]
---

# /ux-audit

You are running a comprehensive UX audit. This works with both **code projects** (SvelteKit, Next.js, etc.) and **Figma files**.

Input: **$ARGUMENTS**

## Determine Mode

- If the input references a Figma URL → run **Figma Audit Mode** (Section F below)
- If the input references files, routes, URLs, or says "audit all pages" → run **Code Audit Mode** (Section C below)
- If unclear, check if the current directory has a `package.json` or `src/routes/` → Code Audit Mode. If it has Figma references → Figma Audit Mode.

---

## Section C: Code Audit Mode

### 1. Discover All Routes

Scan the project to build a complete route map:
- **SvelteKit**: `find src/routes -name '+page.svelte'` — each is a page
- **Next.js**: `find app -name 'page.tsx'` or `find pages -name '*.tsx'`
- **Nuxt**: `find pages -name '*.vue'`

List ALL discovered routes before proceeding. Do not skip any.

### 2. Systematic Page-by-Page Audit

For EACH route/page, read the source files (`+page.svelte`, `+page.ts`, `+layout.svelte`, related components) and evaluate:

| Category | What to check |
|----------|--------------|
| **Loading states** | Does it have skeleton/loading UI while data loads? Are there empty states for no-data scenarios? |
| **Pagination** | If it renders lists/tables, is there pagination or infinite scroll for large datasets? |
| **Error handling** | Are there error boundaries? User-friendly error messages? Retry mechanisms? |
| **Navigation** | Can the user get here from the sidebar/nav? Can they get back? Is the current route highlighted in nav? |
| **Responsiveness** | Are Tailwind responsive classes used? Does the layout adapt for mobile? |
| **Accessibility** | Keyboard navigation, focus management, ARIA labels, color contrast |
| **Content hierarchy** | Is the most important information prominent? Is the layout scannable? |
| **Consistency** | Does this page use the same patterns (spacing, colors, typography) as other pages? |
| **User flow** | Does the feature make sense from a user perspective? Can they accomplish their goal? |

### 3. Cross-Page Analysis

After auditing individual pages, evaluate the app holistically:
- **Navigation coherence**: Are all pages reachable? Are there orphan pages? Does the sidebar reflect the actual route structure?
- **Pattern consistency**: Do similar features (forms, tables, cards) use the same components/patterns across pages?
- **Feature completeness**: Are there references to features that don't exist yet (dead links, placeholder pages)?
- **Data presentation**: Is information presented in the most appropriate way? (tables vs cards vs charts)

### 4. Generate Report

```markdown
## UX Audit Report

### Route Map
[List all discovered routes with brief description]

### Critical Issues (must fix)
[Issues that break user flows or prevent task completion]

### UX Improvements (should fix)
[Issues that degrade experience: missing loading states, no pagination, poor mobile layout]

### Consistency Issues
[Patterns that vary across pages when they shouldn't]

### Missing Features
[Expected UX patterns that are absent: empty states, error recovery, keyboard shortcuts]

### Page-by-Page Summary
| Route | Loading | Pagination | Errors | Mobile | Score |
|-------|---------|-----------|--------|--------|-------|
| /dashboard | ⚠️ | ✅ | ❌ | ✅ | 6/10 |
```

---

## Section F: Figma Audit Mode

### 1. Parse the Brief

Extract structured requirements from the user's brief text. Look for:

| Category | What to extract |
|----------|----------------|
| **Pages** | Required page names, count, ordering |
| **Frames** | Frame naming conventions, required sizes (e.g., 1440×900) |
| **Components** | Required component types, variant states, naming patterns |
| **Styles** | Required color palette (hex values), text styles (font, size, weight) |
| **Content** | Required sections, headings, text content, annotations |
| **Variables/Tokens** | Required design tokens, variable collections |
| **Naming** | Specific naming conventions (e.g., `S3-A`, `Brand/Primary`) |

If the brief is unclear on specifics, state your assumptions before auditing.

### 2. Connect to Figma

```
figma_get_status → verify connection
figma_get_file_data(depth: 1, verbosity: 'summary') → get file overview
```

If not connected, guide the user to open the Desktop Bridge plugin.

### 3. Structural Audit

Check page and frame structure against requirements:

```javascript
// Get all pages
figma_execute: `
  const pages = figma.root.children.map(p => ({
    name: p.name,
    id: p.id,
    childCount: p.children.length
  }));
  return pages;
`
```

For each required page:
- Does it exist with the correct name?
- Does it contain the expected frames?

For each required frame:
- Check name matches exactly
- Check dimensions: `frame.width` and `frame.height`
- Check it's on the correct page

### 4. Style Audit

Check Figma styles against requirements:

```javascript
// Get all local styles
figma_execute: `
  const paintStyles = (await figma.getLocalPaintStylesAsync()).map(s => ({
    name: s.name,
    id: s.id,
    paints: s.paints
  }));
  const textStyles = (await figma.getLocalTextStylesAsync()).map(s => ({
    name: s.name,
    id: s.id,
    fontSize: s.fontSize,
    fontName: s.fontName
  }));
  return { paintStyles, textStyles };
`
```

For each required color:
- Does a Paint Style exist with the correct name?
- Does the color value match the required hex?

For each required text style:
- Does a Text Style exist with the correct name?
- Do font family, size, and weight match?

### 5. Component Audit

Check components against requirements:

```javascript
// Find all component sets
figma_execute: `
  await figma.loadAllPagesAsync();
  const sets = figma.root.findAllWithCriteria({ types: ['COMPONENT_SET'] });
  return sets.map(cs => ({
    name: cs.name,
    id: cs.id,
    page: cs.parent?.parent?.name || cs.parent?.name,
    variants: cs.children.map(v => v.name)
  }));
`
```

For each required component:
- Does a COMPONENT_SET exist with the correct name?
- Does it have all required variants?
- Are variant names following the `Property=Value` convention?

### 6. Content Audit

Check text content, sections, and annotations:

```javascript
// Get text content from a specific page
figma_execute: `
  const page = await figma.getNodeByIdAsync('PAGE_ID');
  const textNodes = page.findAllWithCriteria({ types: ['TEXT'] });
  return textNodes.map(t => ({
    characters: t.characters.substring(0, 100),
    parent: t.parent?.name,
    fontSize: t.fontSize
  }));
`
```

For each required content element:
- Does the expected heading/section title exist?
- Is required body text present?
- Are annotations/callouts where they should be?

### 7. Visual Audit

Take screenshots and analyze visually:

```
figma_capture_screenshot(pageNodeId) → for each page
```

Check each screenshot for:
- Layout alignment and spacing consistency
- Visual hierarchy (headings larger than body text)
- Color usage matching the palette
- No obvious visual defects (overlapping elements, cut-off text)
- Content completeness (no placeholder/lorem ipsum unless intentional)

### 8. Variable/Token Audit (if applicable)

If the brief requires design tokens or variables:

```
figma_get_variables(format: 'summary') → get variable overview
```

Check:
- Required variable collections exist
- Required variables within each collection
- Values match specifications
- Modes are set up correctly (e.g., Light/Dark)

### 9. Generate Report

Compile findings into a structured compliance report:

```markdown
## Compliance Audit Report

### Summary
- **File**: [file name]
- **Brief**: [brief summary]
- **Score**: X / Y requirements met
- **Status**: ✅ PASS / ⚠️ PARTIAL / ❌ FAIL

### Detailed Results

| # | Category | Requirement | Status | Notes |
|---|----------|-------------|--------|-------|
| 1 | Structure | Page "Cover" exists | ✅ | — |
| 2 | Structure | Frame "S3-A" at 1440×900 | ✅ | 1440×900 confirmed |
| 3 | Styles | Color "Brand/Primary" = #1B3A5C | ✅ | — |
| 4 | Components | Button with 5 variants | ⚠️ | 4/5 variants found |
| 5 | Content | Critique notes present | ❌ | Section missing |

### Missing Items
[List each missing requirement with specific fix instructions]

### Recommendations
[Optional improvements beyond the brief requirements]
```

## Scoring

- **✅ PASS**: Requirement fully met
- **⚠️ PARTIAL**: Requirement partially met (exists but incomplete/incorrect)
- **❌ FAIL**: Requirement not met

Final score = (PASS count) / (Total requirements) × 100

## Notes

- Use `figma.getNodeByIdAsync()` (async) for all node lookups — dynamic page access requires it
- Use `figma.loadAllPagesAsync()` before searching across pages
- Take screenshots using `figma_capture_screenshot` for current-state validation
- If a requirement is ambiguous, note both your interpretation and the result
- Keep the report factual — report what IS vs what SHOULD BE, without editorializing

## MCP Fallback

If Figma Desktop Bridge is unavailable:
- Ask the user for screenshots of each page/screen and a file description
- Perform a best-effort visual and structural audit from the provided materials
- Flag items that cannot be verified without Figma access

## What's Next

After auditing a Figma file:
- `/figma-create` — fix missing or non-compliant elements directly in Figma
- `/design-review` — run a deeper quality audit (accessibility, usability, content)
- `/design-handoff` — generate developer handoff docs once the design passes audit
- `/figma-sync` — check if code implementation matches the audited design
