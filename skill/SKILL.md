# Chat Title Token Ticker — the ~x stamp

**Purpose:** a chat's name carries its live size at the end, in **`~x`
format** — `x` is the exact per-message token read from Muse's
`session_status`. Example: `Deep Work ~98412`. The user can watch a long
thread climb toward their rotation threshold from the chat list, without
opening it. If you run a rotation rule ("at N tokens a message, hand over
to a successor"), this ticker and that rule consume the SAME read: the
ticker shows the number, the rotation acts on it.

## The value

- **Source:** `muse.session_status` → `context.estimated_prompt_tokens`.
  No other meter counts — not database token-usage sums (those aggregate
  every model call a message made), not estimates from message count.
- **Format:** the exact integer, no separators, no rounding, no "K". The
  title is `"{base name} ~{value}"`. The base name is the chat's name with
  any previous `~\d+` suffix stripped — a rename never stacks suffixes.
- **Who can read it:** only an agent inside a live turn of that chat.
  There is no external API for another chat's live prompt size, and this
  skill never pretends otherwise — staleness is handled by the loop design
  below, not by fabrication.

## Layer 1 — in-turn refresh (primary, exact, free)

**Mandatory, every turn:** in a ticker-enabled chat, the agent reads
`muse.session_status` at the START of handling every user message and
every handoff — not only when some other rule needs the number. This
read is the ticker's only source; skipping it is the one failure mode
that starves the whole system (in production this froze a title at its
setup value across several busy turns while the loop correctly stayed
silent — there was no drift between state and title to fix). On taking
the read:

1. Write the read to the chat's ticker state file:
   `~/hooks/state/chat-ticker-<chat_id>.json` with
   `{chat_id, base_name, value, stamped_value, updated_at}` — set `value`
   to the fresh read, keep `stamped_value` as-is for one step.
2. If `value` differs from the suffix currently on the chat's name, rename
   the chat to `"{base_name} ~{value}"`.
3. Set `stamped_value` = `value` in the state file. Title and state now
   agree, so the loop stays silent.

This rides turns that are already happening; it costs no extra model
calls.

## Layer 2 — the 10-minute loop (backstop, wake-on-drift only)

One hook per ticker-enabled chat, id `chat-ticker-<first 8 of chat_id>`,
polling every **600 seconds**:

- Script: `~/hooks/scripts/chat-ticker-<chat_id>.sh` (template ships with
  this skill's repo). It reads ONLY the state file — no network, no model.
  If `value` == `stamped_value` (or file/value missing), it ends `silent`.
  If they differ — a turn recorded a fresher read but the rename never
  landed — it ends `wake` with the state as payload.
- The woken worker's whole job: rename the chat to
  `"{base_name} ~{value}"`, set `stamped_value` = `value`, verify, end.
  It sends the user no message — a title fixing itself is not news.
  Exception: if `value` >= the escalation threshold (default 250000,
  configurable), the worker does not rename; it reports the crossing so a
  rotation rule, if the user runs one, governs from there.

Why wake-on-drift instead of a 10-minute agent cron: an agent run pays
the full standing-context floor (100K+ tokens) even to do nothing, so a
naive 10-minute cron burns on the order of 15M+ tokens a day standing
still. The hook script costs zero tokens while the title is current,
which is nearly always, because Layer 1 stamps on every active turn.
Idle chats don't drift; their number only moves when they work.

## Pairing with a rotation rule (optional)

- Same read, two consumers. The ticker never delays, replaces, or softens
  a rotation rule.
- When a chat rotates: the rotating agent disables the old chat's ticker
  hook before archiving it, and the handover brief names the ticker as an
  open thread. The successor's first turn creates its own state file
  (base name = the thread's canonical name, no inherited suffix), its own
  hook, and stamps its fresh read — the new chat's title starts at its
  own floor number, not the old chat's peak.
- A renamed suffix is never part of the base name: records, briefs, and
  successor names use the base name only.

## Enabling the ticker on a chat (once, by an agent in that chat)

1. Note the chat_id and base name (chat list tool).
2. Write the state file with the current `session_status` read as both
   `value` and `stamped_value`.
3. Write the hook script from the template, register the hook with
   `poll_interval_secs: 600` and the worker instruction, dry-run it until
   the decision is a clean `silent`, then enable it.
4. Rename the chat to `"{base_name} ~{value}"` and verify in the chat
   list.

Before enabling, confirm the environment actually exposes: a session
status tool reporting `estimated_prompt_tokens`, a chat rename tool, and
scriptable hooks with a wake mechanism. If any is missing, say which one
and stop — a partial ticker that stamps stale numbers as if live is worse
than none.

## Guardrails

- Never fight a manual rename: if the chat's current name has no `~\d+`
  suffix and doesn't match the recorded base name, the user changed it —
  adopt their name as the new base name, then suffix that.
- The main chat can be renamed like any other; the ticker works there
  too.
- If a rename fails, leave the state unstamped so the loop keeps the
  drift visible instead of stamping a lie.

## Changelog

- v1: two layers (in-turn refresh + 10-minute wake-on-drift hook),
  `include_in_prompt: true`. Generalized from a production setup where it
  runs alongside a 250K rotation rule.
