# Security Policy

## Supported versions

The `main` branch receives security fixes; released tags are point-in-time
snapshots and are not patched retroactively. Re-install from `main` or the
latest tag.

## Reporting a vulnerability

Please do **not** open a public issue for security problems.

Use [GitHub's private vulnerability reporting](
https://github.com/WyattAu/uofg_r_mono/security/advisories/new) to report
vulnerabilities. Include a minimal reproduction and the affected package
(`uofgcore`, `uofgstats`). You can expect an initial response within 7 days.

## Scope

This repository ships data-processing utilities only. Reported issues in
upstream dependencies should also be reported upstream; note that
dependency versions are pinned in `renv.lock`, so the fix path is a
lockfile update (see README "Maintenance").
