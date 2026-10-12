# 3. Reject Set Cumulative Value until phase 2

- **Status**: Accepted
- **Date**: 2026-10-12
- **Affects**: SRS §4.3; SDD §10

## Context

When speed is enabled, CSCS exposes the SC Control Point. Set Cumulative Value lets a central align wheel revolution counts.

## Decision

With speed on, the control point is present, and Set Cumulative Value responds `10 01 04` (Operation Failed) until phase 2.

## Consequences

**Positive**: Honest GATT surface without half-implemented counter sync.

**Negative**: Centrals that require Set Cumulative Value cannot align wheel counts yet.

**Risks / follow-ups**: Phase 2 (#19) implements the delegate and counter updates; mark this PDR Superseded then.
