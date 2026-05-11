# ADR: CI/CD Approach for Bare-Metal Server

**Date:** 2026-05-11
**Status:** Accepted
**Decision:** Self-hosted GitHub Actions runner (Option B)

---

## Context

The project deploys to a bare-metal Ubuntu 24.04 server with 1 GB RAM, accessible only via VPN (no public SSH). The current deployment process is fully manual: SSH into the server and run `deploy.sh`. We need continuous deployment triggered by pushes to the `main` branch, including Flutter Web builds.

### Constraints

- Server SSH is **VPN-only** -- GitHub cloud runners cannot reach port 22
- Server has **1 GB RAM** (currently ~91 MB used, ~500 MB swap used)
- GitHub free tier: **2,000 Actions minutes/month** (repo is private)
- Cost must be **zero** (no paid plans)
- Flutter Web cannot be built on the server (build requires 2-3 GB RAM)

---

## Options Considered

### Option 1 (Eliminated Early): GitHub Actions + Direct SSH

Cloud runners build everything and SSH into the server to deploy. **Eliminated** because SSH is VPN-only -- would require a tunnel (Cloudflare, Tailscale, WireGuard) adding permanent infrastructure to maintain and a fragile dependency.

### Option A: Custom Webhook Listener + GitHub Actions Hybrid

A lightweight HTTP listener on the server receives GitHub webhook POST events on push to `main`. The server validates the HMAC signature and runs the deploy autonomously (git pull, deps, migrations, restart). Flutter Web is built on a GitHub Actions cloud runner and uploaded as a Release asset, which the server downloads.

### Option B: Self-hosted GitHub Actions Runner + Cloud Runner Hybrid

Install the GitHub Actions runner agent on the server. A single workflow file uses two job types: a cloud runner (`ubuntu-latest`) builds Flutter Web, and the self-hosted runner deploys the backend (git pull, deps, migrations, restart) and extracts the Flutter build. The runner agent only makes outbound connections to GitHub (works behind VPN).

---

## Comparison: Option A (Webhook) vs Option B (Self-hosted Runner)

| Criteria | A (Webhook) | B (Self-hosted) | Notes |
|----------|:-----------:|:----------------:|-------|
| Works behind VPN | YES | YES | Both use outbound connections only |
| GitHub free tier compatible | YES | YES | Both consume Actions minutes only for Flutter cloud build |
| RAM cost (idle) | YES ~5-10 MB | YES ~100-200 MB | With 900 MB free, both are comfortable |
| RAM cost (during deploy) | YES ~30 MB peak | YES ~250 MB peak | Still fine for both given headroom |
| Custom code to write | NO ~200 lines | YES ~0 lines | Webhook needs a listener; runner is a binary you download |
| Custom code to maintain | NO yours forever | YES GitHub maintains it | Bug in your listener = broken deploys with no visibility |
| Setup complexity | NO medium | YES low | Webhook: write script + nginx route + systemd + HMAC. Runner: download binary + register + systemd |
| CI/CD dashboard | NO none | YES full GitHub UI | Webhook logs are only on server via journalctl |
| Deploy logs visibility | NO SSH into server | YES browser (GitHub) | Team members can see deploy status without SSH |
| Failure notifications | NO you implement | YES built-in | GitHub sends email/Slack on failure automatically |
| Concurrency control | NO you implement | YES `concurrency:` key | Two rapid pushes: webhook needs locking logic; runner handles it natively |
| Retry on failure | NO you implement | YES re-run button in UI | GitHub retries webhooks 3x, but YOUR deploy logic has no retry |
| Deploy locking | NO you implement | YES built-in | Prevents two deploys from running simultaneously |
| Flutter + backend in one pipeline | NO two systems | YES one workflow file | Webhook = separate coordination; Runner = `needs:` dependency in YAML |
| Standardization | NO custom/proprietary | YES industry standard | Any dev who knows GitHub Actions can read and modify the workflow |
| Security surface | NO HTTP endpoint exposed | YES no inbound endpoint | Webhook exposes a URL (even with HMAC). Runner only polls outbound |
| Requires nginx change | NO yes (new route) | YES no | Webhook needs `/server03/deploy-webhook` proxied |
| Requires new systemd service | NO yes | NO yes | Both need a systemd service (listener vs runner agent) |
| Offline resilience | YES polls when ready | YES polls when ready | Both handle temporary network outages gracefully |
| Minimal moving parts | NO 3 (listener + Actions + nginx) | YES 2 (runner + Actions) | Less to break |

### Score

| | A (Webhook) | B (Self-hosted) |
|--|:-----------:|:---------------:|
| Wins | 5 | 15 |
| Losses | 12 | 2 |
| Ties | 3 | 3 |

---

## Decision

**Option B (Self-hosted GitHub Actions runner)** is the clear winner.

The only advantage of Option A (webhook) was lower RAM usage (~5-10 MB vs ~100-200 MB). With 900 MB free RAM on the server, this difference is irrelevant. Option B dominates in every other category: zero custom code to write or maintain, full GitHub CI/CD dashboard with logs visible in the browser, built-in concurrency control and failure notifications, a single unified workflow file, no exposed HTTP endpoint, and no nginx changes required.

The self-hosted runner only makes outbound HTTPS connections to GitHub, so it works natively behind the VPN without any tunneling or port exposure.

---

## Architecture

```
Push to main
    |
    +---> GitHub Actions triggers workflow
            |
            +--- Job 1: build-flutter (runs-on: ubuntu-latest)
            |      - Only runs if mobile/ files changed
            |      - flutter build web --release
            |      - Uploads build artifact
            |
            +--- Job 2: deploy (runs-on: self-hosted)
                   - needs: [build-flutter] (waits for Flutter if it ran)
                   - git pull origin main
                   - pip install (if requirements changed)
                   - alembic upgrade head
                   - systemctl restart fcg3-api fcg3-mcp fcg3-ai
                   - Downloads Flutter artifact (if available)
                   - Extracts to /home/grupo3/desafio-fcg3/frontend
                   - Re-ingests knowledge base (if ai_service/knowledge/ changed)
                   - Health checks
```

---

## Consequences

- Server RAM increases by ~100-200 MB idle (acceptable with 900 MB free)
- Runner process must be kept alive via systemd (one-time setup)
- Deploy key already configured -- no additional GitHub auth needed for git pull
- GitHub Actions minutes consumed only for Flutter cloud builds (~5-10 min each, well within 2,000/month)
- Self-hosted runner jobs consume zero GitHub Actions minutes
- All deploy visibility moves from server-only logs to GitHub Actions UI

---

## References

- `docs/deploy.md` -- current manual deploy process
- `docs/ssh-setup.md` -- server SSH and deploy key configuration
- `scripts/deploy.sh` -- existing deploy script (setup + menu-based management)
