# 4. One measurement per tick with advancing halves only

- **Status**: Accepted
- **Date**: 2026-10-12
- **Affects**: SRS §4.3; SDD §10

## Context

The legacy encoder sent every enabled half each second even when revolution counts did not change.

## Decision

At most one notification per second carries only the halves whose count changed (flags `0x03`, `0x01`, or `0x02`). Nothing is sent when neither changed. When the subscriber count rises from 0 and a metric is moving, one sample goes out immediately; a second central waits for the next tick.

## Consequences

**Positive**: Less airtime; clients ignore unchanged halves with Δt = 0.

**Negative**: Some head units may treat silence at a standstill as lost data.

**Risks / follow-ups**: Device testing should confirm client behavior at zero speed.
