# HomeDojo for TrueNAS

This directory contains two deployment formats:

- `custom-app.yaml` is a fallback and pre-catalog smoke test for **Apps →
  Discover → ⋮ → Install via YAML** on TrueNAS 24.10 or newer.
- `ix-dev/community/homedojo/` is the source contribution for the official
  [`truenas/apps`](https://github.com/truenas/apps) community train.

## Test the custom app

1. Make `ghcr.io/lockerbill/homedojo:1.0.0` public.
2. Create a Custom App named `homedojo` and paste `custom-app.yaml` into the
   YAML editor.
3. Open `http://<truenas-host>:31080` and complete the first-run wizard.
4. Restart the app and confirm the family and uploaded avatars remain present.

HomeDojo generates its Rails signing key on first boot and stores it inside the
same `/rails/storage` volume as its SQLite databases and uploads. Back up that
entire volume or dataset; do not back up only `production.sqlite3`.

## Prepare the catalog pull request

Copy `ix-dev/community/homedojo` into a current fork of `truenas/apps`, then run
the upstream tools from the catalog repository root:

```bash
./.github/scripts/generate_metadata.py --app homedojo --train community
./.github/scripts/ci.py --app homedojo --train community \
  --test-file basic-values.yaml --render-only=true
./.github/scripts/ci.py --app homedojo --train community \
  --test-file hostpath-smtp-values.yaml --render-only=true
./.github/scripts/port_validation.py
```

After the public image exists, repeat both CI commands without
`--render-only=true` to exercise real deployments. The catalog scripts generate
`item.yaml`, the library snapshot, metadata, and the library hash; do not create
or hand-edit those generated files here.
