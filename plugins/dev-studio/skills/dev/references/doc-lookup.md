
# Doc Lookup — Verified Documentation Access

## Documentation Lookup (WebSearch + WebFetch)

When you need to verify a claim about how a library, framework, or API actually behaves — do NOT guess from training data. Look it up using Claude Code's native tools.

### When to use this

- "This framework includes X protection by default" — verify it
- "This ORM parameterizes queries automatically" — verify it
- "This function validates input" — verify it
- "The docs say to do X" — verify it
- Any claim about library behavior that affects your bug verdict

### How to use it

**Step 1: Search for the relevant documentation**

Use WebSearch to find the official documentation page:
```
WebSearch("express.js middleware security default protections site:expressjs.com")
```

Tips for effective searches:
- Always include `site:<official-docs-domain>` to prioritize official docs
- Common doc domains: `site:expressjs.com`, `site:prisma.io`, `site:nextjs.org`, `site:docs.djangoproject.com`, `site:fastapi.tiangolo.com`, `site:svelte.dev`
- If the official domain is unknown, search `<library> official documentation <specific question>`
- Be specific: "prisma raw query parameterized" beats "prisma security"

**Step 2: Fetch and read the documentation**

Once you find the relevant URL from search results, fetch the actual page:
```
WebFetch(url: "https://expressjs.com/en/advanced/security-updates.html")
```

If WebFetch is unavailable, use the Perplexity MCP for deep research:
```
mcp__perplexity-ask__perplexity_ask(question: "Does Express.js sanitize user input in middleware by default? Cite official docs.")
```

**Step 3: Cite what you found**

Always quote the source:
- "Per Express docs (expressjs.com/en/guide/...): [quote]"
- "Prisma docs confirm that $queryRaw uses parameterized queries (prisma.io/docs/...)"

### Rules

- Only look up docs when you have a SPECIFIC claim to verify. Do not speculatively search for every library in the codebase.
- One lookup per claim. Don't chain 5 searches — pick the most impactful one.
- If the search returns nothing useful, say so explicitly: "Could not verify from docs — proceeding based on code analysis."
- Prefer official documentation over blog posts or Stack Overflow answers.
- For security-specific claims, also search the library's security advisories or CVE database.
