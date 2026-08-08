# Parent Tools Platform — Plan & Design

**Project codename:** HomeDojo (working title)
**Deployment target:** Self-hosted / home lab (Docker)
**Stack:** Ruby on Rails 8, Hotwire, SQLite
**First feature:** Family behaviour points tracking (a family-scoped subset of ClassDojo)

---

## 1. Vision & Scope

A self-hosted platform of tools for parents, designed to run comfortably on a home lab (NAS, mini PC, Raspberry Pi, or a small VM). The platform is built as a modular Rails monolith so new parent tools (chores, allowance, screen-time tracking, family calendar, etc.) can be added later as additional modules.

**Feature 1 — Behaviour Points ("Dojo" module):**
Parents award (or deduct) points to their children for behaviours they define themselves, view history and trends, and optionally let kids redeem points for rewards. Everything is private to the family — there is no school, teacher, or social component.

### What's in scope (v1)

- One family per installation (multi-family support deferred — see roadmap)
- Parent accounts with full control; optional read-only kid view
- Child profiles with avatars and point balances
- Customisable behaviours: positive (+points) and needs-work (−points), with icons and colours
- Awarding points to one child or several at once
- Full point history / activity feed with undo
- Weekly and monthly summaries per child (charts)
- Rewards catalogue and point redemption (simple version)
- Mobile-friendly UI (parents will mostly use phones)

### Explicitly out of scope (v1)

- Messaging, photos/stories, portfolios (ClassDojo features that don't fit a family)
- Push notifications (later, via web push)
- Multi-tenancy / SaaS features, billing
- Native mobile apps (PWA instead)

---

## 2. Why this stack for a home lab

| Choice | Rationale |
|---|---|
| **Rails 8** | Batteries included; built-in authentication generator (no Devise needed); Solid Queue / Solid Cache / Solid Cable remove the need for Redis. |
| **SQLite** | Rails 8 treats SQLite as production-ready. One file to back up, zero database container, ideal for a single-family home lab. Postgres remains a config-swap away if ever needed. |
| **Hotwire (Turbo + Stimulus)** | Interactive UI (live point updates, modals, toasts) without a JavaScript SPA. One codebase, no separate frontend build/deploy. |
| **Tailwind CSS** | Fast, consistent styling; pairs well with a component approach (ViewComponent optional). |
| **Puma + Thruster** | Thruster (ships with Rails 8) handles asset caching/compression and can terminate TLS, so a single container can even run without a reverse proxy if desired. |
| **Docker (single image)** | Rails 8 generates a production Dockerfile. One container + one volume = the whole system. Compose file for convenience; works behind Traefik/Nginx Proxy Manager/Caddy — the usual home-lab reverse proxies. |
| **Solid Queue** | Background jobs (summary emails, weekly digests) with no extra infrastructure — jobs live in the same SQLite DB. |

**Resource footprint:** ~300–500 MB RAM, negligible CPU at family scale. Runs happily on a Pi 4/5 or any NAS with Docker.

---

## 3. Architecture

Modular monolith. Modules are namespaced within one Rails app rather than split into services — the right trade-off at this scale.

```
┌─────────────────────────────────────────────────┐
│  Home lab host (Docker)                         │
│                                                 │
│  ┌───────────────────────────────┐              │
│  │  app container (Rails 8)      │              │
│  │  Puma + Thruster              │  ← reverse   │
│  │  Solid Queue (Puma plugin)    │    proxy /   │
│  │  Solid Cache / Solid Cable    │    Tailscale │
│  └──────────────┬────────────────┘              │
│                 │                               │
│      volume: /rails/storage                     │
│        ├── production.sqlite3   (app data)      │
│        ├── queue / cache / cable DBs            │
│        └── Active Storage files (avatars)       │
└─────────────────────────────────────────────────┘
```

### Code organisation

```
app/
  models/
    family.rb  user.rb  child.rb
    dojo/
      behavior.rb  point_event.rb  reward.rb  redemption.rb
  controllers/
    dojo/
      dashboard_controller.rb  behaviors_controller.rb
      point_events_controller.rb  rewards_controller.rb
      redemptions_controller.rb  reports_controller.rb
    kids/                     # read-only kid view
      dashboard_controller.rb
  views/ ...
  components/ ...             # optional ViewComponents
  jobs/
    weekly_digest_job.rb
```

Future tools (chores, allowance) each get their own namespace (`Chores::`, `Allowance::`) and mount alongside `Dojo::`, sharing `Family`, `User`, and `Child`.

---

## 4. Data model

```
Family 1──* User        (parents; role: owner | parent | kid_viewer)
Family 1──* Child
Family 1──* Dojo::Behavior
Family 1──* Dojo::Reward

Child  1──* Dojo::PointEvent *──1 Dojo::Behavior (nullable for manual adj.)
Child  1──* Dojo::Redemption *──1 Dojo::Reward
User   1──* Dojo::PointEvent   (who awarded it)
```

### Tables (v1)

**families** — `name`, `settings (json)` (e.g. allow negative balances, week start day)

**users** — `family_id`, `email_address`, `password_digest`, `name`, `role` (enum: `owner`, `parent`, `kid_viewer`). Rails 8 auth generator provides sessions + password reset.

**children** — `family_id`, `name`, `birthdate (optional)`, `avatar` (Active Storage), `points_balance (integer, cached)`, `archived_at`

**dojo_behaviors** — `family_id`, `name`, `points (integer, may be negative)`, `category` (enum: `positive`, `needs_work`), `icon`, `color`, `position`, `archived_at`
*Seeded defaults on setup: e.g. "Helping at home +2", "Homework done +3", "Kind to sibling +2", "Teasing −2", "Not listening −1" — all editable.*

**dojo_point_events** — `child_id`, `behavior_id (nullable)`, `user_id`, `points (integer)`, `note`, `occurred_at`, `reverted_at (nullable)`
*Immutable ledger. "Undo" sets `reverted_at` and adjusts balance rather than deleting — history stays honest.*

**dojo_rewards** — `family_id`, `name`, `cost (integer)`, `icon`, `archived_at`
*Examples: "30 min extra screen time — 20 pts", "Choose Friday movie — 30 pts".*

**dojo_redemptions** — `child_id`, `reward_id`, `user_id (approving parent)`, `cost (integer, copied at redemption time)`, `status` (enum: `requested`, `approved`, `denied`, `fulfilled`), `created_at`

**Balance integrity:** `points_balance` is a cached counter updated in the same transaction as each `PointEvent`/`Redemption`, and recomputable from the ledger at any time (`rake dojo:recalculate_balances`).

---

## 5. Key user flows

### Award points (the core loop — must be ≤ 3 taps)
1. Dashboard shows child cards with balances.
2. Tap a child (or long-press/checkbox to multi-select) → behaviour picker sheet slides up, positive tab first.
3. Tap a behaviour → point event(s) created, balance animates, toast with **Undo** appears (Turbo Stream update, no page reload).

### Manage behaviours
Settings → Behaviours: drag-to-reorder list, add/edit with name, points, icon (emoji picker is enough for v1), colour. Archiving hides a behaviour from the picker but keeps history intact.

### Rewards & redemption
- Parent flow: open a child → Rewards tab → tap a reward → confirm → balance deducted, redemption logged as `fulfilled`.
- Kid flow (optional, if kid_viewer accounts are enabled): kid sees their balance and reward catalogue, taps **Request** → parent sees a pending request badge and approves/denies.

### Reports
Per child: current balance, points this week vs last week, bar chart of daily net points (last 30 days), breakdown by behaviour, positive-to-needs-work ratio. Weekly digest email (optional, via Solid Queue + SMTP settings) summarising each child's week.

### Kid view
A simplified, read-only dashboard: avatar, big balance number, recent events, reward catalogue. Access via kid_viewer login or a per-child access link/PIN for shared family tablets. No ability to award points.

---

## 6. Routes sketch

```ruby
# config/routes.rb
root "dojo/dashboard#show"

resource :session
resources :passwords, param: :token

namespace :dojo do
  resource :dashboard, only: :show
  resources :children do
    member { get :report }
  end
  resources :behaviors
  resources :point_events, only: [:create, :index] do
    member { post :revert }
  end
  resources :rewards
  resources :redemptions, only: [:create, :index, :update]
end

namespace :kids do
  resource :dashboard, only: :show
end
```

---

## 7. Security & privacy (home-lab specific)

- **All data stays home.** No third-party services required; avatars in local Active Storage; email is optional and uses your own SMTP.
- **Authentication:** Rails 8 built-in auth (bcrypt sessions). Enforce strong owner password at setup. Rate-limit login (`rate_limit` in Rails 8).
- **Authorization:** simple role checks (Pundit optional at this scale). Kid accounts can never create/modify point events; every query is scoped through `Current.family`.
- **Exposure model:** recommend LAN-only or VPN access (Tailscale/WireGuard) as the default; if exposing publicly, put it behind the reverse proxy with TLS and consider forward-auth (Authelia/Authentik) as an extra layer.
- **Backups:** the entire state is one volume. Nightly `sqlite3 .backup` (or Litestream replication to a NAS share/S3-compatible target) + copying the storage directory is a complete backup.

---

## 8. Deployment

Rails 8's generated Dockerfile, plus a minimal compose file:

```yaml
# docker-compose.yml
services:
  app:
    image: ghcr.io/you/homedojo:latest   # or build: .
    restart: unless-stopped
    ports:
      - "3000:80"          # Thruster listens on 80 in-container
    environment:
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - TZ=Australia/Perth
      # optional SMTP_* vars for digests/password resets
    volumes:
      - homedojo_storage:/rails/storage
volumes:
  homedojo_storage:
```

- First-boot setup wizard: create family → create owner account → seed default behaviours → add children.
- Migrations run automatically on container start (`bin/docker-entrypoint` does `db:prepare`).
- Upgrades: pull new image, restart. SQLite migrations are instant at this scale.
- Publish the image via GitHub Actions to GHCR so home-lab users (including future you) can `docker compose pull`.

---

## 9. Testing strategy

- **Models:** balance math, undo semantics, redemption state machine (Minitest, fixtures).
- **System tests:** the award-points loop end-to-end with Turbo (Capybara + headless Chrome) — this flow is the product; it must never break.
- **CI:** GitHub Actions — rubocop, brakeman, test suite, then image build/push on tag.

---

## 10. Build plan

**Phase 0 — Foundation (week 1)**
Rails 8 new app (SQLite, Tailwind, importmap). Auth generator, Family/User/Child models, setup wizard, Dockerfile + compose verified on the home lab.

**Phase 1 — Core points loop (weeks 2–3)**
Behaviours CRUD + seeds, dashboard child cards, behaviour picker sheet, point events with Turbo Stream updates, undo, activity feed. *At the end of this phase the app is already genuinely usable.*

**Phase 2 — Rewards & kid view (week 4)**
Rewards CRUD, redemption flow (parent-direct first, then kid requests), kid_viewer role + read-only dashboard.

**Phase 3 — Reports & polish (week 5)**
Charts (Chartkick + Chart.js via importmap), weekly digest job + SMTP settings page, PWA manifest + icons so it installs to phone home screens, avatar uploads.

**Phase 4 — Hardening (week 6)**
Backup docs/Litestream option, `dojo:recalculate_balances` task, system test coverage of core flows, README with home-lab install guide, first tagged release.

**Later / roadmap ideas**
Multi-family support (proper `family_id` scoping is already in place, so this is mostly onboarding/invites), web push notifications, chores module (`Chores::` — recurring tasks that auto-award points, bridging naturally into allowance), point expiry / weekly reset options, CSV export, localisation.

---

## 11. Open decisions (answer before Phase 1)

1. **Kid access model:** full kid_viewer logins, per-child PIN on a shared tablet, or skip kid view entirely in v1?
2. **Negative balances:** allowed, or floor at zero? (Suggest: family setting, default floor at zero.)
3. **Shared vs per-child behaviours:** v1 assumes one behaviour list for the whole family — sufficient?
4. **Digest emails in v1** or defer (removes SMTP setup entirely from initial install)?
