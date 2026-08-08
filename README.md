# HomeDojo

Family behaviour points, self-hosted. Parents award (or deduct) points for
behaviours they define, kids see their balance on the family tablet and swap
points for rewards. No school, no social feed, no cloud — everything lives in
one SQLite file on your own hardware.

Built as a modular Rails 8 monolith so more parent tools (chores, allowance,
screen time) can be added later alongside the `Dojo::` module.

- **Stack:** Rails 8, Hotwire (Turbo + Stimulus), Tailwind CSS, SQLite, Solid Queue/Cache/Cable
- **Footprint:** one container, one volume, ~300–500 MB RAM. Happy on a Pi 4/5 or any NAS.

---

## Quick start (Docker)

```bash
git clone <this repo> homedojo && cd homedojo
cp .env.example .env
openssl rand -hex 64            # paste into SECRET_KEY_BASE in .env
docker compose up -d --build
```

Open `http://<your-host>:3000`. The first-boot wizard asks for your family name
and creates the owner account, then seeds a starter set of behaviours and
rewards. Migrations run automatically on container start.

Upgrades are `docker compose pull && docker compose up -d` (or `--build`).

### Reverse proxy / remote access

The recommended exposure model is **LAN-only or over a VPN** (Tailscale,
WireGuard). If you do put HomeDojo behind Traefik, Caddy or Nginx Proxy Manager
with TLS, set these in `.env`:

```
FORCE_SSL=1
APP_HOSTS=homedojo.example.com
```

`FORCE_SSL` is off by default on purpose — forcing HTTPS breaks a plain-http LAN
install. `/up` is always reachable for health checks.

---

## Local development

Ruby 3.3+ and SQLite are the only prerequisites.

```bash
bundle install                  # also writes Gemfile.lock
bin/rails db:prepare
bin/rails db:seed               # optional demo family; DEMO=1 adds point history
bin/dev                         # Rails + Tailwind watcher on :3000
```

The demo family signs in as `parent@example.com` / `homedojo123`, with kid PINs
`1234` (Ada) and `2345` (Bo).

Once `bundle install` has produced a `Gemfile.lock`, you can flip
`BUNDLE_DEPLOYMENT` back to `"1"` in the `Dockerfile` for reproducible builds.

---

## How it works

### The core loop

The dashboard shows a card per child with their balance. Tap a child, the
behaviour picker slides up, tap a behaviour — done, three taps. The balance
animates in place over Turbo Streams and a toast offers **Undo**. Tick several
children first and one tap awards them all.

Undo is available for a day, and only while the points are still there — once a
child has spent them, undo is refused and you make an adjustment instead. That
keeps the cached balance exactly equal to the ledger at all times.

### The ledger

`dojo_point_events` is an append-only ledger. Undo stamps `reverted_at` and
reverses the balance rather than deleting the row, so the history a family looks
back on stays honest. Every event stores both what was asked for
(`requested_points`) and what was actually applied (`points`).

`children.points_balance` is a cached counter updated in the same transaction as
the event. It is always recomputable:

```bash
bin/rails dojo:recalculate_balances
```

### Never below zero

By default a deduction can only take away points a child actually has: a −2 on a
balance of 1 records −1, and the activity feed says so. Turn this off in
**Settings → Allow negative balances** if your family prefers a true running
total.

### Kid view

`/kids` is a read-only screen for a shared family tablet. A kid taps their face,
enters a 4–6 digit PIN (set per child, optional), and sees their balance, recent
points and the reward catalogue. Kids can *request* a reward; points only move
when a parent approves. Nothing in the kid view can create or change a point
event.

Add it to a tablet home screen — the PWA manifest makes it launch full screen.

### Rewards

Parents redeem directly from a child's page (approved and deducted in one step).
Kid requests land in **Rewards → Requests** with a badge in the nav. Approving
deducts; "Mark as given" is bookkeeping; "Refund" returns the points.

---

## Configuration

Everything is environment variables — see `.env.example`.

| Variable | Default | Purpose |
|---|---|---|
| `SECRET_KEY_BASE` | — | **Required.** `openssl rand -hex 64` |
| `TZ` | `UTC` | Groups days and weeks in reports |
| `APP_HOST` | `localhost:3000` | Host used in emailed links |
| `FORCE_SSL` | off | Set to `1` behind a TLS proxy |
| `APP_HOSTS` | unset (any host) | Comma-separated allow-list |
| `SOLID_QUEUE_IN_PUMA` | — | Run background jobs inside the web process |
| `SMTP_*` | unset | Optional; without it no email is ever sent |

Family-level options live in **Settings**: family name, week start day, negative
balances, kid view on/off, kid reward requests on/off.

### Email is optional

Digest emails are **off** by default and the app never contacts an SMTP server
unless `SMTP_ADDRESS` is set. To reset a forgotten password without email, run
on the host:

```bash
docker compose exec app bin/rails homedojo:reset_password EMAIL=you@example.com PASSWORD=...
```

To turn digests on, set the `SMTP_*` variables and add to `config/recurring.yml`:

```yaml
production:
  weekly_digest:
    class: WeeklyDigestJob
    schedule: every sunday at 7pm
```

---

## Backups

The entire state is one directory: `/rails/storage` (the `homedojo_storage`
volume). It holds the SQLite databases and every uploaded avatar.

```bash
# consistent hot backup into storage/backups/<timestamp>
docker compose exec app bin/rails homedojo:backup

# or copy the whole volume while the app is stopped
docker compose stop app
docker run --rm -v homedojo_storage:/data -v "$PWD":/out alpine \
  tar czf /out/homedojo-$(date +%F).tar.gz -C /data .
docker compose start app
```

For continuous replication to a NAS share or S3-compatible target, point
[Litestream](https://litestream.io) at `storage/production.sqlite3`.

---

## Useful commands

```bash
bin/rails dojo:recalculate_balances      # rebuild balances from the ledger
bin/rails homedojo:users                 # list parent accounts
bin/rails homedojo:reset_password EMAIL=... PASSWORD=...
bin/rails homedojo:backup
bin/rails test                           # models, controllers, integration
bin/rails test:system                    # the award-points loop end to end
bin/rubocop && bin/brakeman              # style and security
```

---

## Project layout

```
app/
  models/
    family.rb  user.rb  child.rb  session.rb  current.rb
    dojo/
      behavior.rb  point_event.rb  reward.rb  redemption.rb  child_report.rb
  controllers/
    setup_controller.rb  sessions_controller.rb  passwords_controller.rb
    dojo/     # parent side: dashboard, children, behaviors, point_events,
              # rewards, redemptions, reports, settings, users
    kids/     # read-only tablet view behind a per-child PIN
  javascript/controllers/   # toast, modal, tabs, multi-select, reorder, pin pad
lib/tasks/homedojo.rake
```

Future modules (`Chores::`, `Allowance::`) mount alongside `Dojo::` and share
`Family`, `User` and `Child`.

---

## Roadmap

Multi-family support (every query is already scoped by `family_id`, so this is
mostly invites and onboarding), web push notifications, a chores module that
auto-awards points, point expiry / weekly reset options, CSV export,
localisation.
