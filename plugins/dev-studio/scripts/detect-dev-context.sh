#!/bin/bash
# Detect project dev context for the dev-studio plugin
# Runs at SessionStart to provide bug-hunt with project awareness

PROJECT_DIR="${PWD}"
CONTEXT=""

# --- Previous bug-hunter runs ---
if [ -d "$PROJECT_DIR/.bug-hunter" ]; then
  CONTEXT="${CONTEXT}- Bug Hunter: previous scan data found in .bug-hunter/\n"
  if [ -f "$PROJECT_DIR/.bug-hunter/report.md" ]; then
    REPORT_DATE=$(stat -c '%Y' "$PROJECT_DIR/.bug-hunter/report.md" 2>/dev/null || stat -f '%m' "$PROJECT_DIR/.bug-hunter/report.md" 2>/dev/null)
    if [ -n "$REPORT_DATE" ]; then
      REPORT_AGE=$(( ($(date +%s) - REPORT_DATE) / 86400 ))
      CONTEXT="${CONTEXT}- Last bug-hunt report: ${REPORT_AGE} days ago\n"
    fi
  fi
  if [ -f "$PROJECT_DIR/.bug-hunter/triage.json" ]; then
    CONTEXT="${CONTEXT}- Triage data available\n"
  fi
fi

# --- Dev-studio config ---
if [ -f "$PROJECT_DIR/.dev-studio/config.json" ]; then
  CONTEXT="${CONTEXT}- Dev Studio: project config found\n"
fi

# --- Language detection ---
if [ -f "$PROJECT_DIR/package.json" ]; then
  CONTEXT="${CONTEXT}- Language: JavaScript/TypeScript\n"
elif [ -f "$PROJECT_DIR/pyproject.toml" ] || [ -f "$PROJECT_DIR/setup.py" ]; then
  CONTEXT="${CONTEXT}- Language: Python\n"
elif [ -f "$PROJECT_DIR/go.mod" ]; then
  CONTEXT="${CONTEXT}- Language: Go\n"
elif [ -f "$PROJECT_DIR/Cargo.toml" ]; then
  CONTEXT="${CONTEXT}- Language: Rust\n"
elif [ -f "$PROJECT_DIR/pom.xml" ] || [ -f "$PROJECT_DIR/build.gradle" ] || [ -f "$PROJECT_DIR/build.gradle.kts" ]; then
  CONTEXT="${CONTEXT}- Language: Java/Kotlin\n"
fi

# --- TypeScript ---
if [ -f "$PROJECT_DIR/tsconfig.json" ]; then
  CONTEXT="${CONTEXT}- TypeScript: enabled\n"
fi

# --- Framework (Svelte/SvelteKit first) ---
if grep -q '"@sveltejs/kit"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  CONTEXT="${CONTEXT}- Framework: SvelteKit\n"
elif grep -q '"svelte"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  CONTEXT="${CONTEXT}- Framework: Svelte\n"
elif grep -q '"next"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  CONTEXT="${CONTEXT}- Framework: Next.js\n"
elif grep -q '"nuxt"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  CONTEXT="${CONTEXT}- Framework: Nuxt\n"
elif grep -q '"@angular/core"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  CONTEXT="${CONTEXT}- Framework: Angular\n"
elif grep -q '"react"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  CONTEXT="${CONTEXT}- Framework: React\n"
elif grep -q '"vue"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  CONTEXT="${CONTEXT}- Framework: Vue\n"
fi

# --- Python framework ---
if [ -f "$PROJECT_DIR/pyproject.toml" ]; then
  if grep -q 'django' "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
    CONTEXT="${CONTEXT}- Framework: Django\n"
  elif grep -q 'fastapi' "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
    CONTEXT="${CONTEXT}- Framework: FastAPI\n"
  elif grep -q 'flask' "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
    CONTEXT="${CONTEXT}- Framework: Flask\n"
  fi
fi

# --- Package manager ---
if [ -f "$PROJECT_DIR/pnpm-lock.yaml" ]; then
  CONTEXT="${CONTEXT}- Package manager: pnpm\n"
elif [ -f "$PROJECT_DIR/yarn.lock" ]; then
  CONTEXT="${CONTEXT}- Package manager: yarn\n"
elif [ -f "$PROJECT_DIR/bun.lockb" ] || [ -f "$PROJECT_DIR/bun.lock" ]; then
  CONTEXT="${CONTEXT}- Package manager: bun\n"
elif [ -f "$PROJECT_DIR/package-lock.json" ]; then
  CONTEXT="${CONTEXT}- Package manager: npm\n"
elif [ -f "$PROJECT_DIR/uv.lock" ]; then
  CONTEXT="${CONTEXT}- Package manager: uv\n"
fi

# --- Test runner ---
if grep -q '"vitest"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  CONTEXT="${CONTEXT}- Test runner: Vitest\n"
elif grep -q '"jest"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  CONTEXT="${CONTEXT}- Test runner: Jest\n"
elif [ -f "$PROJECT_DIR/pytest.ini" ] || [ -f "$PROJECT_DIR/pyproject.toml" ] && grep -q 'pytest' "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
  CONTEXT="${CONTEXT}- Test runner: pytest\n"
fi

# --- ORM ---
if grep -q '"drizzle-orm"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  CONTEXT="${CONTEXT}- ORM: Drizzle\n"
elif grep -q '"prisma"' "$PROJECT_DIR/package.json" 2>/dev/null || [ -d "$PROJECT_DIR/prisma" ]; then
  CONTEXT="${CONTEXT}- ORM: Prisma\n"
elif grep -q 'sqlalchemy' "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
  CONTEXT="${CONTEXT}- ORM: SQLAlchemy\n"
fi

# --- CI/CD ---
if [ -d "$PROJECT_DIR/.github/workflows" ]; then
  CONTEXT="${CONTEXT}- CI: GitHub Actions\n"
fi

# --- Docker ---
if [ -f "$PROJECT_DIR/Dockerfile" ] || [ -f "$PROJECT_DIR/docker-compose.yml" ] || [ -f "$PROJECT_DIR/docker-compose.yaml" ]; then
  CONTEXT="${CONTEXT}- Container: Docker\n"
fi

# --- Output ---
if [ -n "$CONTEXT" ]; then
  RESULT=$(printf '{"continue": true, "systemMessage": "Dev Studio detected project context:\\n%s\\nUse this context for bug-hunt triage and analysis."}' "$CONTEXT")
  echo "$RESULT"
else
  echo '{"continue": true}'
fi
