# Tauri v2 WebView Gotchas & Best Practices

Hard-won lessons from building Tauri v2 Android apps with SvelteKit + Tailwind v4.

## 1. Keyboard Covers Input Fields

**Symptom**: Virtual keyboard opens but covers the text input. `visualViewport`, `h-dvh`, `adjustResize` all seem to do nothing.

**Root cause**: `enableEdgeToEdge()` in `MainActivity.kt` calls `setDecorFitsSystemWindows(false)`, which disables ALL automatic inset handling — including keyboard resize.

**Fix**: Handle IME insets manually in Kotlin (see `tauri-android.md` reference for full code).

**What does NOT work** (don't waste time):
- `visualViewport` API — broken in Tauri Android WebView (issues #7868, #10631)
- `position: absolute` + JS offset calculation — unreliable, race conditions
- CSS `dvh` units alone — depends on WebView resize which doesn't happen without IME insets
- `adjustResize` in AndroidManifest alone — overridden by `enableEdgeToEdge()`

**What DOES work after the Kotlin fix**:
- `h-dvh` + natural flex layout (`shrink-0` for input, `flex-1 overflow-y-auto` for content)
- The WebView actually resizes, so all CSS-based approaches work

---

## 2. Dark Mode / Theme Toggling

**Symptom**: Toggle between light/dark does nothing visually despite code appearing correct.

### Tailwind v4 requires explicit class-based dark mode

Tailwind v4 uses `@media (prefers-color-scheme: dark)` by default. To use a `.dark` class on `<html>`:

```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));
```

**Common mistakes**:
- Using `(&:is(.dark *))` — misses the `.dark` element itself and has higher specificity
- Forgetting to add this line entirely — `dark:` utilities won't respond to class toggling
- Placing it before `@import "tailwindcss"` — must come after

### Theme system: avoid Svelte reactivity

**Do NOT use** `$state` or reactive classes for cross-component theme state. Svelte 5's `$state` in `.svelte.ts` modules has inconsistent reactivity across component boundaries in WebView.

**DO use** pure functions + DOM manipulation:
```typescript
export function setTheme(value: ThemeValue) {
    localStorage.setItem('theme_key', value);
    const resolved = value === 'system'
        ? (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
        : value;
    if (resolved === 'dark') document.documentElement.classList.add('dark');
    else document.documentElement.classList.remove('dark');
}

export function getStoredTheme(): ThemeValue {
    const stored = localStorage.getItem('theme_key');
    return (stored === 'light' || stored === 'dark' || stored === 'system') ? stored : 'system';
}

setTheme(getStoredTheme());
```

---

## 3. Textarea Editing: Cursor Jumping / Text Erasing

**Symptom**: User types in a `<textarea>`, cursor jumps to end, text gets erased or overwritten.

**Root cause**: One-way binding `value={content}` + `oninput` handler that sets state causes cursor reset on every re-render.

**Fix**: Use two-way binding:
```svelte
<!-- GOOD: preserves cursor position -->
<textarea bind:value={content} oninput={scheduleSave} />
```

The `oninput` handler should only trigger side effects (like autosave), NOT set the bound state.

---

## 4. Title Input: Horizontal Truncation

**Symptom**: Long titles get cut off horizontally in `<input type="text">`.

**Fix**: Use `<textarea>` with auto-resize instead:
```svelte
<textarea
    bind:this={titleEl}
    bind:value={title}
    oninput={onTitleInput}
    rows="1"
    class="w-full resize-none overflow-hidden"
></textarea>

<script>
function resizeTitle() {
    if (!titleEl) return;
    titleEl.style.height = 'auto';
    titleEl.style.height = titleEl.scrollHeight + 'px';
}
$effect(() => { title; requestAnimationFrame(resizeTitle); });
</script>
```

---

## 5. Svelte 5 Reactivity Across Components

**Symptom**: A `$state` variable in a `.svelte.ts` module updates in one component but not others.

**Best practices**:
- For UI state shared across 2-3 components: use Svelte context (`setContext`/`getContext`)
- For app-wide persistent state (theme, auth): use pure functions + localStorage + DOM
- For data caches: use a class with `$state` fields, instantiated once via context
- Reserve `$state` in `.svelte.ts` for single-component or parent-child patterns

---

## 6. Content Cut Off at Bottom

**Symptom**: Bottom of scrollable content hidden behind fixed elements or safe area.

**Fix**: Add `pb-16` (or appropriate padding) to the last content container. For safe area:
```css
.safe-bottom { padding-bottom: env(safe-area-inset-bottom, 0px); }
```

---

## 7. Mobile-Web Feature Parity

When maintaining both web and mobile versions of the same app:

- **Always propagate fixes**: After fixing a bug on web, check if the same code path exists in mobile and apply the fix there too.
- **SSE/Streaming**: Verify that SSE streaming works in the Tauri WebView — it may need different event handling than the browser.
- **Settings sync**: API keys, model selection, and preferences must use the same storage mechanism (or sync between web localStorage and Tauri store).

---

## 8. Mobile Screen Dimensions & Layout Mistakes

### NEVER hardcode pixel values for layout calculations

The agent repeatedly wrote CSS like `calc(100dvh - 108px)` where `108px` was a guess. This breaks on every device with different status bar, nav bar, or keyboard heights.

**Real Android element heights (vary by device and density):**

| Element | Typical height | Notes |
|---------|---------------|-------|
| Status bar | 24-28dp (~48-56px @2x) | Varies by device, notch presence |
| Navigation bar | 48dp (~96px @2x) | Can be gesture nav (0dp) or 3-button |
| Keyboard | 250-350dp (~500-700px @2x) | Varies by keyboard app, language, suggestions |
| Action bar / toolbar | 56dp (~112px @2x) | Material standard |
| Bottom nav bar (app) | 56-80dp | Your own UI element |

**The correct approach:** NEVER subtract fixed pixel values. Use flex layout:
```html
<!-- CORRECT: flex layout, no hardcoded heights -->
<div class="flex flex-col h-dvh">
  <header class="shrink-0">...</header>
  <main class="flex-1 overflow-y-auto">...</main>
  <footer class="shrink-0">...</footer>
</div>
```

```html
<!-- WRONG: hardcoded subtraction that breaks on every device -->
<div class="h-[calc(100dvh-108px)]">...</div>
<div class="h-[calc(100dvh-var(--sat,0px)-54px-var(--sab,0px)-54px)]">...</div>
```

### dp vs px vs pt

- **dp (density-independent pixels)**: Android's unit. 1dp = 1px at 160dpi.
- **CSS px**: Not the same as device pixels. On a 2x display, 1 CSS px = 2 device pixels.
- **pt (points)**: iOS unit. 1pt = 1dp essentially.
- A Samsung S24 Ultra at 3x density: `1dp = 3 device pixels`. A `1px` CSS border renders as 3 physical pixels — thicker than expected.

### Border visibility on mobile

The agent oscillated between borders too thick and borders invisible:

| What the agent tried | Result on mobile | Why |
|---------------------|-----------------|-----|
| `border border-neutral-200` | Too thick on 3x displays | 1px CSS = 3 physical pixels |
| `border border-neutral-200/40` | Invisible | 40% opacity on a thin line = invisible |
| `border border-neutral-200/30` | Invisible | Even worse |
| `border-[0.5px] border-neutral-200/70` | Correct | Sub-pixel + moderate opacity = hairline |

**Rule of thumb for mobile borders:**
- Use `border-[0.5px]` for hairline borders (renders as 1 physical pixel on 2x, 1.5 on 3x)
- Use opacity `60-80%` — never below `50%` for functional borders
- Test on actual device, not browser DevTools (DevTools doesn't simulate density correctly)

### Centering failures in WebView

The agent repeatedly failed to center content. Common mistakes:

| Mistake | Fix |
|---------|-----|
| `mx-auto` on a flex child without `w-full` or explicit width | Add `w-full max-w-3xl mx-auto` |
| `items-center` without `min-h-full` on the container | Add `min-h-full` or `h-full` to parent |
| Centering in a scrollable container | Use `flex-1 flex items-center justify-center` inside the scroll area, not on the scroll container itself |
| `text-center` but content still left-aligned | Check if a parent has `text-left` or the element is `inline-block` without full width |

### Font size on mobile

Desktop designs at `text-sm` (14px) may feel small on mobile. Consider:
- Body text: minimum `text-base` (16px) for mobile readability
- Touch-target labels: `text-sm` (14px) minimum with adequate padding
- Titles: test with actual content length — long titles on narrow screens wrap unexpectedly

### The oscillation anti-pattern

The agent's most common mistake is overcorrecting: if borders are "too thick", making them invisible, then being told they're invisible, making them too thick again. 

**Prevention:** When the user says "X is wrong", change X by the **minimum amount** to fix it. Don't swing to the opposite extreme:
- "Border too thick" → try `border-[0.5px]`, not `border-0` or `opacity-30`
- "Text too big" → try one step down (`text-base` → `text-sm`), not three (`text-xs`)
- "Spacing too wide" → try reducing by 25-50%, not removing it entirely

---

## 9. UI Design Fidelity in WebView

When implementing designs for Tauri mobile:

- **Touch targets**: Minimum 44x44pt for all interactive elements. This means `min-h-11 min-w-11` in Tailwind.
- **Border visibility**: Use `border-[0.5px] border-neutral-200/70` for hairline borders. Never go below `opacity-50`.
- **Font rendering**: WebView font rendering differs from desktop browsers. Always test on device.
- **Centering**: Use `flex items-center justify-center` with explicit height, not just `mx-auto`.
- **Padding for safe areas**: After the Kotlin IME fix, use flex layout with `shrink-0` footers, not hardcoded `calc()`.
- **Never delete functional UI elements** while fixing visual issues. If asked to fix borders, only change borders — don't remove buttons, features, or integrations.

---

## 10. Debugging Checklist

When something "doesn't work" in Tauri Android:

1. **Is it a native issue?** Check `MainActivity.kt`, `AndroidManifest.xml` first
2. **Is it a CSS issue?** Inspect with Chrome DevTools (`chrome://inspect/#devices` on debug builds)
3. **Is it a Tauri-specific WebView issue?** Search Tauri GitHub issues before guessing
4. **Is it a framework config issue?** (e.g., Tailwind v4 dark mode syntax)

**Always research before guessing.** Use WebSearch for "tauri android [symptom]" and check official docs. Three failed guesses waste more time than one proper investigation.
