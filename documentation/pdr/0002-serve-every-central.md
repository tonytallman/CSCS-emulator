# 2. Serve every central

- **Status**: Accepted
- **Date**: 2026-10-12
- **Affects**: SRS §4.4; SDD §10, §11, §16

## Context

The first implementation notified only the first subscribed central. It never disconnected additional centrals; it only withheld measurements from them.

## Decision

Every subscribed central receives the same measurements.

## Consequences

**Positive**: Multiple test devices can observe the emulator at once.

**Negative**: Higher notification load when many centrals subscribe.

**Risks / follow-ups**: Mention multi-central support in the next release What's New.
