# OAuth Mobile Auth in Tauri v2

## Core Problem

Android WebView blocks third-party cookies. When your Tauri app (origin `https://tauri.localhost`) makes `fetch()` calls to your backend (`https://your-api.com`), cookies set by the backend are third-party and silently dropped. This breaks OAuth flows that rely on state cookies.

## Solution Architecture

```
┌─────────────────┐     GET /mobile-auth/start        ┌──────────────┐
│  Tauri WebView   │ ──────────────────────────────────▶│   Backend    │
│ tauri.localhost  │                                    │ your-api.com │
└─────────────────┘                                    └──────┬───────┘
        ▲                                                     │
        │  302 redirect to tauri.localhost/auth/callback       │ 302 to Discord
        │  with ?token=XXX                                     │
        │                                                      ▼
        │                                              ┌──────────────┐
        └──────────────────────────────────────────────│   Discord    │
                    302 redirect back                  │  OAuth Page  │
                                                       └──────────────┘
```

### Key Insight

Navigate the **entire WebView** to the backend URL (not `fetch()`). This makes cookies first-party because the WebView's origin becomes your backend domain during the OAuth flow.

## Implementation

### 1. Frontend Login Button

```typescript
const API_URL = 'https://your-api.com';
function loginWithDiscord() {
  window.location.href = `${API_URL}/mobile-auth/start?callbackURL=${encodeURIComponent(`${API_URL}/mobile-auth/callback`)}`;
}
```

### 2. Backend: `/mobile-auth/start` (GET endpoint)

Proxies OAuth initiation server-side, forwarding Set-Cookie headers as first-party:

```typescript
export const GET: RequestHandler = async ({ url, request }) => {
  const callbackURL = url.searchParams.get('callbackURL')
    || `${url.origin}/mobile-auth/callback`;

  const res = await fetch(`${url.origin}/api/auth/sign-in/social`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Cookie': request.headers.get('cookie') || '',
      'Origin': url.origin,
    },
    body: JSON.stringify({ provider: 'discord', callbackURL }),
  });

  const data = await res.json();
  if (!data?.url) return new Response('Failed to start OAuth', { status: 500 });

  const headers = new Headers();
  headers.set('Location', data.url);

  const setCookies = res.headers.getSetCookie?.() || [];
  for (const cookie of setCookies) {
    headers.append('Set-Cookie', cookie);
  }

  return new Response(null, { status: 302, headers });
};
```

### 3. Backend: `/mobile-auth/callback` (GET endpoint)

Reads session after OAuth completes, redirects to Tauri with token:

```typescript
export const GET: RequestHandler = async ({ request, cookies }) => {
  const session = await auth.api.getSession({ headers: request.headers });
  const sessionToken = cookies.get('better-auth.session_token')
    || cookies.get('__Secure-better-auth.session_token');

  if (!session || !sessionToken) {
    throw redirect(302, 'https://tauri.localhost/login?error=oauth_failed');
  }

  throw redirect(302,
    `https://tauri.localhost/auth/callback?token=${encodeURIComponent(sessionToken)}`
  );
};
```

**Critical**: Use HTTP 302 redirect to `tauri.localhost`, NOT `window.location.replace()`. JS redirects fail because `tauri.localhost` doesn't resolve in DNS. HTTP 302 works because Tauri intercepts the redirect before DNS resolution.

### 4. better-auth Configuration

```typescript
import { bearer } from 'better-auth/plugins';

export const auth = betterAuth({
  account: {
    storeStateStrategy: 'cookie' as const,
  },
  advanced: {
    defaultCookieAttributes: {
      sameSite: 'none' as const,
      secure: true,
    },
  },
  plugins: [
    bearer(),
  ],
});
```

### 5. Frontend: Token Storage & API Calls

```typescript
function setAuthToken(token: string) {
  localStorage.setItem('auth_token', token);
}

function getAuthHeaders(): Record<string, string> {
  const token = localStorage.getItem('auth_token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function apiFetch(path: string, options: RequestInit = {}) {
  return fetch(`${API_URL}${path}`, {
    ...options,
    headers: { ...options.headers, ...getAuthHeaders() },
  });
}
```

### 6. Callback Page in Tauri App

```svelte
<script lang="ts">
  import { goto } from '$app/navigation';
  import { page } from '$app/state';

  $effect(() => {
    const token = page.url.searchParams.get('token');
    const error = page.url.searchParams.get('error');

    if (error) { goto('/login'); return; }
    if (token) {
      setAuthToken(token);
      checkAuth().then(ok => goto(ok ? '/home' : '/login'));
    }
  });
</script>
```

## Common Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| `state_security_mismatch` | Default `storeStateStrategy` uses signed cookie that fails cross-origin | Use `storeStateStrategy: 'cookie'` |
| `auth state cookie not found` | State cookie blocked as third-party | Use server-side proxy (navigate WebView to backend) |
| `MISSING_OR_NULL_ORIGIN` | Internal fetch missing Origin header | Add `'Origin': url.origin` to fetch headers |
| JS redirect to tauri.localhost fails | DNS can't resolve `tauri.localhost` | Use HTTP 302 redirect (Tauri intercepts before DNS) |
| Redirect loops back to login | Session token not forwarded to Tauri app | Pass token via URL param + Bearer auth |
| Only `session_token` has SameSite=None | Only configured `session.cookieCache` | Use `defaultCookieAttributes` for ALL cookies |
| System browser loses cookies | WebView and system browser have separate cookie stores | Keep entire OAuth flow inside the WebView |

## What Does NOT Work (Don't Waste Time)

These approaches were all tested and failed:

| Approach | Why It Fails |
|----------|-------------|
| `fetch()` with `credentials: 'include'` from `tauri.localhost` | Third-party cookies blocked |
| `callbackURL=tauri.localhost` in OAuth | better-auth rejects non-matching baseURL |
| HTTP 302 to `tauri.localhost` from external page | DNS resolution failure |
| `window.location.replace('tauri.localhost')` | Same DNS failure |
| Open OAuth in system browser + deep link back | Cookie stores are separate, state cookie lost |
| `mathub://` deep link from inside WebView | WebView navigation to custom scheme doesn't trigger Tauri handler |

## CORS Configuration

Backend must allow requests from Tauri origins:

```typescript
const CORS_ORIGINS = new Set([
  'tauri://localhost',
  'https://tauri.localhost',
]);
```

Add these to better-auth's `trustedOrigins` as well.
