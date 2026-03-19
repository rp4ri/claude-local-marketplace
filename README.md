# claude-local-marketplace

Personal Claude Code plugin marketplace for third-party plugins not yet in the official marketplace.

## Plugins

| Plugin | Version | Upstream | Description |
|--------|---------|----------|-------------|
| [design-studio](./plugins/design-studio) | 4.8.0 | [naksha-studio](https://github.com/Adityaraj0421/naksha-studio) | Virtual design team — 26 roles, 60 commands for UI/UX workflows, Figma, social media, email, data viz |
| [marketing-studio](./plugins/marketing-studio) | 1.0.0 | [agency-agents](https://github.com/msitarzewski/agency-agents) (adapted) | Virtual marketing team — 8 roles, 11 commands, 2 agents, 3 pipelines, 6,400+ lines for SEO, growth hacking, AI citations, content strategy, social media |

## Plugin Details

### design-studio
Adapted from naksha-studio. Rebranded, hooks cleaned up, prompts improved for SvelteKit workflows. See [CLAUDE.md](./CLAUDE.md) for update process.

### marketing-studio
Original plugin inspired by [agency-agents](https://github.com/msitarzewski/agency-agents) marketing role files. Not a clone — rebuilt from scratch as a Claude Code plugin with commands, routing skill, and reference files tailored for solo developer/founder marketing of SaaS, dev tools, and open-source projects.

**Commands**: `/marketing-init`, `/marketing`, `/seo-audit`, `/ai-citations`, `/growth-plan`, `/content-plan`, `/social-strategy`, `/launch-plan`, `/competitor-analysis`, `/reddit-strategy`, `/marketing-status`

**Agents**: `seo-scanner` (haiku), `citation-checker` (haiku)

**Pipelines**: `product-launch`, `competitive-intel`, `content-cycle`

## Setup

Add this marketplace to Claude Code:

```bash
claude plugin marketplace add rp4ri/claude-local-marketplace
```

Then install plugins:

```bash
claude plugin install design-studio
claude plugin install marketing-studio
```
