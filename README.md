# Muse-Chat-Counter_Live

**See how big a Muse chat is — right in its name.**

A Muse skill that stamps a chat's live per-message token count at the end of
the chat's title, in `~x` format:

```
Deep Work ~98412
```

The number is the exact `estimated_prompt_tokens` read from Muse's
`session_status` — the same read an agent uses to judge context pressure — so
the title is a live gauge: you can watch a long thread climb toward your
rotation threshold from the chat list, without opening it.

Built for any Muse agent to pick up and adapt. It pairs naturally with a
rotation rule ("when a chat hits N tokens a message, hand over to a fresh
successor and archive the old one"), but works fine on its own as a gauge.

## How it works

Two layers, because the exact read only exists inside a live turn of the
chat itself:

1. **In-turn refresh (primary, free).** Whenever the agent in a
   ticker-enabled chat reads `session_status` during a turn, it writes the
   value to a small state file and renames the chat if the number moved.
   No extra model calls — it rides turns that already happen.
2. **10-minute wake-on-drift loop (backstop).** A lightweight hook polls the
   state file every 600 seconds. While the title matches the last read it
   stays silent (zero tokens). If a fresher read was recorded but the rename
   never landed, it wakes a worker once to fix the title and re-stamp.

Why not just run an agent every 10 minutes? An agent run pays the full
standing-context floor (100K+ tokens) even to do nothing — a standing
10-minute cron burns on the order of 15M+ tokens a day standing still. The
hook script costs nothing while the title is current, which is nearly
always: the number only moves when the chat is working, and working turns
re-stamp it themselves.

## Install

1. Copy `skill/` into your Muse workspace as a custom skill:

   ```
   ~/workspace/custom-skills/chat_title_token_ticker/
     SKILL.md
     skill.yaml      (include_in_prompt: true — the skill rides every chat)
   ```

2. In each chat you want to track, have your agent enable the ticker
   (the SKILL.md has the exact 4-step procedure): it writes the state file,
   installs the hook from `templates/hook-script.sh`, and renames the chat
   to its first stamp. The intended scope is **every active chat**, with
   every new chat self-enrolling on its first turn — see the Scope
   section of `skill/SKILL.md`.

3. Adapt the knobs: poll interval, the worker prompt
   (`templates/worker-prompt.md`), and the escalation threshold in the
   worker (default 250000 — at or above it, the worker stops renaming and
   reports the crossing instead, so a rotation rule can take over).

## Files

- `skill/SKILL.md` — the skill itself, written to be dropped into a Muse
  custom-skills folder as-is.
- `skill/skill.yaml` — the skill descriptor (`include_in_prompt: true`).
- `templates/hook-script.sh` — the per-chat polling script, parameterized
  by chat id.
- `templates/worker-prompt.md` — the instruction for the woken worker.
- `templates/state-file.json` — the state file shape.
- `examples/` — a worked example with a filled-in state file and the exact
  hook/worker for one chat, so you can see the moving parts wired together.

## Honest limits

- The number is `estimated_prompt_tokens` — Muse's own estimate of the
  current per-message prompt size, not a billing meter.
- No outside process can read another chat's live prompt size. Between
  turns the title shows the last read taken inside the chat. That is a
  design fact, not a bug: the value only changes when the chat takes a
  turn, and turns re-stamp it.
- Renaming assumes your Muse build exposes the chat rename tool to the
  agent; the skill checks for it during setup and says so if it's missing.

## License

MIT — see `LICENSE`. Take it, rename it, re-threshold it, make it yours.
