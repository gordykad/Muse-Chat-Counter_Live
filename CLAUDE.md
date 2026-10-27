# CLAUDE.md — Muse-Chat-Counter_Live (PUBLIC repo, MIT)

Shows a Muse chat's live size right in its name: the
chat-title-token-ticker stamps `~x` (the exact per-message
`estimated_prompt_tokens` from session status) onto the chat title, and the
chat-rotation ritual rotates a chat at 250K tokens without losing its
brain. You are a specialist consult — the maintainer dispatches packets,
verifies the work, and approves every push.

## The law of this repo: it is public

- **Nothing personal ever lands here.** No real names, chat IDs, private
  operational details, or one workspace's specifics. Write so any Muse
  agent can pick the skill up and adapt it — that is the house
  generalization standard, and this repo is its reference example.
- Before any commit/push: scrub, then **grep-verify** the scrub. An
  unverifiable change does not ship.
- No secrets, no tokens, no real paths beyond `~`-relative placeholders.

## Working rules

- Sources of truth: `skill/SKILL.md` (the ticker), the rotation skill text
  in `skill/` and `templates/`, and `README.md`. Change behavior in the
  skill first, then sync README + templates + examples in the same change —
  the copies must never drift from each other.
- The numbers are the product: the stamp is the **exact integer**, no
  separators, no rounding, no "K". A rename never stacks `~\d+` suffixes.
- The 250K rotation threshold, the 600s wake-on-drift backstop, and the
  no-agent-cron rule (floor-cost burn) are load-bearing design decisions —
  don't "simplify" them away; flag a proposed change instead.
- Keep the docs plain and copy-paste runnable. MIT license stays.
- Token economy: one packet, one job; diffs over rewrites; report only
  what you actually ran and saw.
